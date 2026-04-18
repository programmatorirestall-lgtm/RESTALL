import { Router } from "express";
import Scarico from "../../models/scarico.js";

const router = new Router()

router.post('/', (req, res) => {
    let scarichi = req.body.scarichi

    return Promise.all([scarichi.forEach(scarico => {
        return new Promise((resolve, reject) => {
            new Scarico(scarico)
            .then(s => s.create())
            .then(response => resolve(response))
            .catch(err => {console.log(err); return reject(err)})
        })
    })]).then(r => res.status(201).json({
        message: "Scarichi effettuati con successo"
    })).catch(err => {console.log(err); return res.status(500).json(err)})
})

export default router