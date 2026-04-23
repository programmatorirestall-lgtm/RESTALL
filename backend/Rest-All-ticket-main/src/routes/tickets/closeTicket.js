import Router from 'express';
import { dynamoClient } from '../../helpers/aws.js';
import Ticket from '../../models/ticket.js';
import ejs from 'ejs'
import pup from '../../helpers/puppeteer.js'
import { s3_client } from '../../helpers/aws.js';
import path from 'path'
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { AWS } from '../../config/config.js';
import moment from 'moment';
import NotificationManager from '../../helpers/FCMTokenManager.js';
import { AUTOMATION_SETTINGS, HUBSPOT } from '../../config/constants.js';
import { calculateDistanceFromBase } from '../../helpers/googleMaps.js'
import Tecnico from '../../models/tecnico.js';
import HubspotTicketsHelper from '../../helpers/hubspotTicketHelper.js';


const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const router = new Router();
moment.locale('it')

const hubspot = new HubspotTicketsHelper(HUBSPOT.TOKEN);

router.post('/:id_ticket', async (req, res) => {

    req.body.operatori.push(String(req.user.id))
    let tech = null;

    if (req.user.type === "tech") {
        try {
            const techIst = await new Tecnico({ id: req.user.id });
            tech = await techIst.getById();
        } catch (err) {
            console.log("Errore caricamento tecnico:", err);
        }
    }

    let data = {
        ragioneSociale: req.body.ragioneSociale,
        indirizzo: req.body.indirizzo,
        indirizzoFatturazione: req.body.indirizzoFatturazione,
        codUnivoco: req.body.codUnivoco,
        citta: req.body.citta,
        descrLavoro: req.body.descrLavoro,
        fineLavoro: moment().format("YYYY-MM-DD HH:mm:ss"),
        piva: req.body.piva,
        tot: 0,
        supplemento: req.body.supplemento || 0,
        numTel: req.body.numTel,
        datiMacchina: req.body.datiMacchina,
        orderInfo: req.body.orderInfo,
        idTicket: req.params.id_ticket,
        firma: req.body.firma,
        metodoPagamento: req.body.metodoPagamento,
        operatori: [],
        infoIntervento: req.body.infoIntervento,
        iva: req.body.iva,
        ragSocialeFirmatario: req.body.ragSocialeFirmatario,
        ticketEsterno: req.body.ticketEsterno
    }

    const interventoRifiutato = String(req.body.infoIntervento).toLowerCase() === "rifiutato";
    let costiOrariOperatori = [];

    let distanceKM = 0;

    if (interventoRifiutato) {
        data.costoTrasferta = 0;
        data.tot = 0;
    } else {
        data.costoChiamata = AUTOMATION_SETTINGS.find((o) => o.id == 2).value
        let costoKM = (AUTOMATION_SETTINGS.find((o) => o.id == 1)).value
        let raggioNoTax = (AUTOMATION_SETTINGS.find((o) => o.id == 3)).value
        let distanceKM = await calculateDistanceFromBase(req.body.indirizzo);
        data.costoTrasferta = 0;

        if (distanceKM > raggioNoTax) {
            let distanceAR = 2 * distanceKM;
            data.costoTrasferta = Math.round(distanceAR * costoKM);
        }
        console.log("operatori: ", req.body.operatori)
        if (req.body.operatori.length > 0) {
            for (const idTecnico of req.body.operatori) {
                try {
                    let techIst = await new Tecnico({ id: idTecnico });
                    let tecnico = await techIst.getById();
                    console.log("tecnico: ", tecnico)
                    if (tecnico) {
                        data.operatori.push(`${tecnico.nome} ${tecnico.cognome}`);
                        costiOrariOperatori.push(tecnico.pagamento_orario);
                    }
                } catch (err) {
                    console.log(err);
                }
            }
        }

    }
    new Ticket({
        id: req.params.id_ticket
    })
        .then(ticket => ticket.getById())
        .then(t => {
            new Promise((resolve, reject) => {
                if (t.length == 0) return reject({
                    error: {
                        message: "Il ticket non esiste!"
                    }
                })

                if (t.stato !== 'In corso') return reject({
                    error: {
                        message: "Impossibile completare l'operazione!"
                    }
                })

                data.summary = t.summary
                data.summary.push({
                    dataInizio: moment().add(1, 'hours').format("YYYY-MM-DD HH:mm:ss"),
                    dataFine: "",
                    evento: "Chiuso"
                })


                data.summary.forEach(e => {
                    if (e.evento == 'In corso') {
                        if (e.dataFine == '') {
                            e.dataFine = moment().add(1, 'hours').format("YYYY-MM-DD HH:mm:ss")
                        }
                        let totMinutes = moment(e.dataFine).diff(moment(e.dataInizio), 'minute');
                        let workingMinutes = totMinutes - (960 * moment(e.dataFine).diff(moment(e.dataInizio), 'days'));

                        if (!interventoRifiutato) {
                            costiOrariOperatori.forEach((costo) => {
                                data.tot += Math.round((costo / 60) * workingMinutes);
                            })
                        }

                        e.oreLavorative = interventoRifiutato ? 0 : ((workingMinutes < 60) ? 1 : workingMinutes);
                    }
                    else { e.oreLavorative = 0 }
                });
                console.log("summary: ", data.summary)

                let pdfKey = `${req.params.id_ticket}_${Date.now()}.pdf`
                ejs.renderFile(path.join(__dirname, '../../../res/template_chiusura.ejs'), { data: data }, (err, result) => {

                    if (err) {
                        console.log(err)
                        return reject(err)
                    }
                    else {
                        try {
                            pup.pdfFromHtmlCode(result, 'A4')
                                .then(pdfBuffer => {
                                    dynamoClient.getItemById(t.id_utente).then((user) => {
                                        s3_client.uploadWithBuffer(AWS.RECEIPT_BUCKET, pdfBuffer, pdfKey, { 'user-email': user.email, 'tech-name': `${req.user.nome} ${req.user.cognome}`, 'details': 'Chiusura' })
                                            .then(result => {
                                                new Ticket({
                                                    id: req.params.id_ticket,
                                                    oraChiusura: data.fineLavoro
                                                })
                                                    .then(temp => temp.closeTicket(result.location, pdfKey))
                                                    .then(res => {

                                                        // try {
                                                        //     // Prendi le iniziali del nome
                                                        //     const nomeInitial = req.user.nome.charAt(0);
                                                        //     // Prendi le iniziali del cognome (anche se contiene spazi)
                                                        //     const cognomeParts = req.user.cognome.split(' ');
                                                        //     const cognomeInitials = cognomeParts.map(part => part.charAt(0)).join('');
                                                        //     hubspot.updateTicket(req.params.id_ticket, {
                                                        //         hs_pipeline_stage: "2602144979",
                                                        //         operatore: `${nomeInitial}${cognomeInitials}`
                                                        //     })
                                                        // } catch (err) {
                                                        //     console.log(err)
                                                        // }

                                                        return resolve({
                                                            message: 'Pdf creato e caricato con successo',
                                                            location: res.location
                                                        })
                                                    })
                                                    .catch(err => { console.log(err); return reject(err) })
                                            })
                                    })
                                        .catch(err => { console.log(err); return reject(err) })
                                })

                        } catch (err) {
                            console.log(err)
                            return reject(err)
                        }

                    }
                });
            })
                .then(async (pdf) => {

                    try {
                        // 🔹 Cerca l’ID HubSpot del ticket corrispondente al tuo id_ticket app
                        const hubspotTicketId = await hubspot.searchTicket(req.params.id_ticket);

                        if (hubspotTicketId) {
                            if (req.user.type === "tech" && tech.codCRM) {
                                hubspot.updateTicket(req.params.id_ticket, {
                                    hs_pipeline_stage: "2602144979",
                                    operatore: `${tech.codCRM}`
                                })
                            }
                            // 🔹 Aggiorna il ticket su HubSpot (chiusura + operatore)
                            // Prendi le iniziali del nome
                            // const nomeInitial = req.user.nome.charAt(0);
                            // // Prendi le iniziali del cognome (anche se contiene spazi)
                            // const cognomeParts = req.user.cognome.split(' ');
                            // const cognomeInitials = cognomeParts.map(part => part.charAt(0)).join('');
                            // hubspot.updateTicket(req.params.id_ticket, {
                            //     hs_pipeline_stage: "2602144979",
                            //     operatore: `${cognomeInitials}${nomeInitial}`
                            // })
                        } else {
                            console.warn(`Ticket HubSpot non trovato per id_ticket_app=${req.params.id_ticket}`);
                        }
                    } catch (err) {
                        console.error("Errore aggiornamento HubSpot:", err.response?.data || err.message);
                    }

                    // 🔹 QUI aggiungiamo la chiamata al webhook
                    try {
                        hubspot.callWebhook({
                            id_ticket: req.params.id_ticket,
                            utente: {
                                id: req.user.id,
                                nome: req.user.nome,
                                cognome: req.user.cognome,
                                email: req.user.email || null,
                            },
                            cliente: {
                                ragioneSociale: data.ragioneSociale,
                                piva: data.piva,
                                citta: data.citta,
                                indirizzo: data.indirizzo,
                                telefono: data.numTel,
                            },
                            macchina: data.datiMacchina,
                            intervento: {
                                descrizione: data.descrLavoro,
                                fineLavoro: data.fineLavoro,
                                metodoPagamento: data.metodoPagamento,
                                firma: !!data.firma,
                                operatoriCoinvolti: data.operatori,
                                costoChiamata: data.costoChiamata,
                                costoTrasferta: data.costoTrasferta,
                                totale: data.tot,
                                supplemento: data.supplemento,
                                iva: data.iva,
                                distanza_km: distanceKM || 0,
                            },
                            pdf: {
                                url: pdf.location,
                            },
                            timestamp: new Date().toISOString(),
                            eventi: data.summary
                        });
                        console.log("Webhook Make.com inviato correttamente ✅");
                    } catch (err) {
                        console.error("Errore invio webhook:", err.message);
                    }

                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket} terminato`, `${req.user.nome} ${req.user.cognome} ha appena concluso il suo intervento`)
                        .then(success => {
                            return res.status(200).json({
                                message: pdf.message,
                                location: pdf.location
                            })
                        })
                        .catch(err => { console.log(err); return reject(err) })
                })
                .catch(err => { console.log(err); return res.status(500).json({ err }) })
        })
})


export default router