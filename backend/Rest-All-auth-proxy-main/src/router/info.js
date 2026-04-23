const Router = require('express').Router;
const router = new Router();
const INFO = require('../config/config.js').INFO

router.get('/info', (req, res) =>{
    res.status(200).json({
        version: INFO.APP_VERSION,
    })
})

module.exports = router;