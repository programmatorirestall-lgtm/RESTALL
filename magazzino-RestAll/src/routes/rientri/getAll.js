import { Router } from "express";
import Rientro from "../../models/rientro.js";

const router = new Router()

router.get('/', (req, res) => {
    new Rientro({})
    .then(r => r.getAll())
    .then(response => res.status(201).json({
        response
    }))
    .catch(err => {console.log(err); return res.status(500).json({err})})
})

export default router