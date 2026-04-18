import CONSTANTS from '../config/constants';
import { FastifyInstance, FastifyPluginOptions, FastifyRequest, FastifyReply } from "fastify";

async function authenticatePlugin(fastify: FastifyInstance, opts: FastifyPluginOptions){ 
    fastify.decorate("authenticate", async function (request: FastifyRequest, reply: FastifyReply) {
        
      })
}

export default authenticatePlugin
