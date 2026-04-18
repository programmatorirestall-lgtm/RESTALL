import Products from "../../models/products.js";
import Router from 'express'

const router = new Router()

router.get('/:codeArt', (req,res) => {
    new Products({
        codArticolo: req.params.codeArt
    })
    .then(prod => prod.getByCodArticolo())
    .then(data => res.status(200).json(data))
    .catch(err => res.status(500).json({err}))
})

export default router