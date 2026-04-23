import Preventivi from '../../models/preventivi.js';
import { Router } from 'express';

const router = new Router();

router.get('/', async (req, res) => {
    const offset = parseInt(req.query.offset) || 0;
    const limit = parseInt(req.query.limit) || 10;

    let pr;
    let preventivi; 
    try {
        if(req.user.type == 'user'){
            pr = await new Preventivi({
                idUtente: req.user.id || ''
            })
    
            preventivi = await pr.getByUserId()
        } else {
            pr = await new Preventivi({})
            preventivi = await pr.getAll(offset, limit)
        }

        return res.status(200).json({
            preventivi
        });

    } catch(err){
        return res.status(500).json({
            err
        })
    }
});

export default router;
