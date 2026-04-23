import dotenv from 'dotenv';
dotenv.config();

const environment = process.env.NODE_ENV || 'development';
console.log(`Server environment is ${environment}.`);

const SERVER = {
  HOST: process.env.HOST || '0.0.0.0',
  PORT: process.env.PORT || 9000,
  HOST_SECURE: process.env.HOST_SECURE || '0.0.0.0',
  PORT_SECURE: process.env.PORT_SECURE || 443,
};

const DATABASE = {
  USER: process.env.RDS_USER,
  PASS: process.env.RDS_PASS,
  CLUSTER: process.env.RDS_CLUSTER,
  PORT: process.env.RDS_PORT || 3306,
  CONNECTION_LIMIT: 80,
  NAME: process.env.RDS_DB_NAME,
};

const FILES = {
  MAX_SIZE: 15 * 1024 * 1024
};

const AWS = {
  DYNAMO_TABLE: process.env.DYNAMO_TABLE,
  FCM_TOKEN_DYNAMO_TABLE: process.env.FCM_TOKEN_DYNAMO_TABLE,
  LAMBDA_ENDPOINT: `${process.env.AWS_LAMBDA_ENDPOINT}`,
  LAMBDA_LAYER_NAME: process.env.AWS_LAMBDA_LAYER_ARN,
  LAMBDA_FUNCTION_NAME: process.env.AWS_LAMBDA_FUNCTION_NAME,
  LAMBDA_SEND_ADMINS_EMAIL: process.env.LAMBDA_SEND_ADMINS_EMAIL,
  REGION: 'eu-central-1',
  RECEIPT_BUCKET: process.env.RECEIPT_BUCKET,
  SIGNATURE_BUCKET: process.env.SIGNATURE_BUCKET,
  ATTACHMENTS_BUCKET: process.env.ATTACHMENTS_BUCKET,
  S3: {
    ACCESS_KEY_ID: process.env.S3_USER_ACCESS_KEY_ID,
    SECRET_ACCESS_KEY: process.env.S3_USER_SECRET_ACCESS_KEY
  }
};

const PUPPETEER = {
  BROWSERLESS_TOKEN: `${process.env.BROWSERLESS_TOKEN}`
}

const GOOGLE = {
  API_KEY: process.env.GOOGLE_API_KEY
}

export {
  SERVER,
  DATABASE,
  FILES,
  AWS,
  PUPPETEER,
  GOOGLE
};
