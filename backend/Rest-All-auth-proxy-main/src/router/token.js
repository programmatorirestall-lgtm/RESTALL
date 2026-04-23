const Router = require('express').Router;
const moment = require('moment/moment.js');
const { AWS } = require('../config/config.js');
const client = require('../helpers/dynamo.js');

const router = new Router();
const checkIfAuth = require('../middlewares/auth.js');
const FCMTokenTableName = AWS.FCM_TOKEN_TABLE_NAME
const dd = client
moment.locale('it')


router.post('/token', checkIfAuth, (req, res) => {
    if(!req.body.FCMToken) return res.status(500).json({ message: "Token required!"})

    dd.put({
        "TableName": FCMTokenTableName,
        "Item": {
            "token": req.body.FCMToken,
            "userId": req.user.id,
            "userType": req.user.userType,
            "creationDate": moment().format()
        }
    }, (err, data) => {
        console.log(err)
        if(err) return res.status(500).json({ message: "Errore nella fase di inserimento, contattare l'amministrazione"})
    })


    return res.status(200).json({ message: "Token inserito con successo" })
});

router.delete('/token', checkIfAuth, (req, res) => {
    if(!req.body.FCMToken) return res.status(500).json({ message: "Token required!"})

    dd.delete({
        "TableName": FCMTokenTableName,
        "Key": {
            "token": req.body.FCMToken
        }
    }, (err, data) => {
        console.log(err)
        if(err) return res.status(500).json({ message: "Errore durante l'operazione, contattare l'amministrazione" })
    })

    return res.status(202).json({ message: "Cancellazione avvenuta con successo!" })
})

module.exports = router