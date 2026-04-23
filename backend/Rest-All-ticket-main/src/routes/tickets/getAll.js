import Router from 'express';
import Ticket from '../../models/ticket.js';
import tech_ticket from '../../models/tech_ticket.js';
import { dynamoClient } from '../../helpers/aws.js';

const router = new Router();

router.get('/', (req, res) => {
    switch(req.user.type){
        case 'tech': {
            let tt = {
                id_tecnico: parseInt(req.user.id)
            }
            new tech_ticket(tt).then(result => result.getAll())
            .then(tickets => {
                return Promise.all(tickets.map(({id, tipo_macchina, stato_macchina, data, indirizzo, stato, id_utente, oraPrevista, ragSocAzienda, idMacchina}) => {
                    return new Promise((resolve, reject) => {
                        dynamoClient.getItemById(id_utente).then(user => {
                            return resolve({
                                id,
                                tipo_macchina,
                                stato_macchina,
                                idMacchina,
                                data,
                                stato,
                                indirizzo,
                                oraPrevista,
                                ragSocAzienda,
                                utente: {
                                    nome: user.nome, 
                                    cognome: user.cognome,
                                    email: user.email
                                }
                            })
                        })
                        .catch(err => reject(err))
                    })
                }))
            })
            .then(tickets => res.status(200).json({
                tickets
            }))
            .catch(err => res.status(500).json({
                err
            }))
            break
        }
        default: {

            let t = {
                'admin' : {},
                'user': {
                    id_utente: req.user.id
                }
            }
            new Ticket(t[req.user.type])
            .then(ticket => ticket.getAll())
            .then(tickets => {
                return Promise.all(tickets.map(({id, tipo_macchina, stato_macchina, data, indirizzo, stato, id_utente, id_tecnico, oraPrevista, ragSocAzienda, idMacchina}) => {
                    return new Promise(async (resolve, reject) => {
                        switch(req.user.type){
                            case 'admin': {
                                dynamoClient.getItemById(id_utente).then((user) => 
                                    resolve({
                                        id,
                                        tipo_macchina,
                                        stato_macchina,
                                        idMacchina,
                                        data,
                                        stato,
                                        indirizzo,
                                        oraPrevista,
                                        ragSocAzienda,
                                        utente: {
                                            nome: user.nome, 
                                            cognome: user.cognome,
                                            email: user.email,
                                            numTel: user.numTel
                                        },
                                        id_tecnico 
                                    })
                                )
                                .catch(err => {
                                    console.log(err)
                                    return reject(err)
                                })
                                break
                            }
                            default: {
                                const user = await dynamoClient.getItemById(id_utente)
                                resolve({
                                    id,
                                    tipo_macchina,
                                    stato_macchina,
                                    data,
                                    stato,
                                    indirizzo,
                                    oraPrevista,
                                    utente: {
                                        nome: user.nome, 
                                        cognome: user.cognome,
                                        email: user.email,
                                        numTel: user.numTel
                                    },
                                    id_tecnico
                                })
                                break
                            }
                        }
                    })
                }))
            })
            .then(tickets => { return res.status(200).json({
                tickets
            })})
            .catch(err => {console.log(err); return res.status(500).json({
                message: err
            })})

            break
        }
    }

    
})

export default router;