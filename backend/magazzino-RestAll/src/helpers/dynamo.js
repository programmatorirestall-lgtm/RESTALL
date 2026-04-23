import { DynamoDBClient, ScanCommand } from "@aws-sdk/client-dynamodb";
import { PutCommand, DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";
import { DYNAMO } from '../config/config.js'

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

export const dd = {
  warehouse: {
      put: (prodotto) => {
        return new Promise((resolve, reject) => {
            const command = new PutCommand({
                TableName: DYNAMO.WAREHOUSE_TABLE_NAME,
                Item: {
                  matricola: prodotto.matricola,
                  quantita: prodotto.quantita,
                  prezzo: prodotto.prezzo,
                  descrizione: prodotto.descrizione,
                  sconto1: prodotto.sconto1,
                  sconto2: prodotto.sconto2,
                  sconto3: prodotto.sconto3
                },
              });
            
              docClient.send(command).then(response => resolve(response))
              .catch(err => reject(err))
        })
    },
    get: (prodotto) => {
        return new Promise((resolve, reject) => {
            const command = new GetCommand({
                TableName: DYNAMO.WAREHOUSE_TABLE_NAME,
                Key: {
                  matricola: prodotto.matricola
                }
              });
            
              docClient.send(command).then(response => resolve(response))
              .catch(err => reject(err))
        })
    },
    getAll: () => {
        return new Promise((resolve, reject) => {
          const command = new ScanCommand({
            TableName: DYNAMO.WAREHOUSE_TABLE_NAME,
          });

          docClient.send(command).then(response => resolve(response.Items))
          .catch(err => reject(err))
        })
    }
  },
  rientri: {
    put: (rientro) => {
      return new Promise((resolve, reject) => {
          const command = new PutCommand({
              TableName: DYNAMO.RIENTRI_TABLE_NAME,
              Item: {
                matricola: rientro.matricola,
                descrizione: rientro.descrizione,
                quantita: rientro.quantita
              },
            });
          
            docClient.send(command).then(response => resolve(response))
            .catch(err => reject(err))
      })
  },
  get: (prodotto) => {
      return new Promise((resolve, reject) => {
          const command = new GetCommand({
              TableName: DYNAMO.RIENTRI_TABLE_NAME,
              Key: {
                matricola: prodotto.matricola
              }
            });
          
            docClient.send(command).then(response => resolve(response))
            .catch(err => reject(err))
      })
  },
    getAll: () => {
      return new Promise((resolve, reject) => {
        const command = new ScanCommand({
          TableName: DYNAMO.RIENTRI_TABLE_NAME,
        });

        docClient.send(command).then(response => resolve(response.Items))
        .catch(err => reject(err))
      })
    }
  },
  scarichi: {
    put: (scarico) => {
      return new Promise((resolve, reject) => {
          const command = new PutCommand({
              TableName: DYNAMO.SCARICHI_TABLE_NAME,
              Item: {
                matricola: scarico.matricola,
                descrizione: scarico.descrizione,
                quantita: scarico.quantita
              },
            });
          
            docClient.send(command).then(response => resolve(response))
            .catch(err => reject(err))
      })
  },
  get: (prodotto) => {
      return new Promise((resolve, reject) => {
          const command = new GetCommand({
              TableName: DYNAMO.SCARICHI_TABLE_NAME,
              Key: {
                matricola: prodotto.matricola
              }
            });
          
            docClient.send(command).then(response => resolve(response))
            .catch(err => reject(err))
      })
  },
    getAll: () => {
      return new Promise((resolve, reject) => {
        const command = new ScanCommand({
          TableName: DYNAMO.SCARICHI_TABLE_NAME,
        });

        docClient.send(command).then(response => resolve(response.Items))
        .catch(err => reject(err))
      })
    }
  }
}