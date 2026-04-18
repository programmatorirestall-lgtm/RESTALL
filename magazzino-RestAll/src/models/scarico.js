import pool from "../helpers/mysql.js";
import moment from "moment";

moment.locale('it')

class Scarico {
    constructor(scarico){
        return new Promise((resolve) => {
            this.codiceArticolo = scarico.codiceArticolo
            this.dataScarico = scarico.dataRientro || moment().add(2, 'hours').format('LLL'),
            this.quantita = scarico.quantita
            resolve(this)
        })
    }

    create(){
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO scarichi SET ? "

            pool.query(sql, [this],
                (err) => {
                    if(err) return reject(err)
                })
            return resolve(this)
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
            const sql = "SELECT * FROM scarichi JOIN products ON products.codArticolo = scarichi.codiceArticolo"

           pool.query(sql, (err, data) => {
            if(err) return reject(err)

            return resolve(data)
           })
        })
    }
}

export default Scarico