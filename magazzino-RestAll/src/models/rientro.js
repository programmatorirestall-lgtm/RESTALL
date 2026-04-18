import pool from "../helpers/mysql.js";
import moment from 'moment'

moment.locale('it')

class Rientro {
    constructor(rientro){
        return new Promise((resolve) => {
            this.codiceArticolo = rientro.codiceArticolo
            this.dataRientro = rientro.dataRientro || moment().add(2, 'hours').format('LLL'),
            this.quantita = rientro.quantita
            this.destinazione = rientro.destinazione
            resolve(this)
        })
    }

    create(){
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO rientri SET ? "

            pool.query(sql, [this],
                (err) => {
                    if(err) {console.log(err); return reject(err)}
                })
            return resolve(this)
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
           let sql = "SELECT * FROM rientri JOIN products ON products.codArticolo = rientri.codiceArticolo"

           pool.query(sql, (err, data) => {
            if(err) return reject(err)

            return resolve(data)
           })
        })
    }
}

export default Rientro