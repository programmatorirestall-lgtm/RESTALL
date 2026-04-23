import {pool} from '../helpers/mysql.js';

class Tecnico{
    constructor(tecnico){
        return new Promise((resolve) => {
            this.id = tecnico.id
            this.nome = tecnico.nome
            this.cognome = tecnico.cognome
            this.verified = tecnico.verified || "TRUE"
            this.pagamento_orario = tecnico.pagamento_orario || 0;
            this.codCRM = tecnico.codCRM || null;
            resolve(this)
        })
    }

    create(){
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO tecnico SET ?"

            pool.query(sql, [this],
                function(err){
                    if(err) {console.log(err); return reject(err)}
                })
                resolve(this)
        })
    }

    getById(){
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM tecnico WHERE id = ?"

            pool.query(sql, [this.id],
                function(err, res){
                    if(err) return reject(err)

                    resolve(res[0])
                })
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM tecnico"

            pool.query(sql, function(err, res){
                if(err) return reject(err)

                resolve(res)
            })
        })
    }

    updateVerify(){
        return new Promise((resolve, reject) => {
            let sql = "UPDATE tecnico SET verified = ? WHERE id = ?"
            
            pool.query(sql, [this.verified, this.id], 
                (err, res) => {
                    if(err) reject(err)

                    return resolve(res)
                })
        })
    }

    patchPagamentoOrario(){
        return new Promise((resolve, reject) => {
            let sql = "UPDATE tecnico SET pagamento_orario = ? WHERE id = ?"

            pool.query(sql, [this.pagamento_orario, this.id],
                (err, res) => {
                    if(err) reject(err)

                    return resolve(res)
                }
            )
        })
    }

    getAnalytics(dataInizio, dataFine){
        return new Promise((resolve, reject) => {
            let sql = "SELECT COUNT(*) AS num FROM tech_ticket JOIN ticket ON ticket.id = tech_ticket.id_ticket WHERE tech_ticket.id_tecnico = ? AND ticket.stato = ?"
            //if(dataFine != undefined && dataInizio != undefined) sql += " AND ticket.data BETWEEN ? AND ?"

            pool.getConnection((err, connection) => {
                connection.beginTransaction((err) => {
                    if(err) {console.log(err); connection.rollback(() => {connection.release(); return reject(err)})}

                    connection.query(sql, [this.id, 'In corso'], 
                        (err, numIncorso) => {
                            if(err) {console.log(err); connection.rollback(() => {connection.release(); return reject(err)})}

                            connection.query(sql, [this.id, 'Chiuso'],
                                (err, numChiusi) => {
                                    if(err) {console.log(err); connection.rollback(() => {connection.release(); return reject(err)})}

                                    connection.query(sql, [this.id, 'Sospeso'],
                                        (err, numSospesi) => {
                                            if(err) {console.log(err); connection.rollback(() => {connection.release(); return reject(err)})}

                                            connection.commit((err) => {
                                                if(err) {console.log(err); connection.rollback(() => {connection.release(); return reject(err)})}

                                                connection.release()
                                                resolve({
                                                    incorso: numIncorso[0].num,
                                                    chiusi: numChiusi[0].num,
                                                    numSospesi: numSospesi[0].num
                                                })
                                            })
                                        }
                                    )
                                }
                            )
                        }
                    )
                })
            })
        })
    }
}

export default Tecnico;