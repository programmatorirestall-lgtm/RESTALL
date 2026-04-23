import fastify from 'fastify';
import CONSTANTS from './src/config/constants';
import { AppDataSource } from './src/helpers/data-source';
import fastifyMultipart from '@fastify/multipart';

const server = fastify();

declare module 'fastify' {
  interface FastifyRequest {
    jwtVerify: () => Promise<any>;
    user: {
      type: string,
      id: string,
      email: string,
      nome: string,
      cognome: string,
      dataNascita: string,
      codFiscale: string,
      context: string,
      completed: string,
      verified: string
    };
  }
}

// Init database first
AppDataSource.initialize()
  .then(() => {
    console.log('📦 Database connected');

    // Register plugins after DB init
    server.register(require('@fastify/jwt'), {
      secret: CONSTANTS.JWT.SECRET_KEY,
      verify: { allowedIss: CONSTANTS.JWT.ISSUER }
    });

    server.register(fastifyMultipart, {
      limits: { fileSize: 10 * 1024 * 1024 } // 10MB
    });

    server.register(require('./src/routes/healthCheck'), { logLevel: 'info' });
    server.register(require('./src/routes/products'), { prefix: 'api/v1/shop', logLevel: 'info' });
    server.register(require('./src/routes/cart'), { prefix: 'api/v1/shop/cart', logLevel: 'info' });
    server.register(require('./src/routes/auctionRoutes').default, { prefix: 'api/v1/shop/auctions', logLevel: 'info' })
    server.register(require('./src/routes/refoundRequests').default, { prefix: 'api/v1/shop/refund-requests', logLevel: 'info' })

    server.addHook('onRequest', async (request, reply) => {
      if (request.url === '/') return reply.send("OK");
      try {
        await request.jwtVerify();
      } catch (err) {
        reply.send(err);
      }
    });

    server.listen({ port: CONSTANTS.SERVER.PORT, host: CONSTANTS.SERVER.HOST }, (err, address) => {
      if (err) {
        console.error(err);
        process.exit(1);
      }
      console.log(`🚀 Server listening at ${address}`);
    });
  })
  .catch((err: any) => {
    console.error('❌ Error initializing database:', err);
    process.exit(1);
  });
