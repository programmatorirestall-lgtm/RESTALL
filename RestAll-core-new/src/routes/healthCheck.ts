import { FastifyInstance, FastifyPluginOptions } from "fastify";

async function healthCheckPlugin(fastify: FastifyInstance, options: FastifyPluginOptions){
    fastify.get('/', async (request, reply) => {
        return reply.status(200).send("health check ok!")
    });
}

export default healthCheckPlugin;