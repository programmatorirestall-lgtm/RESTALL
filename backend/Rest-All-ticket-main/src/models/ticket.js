import {pool} from '../helpers/mysql.js';
import Fogli from './fogli.js';
import Eventi from './eventi.js';
import moment from 'moment';

moment.locale('it');
moment.suppressDeprecationWarnings = true;

class Ticket{
    constructor(ticket){
        return new Promise((resolve) => {
            this.id = ticket.id
            this.tipo_macchina = ticket.tipo_macchina
            this.stato_macchina = ticket.stato_macchina
            this.descrizione = ticket.descrizione
            this.data = ticket.data
            this.id_utente = ticket.id_utente
            this.indirizzo = ticket.indirizzo
            this.stato = ticket.stato || 'Aperto'
            this.oraInizio = ticket.oraInizio 
            this.inizioSospensione = ticket.inizioSospensione
            this.fineSospensione = ticket.fineSospensione
            this.oraPrevista = ticket.oraPrevista
            this.oraChiusura = ticket.oraChiusura
            this.rifEsterno = ticket.rifEsterno
            this.rifFurgone = ticket.rifFurgone
            this.ragSocAzienda = ticket.ragSocAzienda
            this.idMacchina = ticket.idMacchina
            resolve(this)
        })
    }

    create(){
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO ticket SET ?";

            pool.query(sql, [this],
                (err, res) => {
                    if(err) {console.log(err); return reject(err)}
                    resolve({
                        id: res.insertId,
                        tipo_macchina: this.tipo_macchina,
                        stato_macchina: this.stato_macchina,
                        descrizione: this.descrizione,
                        data: this.data,
                        id_utente: this.id_utente,
                        indirizzo: this.indirizzo,
                        stato: this.stato || 'Aperto',
                        oraInizio: this.oraInizio,
                        inizioSospensione: this.inizioSospensione,
                        fineSospensione: this.fineSospensione,
                        oraPrevista: this.oraPrevista,
                        oraChiusura: this.oraChiusura,
                        rifEsterno: this.rifEsterno,
                        rifFurgone: this.rifFurgone,
                        ragSocAzienda: this.ragSocAzienda,
                        idMacchina: this.idMacchina
                    })
            })
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM ticket"
            // let sql = "SELECT *, ticket.id AS id, tecnico.id AS tech_id FROM ticket" "LEFT JOIN tecnico ON tech_ticket.id_tecnico = tecnico.id"
            sql += " LEFT JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket WHERE stato != 'Chiuso' AND stato != 'Annullato'"
            if(this.id_utente !== undefined) sql += ` AND id_utente = ${this.id_utente}`
            sql += " ORDER BY id DESC"
            
            pool.query(sql,
                function(err, res){
                    if(err) reject(err)

                    resolve(res)
                })
        })
    }

    getAllClosed(limit=50, offset=0){
        return new Promise((resolve, reject) => {
            let sql = `SELECT * FROM ticket JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket WHERE (stato = 'Chiuso' OR stato = 'Annullato')`
            if(this.id_utente !== undefined) sql += ` AND id_utente = ${this.id_utente}`
            sql += ` ORDER BY id DESC LIMIT ${limit} OFFSET ${offset}; SELECT COUNT(*) AS num FROM ticket JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket WHERE (stato = 'Chiuso' OR stato = 'Annullato')`

            pool.query(sql,
                function(err, res){
                    if(err) reject(err)
                    resolve(res)
                })
        })
    }

    getByUserId(){
        return new Promise((resolve, reject) => {
            let sql = "SELECT id, tipo_macchina, stato_macchina, descrizione, data, id_utente, id_tecnico, ragSocAzienda, rifEsterno "
            + "FROM ticket LEFT JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket WHERE ticket.id_utente = ?"

            pool.query(sql, [this.id_utente],
                function(err, res){
                    if(err) return reject(err)
                    return resolve(res)
                })

        })
    }

    getById(){
        return new Promise((resolve, reject) => {
            pool.getConnection((err, connection) => {
                if(err) reject(err)

                connection.beginTransaction((err) => {
                    if(err) {connection.release(); return reject(err)}

                    let sql = " SELECT * FROM ticket LEFT JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket WHERE ticket.id = ?"

                    connection.query(sql, [this.id],
                        function(err, ticket){
                            if(err) connection.rollback(() => {connection.release(); return reject(err)})

                            sql = "SELECT * FROM eventi WHERE idTicket = ? ORDER BY dataInizio"
                            let riepilogo = []
                            connection.query(sql, [ticket[0].id],
                                (err, eventi) => {
                                    if(err) connection.rollback(() => {connection.release(); return reject(err)})
                                    eventi.map(({dataInizio, dataFine, evento}) => {
                                        riepilogo.push({
                                            dataInizio: moment(dataInizio).format("YYYY-MM-DD HH:mm:ss"),
                                            dataFine: (dataFine !== null) ? moment(dataFine).format("YYYY-MM-DD HH:mm:ss") : "",
                                            evento
                                        })
                                    })
                                    console.log(riepilogo)
                                    connection.commit((err) => {
                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                        connection.release()
                                        return resolve({
                                            id: ticket[0].id,
                                            stato_macchina: ticket[0].stato_macchina,
                                            tipo_macchina: ticket[0].tipo_macchina,
                                            descrizione: ticket[0].descrizione,
                                            id_utente: ticket[0].id_utente,
                                            data: ticket[0].data,
                                            indirizzo: ticket[0].indirizzo,
                                            stato: ticket[0].stato,
                                            oraInizio: "Consultare il sommario",
                                            oraPrevista: ticket[0].oraPrevista,
                                            rifEsterno: ticket[0].rifEsterno,
                                            rifFurgone: ticket[0].rifFurgone,
                                            ragSocAzienda: ticket[0].ragSocAzienda,
                                            id_tecnico: ticket[0].id_tecnico,
                                            summary: riepilogo
                                        })
                                    })
                                })

                    })
                })
            })
        })
    }

    // updateTicket(){
    //     return new Promise((resolve, reject) => {
    //         let sql = `UPDATE ticket SET `
    //         let delimiter = ""

    //         sql += Object.keys(this).map((key) => {
    //             console.log(delimiter)
    //             delimiter = ""
    //             if(key !== 'id' && this[key] !== undefined) {
    //                 const value = typeof this[key] === 'string' ? `'${this[key]}'` : this[key]
    //                 delimiter = ', '
    //                 return `${key} = ${value} `
    //             }
    //         }).join(delimiter)

    //         sql += ` WHERE id = ${this.id}`
    //         resolve(sql)
    //     })
    // }

    startTicket(){
        return new Promise((resolve, reject) => {
            pool.getConnection((err, connection) => {
                if(err) return reject(err)

                connection.beginTransaction((err) => {
                    if(err) {connection.release(); return reject(err)}
                    
                    let sql = "UPDATE ticket SET stato = ? WHERE id = ?"
                    connection.query(sql, [this.stato, this.id],
                        (err, res) => {
                            if(err) return connection.rollback(() => {connection.release(); return reject(err)})

                            new Eventi({
                                idTicket: this.id,
                                dataInizio: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                evento: this.stato
                            })
                            .then(e => {
                                sql = "INSERT INTO eventi SET ?"

                                connection.query(sql, e, 
                                    (err, res) => {
                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                        connection.commit((err) => {
                                            if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                            connection.release()
                                            return resolve(res)
                                        })
                                    })
                            })
                            .catch(err => {connection.release(); return reject(err)}) 
                        })
                })
            })
        })
    }

    cancelTicket(){
        return new Promise((resolve, reject) => {
            pool.getConnection((err, connection) => {
                if(err) return reject(err)
            
                connection.beginTransaction((err) => {
                    if(err) {connection.release(); return reject(err)}
    
                    let sql = "UPDATE ticket SET stato = ? WHERE id = ?"
    
                    connection.query(sql, [this.stato, this.id], 
                        (err, res) => {
                            if(err) {
                                console.log(err)
                                return connection.rollback(() => {connection.release(); return reject(err)})
                            }

                            new Eventi({
                                idTicket: this.id,
                                dataInizio: moment().add(2, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                evento: this.stato
                            })
                            .then(e => {
                                sql = "INSERT INTO eventi SET ?"

                                connection.query(sql, e, 
                                    (err, res) => {
                                        if(err){
                                            return connection.rollback(() => {connection.release(); return reject(err)})
                                        }

                                        connection.commit((err) => {
                                            if(err){
                                                return connection.rollback(() => {connection.release(); return reject(err)})
                                            }

                                            connection.release()
                                            return resolve(res)
                                        })
                                    })
                            })
                            .catch(err => reject(err))
                        })
                })
            })
        })
    }

    suspendTicket(location, fileKey){
        return new Promise((resolve, reject) => {
            pool.getConnection((err, connection) => {
                if(err) reject(err)

                connection.beginTransaction((err) => {
                    if(err) {connection.release(); return reject(err)}

                    let sql = "UPDATE ticket SET stato = ? WHERE id = ?"
                    connection.query(sql, [this.stato, this.id], 
                        (err, res) =>{
                            if(err) connection.rollback(() => {connection.release(); return reject(err)})
                            
                            new Eventi({
                                idTicket: this.id,
                                dataInizio: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                evento: this.stato
                            })
                            .then(e => {
                                sql = "INSERT INTO eventi SET ?"
                                connection.query(sql, e,
                                    (err, res) => {
                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                        sql = "UPDATE eventi SET dataFine = ? WHERE idTicket = ? AND dataFine IS NULL AND evento = 'In corso'"
                                        connection.query(sql, [e.dataInizio, e.idTicket],
                                            (err, res) => {
                                                if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                                new Fogli({
                                                    idTicket: this.id,
                                                    location,
                                                    fileKey
                                                })
                                                .then(foglio => foglio.create())
                                                .then(res => {
                                                    connection.commit((err) => {
                                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})
        
                                                        connection.release()
                                                        return resolve(res)
                                                    })
                                                })
                                                .catch(err => connection.rollback(() => {connection.release(); return reject(err)}))
                                        })
                                    })
                            })
                            .catch(err => connection.rollback(() => {connection.release(); return reject(err)}))
                        })
                })
            })
        })
    }

    resumeTicket(){
        return new Promise((resolve, reject) => {
            pool.getConnection((err,connection) => {
                if(err) reject(err)

                connection.beginTransaction((err) => {
                    if(err) reject(err)

                    let sql = "UPDATE ticket SET stato = ? WHERE id = ?"
                    connection.query(sql, [this.stato, this.id], 
                        (err, res) => {
                            if(err) connection.rollback(() => {connection.release(); return reject(err)})

                            new Eventi({
                                idTicket: this.id,
                                dataFine: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                evento: "Sospeso"
                            })
                            .then(e => {
                                sql = "UPDATE eventi SET dataFine = ? WHERE idTicket = ? AND dataFine IS NULL AND evento = ?"
                                connection.query(sql, [e.dataFine, e.idTicket, e.evento],
                                    (err, res) => {
                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                        new Eventi({
                                            idTicket: this.id,
                                            dataInizio: e.dataFine,
                                            evento: "In corso"
                                        })
                                        .then(evento => {
                                            sql = "INSERT INTO eventi SET ?"
                                            connection.query(sql, evento,
                                                (err, startResult) => {
                                                    if(err) connection.rollback(() => {connection.release(); return reject(err)})
                                                
                                                    connection.commit((err) => {
                                                        if(err) connection.rollback(() => {connection.release(); return reject(err)})
            
                                                        connection.release()
                                                        return resolve(startResult)
                                                    })
                                                })
                                        })
                                        .catch(err => {connection.release(); return reject(err)})
                                    })
                            })
                            .catch(err => connection.rollback(() => {connection.release(); return reject(err)}))
                        })
                })
            })
        }) 
    }

    closeTicket(location, fileKey){
        return new Promise((resolve, reject) => {
            pool.getConnection((err, connection) => {
                if(err) reject(err)

                connection.beginTransaction((err) => {
                    if(err) {connection.release(); return reject(err)}

                    let sql = "UPDATE ticket SET stato = 'Chiuso' WHERE id = ?"
                    connection.query(sql, [this.id],
                        (err, res) => {
                            if(err) connection.rollback(() => {console.log(err); connection.release(); return reject(err)})

                            new Eventi({
                                idTicket: this.id,
                                dataInizio: moment().add(1, 'hours').format("YYYY/MM/DD HH:mm:ss"),
                                evento: "Chiuso"
                            })
                            .then(e => {
                                sql = "INSERT INTO eventi SET ?"    
                                connection.query(sql, e, 
                                    (err, res) => {
                                        if(err) connection.rollback(() => {console.log(err); connection.release(); return reject(err)})

                                        sql = "UPDATE eventi SET dataFine = ? WHERE idTicket = ? AND dataFine IS NULL AND evento = 'In corso'"
                                        connection.query(sql, [e.dataInizio, e.idTicket],
                                            (err, res) => {
                                                if(err) connection.rollback(() => {connection.release(); return reject(err)})

                                                new Fogli({
                                                    idTicket: this.id,
                                                    location,
                                                    fileKey
                                                })
                                                .then(foglio => foglio.create())
                                                .then(res => {
                                                    connection.commit((err) => {
                                                        if(err) connection.rollback(() => {console.log(err); connection.release(); return reject(err)})
        
                                                        connection.release()
                                                        return resolve(res)
                                                    })
                                                })
                                                .catch(err => connection.rollback(() => {console.log(err); connection.release(); return reject(err)}))
                                            
                                        })

                                    })
                            })
                            .catch(err => connection.rollback(() => {console.log(err); connection.release(); return reject(err)}))
                        })
                })
            })
        })
    }

    assignTicket(){
        return new Promise((resolve, reject) => {
            let sql = "UPDATE ticket set oraPrevista = ? WHERE id = ?"

            pool.query(sql, [this.oraPrevista, this.id],
                function(err, res){
                    if(err) reject(err)

                    return resolve(res)
                })
        })
    }
}

export default Ticket;