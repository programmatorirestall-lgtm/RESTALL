import Router from 'express';
import Ticket from '../../models/ticket.js';

const router = new Router();

router.get('/:id_utente', (req, res) => {
    new Ticket({
        id_utente: req.params.id_utente
    })
    .then(ticket => ticket.getByUserId())
    .then(tickets => {
        return new Promise.all(tickets.map(({id, tipo_macchina, stato_macchina, data}) => {
            return new Promise(resolve => {
                resolve({
                    id, 
                    tipo_macchina,
                    stato_macchina,
                    data
                })
            })
        }))
    })
    .then(async result => { 
        const user = await dynamoClient.getItemById(details.id_utente)
        return res.status(200).json({
            tickets: {
                id: result.id,
                tipo_macchina: result.tipo_macchina,
                stato_macchina: result.stato_macchina,
                data: result.data,
                numTel: user.numTel
            }
    }) })
    .catch(err => {
        return res.json(500).json(err)
    })
})

export default router;