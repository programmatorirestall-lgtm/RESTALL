const passport = require('passport');
const Router = require('express').Router;
const jwtHelper = require('../helpers/jwt.js');
const Axios = require('axios');
const { TARGET_SERVER } = require('../config/config.js');
const { AWS } = require('../config/config.js');
const client = require('../helpers/dynamo.js');
const https = require('https')

var dd = client
var tableName = AWS.USERS_TABLE_NAME
const checkIfAuth = require('../middlewares/auth.js');

const router = new Router();

const ticket_target = `${TARGET_SERVER.TICKET.PROTOCOL}://${TARGET_SERVER.TICKET.HOST}:${TARGET_SERVER.TICKET.PORT}`;

router.post('/login', function(req, res, next){
    passport.authenticate('local-login', (err, user, info) => {
        if(err) return res.status(500).json({
            error: err.error,
            message: err.message
        })
        if(!user) return res.status(500).json({
            error: err.error,
            message: err.message
        })
        
        if(!user.completed) return res.status(500).json({
            error: {
                message: "Completa prima il profilo per poter continuare!"
            }
        })

        req.logIn(user, (err) =>{
            if(err) return res.status(500).json({
                message: err.message,
                error: err.error
            })
            const jwtToken = jwtHelper.signAccessToken(user)
            const refreshToken = jwtHelper.signRefreshToken(user)
            res.cookie('jwt', jwtToken, {
                httpOnly: false, 
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 60000*30,
            })
            
            res.cookie('refreshToken', refreshToken, {
                httpOnly: false, 
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 86400000*7,
            })
            
            return res.status(200).json({
                user
            }).send()
        })
    })(req, res, next)
})

router.post('/signup', function(req, res, next){

    req.body.email = req.body.email.toLowerCase()

    passport.authenticate('local-signup', (err, user, info) => {
        if(err) {            
            return res.status(500).json({
            message: err.message,
            error: err
        })}
        
        if(!user) {
            return res.status(500).json({
                message: "Problemi riscontrati nel creare l'utente, contattare un amministratore!"
            })
        }

        if(!user.completed) {

            res.cookie('jwt', jwtHelper.signAccessToken(user), {
                httpOnly: false, 
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 1800000,
            })
            
            return res.status(201).json({
                user
            })
        }
        
        req.logIn(user, (err) =>{
            console.log(err)
            if(err) return res.status(500).json({
                message: err.message,
                error: err.error
            })

            const refreshToken = jwtHelper.signRefreshToken(user)
            const jwtToken = jwtHelper.signAccessToken(user)
            if(user.type == 'tech'){
                Axios({
                    method: 'POST',
                    url: ticket_target + '/api/v1/tecnico',
                    httpsAgent: new https.Agent({ rejectUnauthorized: false}),
                    data: {
                        id: user.id,
                        nome: req.body.nome,
                        cognome: req.body.cognome
                    },
                    headers: { Authorization: `Bearer ${jwtToken}` },
                    withCredentials: true,
                }).catch(err => console.log(err))
            }

            res.cookie('jwt', jwtToken, {
                httpOnly: false, 
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 1800000,
            })
            
            res.cookie('refreshToken', refreshToken, {
                httpOnly: false, 
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 604800000,
            })

            return res.status(201).json({
                user
            })
        })
    })(req, res, next)
})

router.get( '/google/callback',
    passport.authenticate( 'google', {
        successRedirect: '/google/callback/success',
        failureRedirect: '/google/callback/failure'
}));
  
// Success 
router.get('/google/callback/success' , (req , res) => {
    console.log(req.user)
    if(!req.user) { return res.redirect('/google/callback/failure'); }

    const jwtToken = jwtHelper.signAccessToken(user)
    res.status(200).json({
        user: req.user,
        jwt: jwtToken
    })
});
  
// failure
router.get('/google/callback/failure' , (req , res) => {
    res.send("Error");
})

router.get('/google', (req, res) => {
    req.session.userType = req.query.type;

    passport.authenticate('google', (err, user) => {
        if(!err){
            req.logIn(user, (err) => {
                if(err) res.status(500).json({
                    message: err
                })
            })
        }
    })(req, res)
})

router.get( '/facebook/callback',
    passport.authenticate( 'facebook', {
        successRedirect: '/facebook/callback/success',
        failureRedirect: '/facebook/callback/failure'
}));

// Success 
router.get('/facebook/callback/success' , (req , res) => {
    if(!req.user) {return res.redirect('/facebook/callback/failure');}

    const jwtToken = jwtHelper.signAccessToken(user)
    res.status(200).json({
        user: req.user,
        jwt: jwtToken
    })
});
  
// failure
router.get('/facebook/callback/failure' , (req , res) => {
    res.send("Error");
})

router.get('/facebook', (req, res) => {
    req.session.userType = req.query.type;

    passport.authenticate('facebook', {
        scope: ['email']
    }, (err, user) => {
        if(!err){
            req.logIn(user, (err) => {
                if(err) res.status(500).json({
                    message: err
                })
            })
        }
    })(req, res)
})

router.post('/logout', checkIfAuth, (req, res, next) => {
    req.logout((err) => {
        console.log(err);
        if(err) return res.status(500).json({
            err
        })
        return res.status(200).json({
            message: "logout avvenuto con successo"
        })
    })
})

module.exports = router;
