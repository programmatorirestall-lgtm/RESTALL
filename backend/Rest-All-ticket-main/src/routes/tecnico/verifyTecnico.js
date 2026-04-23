import Tecnico from '../../models/tecnico.js';
import { Router } from 'express';

const router = new Router()

router.patch("/:idTecnico", (req, res) => {
    let verified = req.body.verified.toUpperCase().toString()

    if(verified != 'TRUE' && verified != 'FALSE') return res.status(500).json({"message": "Impossibile completare la richiesta"})

    new Tecnico({
        id: req.params.idTecnico,
        verified
    })
    .then(t => t.updateVerify())
    .then(result => res.status(200).json({"message": "Tecnico aggiornato con successo"}))
    .catch(err => {console.log(err); return res.status(500).json({err})})
})

export default router;