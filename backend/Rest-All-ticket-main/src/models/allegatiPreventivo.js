import { pool } from "../helpers/mysql.js";

export default class AllegatiPreventivo {
    constructor(allegato) {
        return new Promise((resolve) => {
            this.id = allegato.id;
            this.idPreventivo = allegato.idPreventivo;
            this.url = allegato.url;
            this.fileKey = allegato.fileKey
            resolve(this);
        });
    }

    create() {
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO allegatiPreventivo SET ?";
            pool.query(sql, [this], (err, res) => {
                if (err) {
                    console.log(err);
                    return reject(err);
                }
                resolve({
                    id: res.insertId,
                    idPreventivo: this.idPreventivo,
                    url: this.url
                });
            });
        });
    }

    getByIdPreventivo() {
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM allegatiPreventivo WHERE idPreventivo = ?";
            pool.query(sql, [this.idPreventivo], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }

    update() {
        return new Promise((resolve, reject) => {
            let sql = "UPDATE allegatiPreventivo SET ? WHERE id = ?";
            pool.query(sql, [this, this.id], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }
}