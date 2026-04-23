import Ticket from '../../models/ticket.js';
import Router from 'express';
import moment from 'moment';

const router = new Router();

router.delete('/:id_ticket', (req, res) => {
    new Ticket({
        id: req.params.id_ticket,
        stato: 'Annullato'
    })
    .then(t => t.cancelTicket())
    .then(result => res.status(200).json({
        'message': 'Ticket annullato con successo!'
    }))
    .catch(err => {
        console.log(err)
        res.status(500).json({'message': 'Impossibile annullare il ticket'
    })})
})

export default router