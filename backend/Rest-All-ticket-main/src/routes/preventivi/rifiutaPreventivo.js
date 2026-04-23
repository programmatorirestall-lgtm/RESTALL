import Preventivi from '../../models/preventivi.js';
import Router from 'express';

const router = new Router();

router.delete('/:id', async (req, res) => {
    try {
        const { id } = req.params;

        let preventivo = await new Preventivi({ id });
        let result = await preventivo.getById();

        console.log(preventivo)

        if (result.length === 0) {
            return res.status(404).json({ error: 'Preventivo non trovato' });
        }


        if(result[0].stato === 'CONSEGNATO') {
            return res.status(400).json({ error: 'Preventivo già consegnato' });
        }
        
        result[0].stato = 'RIFIUTATO';
        result[0].descrizione = req.body.descrizione;
        let newPreventivo = await new Preventivi(result[0]);
        await newPreventivo.update();

        res.status(200).json({ message: 'Preventivo rifiutato con successo' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;