import { Router } from "express";
import Products from "../../models/products.js";

const router = new Router()

router.post('/', (req, res) => {
    let prodotto = {
        codArticolo: req.body.codArticolo,
        descrizione: req.body.descrizione,
        giacenza: req.body.giacenza,
        prezzoFornitore: req.body.prezzoFornitore,
        sconto1: req.body.sconto1,
        sconto2: req.body.sconto2,
        sconto3: req.body.sconto3,
        codeAn: req.body.codeAn
    }

    new Products(prodotto)
    .then(product => product.create())
    .then(response => res.status(201).json({
        message: "Prodotto creato con successo"
    }))
    .catch(err => {console.log(err); return res.status(500).json({err})})
})

export default router