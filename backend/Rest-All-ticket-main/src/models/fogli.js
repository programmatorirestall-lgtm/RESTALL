import {pool} from '../helpers/mysql.js';

class Fogli{
    constructor(fogli){
        return new Promise((resolve) => {
            this.id = fogli.id
            this.idTicket = fogli.idTicket
            this.location = fogli.location
            this.fileKey = fogli.fileKey
            resolve(this)
        })
    }

    create(){
        return new Promise((resolve, reject) => {
            let sql = 'INSERT INTO fogli SET ?'
            pool.query(sql, [this], 
                function(err, res){
                    if(err) reject(err)
                })
            resolve(this)
        })
    }

    getByTicketId(){
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM fogli WHERE idTicket = ?"
            pool.query(sql, [this.idTicket], 
                function(err, res){
                    if(err) reject(err)

                    resolve(res)
                })
        })
    }

    updateLocation(){
        return new Promise((resolve, reject) => {
            let sql = "UPDATE fogli SET location = ? WHERE id = ?"

            pool.query(sql, [this.location, this.id],
                function(err){
                    if(err) {console.log(err); return reject(err)}
                })
                return resolve(this)
        })
    }
}

export default Fogli;