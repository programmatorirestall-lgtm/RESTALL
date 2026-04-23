import Router from 'express';
import Ticket from '../../models/ticket.js';
import moment from 'moment/moment.js';
import ejs from 'ejs'
import pup from '../../helpers/puppeteer.js'
import { s3_client, dynamoClient } from '../../helpers/aws.js';
import path from 'path'
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import { AWS } from '../../config/config.js';
import NotificationManager from '../../helpers/FCMTokenManager.js';
import { AUTOMATION_SETTINGS, HUBSPOT } from '../../config/constants.js';
import { calculateDistanceFromBase } from '../../helpers/googleMaps.js'
import Tecnico from '../../models/tecnico.js';
import HubspotTicketsHelper from '../../helpers/hubspotTicketHelper.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const router = new Router();
moment.locale('it');

const hubspot = new HubspotTicketsHelper(HUBSPOT.TOKEN);

router.patch('/:id_ticket', async (req, res) => {
    let tech = null;
    let distanceKM = 0;
    if (req.user.type === "tech") {
        try {
            const techIst = await new Tecnico({ id: req.user.id });
            tech = await techIst.getById();
        } catch (err) {
            console.log("Errore caricamento tecnico:", err);
        }
    }

    new Ticket({
        id: req.params.id_ticket
    }).then(ticket => ticket.getById())
        .then(async t => {
            switch (t.stato) {
                case 'Aperto': {
                    switch (req.user.type) {
                        case 'admin': {
                            new Ticket({
                                id: req.params.id_ticket,
                                oraPrevista: req.body.oraPrevista
                            })
                                .then(ticket => ticket.assignTicket())
                                .then(result => {
                                    try {
                                        hubspot.updateTicket(String(req.params.id_ticket), {
                                            hs_pipeline_stage: "2602144977"
                                        })
                                    } catch (err) {
                                        console.log(err)
                                    }
                                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket} aggiornato!`, `L'ora prevista di intervento è ${req.body.oraPrevista}!`)
                                        .then(success => {
                                            return res.status(200).json({
                                                result: {
                                                    message: "Orario previsto aggiornato con successo"
                                                }
                                            })
                                        })
                                        .catch(err => { console.log(err); return res.status(500).json(err) })
                                })
                                .catch(err => res.status(500).json({ err }))
                            break
                        }

                        default: {

                            new Ticket({
                                id: req.params.id_ticket,
                                stato: "In corso",
                                oraInizio: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss")
                            })
                                .then(ticket => { console.log(ticket); return ticket.startTicket() })
                                .then(result => {
                                    try {
                                        if (req.user.type === "tech" && tech.codCRM) {
                                            console.log("Updating Hubspot Ticket with tech codCRM:", tech.codCRM);
                                            hubspot.updateTicket(req.params.id_ticket, {
                                                hs_pipeline_stage: "3059039419",
                                                operatore: `${tech.codCRM}`
                                            })
                                        }
                                    } catch (err) {
                                        console.log(err)
                                    }
                                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket}: In Corso`, `${req.user.nome} ${req.user.cognome} ha appena cominciato il suo intervento`)
                                        .then(success => {
                                            return res.status(200).json({
                                                result: {
                                                    message: "Ticket avviato con successo"
                                                }
                                            })
                                        })
                                })
                                .catch(err => {
                                    console.log(err); return res.status(500).json({
                                        message: err
                                    })
                                })
                            break
                        }
                    }
                    break
                }

                case 'In corso': {
                    let pdfKey = `${req.params.id_ticket}_${Date.now()}.pdf`
                    if (!req.body.operatori) { req.body.operatori = [] }
                    req.body.operatori.push(String(req.user.id))

                    let data = {
                        ragioneSociale: req.body.ragioneSociale,
                        indirizzo: req.body.indirizzo,
                        indirizzoFatturazione: req.body.indirizzoFatturazione,
                        codUnivoco: req.body.codUnivoco,
                        citta: req.body.citta,
                        descrLavoro: req.body.descrLavoro,
                        piva: req.body.piva,
                        numTel: req.body.numTel,
                        datiMacchina: req.body.datiMacchina,
                        orderInfo: req.body.orderInfo,
                        costoTrasferta: req.body.costoTrasferta,
                        costoChiamata: req.body.costoChiamata,
                        tot: 0,
                        supplemento: req.body.supplemento || 0,
                        idTicket: req.params.id_ticket,
                        firma: req.body.firma,
                        metodoPagamento: req.body.metodoPagamento,
                        operatori: [],
                        ragSocialeFirmatario: req.body.ragSocialeFirmatario,
                        infoIntervento: req.body.infoIntervento,
                        iva: req.body.iva
                    }

                    data.costoChiamata = AUTOMATION_SETTINGS.find((o) => o.id == 2).value
                    let costoKM = (AUTOMATION_SETTINGS.find((o) => o.id == 1)).value
                    let raggioNoTax = (AUTOMATION_SETTINGS.find((o) => o.id == 3)).value
                    distanceKM = await calculateDistanceFromBase(req.body.indirizzo);
                    if (!distanceKM) { distanceKM = 0; }
                    data.costoTrasferta = 0;

                    if (distanceKM > raggioNoTax) {
                        let distanceAR = 2 * distanceKM;
                        data.costoTrasferta = Math.round(distanceAR * costoKM);
                    }

                    let costiOrariOperatori = [];
                    if (req.body.operatori.length > 0) {
                        req.body.operatori.forEach(async (idTecnico) => {
                            try {
                                let techIst = await new Tecnico({
                                    id: idTecnico
                                })
                                let tecnico = await techIst.getById()
                                if (tecnico != undefined) {
                                    data.operatori.push(`${tecnico.nome} ${tecnico.cognome}`)
                                    costiOrariOperatori.push(tecnico.pagamento_orario)
                                }

                            } catch (err) {
                                console.log(err)
                            }
                        })
                    }


                    new Ticket({
                        id: req.params.id_ticket
                    })
                        .then(ticket => { return ticket.getById() })
                        .then(result => {
                            data.summary = result.summary
                            data.summary.push({
                                dataInizio: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                dataFine: "",
                                evento: "Sospeso"
                            })


                            data.summary.forEach(e => {
                                if (e.evento == 'In corso') {
                                    if (e.dataFine == '') {
                                        e.dataFine = moment().add(1, 'hours').format("YYYY-MM-DD HH:mm:ss")
                                    }
                                    let totMinutes = moment(e.dataFine).diff(moment(e.dataInizio), 'minute');
                                    console.log((960 * moment(e.dataFine).diff(moment(e.dataInizio), 'days')));
                                    let workingMinutes = totMinutes - (960 * moment(e.dataFine).diff(moment(e.dataInizio), 'days'));
                                    costiOrariOperatori.forEach((costo) => {
                                        data.tot += Math.round((costo / 60) * workingMinutes);
                                    })
                                    e.oreLavorative = (workingMinutes < 60) ? 1 : workingMinutes;
                                }
                                else { e.oreLavorative = 0 }
                            });


                            new Promise((resolve, reject) => {
                                ejs.renderFile(path.join(__dirname, '../../../res/template_sospensione.ejs'), { data: data }, (err, doc) => {

                                    if (err) {
                                        console.log(err);
                                        return reject(err)
                                    }
                                    else {
                                        try {
                                            pup.pdfFromHtmlCode(doc, 'A4')
                                                .then(pdfBuffer => {
                                                    dynamoClient.getItemById(result.id_utente).then((user) => {
                                                        s3_client.uploadWithBuffer(AWS.RECEIPT_BUCKET, pdfBuffer, pdfKey, { 'user-email': user.email, 'tech-name': `${req.user.nome} ${req.user.cognome}`, 'details': 'Sospensione' })
                                                            .then(res => {
                                                                console.log(res)
                                                                new Ticket({
                                                                    id: result.id,
                                                                    stato: "Sospeso",
                                                                    inizioSospensione: moment().format('LLL')
                                                                })
                                                                    .then(temp => { console.log(temp); return temp.suspendTicket(res.location, pdfKey) })
                                                                    .then(susTicket => {
                                                                        return resolve({
                                                                            message: 'Pdf creato e caricato con successo',
                                                                            location: susTicket.location
                                                                        })
                                                                    })
                                                                    .catch(err => reject(err))
                                                            })
                                                    })
                                                        .catch(err => reject(err))
                                                })

                                        } catch (err) {
                                            if (err) {
                                                console.log(err)
                                                return reject(err)
                                            }
                                        }

                                    }
                                });
                            })
                                .then((result) => {

                                    console.log(req.params.id_ticket);
                                    try {
                                        if (req.user.type === "tech" && tech.codCRM) {
                                            console.log("Updating Hubspot Ticket with tech codCRM:", tech.codCRM);
                                            hubspot.updateTicket(req.params.id_ticket, {
                                                hs_pipeline_stage: "3058913480",
                                                operatore: `${tech.codCRM}`
                                            })
                                        }
                                    } catch (err) {
                                        console.log(err)
                                    }

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
                                                url: result.location,
                                            },
                                            timestamp: new Date().toISOString(),
                                            eventi: data.summary
                                        });
                                        console.log("Webhook Make.com inviato correttamente ✅");
                                    } catch (err) {
                                        console.error("Errore invio webhook:", err.message);
                                    }

                                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket}: Sospeso`, `${req.user.nome} ${req.user.cognome} ha appena sospeso il suo intervento`)
                                        .then(success => {
                                            return res.status(200).json({
                                                result: {
                                                    message: "Ticket sospeso con successo"
                                                }
                                            })
                                        })
                                        .catch(err => {
                                            return res.status(500).json(err)
                                        })
                                })
                                .catch((err) => {
                                    console.log(err); return res.status(500).json({
                                        message: err
                                    })
                                })
                        })
                    break
                }

                case 'Sospeso': {
                    switch (req.user.type) {
                        case 'admin': {
                            new Ticket({
                                id: req.params.id_ticket,
                                oraPrevista: req.body.oraPrevista
                            })
                                .then(ticket => ticket.assignTicket())
                                .then(result => {
                                    try {
                                        hubspot.updateTicket(String(req.params.id_ticket), {
                                            hs_pipeline_stage: "2602144977"
                                        })
                                    } catch (err) {
                                        console.log(err)
                                    }
                                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket} aggiornato!`, `L'ora prevista di intervento è ${req.body.oraPrevista}!`)
                                        .then(success => {
                                            return res.status(200).json({
                                                result: {
                                                    message: "Orario previsto aggiornato con successo"
                                                }
                                            })
                                        })
                                        .catch(err => { console.log(err); return res.status(500).json(err) })
                                })
                                .catch(err => res.status(500).json({ err }))
                            break;
                        }
                        default: {
                            new Ticket({
                                id: req.params.id_ticket,
                                stato: "In corso",
                                fineSospensione: moment().format('LLL')
                            })
                                .then(ticket => { console.log(ticket); return ticket.resumeTicket() })
                                .then(result => {

                                    try {
                                        if (req.user.type === "tech" && tech.codCRM) {
                                            console.log("Updating Hubspot Ticket with tech codCRM:", tech.codCRM);
                                            hubspot.updateTicket(req.params.id_ticket, {
                                                hs_pipeline_stage: "3059039419",
                                                operatore: `${tech.codCRM}`
                                            })
                                        }
                                        // // Prendi le iniziali del nome
                                        // const nomeInitial = req.user.nome.charAt(0);
                                        // // Prendi le iniziali del cognome (anche se contiene spazi)
                                        // const cognomeParts = req.user.cognome.split(' ');
                                        // const cognomeInitials = cognomeParts.map(part => part.charAt(0)).join('');
                                        // hubspot.updateTicket(req.params.id_ticket, {
                                        //     hs_pipeline_stage: "3059039419",
                                        //     operatore: `${cognomeInitials}${nomeInitial}`
                                        // })
                                    } catch (err) {
                                        console.log(err)
                                    }

                                    NotificationManager.sendNotificationToUsersById(t.id_utente, `Ticket #${req.params.id_ticket}: In corso`, `${req.user.nome} ${req.user.cognome} ha appena ripreso il suo intervento`)
                                        .then(success => {
                                            return res.status(200).json({
                                                result: {
                                                    message: "Ticket ripreso con successo"
                                                }
                                            })
                                        })
                                        .catch(err => {
                                            console.log(err); return res.status(500).json({
                                                message: err
                                            })
                                        })
                                })
                                .catch(err => {
                                    console.log(err); return res.status(500).json({
                                        message: err
                                    })
                                })
                        }
                    }

                    break
                }

                default: {
                    res.status(500).json({
                        message: "Impossibile completare l'operazione"
                    })
                    break
                }
            }
        })
        .catch(err => {
            console.log(err)
            return res.status(500).json({
                message: err
            })
        })
})

export default router;