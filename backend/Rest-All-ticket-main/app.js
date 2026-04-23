import http from 'http';
import https from 'https';
import express from 'express';
import bodyParser from 'body-parser'
import Router from './src/helpers/Router.js';
import getCertificate from './src/utils/ssl/getCertificate.js';
import { SERVER } from './src/config/config.js';
import cors from 'cors';

class WebServer {
    constructor({ ssl_certificate }) {
        this.app = express();
        this.app.use(cors({
            origin: '*', 
            methods: ['GET','POST','DELETE','UPDATE','PUT','PATCH'],
            allowedHeaders: ['Content-Type', 'Authorization'],
        }))
        this.app.use(express.json());
        this.app.use(bodyParser.json());
        this.router = new Router(this.app).setAllRoutes();
        this.http = http.Server(this.app);
        if (ssl_certificate) this.https = https.Server(ssl_certificate, this.app);
    }

    listen() {
        this.http.listen(SERVER.PORT, () => {
            console.log(`Listening on http://${SERVER.HOST}:${SERVER.PORT}`);
        });
        if (this.https) {
            this.https.listen(SERVER.PORT_SECURE, async () => {
                console.log(`Listening with SSL on https://${SERVER.HOST_SECURE}:${SERVER.PORT_SECURE}`);
            });  
        }           
    }
}

new WebServer({
    ssl_certificate: getCertificate(),
}).listen();
