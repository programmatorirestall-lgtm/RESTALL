const { AWS } = require('../config/config.js');
const { S3, GetObjectCommand } = require('@aws-sdk/client-s3');
const {
    getSignedUrl,
  } = require("@aws-sdk/s3-request-presigner");

const s3 = new S3({
    region: AWS.REGION,
    credentials: {
        accessKeyId: AWS.S3.ACCESS_KEY_ID,
        secretAccessKey: AWS.S3.SECRET_ACCESS_KEY
    }
})

const createPresignedUrl = async ({ bucket, key }) => {
    const command = new GetObjectCommand({ Bucket: bucket, Key: key });
    return getSignedUrl(s3, command, { expiresIn: 86400 });
  };

const s3_client = {
    upload: (bucket, file, key, metadata) => {
        return new Promise((resolve, reject) => {
            s3.putObject({
                Bucket: bucket,
                Body: file.buffer,
                Key: key,
                Metadata: metadata || ""
            })
            .then(res => {
                createPresignedUrl({bucket, key})
                .then(location => {
                    return resolve({
                        location,
                        key 
                    })
                })
                .catch(err => {
                    console.log(err);
                    return reject(err)
                })
            })
            .catch(err => {console.log(err); return reject(err)})
        })
    },

    uploadWithBuffer: (bucket, fileBuffer, key, metadata) => {
        return new Promise((resolve, reject) => {
            s3.putObject({
                Bucket: bucket,
                Body: fileBuffer,
                Key: key,
                Metadata: metadata || ""
            })
            .then(res => {
                createPresignedUrl({ bucket, key})
                .then(location => {
                    return resolve({
                        location,
                        key 
                    })
                })
                .catch(err => {
                    console.log(err);
                    return reject(err)
                })
            })
            .catch(err => {console.log(err); return reject(err)})
        })
    },

    delete: (bucket, key) => {
        return new Promise((resolve, reject) => {
            s3.deleteObject({
                Bucket: bucket,
                Key: key
            })
            .then(res => {
                return resolve(res)
            })
            .catch(err => reject(err))
        })
    }
}

module.exports = {s3_client}
