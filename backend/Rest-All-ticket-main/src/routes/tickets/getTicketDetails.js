import Router from 'express';
import Ticket from '../../models/ticket.js';
import Fogli from '../../models/fogli.js';
import { dynamoClient, lambdaClient } from '../../helpers/aws.js'
import axios from 'axios';
import { parseISO, addSeconds } from 'date-fns';
import { AWS } from '../../config/config.js';

const router = new Router();

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function axiosPostWithRetry(
  url,
  body,
  config,
  {
    retries = 5,
    baseDelayMs = 1000,
  } = {}
) {
  let attempt = 0;

  while (true) {
    try {
      return await axios.post(url, body, config);
    } catch (err) {
      const status = err.response?.status;

      if (status !== 429 || attempt >= retries) {
        throw err;
      }

      attempt += 1;

      const retryAfter =
        Number(err.response?.headers?.["retry-after"]) * 1000 ||
        baseDelayMs * attempt;

      console.warn(
        `HubSpot 429 – retry ${attempt}/${retries} tra ${retryAfter}ms`
      );

      await sleep(retryAfter);
    }
  }
}

// 🔹 Mapping HubSpot -> DB azienda
function mapHubspotToDb(company) {
    return {
        id: Number(company.id),
        clfr: company.properties?.clfr || "",
        codCf: company.properties?.codice_cf || "",
        ragSoc: company.properties?.name || "",
        ragSoc1: company.properties?.rag_soc_secondaria || "",
        indir: company.properties?.address || "",
        cap: company.properties?.zip || "",
        local: company.properties?.city || "",
        prov: company.properties?.state || "",
        codFisc: company.properties?.codice_fiscale || "",
        partiva: company.properties?.partita_iva || "",
        tel: company.properties?.phone || "",
        tel2: company.properties?.phone2 || "",
        fax: company.properties?.fax || "",
        email: company.properties?.email || "",
        codNaz: company.properties?.country || "",
        codsdi: company.properties?.codice_sdi || "",
        pec_fe: company.properties?.email_pec || ""
    };
}

// 🔹 Funzione di ricerca con gestione paginazione
async function searchHubspotByFilter(filters) {
    const token = process.env.HUBSPOT_TOKEN;

    const properties = [
        "name", "address", "city", "state", "zip", "country", "phone", "fax", "email",
        "clfr", "codice_cf", "rag_soc_secondaria", "codice_fiscale", "partita_iva",
        "phone2", "codice_sdi", "pec_fe"
    ];

    let allResults = [];
    let after = undefined;

    do {
        const body = {
            filterGroups: [
                {
                    filters: Object.entries(filters)
                        .filter(([_, value]) => value && value.trim() !== "")
                        .map(([property, value]) => ({
                            propertyName: property,
                            operator: "CONTAINS_TOKEN",
                            value: value.trim()
                        }))
                }
            ],
            properties,
            limit: 100, // massimo per HubSpot
            after
        };

        const response = await axiosPostWithRetry(
            "https://api.hubapi.com/crm/v3/objects/companies/search",
            body,
            {
                headers: {
                    Authorization: `Bearer ${token}`,
                    "Content-Type": "application/json",
                },
            }
        );
        allResults.push(...response.data.results.map(mapHubspotToDb));

        after = response.data.paging?.next?.after; // se c'è una pagina successiva
    } while (after);

    return allResults;
}

const filterMapping = {
    ragSoc: "name",
};

function mapFiltersForHubspot(filters) {
    const mapped = {};
    for (let [key, value] of Object.entries(filters)) {
        const hubspotKey = filterMapping[key] || key; // se non c’è mapping uso la chiave originale
        mapped[hubspotKey] = value;
    }
    return mapped;
}

router.get('/:id_ticket', (req, res) => {
    new Ticket({ id: req.params.id_ticket })
        .then(ticket => ticket.getById())
        .then(async details => {
            if (details.length == 0) return res.status(200).json(details);

            const user = await dynamoClient.getItemById(details.id_utente);

            // 🔹 Ricerca in HubSpot partendo dal nome azienda (ragione sociale)
            let hubspotData = [];
            try {
                const filters = mapFiltersForHubspot({ ragSoc: details.ragSocAzienda });
                hubspotData = await searchHubspotByFilter(filters);

            } catch (err) {
                console.error("Errore durante ricerca HubSpot:", err.message);
            }

            // 🔹 Prendi il primo risultato utile se trovato
            const aziendaHubspot = hubspotData[0] || {};
            const partiva = aziendaHubspot.partiva || "";
            const codFisc = aziendaHubspot.codFisc || "";
            const codsdi = aziendaHubspot.codsdi || "";
            const citta = aziendaHubspot.local || "";
            const indirizzoFatturazione = aziendaHubspot.indir || "";

            new Fogli({ idTicket: details.id })
                .then((foglio) => foglio.getByTicketId())
                .then((result) => {
                    return Promise.all(result.map(({ id, location, fileKey }) => {
                        return new Promise((resolve, reject) => {
                            const params = new Proxy(new URLSearchParams(location), {
                                get: (searchParams, prop) => searchParams.get(prop),
                            });
                            let creationDate = parseISO(params['X-Amz-Date']);
                            let expiresInSecs = Number(params['X-Amz-Expires']);
                            let expiryDate = addSeconds(creationDate, expiresInSecs);

                            if (expiryDate < new Date() || isNaN(expiryDate)) {
                                lambdaClient.invoke({
                                    FunctionName: AWS.LAMBDA_FUNCTION_NAME,
                                    Payload: JSON.stringify({
                                        fileKey: fileKey,
                                        bucket: AWS.RECEIPT_BUCKET
                                    })
                                }).then(res => {
                                    let data = JSON.parse(Buffer.from(res.Payload));
                                    return new Fogli({
                                        id: id,
                                        location: data.body.location,
                                        fileKey
                                    });
                                })
                                    .then(foglio => foglio.updateLocation())
                                    .then(upFoglio => resolve(upFoglio))
                                    .catch(err => reject({ err }));
                            } else {
                                resolve({ id, location, fileKey });
                            }
                        });
                    }));
                })
                .then(files => {
                    return res.status(200).json({
                        ticket: {
                            id: details.id,
                            stato_macchina: details.stato_macchina,
                            tipo_macchina: details.tipo_macchina,
                            idMacchina: details.idMacchina,
                            descrizione: details.descrizione,
                            indirizzo: details.indirizzo,
                            stato: details.stato,
                            oraPrevista: details.oraPrevista,
                            ragSocAzienda: details.ragSocAzienda,
                            id_tecnico: details.id_tecnico,
                            rifEsterno: details.rifEsterno,
                            rifFurgone: details.rifFurgone,
                            summary: details.summary,
                            numTel: user.numTel,
                            fogli: files,
                            partiva,
                            codFisc,
                            codsdi,
                            citta,
                            indirizzoFatturazione

                        }
                    });
                })
                .catch(err => {
                    console.log(err);
                    return res.status(500).json({ err });
                });
        })
        .catch(err => {
            console.log(err);
            return res.status(500).json({ err });
        });
});

export default router;