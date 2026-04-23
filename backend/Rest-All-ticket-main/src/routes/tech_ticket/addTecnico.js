import tech_ticket from '../../models/tech_ticket.js';
import Tecnico from '../../models/tecnico.js';
import adminMiddleware from '../../middlewares/adminRole.js';
import Router from 'express';
import NotificationManager from '../../helpers/FCMTokenManager.js';
import HubspotTicketsHelper from '../../helpers/hubspotTicketHelper.js';
import { HUBSPOT } from '../../config/constants.js';


const router = new Router();
const hubspot = new HubspotTicketsHelper(HUBSPOT.TOKEN);


router.post('/', adminMiddleware, (req, res) => {
    if (!req.body.id_ticket) return res.status(400).json({
        message: 'missing id_ticket'
    })
    if (!req.body.id_tecnico) return res.status(400).json({
        message: 'missing id_tecnico'
    })

    let tt = {
        id_ticket: req.body.id_ticket,
        id_tecnico: req.body.id_tecnico
    }

    new tech_ticket(tt)
        .then(tt => tt.addTecnico())
        .then(async (result) => {

            let tech = await new Tecnico({ id: req.body.id_tecnico })
            let tecnico = await tech.getById();

            try {
                hubspot.updateTicket(req.body.id_ticket, {
                    //hs_pipeline_stage: "2602144978",
                    operatore: `${tecnico.codCRM}`
                })
            } catch (err) {
                console.log(err)
            }
            NotificationManager.sendNotificationToTechsById(`${tt.id_tecnico}`, `Nuovo ticket assegnato #${tt.id_ticket}`, `Nella sezione ticket troverai le informazioni sul nuovo ticket assegnato!`)
                .then(success => {
                    return res.status(201).json({
                        result
                    })
                })
                .catch(err => {
                    return res.status(500).json({ err })
                })
        })
        .catch(err => {
            console.log(err)
            return res.status(500).json({
                err
            })
        })
})

export default router