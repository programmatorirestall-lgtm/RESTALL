import Router from 'express'
import mysql from 'mysql'
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

router.post('/', (req, res) => {
    let {clfr, codCf, ragSoc, indir, cap, local, prov, codFisc, partiva, tel, tel2, fax, email, codNaz, codsdi, pec_fe} = req.body
    let sql = "INSERT INTO azienda (clfr, codCf, ragSoc, indir, cap, local, prov, codFisc, partiva, tel, tel2, fax, email, codNaz, codsdi, pec_fe) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"

    pool.query(sql, [clfr, codCf, ragSoc, indir, cap, local, prov, codFisc, partiva, tel, tel2, fax, email, codNaz, codsdi, pec_fe], (err, data) => {
        if(err){
            return res.status(500).json({err})
        }

        return res.status(200).json(data)
    })
    
})

export default router