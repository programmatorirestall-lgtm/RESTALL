import { FastifyRequest, FastifyReply } from 'fastify';
import WooCommerceRestApi from "@woocommerce/woocommerce-rest-api";
import { stripe } from '../helpers/stripe';
import CONSTANTS from '../config/constants';

// ⚡️ Istanza WooCommerce API v3
const WooCommerce = new WooCommerceRestApi({
  url: CONSTANTS.WOOCOMMERCE.BASE_URL,          
  consumerKey: CONSTANTS.WOOCOMMERCE.WOOCOMMERCE_USER_KEY,
  consumerSecret: CONSTANTS.WOOCOMMERCE.WOOCOMMERCE_USER_SECRET,
  version: "wc/v3"
});

// ----------------- GET AUCTION -----------------
export const getAuctionById = async (request: FastifyRequest, reply: FastifyReply) => {
  const id = (request.params as any).id;

  try {
    const response = await WooCommerce.get(`products/${id}`);
    if (!response.data) return reply.status(404).send({ message: "Auction not found" });

    reply.send(response.data);
  } catch (err: any) {
    console.error("WooCommerce getAuctionById error:", err.response?.data || err.message);
    reply.status(500).send({ message: "Error retrieving auction", error: err.message });
  }
};

// ----------------- GET ACTIVE AUCTIONS -----------------
export const getActiveAuctions = async (_request: FastifyRequest, reply: FastifyReply) => {
  try {
    const response = await WooCommerce.get("products", {
      type: "auction",
      status: "publish"
    });

    reply.send(response.data);
  } catch (err: any) {
    console.error("WooCommerce getActiveAuctions error:", err.response?.data || err.message);
    reply.status(500).send({ message: "Error retrieving auctions", error: err.message });
  }
};

// ----------------- BUY AUCTION -----------------
export const buyAuction = async (request: FastifyRequest, reply: FastifyReply) => {
  const id = (request.params as any).id;
  const body = request.body as { user_id: string; paymentMethodId?: string; paymentIntentId?: string };

  try {
    // Recupera prodotto / asta da WooCommerce
    const auction = await WooCommerce.get(`products/${id}`);
    if (!auction.data) return reply.status(404).send({ message: "Auction not found" });

    // Calcola prezzo corrente dall’API WooCommerce (o dai meta_data del plugin)
    const currentPrice = parseFloat(auction.data.price);

    // 🔹 Stripe payment
    let paymentIntent;
    if (body.paymentIntentId) {
      paymentIntent = await stripe.paymentIntents.confirm(body.paymentIntentId);
    } else if (body.paymentMethodId) {
      paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(currentPrice * 100),
        currency: 'eur',
        payment_method: body.paymentMethodId,
        confirm: true,
        description: `Purchase auction #${id}`,
      });
    } else {
      return reply.status(400).send({ message: "Missing paymentMethodId or paymentIntentId" });
    }

    if (paymentIntent.status !== "succeeded") {
      return reply.status(402).send({ message: "Payment failed or incomplete", paymentIntent });
    }

    // Aggiorna prodotto in WooCommerce come “venduto” o “inactive”
    await WooCommerce.put(`products/${id}`, {
      status: "private", // o cambia meta_data del plugin per segnare asta conclusa
      meta_data: [
        { key: "_auction_winner", value: body.user_id },
        { key: "_auction_end", value: new Date().toISOString() }
      ]
    });

    reply.send({ auction: auction.data, paymentIntent });
  } catch (err: any) {
    console.error("buyAuction error:", err.response?.data || err.message);
    reply.status(500).send({ message: "Payment or auction update error", error: err.message });
  }
};

// ----------------- PLACE BID -----------------
export const placeBid = async (request: FastifyRequest, reply: FastifyReply) => {
  const id = (request.params as any).id;
  const body = request.body as { user_id: string; amount: number };

  try {
    // Recupera prodotto/asta
    const auction = await WooCommerce.get(`products/${id}`);
    if (!auction.data) return reply.status(404).send({ message: "Auction not found" });

    const currentBid = parseFloat(
      auction.data.meta_data.find((m: any) => m.key === "_auction_current_bid")?.value || "0"
    );

    if (body.amount <= currentBid) {
      return reply.status(400).send({ message: "Bid must be higher than current bid" });
    }

    // Aggiorna meta_data con nuova offerta
    await WooCommerce.put(`products/${id}`, {
      meta_data: [
        { key: "_auction_current_bid", value: body.amount },
        { key: "_auction_current_bider", value: body.user_id },
        { key: "_auction_last_bid_time", value: new Date().toISOString() }
      ]
    });

    reply.send({ message: "Bid placed successfully", amount: body.amount });
  } catch (err: any) {
    console.error("placeBid error:", err.response?.data || err.message);
    reply.status(500).send({ message: "Error placing bid", error: err.message });
  }
};
