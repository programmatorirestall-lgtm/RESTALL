import axios from "axios";
import { HUBSPOT } from "../config/constants.js";

const HUBSPOT_BASE_URL = HUBSPOT.BASE_URL;

export default class HubspotProductsHelper {
  constructor(token) {
    this.client = axios.create({
      baseURL: HUBSPOT_BASE_URL,
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
    });
  }

  /**
   * Lista prodotti
   * GET /crm/v3/objects/products
   * @param {Object} params
   * @param {number} params.limit
   * @param {string} params.after
   * @param {string[]} params.properties
   */
  async getProducts({ limit = 100, after, properties } = {}) {
    try {
      const res = await this.client.get("", {
        params: {
          limit,
          after,
          properties: properties?.join(","),
        },
      });

      return res.data.results;
    } catch (err) {
      console.error(
        "Errore recupero lista prodotti:",
        err.response?.data || err.message
      );
      throw err;
    }
  }

  /**
   * Ricerca prodotti
   * POST /crm/v3/objects/products/search
   * @param {Object} data
   * @param {Array} data.filterGroups
   * @param {number} data.limit
   * @param {string[]} data.properties
   * @param {string[]} data.sorts
   * @param {string} data.after
   */
  async searchProducts(data) {
    try {
      const body = {
        after: data.after,
        filterGroups: data.filterGroups,
        limit: data.limit || 20,
        properties: data.properties || [
          "name",
          "description",
          "hs_price_eur",
          "hs_sku",
        ],
        sorts: data.sorts,
      };

      const res = await this.client.post("/search", body);
      return res.data.results;
    } catch (err) {
      console.error(
        "Errore ricerca prodotti:",
        err.response?.data || err.message
      );
      throw err;
    }
  }
}
