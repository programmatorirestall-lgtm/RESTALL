import { FastifyInstance } from "fastify";
import {
  getAllRefundRequests,
  getRefundRequestById,
  createRefundRequest,
  approveRefundRequest,
  declineRefundRequest,
  refundRefundRequest,
  getRefundRequestsByUserId
} from "../controllers/controller.refound";

export default async function (fastify: FastifyInstance) {
  fastify.get("/", getAllRefundRequests);
  fastify.get("/user/:userId", getRefundRequestsByUserId);
  fastify.get("/:id", getRefundRequestById);
  fastify.post("/", createRefundRequest);
  fastify.post("/:id/approve", approveRefundRequest);
  fastify.post("/:id/decline", declineRefundRequest);
  fastify.post("/:id/refund", refundRefundRequest);
}
