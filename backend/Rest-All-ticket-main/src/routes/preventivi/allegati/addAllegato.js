import express from 'express';
import { upload } from '../../../middlewares/multer.js';
import { lambdaClient } from '../../../helpers/aws.js';
import Preventivi from '../../../models/preventivi.js';
import AllegatiPreventivo from '../../../models/allegatiPreventivo.js';

const router = express.Router();

router.post('/', upload.single('allegatoPreventivo'), async (req, res) => {
    try {
        if (!req.file || !req.body.idPreventivo) {
            return res.status(400).json({ message: 'File and ID are required' });
        }

        let preventivo = await new Preventivi({ id: req.body.idPreventivo }).then((p) => p.getById());
        
        if (preventivo.length == 0) {
            return res.status(404).json({ message: 'Preventivo non trovato' });
        }

        if(preventivo.stato == 'CONSEGNATO') {
            return res.status(400).json({ message: 'Non è possibile aggiungere allegati a preventivi consegnati' });
        }

        let aP = await new AllegatiPreventivo({ idPreventivo: req.body.idPreventivo })
        let allegati = await aP.getByIdPreventivo();
        
        if (allegati.length >= 5) {
            return res.status(400).json({ message: 'Non è possibile caricare più di 5 allegati per preventivo' });
        }

        const fileContent = req.file.buffer.toString('base64'); // Convertiamo il file in base64
        const fileName = req.file.originalname;
        const fileType = req.file.mimetype;
        const id = req.body.idPreventivo;

        let presignedUrl = await lambdaClient.invoke({
            FunctionName: 'upload-preventivi-attachment',
            Payload: JSON.stringify({
                fileContent,
                fileName,
                fileType,
                id
            })
        })

        const payloadString = new TextDecoder().decode(presignedUrl.Payload);
        const payloadJson = JSON.parse(payloadString);
        const response = JSON.parse(payloadJson.body);

        if(req.body.isFinal === 'true'){
            await new Preventivi({ 
                id
            }).then((p) => p.getById())
            .then((preventivo) => {
                
                preventivo[0].urlDoc = response.url;
                preventivo[0].fileKey = fileName
                return preventivo;
            }).then(async (finalPreventivo) => {
                let fp = await new Preventivi(finalPreventivo[0]);
                fp.update();
            }).catch(err => console.log(err));
        }
        else{
            new AllegatiPreventivo({
                idPreventivo: id,
                url: response.url,
                fileKey: fileName
            }).then((a) => a.create())
        }
        
        res.status(200).json({message: 'File caricato correttamente', url: response.url});
    } catch (error) {
        console.error('Error uploading file:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

export default router;
