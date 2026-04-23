import { pool } from "../helpers/mysql.js";

export default class Setting{
    constructor(setting){
        return new Promise((resolve, reject) => {
            this.id = setting.id
            this.descr = setting.descr
            this.value = setting.value
            return resolve(this)
        })
    }

    getAll(){
        return new Promise((resolve, reject) => {
          let sql = 'SELECT * FROM settings'
            pool.query(sql, (err, data) => {
                if(err){ return reject(err) }

                return resolve(data)
            })  
        })
    }

    patchByID(){
        return new Promise((resolve, reject) => {
            let sql = 'UPDATE settings SET value = ? WHERE id = ?'
            pool.query(sql, [this.value, this.id], (err, data) => {
                if(err){ return reject(err) }

                return resolve(data)
            })
        })
        
        
    }
}