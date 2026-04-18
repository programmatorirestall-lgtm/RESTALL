import pool from "../helpers/mysql.js";
import HubspotProductsHelper from "../helpers/hubspotProductsHelper.js";
import { HUBSPOT } from "../config/constants.js";

class Products {
    constructor(prodotto) {
        return new Promise((resolve) => {
            this.codArticolo = prodotto.codArticolo
            this.descrizione = prodotto.descrizione
            this.giacenza = prodotto.giacenza
            this.prezzoFornitore = prodotto.prezzoFornitore
            this.sconto1 = prodotto.sconto1
            this.sconto2 = prodotto.sconto2
            this.sconto3 = prodotto.sconto3
            this.codeAn = prodotto.codeAn
            resolve(this)
        })
    }

    create() {
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO magazzino SET ? "

            pool.query(sql, [this],
                (err, data) => {
                    if (err) return reject(err)
                })
            return resolve(this)
        })
    }

    getAll(limit = 10, offset = 0) {
        return new Promise((resolve, reject) => {
            let sql = `SELECT CODART AS codArticolo, PREZZO1 AS prezzoFornitore, DESART AS descrizione, SCONTO AS sconto1, SCONTO2 AS sconto2, SCONTO3 AS sconto3, CODEAN AS codeAn, PROVV as giacenza FROM magazzino LIMIT ${limit} OFFSET ${offset}`

            pool.query(sql, (err, data) => {
                if (err) return reject(err)

                return resolve(data)
            })
        })
    }

    getByCodArticolo() {
        return new Promise((resolve, reject) => {
            let sql = `SELECT CODART AS codArticolo, PREZZO1 AS prezzoFornitore, DESART AS descrizione,
           SCONTO AS sconto1, SCONTO2 AS sconto2, SCONTO3 AS sconto3, CODEAN AS codeAn,
           PROVV as giacenza FROM magazzino WHERE CODART = ?`

            pool.query(sql, [this.codArticolo],
                (err, data) => {
                    if (err) return reject(err)

                    return resolve(data)
                })
        })
    }

    getByCodAn() {
        return new Promise((resolve, reject) => {
            let sql = `SELECT CODART AS codArticolo, PREZZO1 AS prezzoFornitore, DESART AS descrizione,
           SCONTO AS sconto1, SCONTO2 AS sconto2, SCONTO3 AS sconto3, CODEAN AS codeAn,
           PROVV as giacenza FROM magazzino WHERE CODEAN = ?`

            pool.query(sql, [this.codeAn],
                (err, data) => {
                    if (err) return reject(err)

                    return resolve(data)
                })
        })
    }

    // search(filters){
    //     return new Promise((resolve, reject) => {
    //         let size = Object.keys(filters).length
    //         let sql = `SELECT CODART AS codArticolo, PREZZO1 AS prezzoFornitore, DESART AS descrizione, SCONTO AS sconto1, SCONTO2 AS sconto2, SCONTO3 AS sconto3, CODEAN AS codeAn, PROVV as giacenza FROM magazzino WHERE `
    //         for (let key in filters) { 
    //             sql +=  `${key} LIKE '%${filters[key]}%' ${(size > 1) ? 'AND ' : '' }`
    //             size--
    //         }  

    //         pool.query(sql, (err, data) => {
    //             if(err) {console.log(err); return reject(err)}

    //             return resolve(data)
    //         })
    //     })
    // }

    mapDbFieldToHubspot(field) {
        const map = {
            CODART: "hs_sku",
            DESART: "name",
            PREZZO1: "hs_price_eur",
            SCONTO: "sconto_1",
            SCONTO2: "sconto_2",
            SCONTO3: "sconto_3",
            CODEAN: "hs_ean",
            PROVV: "giacenza",
            descrizione: "name",
        };

        return map[field];
    }

    mapHubspotOutput(results) {
        return results.map(p => ({
            codArticolo: p.properties.hs_sku ?? null,
            prezzoFornitore: p.properties.hs_price_eur ?? null,
            descrizione: p.properties.name ?? null,
            sconto1: p.properties.sconto_1 ?? "",
            sconto2: p.properties.sconto_2 ?? "",
            sconto3: p.properties.sconto_3 ?? "",
            codeAn: p.properties.hs_ean ?? "",
            giacenza: p.properties.giacenza ?? "",
        }));
    }

    search(filters) {
        return new Promise(async (resolve, reject) => {
            try {
                const hubspot = new HubspotProductsHelper(HUBSPOT.TOKEN);

                // rimuove filtri vuoti
                const validFilters = Object.entries(filters || {})
                    .filter(([_, value]) => value !== undefined && value !== "")
                    .map(([key, value]) => ({
                        propertyName: this.mapDbFieldToHubspot(key),
                        operator: "CONTAINS_TOKEN",
                        value: String(value),
                    }));

                let results = [];

                if (validFilters.length === 0) {
                    // 🔵 CASO: nessun filtro → lista prodotti
                    results = await hubspot.getProducts({
                        limit: 100,
                        properties: [
                            "hs_sku",
                            "name",
                            "hs_price_eur",
                            "hs_ean",
                        ],
                    });
                } else {
                    // 🟢 CASO: ricerca con filtri
                    results = await hubspot.searchProducts({
                        filterGroups: [{ filters: validFilters }],
                        limit: 50,
                        properties: [
                            "hs_sku",
                            "name",
                            "hs_price_eur",
                            "sconto_1",
                            "sconto_2",
                            "sconto_3",
                            "hs_ean",
                            "giacenza",
                        ],
                    });
                }

                resolve(this.mapHubspotOutput(results));
            } catch (err) {
                console.error("Errore ricerca prodotti HubSpot:", err);
                reject(err);
            }
        });
    }

    deleteAll() {
        return new Promise((resolve, reject) => {

            let sql = "DELETE FROM magazzino"

            pool.query(sql, (err, data) => {
                if (err) return reject(err)

                resolve(data)
            })
        })
    }
}

export default Products