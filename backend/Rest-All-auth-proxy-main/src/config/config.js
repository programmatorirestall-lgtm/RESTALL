require('dotenv').config()

const AWS = {
    USERS_TABLE_NAME: process.env.USERS_TABLE_NAME,
    TOKEN_TABLE_NAME: process.env.VERIFY_TOKEN_TABLE_NAME,
    PASSWORD_RESET_TOKEN_TABLE_NAME: process.env.PWD_RESET_TOKEN_TABLE_NAME,
    FCM_TOKEN_TABLE_NAME: process.env.FCM_TOKEN_TABLE_NAME,
    CONFIG: {
      accessKeyId: process.env.AWS_ACCESS_KEY,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      region: 'eu-central-1',
    },
    S3: {
        ACCESS_KEY_ID: process.env.S3_ACCESS_KEY_ID,
        SECRET_ACCESS_KEY: process.env.S3_SECRET_ACCESS_KEY,
        PROPIC_BUCKET: process.env.S3_PROPIC_BUCKET
    },
    LAMBDA: {
        RENEW_LOCATION_FUNC: process.env.AWS_LAMBDA_RENEW_FUNCTION,
        ACCOUNT_DELETION_FUNC: process.env.AWS_LAMBDA_ACCOUNT_DELETION_FUNCION,
        NETWORK_LAMBDA_NAME: process.env.NETWORK_LAMBDA_NAME
    }
}

const GOOGLE = {
    ACCESS_KEY_ID: process.env.GOOGLE_ACCESS_KEY,
    SECRET: process.env.GOOGLE_SECRET,
    CALLBACK: process.env.GOOGLE_CALLBACK
}

const FACEBOOK = {
    FACEBOOK_APP_ID: process.env.FACEBOOK_APP_ID,
    FACEBOOK_APP_SECRET: process.env.FACEBOOK_APP_SECRET
}

const JWT = {
    SECRET_KEY: process.env.JWT_SECRET_KEY,
    EXPIRES_IN: 60000*30,
    REFRESH_SECRET_KEY: process.env.REFRESH_SECRET_KEY,
    REFRESH_EXPIRES: 86400000*7,
    ISSUER: process.env.JWT_ISSUER
}

const SERVER = {
    HOST: process.env.HOST || '0.0.0.0',
    PORT: process.env.PORT || 5000,
    PORT_SECURE: process.env.PORT_SECURE || 5001,
    SESSION_SECRET: process.env.SESSION_SECRET,
    SESSION_MAXAGE: 18000000
}

const TARGET_SERVER = {
    TICKET: {
        HOST: process.env.TICKET_TARGET_HOST || '0.0.0.0',
        PORT: process.env.TICKET_TARGET_PORT || 80,
        PROTOCOL: process.env.TICKET_TARGET_PROTOCOL || 'http'
    },
    MAGAZZINO: {
        HOST: process.env.MAGAZZINO_TARGET_HOST || '0.0.0.0',
        PORT: process.env.MAGAZZINO_TARGET_PORT || 9001,
        PROTOCOL: process.env.MAGAZZINO_TARGET_PROTOCOL || 'http'
    },
    CORE: {
        HOST: process.env.CORE_TARGET_HOST || '0.0.0.0',
        PORT: process.env.CORE_TARGET_PORT || 5236,
        PROTOCOL: process.env.CORE_TARGET_PROTOCOL || 'http'
    }
}

const MISCELLANEOUS = {
    PWD_SECRET_KEY: process.env.PWD_SECRET_KEY,
    RESET_PWD_TOKEN_EXPIRES: 10800000
}

const STRIPE = {
    STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY
}

const INFO = {
    APP_VERSION: process.env.APP_VERSION,

}

module.exports = {
    AWS,
    SERVER,
    TARGET_SERVER,
    GOOGLE,
    FACEBOOK,
    JWT,
    MISCELLANEOUS,
    STRIPE,
    INFO
}