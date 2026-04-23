var LocalStrategy = require('passport-local').Strategy;
var bcrypt = require('bcrypt-nodejs');
const { AWS } = require('../config/config.js');
const client = require('./dynamo.js');
const stripe = require("./stripe.js");

var dd = client
var tableName = AWS.USERS_TABLE_NAME

module.exports = login = new LocalStrategy({
  // by default, local strategy uses username and password, we will override with email
  usernameField: 'email',
  passwordField: 'password',
  passReqToCallback: true // allows us to pass back the entire request to the callback
},
  function (req, email, password, done) { // callback with email and password from our form
    let params = {
      "TableName": tableName,
      "Key": {
        "userType": req.body.type,
        "email": email
      },
      "KeyConditionExpression": "email = :email AND userType = :userType",
      "ExpressionAttributeValues": {
        ":email": email,
        ":userType": req.body.type
      }
    }
    dd.query(params, async function (err, data) {
      if (err) return done({ error: err, message: "Qualcosa è andato storto, contattare l'amministrazione" }, false);
      if (data.Count == 0) return done({ error: "Credenziali errate", message: 'Le credenziali inserite non corrispondono a nessun account' }, false);
      if (!bcrypt.compareSync(password, data.Items[0].password)) return done({ error: "Password errata!", message: 'Oops! Password errata.' }, false);

      let user = data.Items[0]

      // 🔥 CHECK / FIX STRIPE CUSTOMER
      let stripeCustomerId = user.customerID;

      try {
        if (stripeCustomerId) {
          await stripe.customers.retrieve(stripeCustomerId);
        } else {
          stripeCustomerId = null;
        }
      } catch (e) {
        if (e.code === 'resource_missing') {
          stripeCustomerId = null;
        } else {
          console.error('Errore Stripe retrieve:', e);
        }
      }

      if (!stripeCustomerId) {
        try {
          const customer = await stripe.customers.create({
            email: user.email,
            metadata: {
              userId: user.id.toString(),
              userType: user.userType
            }
          });

          stripeCustomerId = customer.id;

          await client.update({
            TableName: tableName,
            Key: {
              userType: user.userType,
              email: user.email
            },
            UpdateExpression: 'SET customerID = :cid',
            ExpressionAttributeValues: {
              ':cid': stripeCustomerId
            }
          }).promise();
        } catch (e) {
          // ⚠️ NON blocchiamo il login
          console.error('Errore creazione Stripe customer:', e);
        }
      }

      return done(null, {
        type: data.Items[0].userType,
        id: data.Items[0].id,
        email: data.Items[0].email,
        nome: data.Items[0].nome,
        cognome: data.Items[0].cognome,
        dataNascita: data.Items[0].dataNascita || "",
        codFiscale: data.Items[0].codFiscale || "",
        context: data.Items[0].context,
        completed: data.Items[0].completed,
        verified: data.Items[0].verified,
        numTel: data.Items[0].numTel
      });
    });
  });
