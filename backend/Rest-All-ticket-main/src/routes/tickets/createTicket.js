import Ticket from '../../models/ticket.js';
import Router from 'express';
import validate from '../../middlewares/validateTicket.js';
import moment from 'moment';
import { AWS } from '../../config/config.js';
import NotificationManager from '../../helpers/FCMTokenManager.js';
import { dynamoClient, lambdaClient } from '../../helpers/aws.js';
import HubspotTicketsHelper from '../../helpers/hubspotTicketHelper.js';
import { HUBSPOT } from '../../config/constants.js';

const router = new Router();
const admins = await dynamoClient.getAllAdmins();
const hubspot = new HubspotTicketsHelper(HUBSPOT.TOKEN);

moment.locale('it')

router.post('/', validate, (req, res) => {
    let t = {
        tipo_macchina: req.body.tipo_macchina,
        stato_macchina: req.body.stato_macchina,
        descrizione: req.body.descrizione,
        data: moment().format(),
        indirizzo: req.body.indirizzo,
        id_utente: req.user.id,
        rifEsterno: req.body.rifEsterno,
        rifFurgone: req.body.rifFurgone,
        ragSocAzienda: req.body.ragSocAzienda,
        idMacchina: req.body.idMacchina,
    }

    let fonte = req.body.fonte || null;

    new Ticket(t)
        .then(ticket => ticket.create())
        .then(result => {
            let ragSociale
            if (req.body.ragSocAzienda != undefined) {
                ragSociale = `${req.body.ragSocAzienda}`
            } else {
                ragSociale = `${req.user.nome} ${req.user.cognome}`
            }
            NotificationManager.sendNotificationToAdmins(`Nuovo ticket creato!`, `${ragSociale} ha appena creato il ticket ${result.id}`)
                .then(async () => {
                    if (admins.filter((admin) => admin.id == req.user.id).length == 0) {
                        let user = await dynamoClient.getItemById(req.user.id);
                        admins.forEach(admin => {
                            const payload = JSON.stringify({
                                user: {
                                    nome: user.nome,
                                    cognome: user.cognome,
                                    email: user.email,
                                    numTel: user.numTel
                                },
                                ticket: {
                                    id: result.id
                                },
                                recipient: admin.email
                            });

                            console.log("Payload inviato a Lambda:", payload);

                            lambdaClient.invoke({
                                FunctionName: AWS.LAMBDA_SEND_ADMINS_EMAIL,
                                Payload: payload,
                                InvocationType: 'Event'
                            })
                        });
                    }

                    if (fonte != "CRM") {
                        console.log("Ticket proveniente non da CRM! ", fonte)
                        let companyId = null;
                        if (req.body.ragSocAzienda == undefined) {
                            try {
                                const hubData = await hubspot.createTicketNoAssociations({
                                    subject: `Ticket #${result.id}`,
                                    content: result.descrizione,
                                    ticketIdApp: result.id,
                                    tipoMacchina: result.tipo_macchina,
                                    statoMacchina: result.stato_macchina,
                                    priority: "MEDIUM",
                                    pipelineStage: "2602144976"
                                });

                                console.log("HubSpot ticket creation response:", hubData);
                            } catch (err) {
                                console.error("Errore creazione ticket in HubSpot:", err.response?.data || err.message);
                            }
                        } else {
                            try {
                                const company = await hubspot.searchCompanyByName(ragSociale);
                                if (company) {
                                    companyId = company.id;
                                    console.log(`Company trovata su HubSpot: ${company.properties.name} (${companyId})`);
                                } else {
                                    console.log("Nessuna company trovata con quella ragione sociale");
                                }
                            } catch (err) {
                                console.error("Errore ricerca company in HubSpot:", err.response?.data || err.message);
                            }

                            if (companyId) {
                                try {
                                    const hubData = await hubspot.createTicket({
                                        subject: `Ticket #${result.id}`,
                                        content: result.descrizione,
                                        ticketIdApp: result.id,
                                        tipoMacchina: result.tipo_macchina,
                                        statoMacchina: result.stato_macchina,
                                        priority: "MEDIUM",
                                        pipelineStage: "2602144976"
                                    }, companyId);

                                    console.log("HubSpot ticket creation response:", hubData);
                                } catch (err) {
                                    console.error("Errore creazione ticket in HubSpot:", err.response?.data || err.message);
                                }
                            } else {
                                try {
                                    const hubData = await hubspot.createTicketNoAssociations({
                                        subject: `Ticket #${result.id}`,
                                        content: result.descrizione,
                                        ticketIdApp: result.id,
                                        tipoMacchina: result.tipo_macchina,
                                        statoMacchina: result.stato_macchina,
                                        priority: "MEDIUM",
                                        pipelineStage: "2602144976"
                                    });
                                    console.log("HubSpot ticket creation response (no company):", hubData);
                                } catch (err) {
                                    console.error("Errore creazione ticket in HubSpot (no company):", err.response?.data || err.message);
                                }
                            }
                        }
                    }

                    NotificationManager.sendNotificationToUsersById(req.user.id, `Ticket preso in carico!`,
                        `Gentile cliente, grazie per la sua richiesta, il ticket è stato preso in carico`)

                    return res.status(201).json({ ticket: result })
                })
                .catch(err => { console.log(err); return res.status(500).json({ err }) })
        })
        .catch(err => {
            console.log(err); return res.status(500).json({
                err
            })
        })
})

export default router;