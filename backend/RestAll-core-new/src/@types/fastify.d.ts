import * as http from 'http2';

declare module 'fastify' {
    export interface FastifyRequest {
      jwtVerify: () => Promise<any> // Definisci correttamente il tipo restituito
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
      }
    }
}