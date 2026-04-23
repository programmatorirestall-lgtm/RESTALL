import { Router } from "express";
import Products from "../../models/products.js";

const router = new Router()

router.get('/', (req, res) => {
    new Products({})
    .then(product => product.getAll(req.query.limit, req.query.offset))
    .then(data => res.status(200).json({
        prodotto: data
    }))
    .catch(err => res.status(500).json({err}))
})

export default router