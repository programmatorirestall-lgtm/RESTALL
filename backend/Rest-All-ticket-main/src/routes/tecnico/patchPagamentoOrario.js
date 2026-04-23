import Tecnico from '../../models/tecnico.js';
import { Router } from 'express';

const router = new Router()

router.patch("/pagamento/:idTecnico", (req, res) => {
    let pagamento_orario = req.body.pagamento_orario

    if(pagamento_orario == 0){return res.status(500).json({"error":"Valore non valido"})}

    new Tecnico({
        id: req.params.idTecnico,
        pagamento_orario
    })
    .then(t => t.patchPagamentoOrario())
    .then(result => res.status(200).json({"message": "Tecnico aggiornato con successo"}))
    .catch(err => {console.log(err); return res.status(500).json({err})})
})

export default router;