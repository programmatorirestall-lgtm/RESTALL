import dotenv from 'dotenv'
dotenv.config()

const SERVER = {
    HOST: process.env.HOST || '0.0.0.0',
    PORT: process.env.PORT || 9001,
    HOST_SECURE: process.env.HOST_SECURE || '0.0.0.0',
    PORT_SECURE: process.env.PORT_SECURE || 443,
}

const DATABASE = {
    USER: process.env.RDS_USER,
    PASS: process.env.RDS_PASS,
    CLUSTER: process.env.RDS_CLUSTER,
    PORT: process.env.RDS_PORT || 3306,
    CONNECTION_LIMIT: 100,
    NAME: process.env.RDS_DB_NAME,
};

const JWT = {
    SECRET_KEY: process.env.JWT_SECRET,
    EXPIRES_IN: 1800000,
}

export {
    SERVER,
    JWT,
    DATABASE
}