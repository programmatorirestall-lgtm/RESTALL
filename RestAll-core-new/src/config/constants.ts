import 'dotenv/config'

const CONSTANTS = {
    SERVER: {
        PORT: <number><unknown>process.env.SERVER_PORT ?? 5236,
        HOST: process.env.SERVER_HOST ?? '0.0.0.0'
    },
    WOOCOMMERCE: {
        BASE_URL:  "https://restall.it",
        WOOCOMMERCE_USER_KEY: process.env.WOOCOMMERCE_USER_KEY ?? "",
        WOOCOMMERCE_USER_SECRET: process.env.WOOCOMMERCE_USER_SECRET ?? ""
    },
    JWT: {
        SECRET_KEY: process.env.JWT_SECRET,
        EXPIRES_IN: 1800000,
        ISSUER: process.env.JWT_ISSUER
    },
    RDS: {
        HOST: process.env.RDS_CLUSTER,
        USER: process.env.RDS_USER,
        DATABASE: process.env.RDS_DB_NAME,
        PASSWORD: process.env.RDS_PASS,
        PORT: (process.env.RDS_PORT as unknown) as number
    },
    STRIPE: {
        SECRET_KEY: `${process.env.STRIPE_KEY}`
    },
    DYNAMO: {
        USERS_TABLE: 'users'
    },
    WP: {
        USER: process.env.WP_ADMIN ?? "",
        PASS: process.env.WP_PASS ?? ""
    }
}

export default CONSTANTS;