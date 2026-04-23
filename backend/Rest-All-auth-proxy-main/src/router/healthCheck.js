const Router = require('express').Router;
const router = new Router();
const INFO = require('../config/config.js').INFO

router.get('/', (req, res) =>{
    res.status(200).json({
        message: "Health check okay",
        version: INFO.APP_VERSION,
    })
})

module.exports = router;