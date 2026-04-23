import WC from "../helpers/woocommerce";
import { stripe } from "../helpers/stripe";
import { WooRestApiEndpoint } from "woocommerce-rest-ts-api";
import CONSTANTS from "../config/constants";
import AWS from "../helpers/aws";
import axios from "axios";
import { User } from "../entities/entity.user";
import { FastifyReply, FastifyRequest } from "fastify";

export const getAllProducts = async () => {
    try {
        const perPage = 100;
        let page = 1;
        let allProducts: any[] = [];
        let totalPages = 1;

        do {
            const response = await WC.get('products', {
                per_page: perPage,
                page,
                status: 'publish', // opzionale ma consigliato
            });

            allProducts = allProducts.concat(response.data);

            totalPages = parseInt(response.headers['x-wp-totalpages'], 10);
            page++;
        } while (page <= totalPages);

        // filtro finale
        return allProducts.filter((p: any) =>
            p.type === 'simple' &&
            p.stock_status === 'instock'
        );

    } catch (err) {
        console.error(err);
        throw err;
    }
};


export const getAllUserProducts = async (user: any) => {
  try {
    let page = 1;
    let allProducts: any[] = [];

    while (true) {
      const res = await WC.get("products", {
        per_page: 100,
        page,
        status: "any",
        type: "simple"
      });

      if (!res.data.length) break;

      allProducts = allProducts.concat(res.data);
      page++;
    }
    
    const filtered = allProducts.filter((p: any) =>
      p.meta_data?.some(
        (m: any) => m.key === "created_by_id" && String(m.value) === String(user.id)
      )
    );

    return filtered;
  } catch (err) {
    console.error("Errore getAllUserProducts:", err);
    throw err;
  }
};



export const getProductByID = async (idP: number) => {
    let product = await WC.get(`products/${idP}` as WooRestApiEndpoint);
    return product.data
}

export const getAllOrders = async (email: string) => {
    try {
        // 1. Cerco il customer per email
        const customerRes = await WC.get("customers" as WooRestApiEndpoint, { email });

        if (customerRes.data.length > 0) {
            // 🔹 Caso A: utente registrato → recupero ordini per customerId
            const customerId = customerRes.data[0].id;
            const response = await WC.get("orders" as WooRestApiEndpoint, { customer_id: customerId, per_page: 100 });
            return response.data;
        } else {
            // 🔹 Caso B: utente guest → recupero ordini e filtro per email di fatturazione
            const response = await WC.get("orders" as WooRestApiEndpoint, { per_page: 100 });
            const filteredOrders = response.data.filter(
                (order: any) => order.billing?.email?.toLowerCase() === email.toLowerCase()
            );
            return filteredOrders;
        }
    } catch (err) {
        throw err;
    }
};


export const getOrderById = async (orderId: number) => {
    try {
        const response = await WC.get(`orders/${orderId}` as WooRestApiEndpoint);
        return response.data;
    } catch (err) {
        throw err;
    }
}

export const createOrder = async (orderData: any, user: any) => {
    try {
        const response = await WC.post("orders" as WooRestApiEndpoint, orderData);
        let amount = Number(response.data.total || response.data.total_amount || 0);
        AWS.DYNAMO.updateProfitFromShop(CONSTANTS.DYNAMO.USERS_TABLE, (amount / 100 * 2), {
            userType: user.type,
            email: user.email
        }, user.id);
        return response.data;
    } catch (err) {
        throw err;
    }
}

export const updateOrder = async (orderId: number, updatedData: any) => {
    try {
        const response = await WC.put(`orders/${orderId}` as WooRestApiEndpoint, updatedData);
        return response.data;
    } catch (err) {
        throw err;
    }
}

export const deleteOrder = async (orderId: number, force: boolean = false) => {
    try {
        const response = await WC.delete(
            `orders` as WooRestApiEndpoint,
            { force },
            { id: orderId }                      // params (obbligatorio anche se vuoto)
        );
        return response.data;
    } catch (err) {
        throw err;
    }
};

export const createRefund = async (
    orderId: number,
    amountToRefund: number, // in centesimi
    reason: string = "Reso cliente",
    lineItems: { id: number; quantity: number }[] = []
) => {
    try {
        // 1️⃣ Recupero ordine da WooCommerce
        const orderRes = await WC.get(`orders/${orderId}` as WooRestApiEndpoint);
        const order = orderRes.data;

        if (!order) {
            throw new Error(`Ordine ${orderId} non trovato`);
        }

        // 🔹 Assumo che tu abbia salvato il paymentIntentId nello "meta_data" dell'ordine
        const paymentIntentId = order.meta_data?.find(
            (m: any) => m.key === "payment_intent_id"
        )?.value;

        if (!paymentIntentId) {
            throw new Error("Nessun payment_intent_id trovato per l'ordine");
        }

        // 2️⃣ Creo rimborso su Stripe
        const stripeRefund = await stripe.refunds.create({
            payment_intent: paymentIntentId,
            amount: amountToRefund, // in centesimi
        });

        // 3️⃣ Creo rimborso su WooCommerce
        const wcRefundRes = await WC.post(
            `orders/${orderId}/refunds` as WooRestApiEndpoint,
            {
                amount: (amountToRefund / 100).toFixed(2), // Woo vuole amount in formato stringa con decimali
                reason,
                line_items: lineItems, // opzionale
            }
        );

        return {
            stripeRefund,
            wcRefund: wcRefundRes.data,
        };
    } catch (err) {
        throw err;
    }
};

interface WPFile {
    buffer: Buffer;
    filename: string;
    mimetype: string;
}

