import Products from "../../models/products.js";
import Router from 'express'

const router = new Router()

router.delete('/', (req, res) => {
    new Products({})
    .then(p => p.deleteAll())
    .then(result => res.status(200).json({ message: "Operazione avvenuta con successo!"}))
    .catch(err => res.status(500).json({err}))
})

export default router