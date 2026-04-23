const aws = require('aws-sdk');
const {AWS} = require('../config/config.js')

aws.config.update(AWS.CONFIG);
const docClient = new aws.DynamoDB.DocumentClient();

//export default docClient;
module.exports = docClient;