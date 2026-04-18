import { addToCart, getCart } from '../controllers/controller.cart'
import AWS from '../helpers/aws';
import { FastifyInstance, FastifyPluginOptions } from "fastify";
import Cart from '../entities/entity.cart';
import CONSTANTS from '../config/constants';
import { stripe } from '../helpers/stripe';
import WC from '../helpers/woocommerce';
import { getProductByID } from '../controllers/controller.shop';

async function cartPlugin(fastify: FastifyInstance, options: FastifyPluginOptions) {

    fastify.post('/', async (request, reply) => {
        let body = request.body as { cart: Cart }
        body.cart.idUtente = <bigint><unknown>request.user.id
        try {
            await addToCart(body.cart)
        }
        catch (err) {
            return reply.status(500).send(err)
        }

        return reply.status(200).send({ message: "Cart updated succesfully!" })

    })

    fastify.get('/', async (request, reply) => {
        let products = await getCart(BigInt(request.user.id));
        return reply.status(200).send(products)
    });

    fastify.post('/order/intent', async (request, reply) => {
        try {
            const user = await AWS.DYNAMO.getById(CONSTANTS.DYNAMO.USERS_TABLE, request.user.id);

            if (!user) {
                return reply.status(401).send({ error: 'Utente non trovato' });
            }

            // Assicura che il customer Stripe esista davvero
            let stripeCustomerId = user.customerID;

            if (stripeCustomerId) {
                try {
                    // Verifica esistenza customer su Stripe
                    await stripe.customers.retrieve(stripeCustomerId);
                } catch (err: any) {
                    if (err.code === 'resource_missing') {
                        stripeCustomerId = undefined;
                    } else {
                        throw err; // altri errori Stripe reali
                    }
                }
            }

            // Se non esiste su Dynamo o su Stripe → crealo
            if (!stripeCustomerId) {
                const customer = await stripe.customers.create({
                    email: user.email,
                    metadata: {
                        userId: user.id.toString(),
                        userType: user.userType
                    }
                });

                stripeCustomerId = customer.id;

                await AWS.DYNAMO.updateCustomerID(
                    CONSTANTS.DYNAMO.USERS_TABLE,
                    stripeCustomerId,
                    {
                        userType: user.userType,
                        email: user.email
                    }
                );
            }

            // usa SEMPRE stripeCustomerId da qui in poi
            user.customerID = stripeCustomerId;


            // Ottieni il carrello
            const products = await getCart(BigInt(user.id));
            if (!products || products.length === 0) {
                return reply.status(400).send({ error: 'Il carrello è vuoto.' });
            }

            let amount = 0;
            for (const p of products) {
                amount += p.prezzo * p.quantita * 100;
            }

            if (amount < 50) {
                return reply.status(400).send({ error: 'Totale minimo €0.50.' });
            }

            // Ephemeral key
            const ephemeralKey = await stripe.ephemeralKeys.create(
                { customer: user.customerID },
                { apiVersion: '2024-04-10' }
            );

            // PaymentIntent normale
            const paymentIntent = await stripe.paymentIntents.create({
                amount,
                currency: 'eur',
                customer: user.customerID,
                automatic_payment_methods: { enabled: true },
                capture_method: 'manual'
            });

            return reply.send({
                mode: "direct",
                paymentIntent: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                customer: user.customerID,
                ephemeralKey: ephemeralKey.secret
            });

        } catch (err: any) {
            console.error('Errore PaymentIntent diretto:', err);
            return reply.status(500).send({ error: 'Errore nella creazione del PaymentIntent diretto.', details: err.message });
        }
    });

    fastify.post('/order/intent/marketplace/:idprodotto', async (request, reply) => {
        try {
            const { idprodotto } = request.params as { idprodotto: string };

            if (!idprodotto || isNaN(Number(idprodotto))) {
                return reply.status(400).send({ error: "ID prodotto non valido" });
            }

            const user = await AWS.DYNAMO.getById(CONSTANTS.DYNAMO.USERS_TABLE, request.user.id);
            if (!user) {
                return reply.status(401).send({ error: 'Utente non trovato' });
            }

            // Assicura che il customer Stripe esista davvero
            let stripeCustomerId = user.customerID;

            if (stripeCustomerId) {
                try {
                    // Verifica esistenza customer su Stripe
                    await stripe.customers.retrieve(stripeCustomerId);
                } catch (err: any) {
                    if (err.code === 'resource_missing') {
                        stripeCustomerId = undefined;
                    } else {
                        throw err; // altri errori Stripe reali
                    }
                }
            }

            // Se non esiste su Dynamo o su Stripe → crealo
            if (!stripeCustomerId) {
                const customer = await stripe.customers.create({
                    email: user.email,
                    metadata: {
                        userId: user.id.toString(),
                        userType: user.userType
                    }
                });

                stripeCustomerId = customer.id;

                await AWS.DYNAMO.updateCustomerID(
                    CONSTANTS.DYNAMO.USERS_TABLE,
                    stripeCustomerId,
                    {
                        userType: user.userType,
                        email: user.email
                    }
                );
            }

            // usa SEMPRE stripeCustomerId da qui in poi
            user.customerID = stripeCustomerId;


            // Recupera il prodotto da WooCommerce
            const wpProduct = await getProductByID(Number(idprodotto));
            if (!wpProduct) {
                return reply.status(404).send({ error: "Prodotto non trovato" });
            }

            if (!wpProduct.price) {
                return reply.status(400).send({ error: "Prodotto senza prezzo valido" });
            }

            // Recupero vendor dal metadata
            const vendorEmail = wpProduct.meta_data?.find((m: any) => m.key === "created_by_email")?.value;
            if (!vendorEmail) {
                return reply.status(400).send({ error: "Prodotto non associato a un venditore" });
            }

            const seller = await AWS.DYNAMO.getByEmail(CONSTANTS.DYNAMO.USERS_TABLE, vendorEmail);
            if (!seller?.customerID) {
                return reply.status(400).send({ error: "Il venditore non ha un account Stripe valido" });
            }

            const sellerStripeId = seller.connectAccountId;

            // Importo (in centesimi)
            const amount = Math.round(Number(wpProduct.price) * 100);

            if (amount < 50) {
                return reply.status(400).send({ error: 'Totale minimo €0.50.' });
            }

            // Commissione (ad esempio 10%)
            const fee = Math.round(amount * 0.10);

            // Ephemeral Key
            const ephemeralKey = await stripe.ephemeralKeys.create(
                { customer: user.customerID },
                { apiVersion: '2024-04-10' }
            );

            // PaymentIntent marketplace (solo 1 prodotto)
            const paymentIntent = await stripe.paymentIntents.create({
                amount,
                currency: 'eur',
                customer: user.customerID,
                automatic_payment_methods: { enabled: true },
                capture_method: 'manual',
                application_fee_amount: fee,
                transfer_data: {
                    destination: sellerStripeId!
                },
                metadata: {
                    product_id: idprodotto,
                    product_name: wpProduct.name,

                    seller_user_id: String(seller.id),
                    seller_email: vendorEmail,
                    seller_connect_account_id: sellerStripeId!,

                    buyer_user_id: String(request.user.id),
                    buyer_email: user.email,

                    order_type: "marketplace",
                    order_scope: "single_product",
                    platform: "app_restall_marketplace"
                }
            });


            return reply.send({
                mode: "marketplace",
                productId: idprodotto,
                paymentIntent: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                seller: sellerStripeId,
                customer: user.customerID,
                ephemeralKey: ephemeralKey.secret
            });

        } catch (err: any) {
            console.error('Errore PaymentIntent marketplace:', err);
            return reply.status(500).send({ error: 'Errore nella creazione del PaymentIntent marketplace.', details: err.message });
        }
    });










    // fastify.get('/:idProdotto', async (request, reply) => {
    //     let par = request.params as {idProdotto: number} 
    //     console.log(par)
    //     let product = await getProductByID(par.idProdotto)
    //     console.log(product)
    //     return reply.status(200).send(product)
    // })
}

export default cartPlugin;
