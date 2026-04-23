import mysql from 'mysql';
import { DATABASE } from '../config/config.js';

var pool = mysql.createPool({
    connectionLimit : DATABASE.CONNECTION_LIMIT,
    host : DATABASE.CLUSTER,
    port: DATABASE.PORT,
    user : DATABASE.USER,
    password : DATABASE.PASS,
    database : DATABASE.NAME
})


export default pool;