import express from "express";
import axios from "axios";
import { HUBSPOT } from "../../config/constants.js";

const router = express.Router();

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
    const token = HUBSPOT.TOKEN;

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

        const response = await axios.post(
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

// 🔹 Endpoint GET /search
router.get("/search", async (req, res) => {
    if (Object.keys(req.query).length === 0) {
        return res.status(400).json({ err: "Nessun filtro fornito" });
    }

    try {
        const filters = mapFiltersForHubspot(req.query); // mappa i filtri
        const data = await searchHubspotByFilter(filters);
        return res.status(200).json(data);
    } catch (err) {
        console.error("Errore ricerca HubSpot:", err.response?.data || err.message);
        return res.status(500).json({ err: "Errore nella ricerca su HubSpot" });
    }
});

export default router;


// import { Router } from "express";
// import { DATABASE } from "../../config/config.js";
// import mysql from 'mysql'

// var pool = mysql.createPool({
//     connectionLimit : DATABASE.CONNECTION_LIMIT,
//     host : DATABASE.CLUSTER,
//     port: DATABASE.PORT,
//     user : DATABASE.USER,
//     password : DATABASE.PASS,
//     database : 'main'
// })

// const router = new Router()
// let keys = []
// let values = []

// function search(filters){
//     return new Promise((resolve, reject) => {
//         let size = Object.keys(filters).length
//         let sql = "SELECT * FROM azienda WHERE "
//         for (let key in filters) { 
//             sql +=  `${key} LIKE '%${filters[key]}%' ${(size > 1) ? 'AND ' : '' }`
//             size--
//         }  

//         pool.query(sql, (err, data) => {
//             if(err) {console.log(err); return reject(err)}

//             return resolve(data)
//         })
//     })
// };

// router.get('/search', (req, res) => {
//     if(Object.keys(req.query).length == 0) return res.status(500).json({err: "Formato non valido"})
//     const filters = req.query; 

//     search(filters).then(data => res.status(200).json(data))
//     .catch(err => res.status(500).json("Errore nella ricerca"))
// })

// export default router