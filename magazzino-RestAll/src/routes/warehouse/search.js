import Products from "../../models/products.js";
import { Router } from "express";

const router = new Router()

router.get("/search", (req, res) => {
    console.log(req.query)
    if (Object.keys(req.query).length === 0) {
        return res.status(400).json({ err: "Formato non valido" });
    }

    new Products({})
        .then(prod => prod.search(req.query))
        .then(data => res.status(200).json(data))
        .catch(() =>
            res.status(500).json("Errore nella ricerca")
        );
});

export default router