export const uploadImageToWP = async (file: WPFile) => {
    try {
        const auth = Buffer.from(
            `${CONSTANTS.WP.USER}:${CONSTANTS.WP.PASS}`
        ).toString("base64");

        const uploadRes = await axios.post(
            `${CONSTANTS.WOOCOMMERCE.BASE_URL}/wp-json/wp/v2/media`,
            file.buffer,
            {
                headers: {
                    "Authorization": `Basic ${auth}`,
                    "Content-Disposition": `attachment; filename="${file.filename}"`,
                    "Content-Type": file.mimetype,
                }
            }
        );

        console.log("Image uploaded to WP:", uploadRes.data.source_url);
        return uploadRes.data.source_url;

    } catch (err) {
        console.error("Errore upload immagine su WP:", err);
        throw err;
    }
};

export const createDraftProduct = async (productData: any, user: any, imageFiles: any[]) => {
    try {
        const uploadedImages: { src: string; alt?: string }[] = [];

        for (const file of imageFiles) {
            const imageUrl = await uploadImageToWP({
                buffer: file.buffer,
                filename: file.filename,
                mimetype: file.mimetype
            });

            uploadedImages.push({
                src: imageUrl,
                alt: productData.name || "immagine prodotto"
            });
        }

        const metadata = [
            { key: "created_by_email", value: user.email },
            { key: "created_by_nome", value: user.nome },
            { key: "created_by_cognome", value: user.cognome },
            { key: "created_by_id", value: user.id }
        ];

        const payload = {
            title: productData.title,
            name: productData.name,
            regular_price: productData.regular_price,
            price: productData.regular_price,
            description: productData.description || "",
            short_description: productData.short_description || "",
            stock_quantity: Number(productData.stock_quantity || 0),
            status: "draft",
            meta_data: metadata,
            images: uploadedImages,

            // 🔥 FIX CATEGORIE
            categories: productData.categorie.map((catId: number) => ({
                id: Number(catId)
            }))
        };

        const res = await WC.post("products", payload);
        return res.data;

    } catch (err) {
        console.error("Errore creazione bozza prodotto:", err);
        throw err;
    }
};


export async function findCategoryBySlug(slug: string) {
    const res = await WC.get("products/categories" as WooRestApiEndpoint, {
        slug,
        per_page: 100
    });
    console.log('Categorie trovate con slug', slug, ':', res.data);
    if (res.data && res.data.length > 0) {
        return res.data[0];
    }

    return null;
}

export async function createCategory({ name, slug, parent = 0 }: {
    name: string;
    slug: string;
    parent?: number;
}) {
    const res = await WC.post("products/categories" as WooRestApiEndpoint, {
        name,
        slug,
        parent
    });

    return res.data;
}

export async function updateCategoryParent(categoryId: number, newParentId: number) {
    const res = await WC.put(`products/categories/${categoryId}` as WooRestApiEndpoint, {
        parent: newParentId
    });
    console.log(`Categoria ${categoryId} aggiornata con nuovo parent ${newParentId}:`, res.data);

    return res.data;
}

export async function ensureMarketplaceCategory() {
    const slug = "marketplace";

    let marketplace = await findCategoryBySlug(slug);

    if (!marketplace) {
        marketplace = await createCategory({
            name: "Marketplace",
            slug,
            parent: 0
        });
    }

    return marketplace;
}

export const refundMarketplaceProduct = async (
  req: FastifyRequest,
  reply: FastifyReply
) => {
  try {
    const { productId } = req.params as { productId: string };

    if (!productId) {
      return reply.status(400).send({ error: "productId obbligatorio" });
    }

    /**
     * 1️⃣ Troviamo il PaymentIntent associato al prodotto
     * (usando i metadata)
     */
    const paymentIntents = await stripe.paymentIntents.search({
      query: `metadata['product_id']:'${productId}'`,
      limit: 1,
    });

    if (!paymentIntents.data.length) {
      return reply
        .status(404)
        .send({ error: "Pagamento non trovato per questo prodotto" });
    }

    const paymentIntent = paymentIntents.data[0];

    if (!paymentIntent.latest_charge) {
      return reply
        .status(400)
        .send({ error: "Nessuna charge associata al pagamento" });
    }

    const chargeId =
      typeof paymentIntent.latest_charge === "string"
        ? paymentIntent.latest_charge
        : paymentIntent.latest_charge.id;

    /**
     * 2️⃣ Creiamo il refund
     * Stripe gestisce automaticamente:
     * - reverse transfer
     * - rientro fondi dal connected account
     * - fee
     */
    const refund = await stripe.refunds.create({
      charge: chargeId,
      reason: "requested_by_customer",
    });

    return reply.send({
      success: true,
      refund,
    });
  } catch (err) {
    console.error("Errore refund marketplace product:", err);
    return reply.status(500).send({
      error: (err as Error).message,
    });
  }
};

export const updateProduct = async (
    productId: number,
    data: Record<string, any>
) => {
    try {
        const payload: any = {};

        // 🔥 whitelist campi aggiornabili
        const allowedFields = [
            "name",
            "regular_price",
            "price",
            "description",
            "short_description",
            "stock_quantity",
            "categories",
            "meta_data"
        ];

        for (const key of allowedFields) {
            if (data[key] !== undefined) {
                payload[key] = data[key];
            }
        }

        const res = await WC.put(
            `products/${productId}` as WooRestApiEndpoint,
            payload
        );

        return res.data;
    } catch (err) {
        throw err;
    }
};

export const deleteProduct = async (
    productId: number,
    force: boolean = false
) => {
    try {
        const res = await WC.delete(
            `products` as WooRestApiEndpoint,
            { force },
            { id: productId }
        );

        return res.data;
    } catch (err) {
        throw err;
    }
};







