import { FastifyReply, FastifyRequest } from "fastify";
import { AppDataSource } from "../helpers/data-source"; // tua connessione TypeORM
import { RefoundRequest } from "../models/RefoundRequest";
import { createRefund as stripeWooRefund } from "./controller.shop"; // usiamo la funzione già scritta

// Repository TypeORM
const refundRepo = AppDataSource.getRepository(RefoundRequest);

// 1) Get all refund requests
export const getAllRefundRequests = async (_req: FastifyRequest, reply: FastifyReply) => {
  try {
    const requests = await refundRepo.find({ order: { created_at: "DESC" } });
    return reply.send(requests);
  } catch (err) {
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 2) Get refund request by id
export const getRefundRequestById = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { id } = req.params as { id: number };
    const request = await refundRepo.findOneBy({ id });
    if (!request) return reply.status(404).send({ error: "Richiesta non trovata" });
    return reply.send(request);
  } catch (err) {
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 3) Create refund request (cliente)
export const createRefundRequest = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { orderId, amount, reason, lineItems, status } = req.body as {
      orderId: number;
      amount: number;
      reason?: string;
      lineItems?: { id: number; quantity: number }[];
      status?: 'pending' | 'approved' | 'declined' | 'refunded';
    };

    // 🔹 Validazione essenziale
    if (!orderId) {
      return reply.status(400).send({ error: "orderId è obbligatorio" });
    }

    if (!amount) {
      return reply.status(400).send({ error: "amount è obbligatorio (in centesimi)" });
    }

    // 🔹 Gestione default manuali
    const now = new Date();
    const user_id = req.user.id;

    const refundRequest = refundRepo.create({
      order_id: orderId,
      amount,
      reason: reason?.trim() || "Reso cliente",
      status: status || "pending",
      line_items: lineItems?.length ? lineItems : [],
      created_at: now, // default lato codice (in caso il DB non lo gestisca)
      updated_at: now, // idem
      user_id
    });

    await refundRepo.save(refundRequest);

    return reply.status(201).send(refundRequest);
  } catch (err) {
    console.error("Errore in createRefundRequest:", err);
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 4) Approve
export const approveRefundRequest = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { id } = req.params as { id: number };
    const refundRequest = await refundRepo.findOneBy({ id });

    if (!refundRequest) return reply.status(404).send({ error: "Richiesta non trovata" });
    if (refundRequest.status !== "pending") {
      return reply.status(400).send({ error: "Richiesta già processata" });
    }

    refundRequest.status = "approved";
    await refundRepo.save(refundRequest);

    return reply.send(refundRequest);
  } catch (err) {
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 5) Decline
export const declineRefundRequest = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { id } = req.params as { id: number };
    const refundRequest = await refundRepo.findOneBy({ id });

    if (!refundRequest) return reply.status(404).send({ error: "Richiesta non trovata" });
    if (refundRequest.status !== "pending") {
      return reply.status(400).send({ error: "Richiesta già processata" });
    }

    refundRequest.status = "declined";
    await refundRepo.save(refundRequest);

    return reply.send(refundRequest);
  } catch (err) {
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 6) Refund (Stripe + WooCommerce)
export const refundRefundRequest = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { id } = req.params as { id: number };
    const refundRequest = await refundRepo.findOneBy({ id });

    if (!refundRequest) return reply.status(404).send({ error: "Richiesta non trovata" });
    if (refundRequest.status !== "approved") {
      return reply.status(400).send({ error: "Solo le richieste approvate possono essere rimborsate" });
    }

    const refundResult = await stripeWooRefund(
      refundRequest.order_id,
      refundRequest.amount,
      refundRequest.reason,
      refundRequest.line_items
    );

    refundRequest.status = "refunded";
    await refundRepo.save(refundRequest);

    return reply.send({ refundRequest, refundResult });
  } catch (err) {
    return reply.status(500).send({ error: (err as Error).message });
  }
};

// 7) Get refund requests by user_id (with optional status filter)
export const getRefundRequestsByUserId = async (req: FastifyRequest, reply: FastifyReply) => {
  try {
    const { userId } = req.params as { userId: string };
    const { status } = req.query as { status?: 'pending' | 'approved' | 'declined' | 'refunded' };

    if (!userId) {
      return reply.status(400).send({ error: "userId è obbligatorio" });
    }

    // Costruisci condizione dinamica
    const whereClause: any = { user_id: userId };
    if (status) whereClause.status = status;

    const requests = await refundRepo.find({
      where: whereClause,
      order: { created_at: "DESC" },
    });

    if (!requests.length) {
      return reply.status(404).send({ error: "Nessuna richiesta trovata per questo utente" });
    }

    return reply.send(requests);
  } catch (err) {
    console.error("Errore in getRefundRequestsByUserId:", err);
    return reply.status(500).send({ error: (err as Error).message });
  }
};

