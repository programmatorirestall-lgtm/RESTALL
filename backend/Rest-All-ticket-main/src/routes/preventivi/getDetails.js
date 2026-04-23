import AllegatiPreventivo from '../../models/allegatiPreventivo.js';
import Preventivi from '../../models/preventivi.js';
import { Router } from 'express';
import { AWS } from '../../config/config.js';
import { parseISO, addSeconds } from 'date-fns';
import { lambdaClient } from '../../helpers/aws.js';

const router = new Router();

router.get('/:id', async (req, res) => {
    try {
        const id = req.params.id;
        
        const preventivo = await new Preventivi({ id });
        const result = await preventivo.getById();
        
        if (result.length === 0) {
            return res.status(404).json({ error: 'Preventivo non trovato' });
        }
        
        const allegato = await new AllegatiPreventivo({ idPreventivo: id });
        let allegati = await allegato.getByIdPreventivo();

        // Aggiornamento URL scaduti per gli allegati
        await Promise.all(allegati.map(async (allegatoItem) => {
            const params = new Proxy(new URLSearchParams(allegatoItem.url), {
                get: (searchParams, prop) => searchParams.get(prop),
            });

            let creationDate = parseISO(params['X-Amz-Date']);
            let expiresInSecs = Number(params['X-Amz-Expires']);
            let expiryDate = addSeconds(creationDate, expiresInSecs);

            if (expiryDate < new Date() || isNaN(expiryDate)) {
                try {
                    console.log("URL allegato scaduto, aggiornamento in corso...");
                    const payload = JSON.stringify({
                        fileKey: `${allegatoItem.fileKey}`,
                        bucket: 'bucket-attachments'
                    });
                    
                    console.log("Payload Lambda:", payload);
                    const lambdaResponse = await lambdaClient.invoke({
                        FunctionName: AWS.LAMBDA_FUNCTION_NAME,
                        Payload: payload
                    });

                    const data = JSON.parse(Buffer.from(lambdaResponse.Payload));
                    allegatoItem.url = data.body.location;
                    let newAllegato = await new AllegatiPreventivo(allegatoItem)
                    await newAllegato.update();
                } catch (error) {
                    console.log("Errore aggiornamento allegato:", error);
                }
            }
        }));

        // Aggiornamento URL scaduti per il preventivo
        if (result[0].urlDoc) {
            const params = new Proxy(new URLSearchParams(result[0].urlDoc), {
                get: (searchParams, prop) => searchParams.get(prop),
            });

            let creationDate = parseISO(params['X-Amz-Date']);
            let expiresInSecs = Number(params['X-Amz-Expires']);
            let expiryDate = addSeconds(creationDate, expiresInSecs);

            if (expiryDate < new Date() || isNaN(expiryDate)) {
                try {
                    console.log("URL preventivo scaduto, aggiornamento in corso...");
                    const payload = JSON.stringify({
                        fileKey: `${result[0].fileKey}`,
                        bucket: 'bucket-attachments'
                    });

                    console.log("Payload Lambda:", payload);
                    const lambdaResponse = await lambdaClient.invoke({
                        FunctionName: AWS.LAMBDA_FUNCTION_NAME,
                        Payload: payload
                    });

                    const data = JSON.parse(Buffer.from(lambdaResponse.Payload));
                    result[0].urlDoc = data.body.location;
                    const finalP = await new Preventivi(result[0]);
                    await finalP.update();
                } catch (error) {
                    console.log("Errore aggiornamento doc preventivo: ", error)
                    return res.status(500).json({ error });
                }
            }
        }  
        
        return res.status(200).json({
            ...result[0],
            allegati
        });
    } catch (error) {
        console.log(error);
        return res.status(500).json({ error });
    }
});

export default router;
