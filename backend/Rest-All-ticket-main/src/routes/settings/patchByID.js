import { settingsAutomation } from '../../config/constants.js';
import Setting from '../../models/settings.js';
import { Router } from 'express';

const router = new Router()

router.patch('/:id_setting', (req, res) => {
    new Setting({
        id: req.params.id_setting,
        value: req.body.value
    })
    .then(setting => setting.patchByID())
    .then(result => {
        settingsAutomation();
        return res.status(200).json({
            setting: result
        })
    })
    .catch(err => res.status(500).json({
        err
    }))
})

export default router