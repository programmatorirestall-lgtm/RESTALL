import dotenv from 'dotenv'
dotenv.config();

const JWT = {
  SECRET_KEY: process.env.JWT_SECRET,
  EXPIRES_IN: 1800000,
  ISSUER: process.env.JWT_ISSUER
};

const HUBSPOT = {
  BASE_URL: process.env.HUBSPOT_BASE_URL,
  TOKEN: process.env.HUBSPOT_TOKEN
}

const ERRORS = {
    INVALID_REQUEST: 'Invalid request',
    INVALID_ACCESS_TOKEN: 'Invalid access token',
    INVALID_REFRESH_TOKEN: 'Invalid refresh token',
    TOKEN_EXPIRED: 'Access token expired',
    LOGIN: 'Login failed',
    REGISTRATION: 'Registration failed'
  };

  export {
    ERRORS,
    JWT, 
    HUBSPOT
  }