const { AWS } = require('../config/config.js');
const {Lambda} = require('@aws-sdk/client-lambda');

const lambdaClient = new Lambda({
    region: AWS.REGION
})

module.exports = {lambdaClient}