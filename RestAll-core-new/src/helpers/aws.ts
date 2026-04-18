import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { QueryCommand, UpdateCommand } from "@aws-sdk/lib-dynamodb";
import { fromEnv } from "@aws-sdk/credential-providers";
import { User } from "../entities/entity.user";

const dynamo = new DynamoDBClient({ region: 'eu-central-1', credentials: fromEnv() })

const AWS = {
    DYNAMO: {
        getById: async (table: string, key: string) => {
            let command = new QueryCommand({
                TableName: table,
                IndexName: 'id-index',
                KeyConditionExpression: "id = :id",
                ExpressionAttributeValues: {
                ":id": key,
                }
            })
            
            let response = await dynamo.send(command)
            return response.Items && response.Items.length > 0 
                ? (response.Items[0] as unknown as User) 
                : {} as User;
        },
        
        updateCustomerID: async(table: string, customerID: string, key: Object) => {
            let command = new UpdateCommand({
                TableName: table,
                Key: key,
                UpdateExpression: "set customerID = :customerID",
                ExpressionAttributeValues: {
                ":customerID": customerID,
                },
            })

            let response = await dynamo.send(command)
            return response
        },

        updateProfitFromShop: async(table: string, profit: number, key: Object, userId: bigint) => {
            let getCommand = new QueryCommand({
                TableName: table,
                IndexName: 'id-index',
                KeyConditionExpression: "id = :id",
                ExpressionAttributeValues: {
                ":id": userId,
                }
            })

            let user = await dynamo.send(getCommand)
            let profitFromShop = user.Items && user.Items.length > 0 && user.Items[0].profitfromShop
                ? (user.Items[0].profitfromShop) + profit
                : profit
            
            let command = new UpdateCommand({
                TableName: table,
                Key: key,
                UpdateExpression: "set profitfromShop = :profitFromShop",
                ExpressionAttributeValues: {
                ":profitFromShop": profitFromShop,
                },
            })

            let response = await dynamo.send(command)
            return response
        },
        getByEmail: async (table: string, key: string) => {
            let command = new QueryCommand({
                TableName: table,
                IndexName: 'email-index',
                KeyConditionExpression: "email = :email",
                ExpressionAttributeValues: {
                ":email": key,
                }
            })
            
            let response = await dynamo.send(command)
            return response.Items && response.Items.length > 0 
                ? (response.Items[0] as unknown as User) 
                : {} as User;
        },
    }
}

export default AWS;