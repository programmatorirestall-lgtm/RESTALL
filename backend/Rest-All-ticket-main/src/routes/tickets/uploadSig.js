import {upload} from '../../middlewares/multer.js';
import { s3_client } from '../../helpers/aws.js';
import { AWS } from '../../config/config.js';
import Router from 'express';

const router = new Router()

router.post('/', upload.single('firma'), (req, res) => {
    
    let key = `${Date.now()}-${req.file.originalname}`

    s3_client.upload(AWS.SIGNATURE_BUCKET, req.file, key)
    .then(result => {
        return res.status(200).json({
            file: {
                originalname: req.file.originalname,
                key: result.key,
                location: result.location
            }
        })
    })
    .catch(err => {
        return res.status(500).json({
            error: {
                message: err
            }
        })
    })

    
})

export default router;