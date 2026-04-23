import { FastifyInstance } from 'fastify';
import { getAuctionById, buyAuction, getActiveAuctions, placeBid } from '../controllers/controller.auction';

export default async function (fastify: FastifyInstance) {
  fastify.get('/:id', getAuctionById);
  fastify.get('/', getActiveAuctions);
  fastify.post('/:id/buy', buyAuction);
  fastify.put('/:id', placeBid);
}