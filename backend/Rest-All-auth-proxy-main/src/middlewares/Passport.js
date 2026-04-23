'use strict';
const signupStrat = require('../helpers/signup.js');
const loginStrat = require('../helpers/login.js');
const googleStrat = require('../helpers/google.js');
const facebookStrat = require('../helpers/facebook.js');

const {AWS} = require('../config/config.js');
const client = require('../helpers/dynamo.js');

var dd = client
var tableName = AWS.USERS_TABLE_NAME

module.exports = function(passport) {
    // used to serialize the user for the session
  passport.serializeUser(function(user, done) {
    console.log("Serialize user:", user)
    done(null, {
      email: user.email,
      type: user.type
    });
  });

  // used to deserialize the user
  passport.deserializeUser(function(user, done) {
    dd.get({"TableName":tableName,"Key": {"userType": user.type,"email": user.email}}, function(err,data){
      if (err) return done(err, null);
      if(Object.keys(data).length == 0) return done(null, {})
      
        done(null,{
          "userType": data.Item.userType, 
          "id": data.Item.id, 
          "email": data.Item.email, 
          "completed": data.Item.completed, 
          "verified": data.Item.verified,
          "nome": data.Item.nome,
          "cognome": data.Item.cognome,
          "numTel": data.Item.numTel,
          "customerId": data.Item.customerId || null
        });
      })
  });
    passport.use('local-signup', signupStrat);
    passport.use('local-login', loginStrat);
    passport.use('google', googleStrat);
    passport.use('facebook', facebookStrat);
};