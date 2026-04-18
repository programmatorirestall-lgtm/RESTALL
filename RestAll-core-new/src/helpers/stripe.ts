import CONSTANTS from "../config/constants";
import Stripe from "stripe";

export const stripe = new Stripe(CONSTANTS.STRIPE.SECRET_KEY);

