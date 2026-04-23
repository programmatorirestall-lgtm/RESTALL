import mysql from 'mysql2';
import { DATABASE } from '../config/config.js';

var pool = mysql.createPool({
    connectionLimit : DATABASE.CONNECTION_LIMIT,
    host : DATABASE.CLUSTER,
    port: DATABASE.PORT,
    user : DATABASE.USER,
    password : DATABASE.PASS,
    database : DATABASE.NAME,
    maxIdle: DATABASE.CONNECTION_LIMIT, // max idle connections, the default value is the same as `connectionLimit`
    idleTimeout: 60000, // idle connections timeout, in milliseconds, the default value 60000
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0,
    multipleStatements: true
})


export {
    pool
};