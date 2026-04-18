import mysql from 'mysql2/promise'
import CONSTANTS from '../config/constants'

const pool = mysql.createPool({
    host: CONSTANTS.RDS.HOST,
    port: CONSTANTS.RDS.PORT,
    user: CONSTANTS.RDS.USER,
    database: CONSTANTS.RDS.DATABASE,
    password: CONSTANTS.RDS.PASSWORD,
    waitForConnections: true,
    connectionLimit: 10,
    maxIdle: 10, // max idle connections, the default value is the same as `connectionLimit`
    idleTimeout: 60000, // idle connections timeout, in milliseconds, the default value 60000
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
    //rowsAsArray: true
})

export default pool