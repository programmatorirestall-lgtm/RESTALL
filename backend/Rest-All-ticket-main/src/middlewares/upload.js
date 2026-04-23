import S3 from 'aws-sdk/clients/s3.js';
import path from 'path';
import { AWS } from '../config/constants.js';
import multer from 'multer';
import multerS3 from 'multer-s3';

const s3 = new S3({
    signatureVersion: 'v4',
    region: AWS.BUCKET_REGION,
    accessKeyId: AWS.ACCESS_KEY_ID,
    secretAccessKey: AWS.ACCESS_SECRET_KEY
})

const fileFilter = (req, file, cb) => {
    if (file.mimetype === "image/jpeg" || file.mimetype === "image/png") {
      cb(null, true);
    } else {
      cb(new Error("Formato file invalido! Solo PNG e JPEG accettati!"), false);
    }
  };
  
  const uploadS3 = multer({
    fileFilter,
    storage: multerS3({
      acl: "public-read",
      s3,
      bucket: AWS.BUCKET_NAME,
      metadata: function (req, file, cb) {
        cb(null, { fieldName: file.fieldname });
      },
      key: function (req, file, cb) {
        cb(null, Date.now().toString() + '-' + file.originalname);
      },
    }),
  });

// const s3Upload = (file) => {
//     return new Promise((resolve, reject) => {    
//         const params = {
//             Bucket: AWS.BUCKET_NAME,
//             Body: file.buffer,
//             Key: Date.now() + path.extname(file.originalname)
//         }

//         s3.upload(params, (err, result) => {
//             if(err) reject(err)


//             var config = {Bucket: AWS.BUCKET_NAME, Key: result.Key, Expires: 60 * 60 * 24 * 2};
//             var promise = s3.getSignedUrlPromise('getObject', config);
//             promise.then(url => resolve(url))
//         })
//     })
// }

export default
    uploadS3