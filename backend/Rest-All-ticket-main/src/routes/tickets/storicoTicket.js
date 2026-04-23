import Router from 'express';
import Ticket from '../../models/ticket.js';
import tech_ticket from '../../models/tech_ticket.js';
import { dynamoClient } from '../../helpers/aws.js';

const router = new Router()

router.get('/closed', (req, res) => {
    let totalCount;
    switch(req.user.type){
        case 'tech': {
            let tt = {
                id_tecnico: parseInt(req.user.id)
            }
            new tech_ticket(tt).then(result => result.getAllClosed(req.query.limit, req.query.offset))
            .then(result => {
                totalCount = result[1]
                return Promise.all(result[0].map(({id, tipo_macchina, stato_macchina, data, indirizzo, stato, id_utente, oraChiusura, location}) => {
                    return new Promise((resolve, reject) => {
                        dynamoClient.getItemById(id_utente).then(user => {
                            return resolve({
                                id,
                                tipo_macchina,
                                stato_macchina,
                                data,
                                stato,
                                indirizzo,
                                oraChiusura,
                                utente: {
                                    nome: user.nome, 
                                    cognome: user.cognome,
                                    email: user.email
                                },
                                location
                            })
                        })
                        .catch(err => {console.log(err); return reject(err)})
                    })
                }))
            })
            .then(tickets => res.status(200).json({
                tickets,
                totalCount: totalCount[0].count
            }))
            .catch(err => {console.log(err); res.status(500).json({
                err
            })})
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
            .then(ticket => ticket.getAllClosed(req.query.limit, req.query.offset))
            .then(result => {
                totalCount = result[1]
                return Promise.all(result[0].map(({id, tipo_macchina, stato_macchina, data, indirizzo, stato, id_utente, id_tecnico, oraChiusura, idMacchina}) => {
                    return new Promise((resolve, reject) => {
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
                                        oraChiusura,
                                        utente: {
                                            nome: user.nome, 
                                            cognome: user.cognome,
                                            email: user.email
                                        },
                                        id_tecnico
                                        // tecnico: {
                                        //     id: id_tecnico,
                                        //     nome,
                                        //     cognome
                                        // } 
                                    })
                                )
                                .catch(err => {
                                    console.log(err)
                                    return reject(err)
                                })
                                break
                            }
                            default: {
                                resolve({
                                    id,
                                    tipo_macchina,
                                    stato_macchina,
                                    idMacchina,
                                    data,
                                    stato,
                                    indirizzo,
                                    oraChiusura,
                                    id_tecnico
                                })
                                break
                            }
                        }
                    })
                }))
            })
            .then(tickets => { return res.status(200).json({
                tickets,
                totalCount: totalCount[0].num
            })})
            .catch(err => {console.log(err); return res.status(500).json({
                message: err
            })})

            break
        }
    }
})

export default router