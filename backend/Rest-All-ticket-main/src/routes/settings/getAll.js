import Setting from '../../models/settings.js';
import { Router } from 'express';

const router = new Router()

router.get('/', (req, res) => {
    new Setting({})
    .then(setting => setting.getAll())
    .then(result => res.status(200).json({
        setting: result
    }))
    .catch(err => res.status(500).json({
        err
    }))
})

export default router