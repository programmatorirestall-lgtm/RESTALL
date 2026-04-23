import {upload} from '../../middlewares/multer.js';
import { s3_client } from '../../helpers/aws.js';
import { AWS } from '../../config/config.js';
import Router from 'express';
import Fogli from '../../models/fogli.js';

const router = new Router()

router.post('/', upload.any(), (req, res) => {
    if(!req.body.idTicket) res.status(500).json({ message: "Ticket id is required!" })
    let files = req.files
        return Promise.all(files.map((file) => {
            return new Promise((resolve, reject) => {
                let key = `${file.fieldname}-${file.originalname}`
                s3_client.upload(AWS.ATTACHMENTS_BUCKET, file, key)
                .then(result => {
                    new Fogli({
                        idTicket: req.body.idTicket,
                        location: result.location,
                        fileKey: result.key
                    })
                    .then(foglio => foglio.create())
                    .then(res => 
                        resolve({
                            file: {
                                originalname: file.originalname,
                                key: res.fileKey,
                                location: res.location
                            }
                        })
                    )
                    .catch(err => {console.log(err); return reject(err)})
                })
                .catch(err => {console.log(err); return reject(err)})
            })
        }))
        .then(uploadedFiles => {
            return res.status(201).json(uploadedFiles)
        })
        .catch(err => {console.log(err); return res.status(500).json(err)})
})

export default router;