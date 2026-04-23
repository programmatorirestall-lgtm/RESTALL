var http = require("http");
var https = require("https");
var express = require('express');
var { createProxyMiddleware } = require("http-proxy-middleware");
var passport = require('passport');
var session = require('express-session');
var cors = require('cors')
const path = require('path')
const cookieParser = require("cookie-parser");
const { TARGET_SERVER, SERVER } = require("./src/config/config.js");
const appleRoute = require('./src/router/apple-site.js')
const authRoutes = require('./src/router/auth.js');
const userRoutes = require('./src/router/user.js');
const healthCheck = require('./src/router/healthCheck.js');
const tokenRoutes = require('./src/router/token.js')
const infoRoutes = require('./src/router/info.js')
const getCertificate = require('./src/utils/ssl/getCertificate.js')
const checkIfAuth = require('./src/middlewares/auth.js');


const app = express();
const ticket_target = `${TARGET_SERVER.TICKET.PROTOCOL}://${TARGET_SERVER.TICKET.HOST}:${TARGET_SERVER.TICKET.PORT}`;
const magazzino_target = `${TARGET_SERVER.MAGAZZINO.PROTOCOL}://${TARGET_SERVER.MAGAZZINO.HOST}:${TARGET_SERVER.MAGAZZINO.PORT}`
const core_target = `${TARGET_SERVER.CORE.PROTOCOL}://${TARGET_SERVER.CORE.HOST}:${TARGET_SERVER.CORE.PORT}`

console.log("Ticket target: " + ticket_target);
console.log("Magazzino target: " + magazzino_target);
console.log("Core target: " + core_target);



app.use(cors({ origin: "*", credentials: true}));
app.use(express.json())
app.use(cookieParser())
app.use(session({
    secret: SERVER.SESSION_SECRET,
    name: 'RestAllSession',
    resave: true,
    rolling: true,
    saveUninitialized: true,
    cookie: {
        maxAge: SERVER.SESSION_MAXAGE,
        secure: "auto"
    }
}));

app.use(express.static(__dirname + '../views'));
app.use(express.static(path.join(__dirname, "public-flutter")));
app.set('view-engine', 'ejs');

require('./src/middlewares/Passport.js')(passport);

app.use(passport.initialize());
app.use(passport.session());
app.use(appleRoute);
app.use(authRoutes);
app.use(userRoutes);
app.use(tokenRoutes);
app.use(healthCheck);
app.use(infoRoutes);

app.use('/api/v1/ticket', checkIfAuth, createProxyMiddleware({
    target: ticket_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/api/v1/preventivi', checkIfAuth, createProxyMiddleware({
    target: ticket_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.get('/app', function(req, res){
    res.sendFile(path.join(__dirname, "public-flutter/index.html"));
})

app.use('/api/v1/tecnico', checkIfAuth, createProxyMiddleware({
    target: ticket_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/api/v1/settings', checkIfAuth, createProxyMiddleware({
    target: ticket_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/api/v1/azienda', checkIfAuth, createProxyMiddleware({
    target: core_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/api/v1/shop', checkIfAuth, createProxyMiddleware({
    target: core_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        console.log("shop request")
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/swagger', createProxyMiddleware({
    target: core_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))

app.use('/warehouse', checkIfAuth, createProxyMiddleware({
    target: magazzino_target,
    changeOrigin: true,
    logger: console,
    secure: false,
    onProxyReq: (proxyReq, req, res) => {
        if (
            req.headers['content-type'] &&
            req.headers['content-type'].match(/^multipart\/form-data/)
        ) {
            console.log("form-data")
            proxyReq.setHeader(
                'Content-Length',
                parseInt(req.headers['content-length'])
            )
            proxyReq.setHeader(
                'Content-type',
                req.headers['content-type']
            )
        }
        else if (req.body) {
            console.log("body")
            const bodyData = JSON.stringify(req.body);
            proxyReq.setHeader('Content-Type','application/json');
            proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
            proxyReq.write(bodyData, (error) => console.log(error));
        }
    },
}))


// proxy.on('error', (e) => console.log(e))

// proxy.on('proxyReq', (proxyReq, req, res, options) => {
//     try{
        
//     }
//     catch(error){
//         console.log(error)
//     }
// });

const httpServer = http.createServer(app)
const httpsServer = https.createServer(getCertificate(), app)

httpServer.listen(SERVER.PORT, () => {
    console.log("Proxy listen on port " + SERVER.PORT);
});

httpsServer.listen(SERVER.PORT_SECURE, () => {
    console.log("Proxy listen with SSL on port " + SERVER.PORT_SECURE);
});

