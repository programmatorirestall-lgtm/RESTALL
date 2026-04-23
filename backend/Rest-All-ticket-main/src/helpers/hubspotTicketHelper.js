import axios from "axios";
import { HUBSPOT } from "../config/constants.js";

const HUBSPOT_BASE_URL = HUBSPOT.BASE_URL;

export default class HubspotTicketsHelper {
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
   * Crea un nuovo ticket
   * @param {Object} data
   * @param {string} data.subject
   * @param {string} data.content
   * @param {string} data.ticketIdApp
   * @param {string} data.tipoMacchina
   * @param {string} data.statoMacchina
   * @param {string} data.priority (LOW | MEDIUM | HIGH)
   * @param {string} data.pipelineStage (default: 2602144976)
   * @param {string} companyId
   */
  async createTicket(data, companyId) {
    try {
      const body = {
        properties: {
          subject: data.subject,
          content: data.content,
          hs_pipeline: "0",
          hs_pipeline_stage: data.pipelineStage || "2602144976",
          hs_ticket_priority: data.priority || "MEDIUM",
          id_ticket_app: data.ticketIdApp,
          tipo_macchina: data.tipoMacchina,
          stato_macchina: data.statoMacchina,
        },
        associations: [
          {
            to: { id: companyId },
            types: [
              {
                associationCategory: "HUBSPOT_DEFINED",
                associationTypeId: 339,
              },
            ],
          },
        ],
      };

      const res = await this.client.post("", body);
      return res.data.id;
    } catch (err) {
      console.error("Errore creazione ticket:", err.response?.data || err.message);
      throw err;
    }
  }

  async createTicketNoAssociations(data) {
    try {
      const body = {
        properties: {
          subject: data.subject,
          content: data.content,
          hs_pipeline: "0",
          hs_pipeline_stage: data.pipelineStage || "2602144976",
          hs_ticket_priority: data.priority || "MEDIUM",
          id_ticket_app: data.ticketIdApp,
          tipo_macchina: data.tipoMacchina,
          stato_macchina: data.statoMacchina,
        }
      };

      const res = await this.client.post("", body);
      return res.data.id;
    } catch (err) {
      console.error("Errore creazione ticket:", err.response?.data || err.message);
      throw err;
    }
  }

  /**
   * Aggiorna un ticket
   * @param {string} ticketId
   * @param {Object} properties
   */
  async updateTicket(ticketId, properties) {
  try {
    if (!ticketId) {
      throw new Error("ticketId mancante o invalido");
    }

    const bodySearch = {
      filterGroups: [
        {
          filters: [
            {
              propertyName: "id_ticket_app",
              operator: "EQ",
              value: String(ticketId),
            },
          ],
        },
      ],
      properties: ["subject", "hs_pipeline", "hs_pipeline_stage"],
      limit: 1,
    };

    const resSearch = await this.client.post("/search", bodySearch);

    if (resSearch.data.results.length === 0) {
      throw new Error(`Ticket non trovato per id_ticket_app=${ticketId}`);
    }

    const res = await this.client.patch(
      `/${resSearch.data.results[0]?.id}`,
      { properties }
    );
    return res.data.id;
  } catch (err) {
    console.error("Errore aggiornamento ticket:", err.response?.data || err.message);
  }
}

  /**
   * Cerca un ticket per Id_ticket_app
   * @param {string} ticketIdApp
   */
  async searchTicket(ticketIdApp) {
    try {
      const body = {
        filterGroups: [
          {
            filters: [
              {
                propertyName: "id_ticket_app",
                operator: "EQ",
                value: ticketIdApp,
              },
            ],
          },
        ],
        properties: ["subject", "hs_pipeline", "hs_pipeline_stage"],
        limit: 1,
      };

      const res = await this.client.post("/search", body);
      return res.data.results?.[0]?.id || null;
    } catch (err) {
      console.error("Errore ricerca ticket:", err.response?.data || err.message);
      throw err;
    }
  }

  /**
   * Cerca un'azienda collegata a un ticket (stub: l'endpoint nel testo sembra un refuso)
   * In realtà la ricerca aziende dovrebbe usare /crm/v3/objects/companies/search
   */
  async searchCompanyByTicketApp(ticketIdApp) {
    try {
      const body = {
        filterGroups: [
          {
            filters: [
              {
                propertyName: "id_ticket_app",
                operator: "EQ",
                value: ticketIdApp,
              },
            ],
          },
        ],
        properties: ["subject", "hs_pipeline", "hs_pipeline_stage"],
        limit: 1,
      };

      const res = await this.client.post("/search", body);
      return res.data.results?.[0]?.id || null;
    } catch (err) {
      console.error("Errore ricerca azienda:", err.response?.data || err.message);
      throw err;
    }
  }

  async searchCompanyByName(name) {
    try {
      const body = {
        filterGroups: [
          {
            filters: [
              {
                propertyName: "name",
                operator: "EQ",
                value: name
              }
            ]
          }
        ],
        limit: 1,
        properties: ["name"]
      };

      const response = await axios.create({
        baseURL: "https://api.hubapi.com/crm/v3/objects/companies",
        headers: {
          Authorization: `Bearer ${HUBSPOT.TOKEN}`,
          "Content-Type": "application/json",
        },
      }).post(
        "/search",
        body,
        { headers: { Authorization: `Bearer ${HUBSPOT.TOKEN}` } }
      );

      if (response.data.results.length > 0) {
        return response.data.results[0];
      }
      return null;
    } catch (err) {
      console.error("Errore API searchCompanyByName:", err.response?.data || err.message);
      throw err;
    }
  }

    /**
   * Chiama un webhook esterno (es. Make.com)
   * @param {Object} payload - JSON generico da inviare al webhook
   * @returns {Promise<Object>} - Risposta del webhook
   */
  async callWebhook(payload) {
    try {
      const webhookUrl = "https://hook.eu1.make.com/n4fp1t2p2pst5q93q5tj3xco4zqwaxgp";

      const res = await axios.post(webhookUrl, payload, {
        headers: {
          "Content-Type": "application/json",
        },
      });

      console.log("Webhook inviato con successo:", res.status);
      return res.data;
    } catch (err) {
      console.error("Errore chiamata webhook:", err.response?.data || err.message);
      throw err;
    }
  }

}
