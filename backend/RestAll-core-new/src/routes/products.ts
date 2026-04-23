import { FastifyInstance, FastifyPluginOptions, FastifyReply } from "fastify";
import {
    getAllProducts,
    getProductByID,
    getAllOrders,
    getOrderById,
    createOrder,
    updateOrder,
    deleteOrder,
    createRefund,
    createDraftProduct,
    updateCategoryParent,
    createCategory,
    findCategoryBySlug,
    getAllUserProducts,
    refundMarketplaceProduct,
    updateProduct,
    deleteProduct
} from '../controllers/controller.shop';
import WC from "../helpers/woocommerce";


async function shopPlugin(fastify: FastifyInstance, options: FastifyPluginOptions) {

    fastify.get('/prodotto', async (request, reply) => {
        let products;
        try {
            products = await getAllProducts();
        } catch (err) {
            return reply.status(500).send(err)
        }
        return reply.status(200).send(products)
    });

    fastify.get('/prodotto/:idProdotto', async (request, reply) => {
        console.log("get prodotto by id")
        let par = request.params as { idProdotto: number }
        console.log(par)
        let product = await getProductByID(par.idProdotto)
        console.log(product)
        return reply.status(200).send(product)
    })

    // --- ORDINI ---

    // Recupera tutti gli ordini
    fastify.get('/orders', async (request, reply) => {
        try {
            const orders = await getAllOrders(request.user.email);
            return reply.status(200).send(orders);
        } catch (err) {
            return reply.status(500).send(err);
        }
    });

    // Recupera un ordine per ID
    fastify.get('/orders/:orderId', async (request, reply) => {
        try {
            const { orderId } = request.params as { orderId: number };
            const order = await getOrderById(orderId);
            return reply.status(200).send(order);
        } catch (err) {
            return reply.status(500).send(err);
        }
    });

    // Crea un nuovo ordine
    fastify.post('/orders', async (request, reply) => {
        try {
            const orderData = request.body;
            const user = request.user;
            const newOrder = await createOrder(orderData, user);
            return reply.status(201).send(newOrder);
        } catch (err) {
            return reply.status(500).send(err);
        }
    });

    // Aggiorna un ordine esistente
    fastify.put('/orders/:orderId', async (request, reply) => {
        try {
            const { orderId } = request.params as { orderId: number };
            const updatedData = request.body;
            const updatedOrder = await updateOrder(orderId, updatedData);
            return reply.status(200).send(updatedOrder);
        } catch (err) {
            return reply.status(500).send(err);
        }
    });

    // Elimina un ordine
    fastify.delete('/orders/:orderId', async (request, reply) => {
        try {
            const { orderId } = request.params as { orderId: number };
            // Se vuoi puoi passare un flag force via query oppure nel body, qui default false
            const force = (request.query as { force?: string })?.force === 'true';
            const deletedOrder = await deleteOrder(orderId, force);
            return reply.status(200).send(deletedOrder);
        } catch (err) {
            return reply.status(500).send(err);
        }
    });

    fastify.post('/orders/:orderId/refund', async (request, reply) => {
        try {
            const { orderId } = request.params as { orderId: number };
            const { amount, reason, lineItems } = request.body as {
                amount: number; // in centesimi
                reason?: string;
                lineItems?: { id: number; quantity: number }[];
            };

            if (!amount) {
                return reply.status(400).send({ error: "amount è obbligatorio (in centesimi)" });
            }

            const refundResult = await createRefund(orderId, amount, reason, lineItems);
            return reply.status(201).send(refundResult);
        } catch (err) {
            return reply.status(500).send({ error: (err as Error).message });
        }
    });

    // ✅ Crea prodotto bozza con categoria padre "marketplace"
    fastify.post('/user/prodotto', async (request, reply) => {
        try {
            const mpRequest = request as any;
            console.log("Multipart request received for draft product creation");

            const parts = mpRequest.parts();
            const productData: Record<string, any> = {};
            const imageFiles: { buffer: Buffer; filename: string; mimetype: string }[] = [];

            for await (const part of parts) {
                if (part.file) {
                    // Legge l'intero file in memoria come buffer
                    const chunks: Uint8Array[] = [];
                    for await (const chunk of part.file) {
                        chunks.push(chunk as Uint8Array);
                    }
                    const buffer = Buffer.concat(chunks);
                    imageFiles.push({
                        buffer,
                        filename: part.filename,
                        mimetype: part.mimetype
                    });
                } else {
                    // campi normali
                    productData[part.fieldname] = part.value;
                }
            }

            console.log("Product data:", productData);
            console.log("Files:", imageFiles.map(f => f.filename));

            // -----------------------------
            // 🔥 GESTIONE CATEGORIA MARKETPLACE
            // -----------------------------

            const MARKETPLACE_SLUG = "marketplace";
            let marketplaceCategory = await findCategoryBySlug(MARKETPLACE_SLUG);

            // Se non esiste, creala
            if (!marketplaceCategory) {
                console.log("Categoria 'marketplace' non trovata, la creo.");
                marketplaceCategory = await createCategory({
                    name: "Marketplace",
                    slug: MARKETPLACE_SLUG,
                    parent: 0
                });
                console.log("Categoria 'marketplace' creata:", marketplaceCategory);
            }

            // Categorie inviate dal client (se esistono)
            const rawCategories = productData.categorie
                ? JSON.parse(productData.categorie)
                : [];


            const finalCategories: number[] = [];
            finalCategories.push(marketplaceCategory.id); // categoria padre obbligatoria

            // 🔥 Per ogni categoria figlia indicata dal client:
            // - se esiste → usa quella sotto "marketplace"
            // - se NON esiste → creala con parent = marketplace
            for (const catName of rawCategories) {
                const catSlug = catName.toLowerCase().replace(/\s+/g, "-");

                let category = await findCategoryBySlug(catSlug);

                if (!category) {
                    category = await createCategory({
                        name: catName,
                        slug: catSlug,
                        parent: marketplaceCategory.id
                    });
                }

                // Garantiamo che sia sotto marketplace (se non lo è, lo spostiamo)
                if (category.parent !== marketplaceCategory.id) {
                    category = await updateCategoryParent(category.id, marketplaceCategory.id);
                }

                finalCategories.push(category.id);
            }

            // Aggiorna le categorie finali da passare al prodotto
            productData.categorie = finalCategories;

            // -----------------------------
            // 🔥 CREA IL PRODOTTO BOZZA
            // -----------------------------
            const user = request.user;

            const draftProduct = await createDraftProduct(productData, user, imageFiles);

            console.log("Draft product created:", draftProduct);
            return reply.status(201).send(draftProduct);

        } catch (err) {
            console.error("Errore nella creazione del prodotto bozza:", err);
            return reply.status(500).send({ error: "Errore creazione prodotto bozza" });
        }
    });

    fastify.get('/user/prodotto', async (request, reply) => {
        try {
            const user = request.user;

            // 1️⃣ Prodotti dell’utente (via helper)
            const products = await getAllUserProducts(user);

            if (!products.length) {
                return reply.send({
                    draft: [],
                    published: [],
                    sold: []
                });
            }

            // 2️⃣ Ordini validi
            const ordersRes = await WC.get("orders", {
                per_page: 100,
                status: "processing,completed"
            });

            const orders = ordersRes.data;

            // 3️⃣ Mappa vendite
            const salesMap: Record<number, any[]> = {};

            for (const order of orders) {
                for (const item of order.line_items) {
                    if (!salesMap[item.product_id]) {
                        salesMap[item.product_id] = [];
                    }

                    salesMap[item.product_id].push({
                        order_id: order.id,
                        date: order.date_created,
                        status: order.status,
                        quantity: item.quantity,
                        total: item.total,
                        customer: {
                            name: `${order.billing.first_name} ${order.billing.last_name}`,
                            email: order.billing.email
                        }
                    });
                }
            }

            // 4️⃣ Classificazione
            const draft: any[] = [];
            const published: any[] = [];
            const sold: any[] = [];

            for (const product of products) {
                const ordersForProduct = salesMap[product.id] || [];
                const totalSold = ordersForProduct.reduce(
                    (sum, o) => sum + o.quantity,
                    0
                );

                const baseProduct = {
                    id: product.id,
                    name: product.name,
                    price: product.price,
                    status: product.status,
                    images: product.images,
                    stock_quantity: product.stock_quantity
                };

                // 🟡 DRAFT
                if (product.status === "draft") {
                    draft.push(baseProduct);
                    continue;
                }

                // 🟢 SOLD
                if (totalSold > 0) {
                    sold.push({
                        ...baseProduct,
                        total_sold: totalSold,
                        orders: ordersForProduct
                    });
                    continue;
                }

                // 🔵 PUBLISHED
                if (product.status === "publish") {
                    published.push(baseProduct);
                }
            }

            return reply.send({
                draft,
                published,
                sold
            });

        } catch (err) {
            console.error("Errore recupero prodotti utente:", err);
            return reply.status(500).send({ error: "Errore recupero prodotti" });
        }
    });

    fastify.post(
        "/marketplace/products/:productId/refund",
        refundMarketplaceProduct
    );

    fastify.put('/user/prodotto/:productId', async (request, reply) => {
        try {
            const { productId } = request.params as { productId: number };
            const user = request.user;
            const body = request.body as Record<string, any>;

            // ❌ Campi non modificabili
            delete body.images;
            delete body.status;

            // 🔒 Recupero prodotto
            const product = await getProductByID(productId);

            if (!product) {
                return reply.status(404).send({ error: "Prodotto non trovato" });
            }

            // 🔐 Verifica ownership
            const createdBy = product.meta_data?.find(
                (m: any) => m.key === "created_by_id"
            )?.value;

            if (String(createdBy) !== String(user.id)) {
                return reply.status(403).send({ error: "Non autorizzato" });
            }

            const updatedProduct = await updateProduct(productId, body);

            return reply.send(updatedProduct);
        } catch (err) {
            console.error("Errore modifica prodotto:", err);
            return reply.status(500).send({ error: "Errore modifica prodotto" });
        }
    });

    fastify.delete('/user/prodotto/:productId', async (request, reply) => {
        try {
            const { productId } = request.params as { productId: number };
            const user = request.user;
            const force = (request.query as { force?: string })?.force === "true";

            const product = await getProductByID(productId);

            if (!product) {
                return reply.status(404).send({ error: "Prodotto non trovato" });
            }

            const createdBy = product.meta_data?.find(
                (m: any) => m.key === "created_by_id"
            )?.value;

            if (String(createdBy) !== String(user.id)) {
                return reply.status(403).send({ error: "Non autorizzato" });
            }

            const deleted = await deleteProduct(productId, force);

            return reply.send({
                success: true,
                deleted
            });
        } catch (err) {
            console.error("Errore cancellazione prodotto:", err);
            return reply.status(500).send({ error: "Errore cancellazione prodotto" });
        }
    });
}

export default shopPlugin;
