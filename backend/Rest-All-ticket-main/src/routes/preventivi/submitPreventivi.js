import Preventivi from '../../models/preventivi.js';
import Router from 'express';

const router = new Router();

router.patch('/:id', async (req, res) => {
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

        const statoAttuale = result[0].stato;
        const transizioniValide = {
            'APERTO': ['IN LAVORAZIONE'],
            'IN LAVORAZIONE': ['CONSEGNATO'],
            'CONSEGNATO': []
        };

        if(!transizioniValide[statoAttuale]) {
            return res.status(400).json({ error: 'Transizione di stato non valida' });
        }

        if (transizioniValide[statoAttuale].length === 0) {
            return res.status(400).json({ error: 'Transizione di stato non valida' });
        }
        
        result[0].stato = transizioniValide[statoAttuale][0];
        let newPreventivo = await new Preventivi(result[0]);
        await newPreventivo.update();

        res.status(200).json({ message: 'Stato aggiornato con successo', result: newPreventivo });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;