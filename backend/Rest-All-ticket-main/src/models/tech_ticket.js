import {pool} from '../helpers/mysql.js';
import moment from 'moment';

moment.locale('it')

class tech_ticket{
    constructor(data){
        return new Promise((resolve, reject) => {
            this.id_ticket = data.id_ticket
            this.id_tecnico = data.id_tecnico
            resolve(this)
        })
    }

    addTecnico(){
        return new Promise((resolve, reject) => {
                pool.getConnection((err, connection) => {
                    connection.beginTransaction((err) => {
                        if(err) return reject(err)
                        let selectSQL = 'SELECT * FROM tech_ticket WHERE id_ticket = ?'
                        connection.query(selectSQL, [this.id_ticket],
                            (err, result) => {
                                if(err) return connection.rollback(() => {
                                    reject(err)
                                })

                                if(result.length > 0){
                                    if(result[0].id_tecnico == this.id_tecnico) return resolve(this)
                                    let deleteSQL = 'DELETE FROM tech_ticket WHERE id_ticket = ? AND id_tecnico = ?'
                                    connection.query(deleteSQL, [this.id_ticket, result[0].id_tecnico],
                                        (err, result) => {
                                            console.log(result)
                                            if(err) return connection.rollback(() => {
                                                reject(err)
                                            })
                                        })
                                }

                                let insertSQL = 'INSERT INTO tech_ticket SET ?'
                                connection.query(insertSQL, [this],
                                    (err, result) => {
                                        if(err) return connection.rollback(() => {
                                            reject(err)
                                        })
                                    })
                                    
                                connection.commit((err) => {
                                    if(err) return connection.rollback(() => {
                                        reject(err)
                                    })
                                })
                                return resolve(this)
                            })
                    })
            })
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
            let sql = 'SELECT *, ticket.id AS id, tecnico.id AS tech_id FROM ticket JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket '
            sql += "JOIN tecnico ON tecnico.id = tech_ticket.id_tecnico WHERE tech_ticket.id_tecnico = ? AND ticket.stato != 'Chiuso' AND ticket.oraPrevista <= ? AND ticket.stato != 'Annullato' "
            sql += "ORDER BY ticket.oraPrevista"

            pool.query(sql , [this.id_tecnico, moment().endOf('day').format()],
                function(err, res){
                    
                    if(err) return reject(err)

                    resolve(res)
                })
        })
    }

    getAllClosed(limit=10, offset=0){
        return new Promise((resolve, reject) => {
            let sql = `SELECT *, ticket.id AS id, tecnico.id AS tech_id FROM ticket JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket `
            sql += `JOIN tecnico ON tecnico.id = tech_ticket.id_tecnico WHERE tech_ticket.id_tecnico = ? AND ticket.stato = 'Chiuso' LIMIT ${limit} OFFSET ${offset};`
            sql += `SELECT COUNT(*) AS count FROM ticket JOIN tech_ticket ON ticket.id = tech_ticket.id_ticket `

            pool.query(sql , [this.id_tecnico],
                function(err, res){
                    console.log(err)
                    if(err) return reject(err)

                    resolve(res)
                })
        })
    }
}

export default tech_ticket;