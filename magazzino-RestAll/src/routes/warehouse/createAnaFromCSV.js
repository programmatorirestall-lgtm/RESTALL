import Router from 'express'
import xlsx from 'node-xlsx'
import mysql from 'mysql'
import { upload } from '../../middleware/multer.js';
import { DATABASE } from '../../config/config.js';

var pool = mysql.createPool({
    connectionLimit : DATABASE.CONNECTION_LIMIT,
    host : DATABASE.CLUSTER,
    port: DATABASE.PORT,
    user : DATABASE.USER,
    password : DATABASE.PASS,
    database : 'main'
})

const router = new Router();

router.post('/bulk/', upload.single('clienti'), (req, res) => {
    const xlsxBuffer = xlsx.parse(req.file.buffer)
    let values = []
    let sql = "INSERT INTO azienda (clfr, codCf, ragSoc, ragSoc1, indir, cap, local, prov, codFisc, partiva, tel, tel2, fax, email, codNaz, codsdi, pec_fe) VALUES ?"

    xlsxBuffer.map((sheet) => {
        sheet.data.slice(1).map((row) => {
            if(row[16] == undefined) row[16] = ''
            values.push(row)
        })
    })

    if(!values.length) return res.status(200).json({
        message: "Nessun elemento da aggiungere alla warehouse"
    })

    pool.query(sql, [values], (err, data) => {
        if(err){
            return res.status(500).json({err})
        }

        return res.status(200).json(data)
    })
    
})

export default router