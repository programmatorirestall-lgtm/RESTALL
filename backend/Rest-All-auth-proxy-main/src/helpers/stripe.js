const CONFIG = require('../config/config.js');
const Stripe = require('stripe')
const stripe = Stripe(`${CONFIG.STRIPE.STRIPE_SECRET_KEY}`);

module.exports = stripe