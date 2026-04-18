import { Router } from "express";
import Scarico from "../../models/scarico.js";

const router = new Router()

router.get('/', (req, res) => {
    new Scarico({})
    .then(r => r.getAll())
    .then(response => res.status(201).json({
        response
    }))
    .catch(err => {console.log(err); return res.status(500).json({err})})
})

export default router