import dotenv from 'dotenv';
import Setting from '../models/settings.js';
dotenv.config();

const JWT = {
  SECRET_KEY: process.env.JWT_SECRET,
  EXPIRES_IN: 1800000,
  ISSUER: process.env.JWT_ISSUER
};

const REFRESH_TOKEN = {
  LENGTH: 64
};

let AUTOMATION_SETTINGS = []

async function settingsAutomation() {
  AUTOMATION_SETTINGS = [];
  try {
    const setting = await new Setting({});
    const result = await setting.getAll();

    result.forEach(({ id, descr, value }) => {
      AUTOMATION_SETTINGS.push({ id, descr, value });
    });
  } catch (err) {
    throw new Error(err);
  }
}

await settingsAutomation();

const ERRORS = {
  INVALID_REQUEST: 'Invalid request',
  INVALID_ACCESS_TOKEN: 'Invalid access token',
  INVALID_REFRESH_TOKEN: 'Invalid refresh token',
  TOKEN_EXPIRED: 'Access token expired',
  LOGIN: 'Login failed',
  REGISTRATION: 'Registration failed'
};

const SUCCESS_ITA = {
  DEFAULT: 'Operazione effettuata con successo',
  REGISTER: 'Registrazione avvenuta con successo!',
  PAYMENT: 'Pagamento avvenuto con successo!',
  CONNECTION: 'Connessione andata a buon fine!',
  LOGIN: "Login effettuato!"
}

const SUCCESS_EN = {
  DEFAULT: 'Operation succesfully complete!',
  REGISTER: 'Registration was successful',
  PAYMENT: 'Payment successful',
  CONNECTION: 'Connection successful'
}

const REG = {
  EMAIL: /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
}

const MISC = {
  BASE_LEGAL_ADDRESS: "300 EX S.S.98 C/O AUTOPARCO DE FATO, Via Canosa, SP231, KM 31, 76123 Andria BT"
}

const HUBSPOT = {
  BASE_URL: process.env.HUBSPOT_BASE_URL,
  TOKEN: process.env.HUBSPOT_TOKEN
}

export {
  JWT,
  REFRESH_TOKEN,
  ERRORS,
  SUCCESS_ITA,
  SUCCESS_EN,
  REG,
  AUTOMATION_SETTINGS,
  MISC,
  settingsAutomation, 
  HUBSPOT
};
