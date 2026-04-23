var FacebookStrategy = require('passport-facebook').Strategy;
const {FACEBOOK, AWS} = require('../config/config.js');
const client = require('./dynamo.js');

var dd = client
var tableName = AWS.USERS_TABLE_NAME

module.exports = facebook = new FacebookStrategy({
    clientID: FACEBOOK.FACEBOOK_APP_ID,
    clientSecret: FACEBOOK.FACEBOOK_APP_SECRET,
    callbackURL: "http://localhost:5000/facebook/callback",
    profileFields: ['id', 'email', 'gender', 'link', 'locale', 'name', 'timezone', 'updated_time', 'verified'],
    passReqToCallback: true,
    state: true
},
function(req, accessToken, refreshToken, profile, done){
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
        console.log("user db", user.Count)
        if(err) return done(err, null)

        
        switch(user.Count){
            case 0:
                let params = {
                    "TableName": tableName,
                        "Item": {
                            "userType": {"S": userType},
                            "id": {"N": profile._json.id},
                            "email": {"S": profile._json.email},
                            "nome": {"S": profile._json.first_name},
                            "cognome": {"S": profile._json.last_name},
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