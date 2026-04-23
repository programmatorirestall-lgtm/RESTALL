import { AWS } from '../config/config.js'
import {Lambda} from '@aws-sdk/client-lambda'
import { S3, GetObjectCommand } from '@aws-sdk/client-s3';
import {
    getSignedUrl,
    S3RequestPresigner,
  } from "@aws-sdk/s3-request-presigner";
import { DynamoDB, GetItemCommand, QueryCommand, ScanCommand, DeleteItemCommand } from "@aws-sdk/client-dynamodb";


const docClient = new DynamoDB({
    region: AWS.REGION
});

const dynamoTokenClient = {
    getItemById: (id_utente) => {
        return new Promise((resolve, reject) => {
            let command = new QueryCommand({
                TableName: AWS.FCM_TOKEN_DYNAMO_TABLE,
                IndexName: 'id-index',
                KeyConditionExpression: "userId = :key",
                ExpressionAttributeValues: {
                    ":key": {S: id_utente}
                }
            })
            docClient.send(command).then(result => {
                return resolve(result)
            })
            .catch(err => {
                reject(err)
            })
        })        
    },

    getItemsByType: (userType) => {
        return new Promise((resolve, reject) => {
            let command = new ScanCommand({
                TableName: AWS.FCM_TOKEN_DYNAMO_TABLE,
                FilterExpression: "userType = :type",
                ExpressionAttributeValues: {
                    ":type": {S: userType} 
                }
            })
            docClient.send(command).then(result => {
                return resolve(result)
            })
            .catch(err => {
                console.log(err)
                return reject(err)
            })
        })
    },

    deleteItemByToken: (token) => {
        return new Promise((resolve, reject) => {
            let command = new DeleteItemCommand({
                TableName: AWS.FCM_TOKEN_DYNAMO_TABLE,
                Key: {
                    "token": {S: token}
                }
            })

            docClient.send(command).then(result => {
                return resolve(result)
            })
            .catch(err => reject(err))
        })
    }
}

const dynamoClient = {
    getItemById: (id_utente) => {
        return new Promise((resolve, reject) => {
            let command = new QueryCommand({
                TableName: AWS.DYNAMO_TABLE,
                IndexName: 'id-index',
                KeyConditionExpression: "id = :key",
                ExpressionAttributeValues: {
                    ":key": {S: id_utente}
                }
            })
            docClient.send(command).then(result => {
                resolve({
                    nome: result.Items?.[0]?.nome?.S || "",
                    cognome: result.Items?.[0]?.cognome?.S || "",
                    email: result.Items?.[0]?.email?.S || "",
                    numTel: result.Items?.[0]?.numTel?.S || ""
                })
            })
            .catch(err => {
                reject(err)
            })
        })        
    },
    getAllAdmins: () => {
        return new Promise((resolve, reject) => {
            let command = new QueryCommand({
                TableName: AWS.DYNAMO_TABLE,
                KeyConditionExpression: "userType = :userType",
                ExpressionAttributeValues: {
                    ":userType": {S: 'admin'}
                }
            })
            docClient.send(command).then(result => {
                return Promise.all(result.Items.map((admin) => {
                    return new Promise((resolve) => {
                        resolve({
                            id: (admin.id.S == undefined) ? "" : admin.id.S,
                            email: (admin.email.S == undefined) ? "" : admin.email.S
                        })
                    })
                }))
                .then(result => resolve(result))
            })
            .catch(err => {
                reject(err)
            })
        })   
    }
}

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
    }
}



const lambdaClient = new Lambda({
    region: AWS.REGION
})

export {dynamoClient, dynamoTokenClient, lambdaClient, s3_client}
