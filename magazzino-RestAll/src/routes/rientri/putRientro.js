import { Router } from "express";
import Rientro from "../../models/rientro.js";

const router = new Router()

router.post('/', (req, res) => {
    let rientri = req.body.rientri

    return Promise.all([rientri.forEach(rientro => {
        return new Promise((resolve, reject) => {
            new Rientro(rientro)
            .then(r => r.create())
            .then(response => resolve(response))
            .catch(err => {console.log(err); return reject(err)})
        })
    })]).then(r => res.status(201).json({
        message: "rientri effettuati con successo"
    })).catch(err => {console.log(err); return res.status(500).json(err)})    
})


export default router