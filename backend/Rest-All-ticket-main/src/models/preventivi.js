import { pool } from '../helpers/mysql.js';
import moment from 'moment';

moment.locale('it');
moment.suppressDeprecationWarnings = true;

class Preventivi {
    constructor(preventivo) {
        return new Promise((resolve) => {
            this.id = preventivo.id;
            this.descrizione = preventivo.descrizione;
            this.ragSocialeAzienda = preventivo.ragSocialeAzienda;
            this.numCellulare = preventivo.numCellulare;
            this.urlDoc = preventivo.urlDoc;
            this.stato = preventivo.stato || 'APERTO';
            this.data = preventivo.data || '';
            this.fileKey = preventivo.fileKey || '';
            this.idUtente = preventivo.idUtente
            resolve(this);
        });
    }

    create() {
        return new Promise((resolve, reject) => {
            let sql = "INSERT INTO preventivi SET ?";
            if(this.data === ''){
                this.data = moment().format('YYYY-MM-DD HH:mm:ss');
            }
            pool.query(sql, [this], (err, res) => {
                if (err) {
                    console.log(err);
                    return reject(err);
                }
                resolve({
                    id: res.insertId,
                    descrizione: this.descrizione,
                    ragSocialeAzienda: this.ragSocialeAzienda,
                    numCellulare: this.numCellulare,
                    doc: this.doc,
                    stato: this.stato
                });
            });
        });
    }

    getAll(offset = 0, limit = 10) {
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM preventivi LIMIT ? OFFSET ?";
            pool.query(sql, [limit, offset], (err, res) => {
                if (err) reject(err);
                resolve(res);
            });
        });
    }

    getById() {
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM preventivi WHERE id = ?";
            pool.query(sql, [this.id], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }

    getDetailsById() {
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM preventivi JOIN allegatiPreventivo ON preventivi.id = allegatiPreventivo.idPreventivo WHERE preventivi.id = ?";
            pool.query(sql, [this.id], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }

    update() {
        return new Promise((resolve, reject) => {
            let sql = "UPDATE preventivi SET ? WHERE id = ?";
            pool.query(sql, [this, this.id], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }

    delete() {
        return new Promise((resolve, reject) => {
            let sql = "DELETE FROM preventivi WHERE id = ?";
            pool.query(sql, [this.id], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        });
    }

    getByUserId() {
        return new Promise((resolve, reject) => {
            let sql = "SELECT * FROM preventivi WHERE idUtente = ?";
            pool.query(sql, [this.idUtente], (err, res) => {
                if (err) return reject(err);
                return resolve(res);
            });
        }); 
    }
}

export default Preventivi;