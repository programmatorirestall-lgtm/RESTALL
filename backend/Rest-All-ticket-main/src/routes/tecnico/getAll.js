import Tecnico from '../../models/tecnico.js';
import { Router } from 'express';

const router = new Router()

router.get('/', (req, res) => {
    new Tecnico({})
    .then(tecnico => tecnico.getAll())
    .then(result => res.status(200).json({
        tecnico: result
    }))
    .catch(err => res.status(500).json({
        err
    }))
})

export default router