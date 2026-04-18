import Products from "../../models/products.js";
import Router from 'express'

const router = new Router()

router.get('/:codeArt', (req,res) => {
    new Products({
        codeAn: req.params.codeArt
    })
    .then(prod => prod.getByCodAn())
    .then(data => res.status(200).json(data))
    .catch(err => res.status(500).json({err}))
})

export default router