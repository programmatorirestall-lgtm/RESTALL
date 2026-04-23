import Preventivi from '../../models/preventivi.js';
import Router from 'express';
import validate from '../../middlewares/validatePreventivi.js';
import moment from 'moment';
import NotificationManager from '../../helpers/FCMTokenManager.js';

const router = new Router();

moment.locale('it');

router.post('/', validate, async (req, res) => {
    try {
        let p = {
            descrizione: req.body.descrizione,
            ragSocialeAzienda: req.body.ragSocialeAzienda,
            numCellulare: req.body.numCellulare,
            urlDoc: req.body.urlDoc,
            stato: req.body.stato || 'APERTO',
            idUtente: req.user.id
        };
        
        const preventivo = await new Preventivi(p);
        const result = await preventivo.create();
        
        NotificationManager.sendNotificationToAdmins(
            `Nuovo preventivo creato!`, 
            `${p.ragSocialeAzienda} ha appena creato il preventivo ${result.id}`
        );

        NotificationManager.sendNotificationToUsersById(req.user.id, `Preventivo preso in carico!`, 
            `Gentile cliente, grazie per la sua richiesta, il preventivo è stato preso in carico`)
        
        res.status(201).json({ message: 'Preventivo creato con successo', result });
    } catch (err) {
        console.log(err);
        res.status(500).json({ err });
    }
});

export default router;