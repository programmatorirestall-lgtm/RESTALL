import Router from 'express'
import Tecnico from '../../models/tecnico.js'

const router = new Router()

router.get('/:id_tecnico', (req, res) => {
    new Tecnico({
        id: req.params.id_tecnico
    })
    .then(tech => {
        tech.getById()
        .then(tecnico => {
            console.log(req.query)
            const dataInizio = req.query.dataInizio || undefined;
            const dataFine = req.query.dataFine || undefined;

            console.log(dataInizio, dataFine)
            tech.getAnalytics(dataInizio, dataFine)
            .then((analytics) => {
                tecnico.analytics = analytics
                return res.status(200).json(tecnico)
            })
            .catch(err => {
                return res.status(500).json({
                    err
                })
            })
        })
        .catch(err => {
            console.log(err)
            return res.status(500).json({
                err
            }) 
        })
    })
    .catch(err => {console.log(err); return res.status(500).json({
        err
    })})
})

export default router;