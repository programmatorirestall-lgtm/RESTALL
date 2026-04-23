import Router from 'express';
import Tecnico from '../../models/tecnico.js';

const router = new Router();

router.post("/", (req, res) => {
    console.log("create tecnico")
    new Tecnico(req.body)
    .then(tecnico => tecnico.create())
    .then(result => {return res.status(201).json({
        tecnico: result
    })})
    .catch(err => {console.log(err); return res.status(500).json(err)})
})

export default router;