var GoogleStrategy = require('passport-google-oauth20').Strategy;
const {GOOGLE, AWS} = require('../config/config.js');
const client = require('./dynamo.js');
const base64url = require('base64url');

var dd = client
var tableName = AWS.USERS_TABLE_NAME

module.exports = google = new GoogleStrategy({
    clientID: GOOGLE.ACCESS_KEY_ID,
    clientSecret: GOOGLE.SECRET,
    callbackURL: GOOGLE.CALLBACK,
    passReqToCallback: true,
    scope: ['profile', 'email', 'https://www.googleapis.com/auth/user.birthday.read'],
    state: true
    },
    function(req, accessToken, refreshToken, profile, done) {
        let { userType } = req.session
        var params = {
            "TableName": tableName,
            "IndexName":"email-index",
            "KeyConditions":{
            "email":{
                "ComparisonOperator":"EQ",
                "AttributeValueList":[{"S": profile._json.email}]
            }
            }
        }
        dd.query(params, (err, user) => {
            console.log(err)
            if(err) return done(err, null)
            
            switch(user.Count){
                case 0:
                    let params = {
                        "TableName": tableName,
                            "Item": {
                                "userType": {"S": userType},
                                "id": {"N": profile._json.sub},
                                "email": {"S": profile._json.email},
                                "nome": {"S": profile._json.given_name},
                                "cognome": {"S": profile._json.family_name},
                                "dataNascita": {"S": (profile._json.birthday) ? profile._json.birthday : ""},
                                "codFiscale": {"S": ""},
                                "context": {"S": profile.provider}
                            }
                    }

                    dd.putItem(params, (err, user) => {
                        console.log(err)
                        console.log(user)
                        if(err) return done(err, null)
                        return done(null, {
                            type: params.Item.userType.S,
                            id: params.Item.id.N,
                            email: params.Item.email.S,
                            ragioneSociale: params.Item.nome.S + " " + params.Item.cognome.S,
                            context: params.Item.context.S
                          })
                    })
                    break
                default: 
                    return done(null, {
                        type: user.Items[0]['userType'].S,
                        id: user.Items[0]['id'].N,
                        email: user.Items[0]['email'].S,
                        ragioneSociale: user.Items[0]['nome'].S + " " + user.Items[0]['cognome'].S,
                        dataNascita: user.Items[0]['dataNascita'].S,
                        codFiscale: user.Items[0]['codFiscale'].S,
                        context: user.Items[0]['context'].S
                    })
            }
        })
})