const Router = require('express').Router
const fs = require('fs')
const path = require('path')
const router = new Router()

router.get('/.well-known/apple-app-site-association', (req, res) => {
    fs.readFile(path.join(__dirname, '../../.well-known/apple-app-site-association'), 'utf-8', (err, data) => {
        if(err){console.log(err); return res.status(500).json(err)}

        return res.end(data);
    })
})

module.exports = router;