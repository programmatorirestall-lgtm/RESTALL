var LocalStrategy = require('passport-local').Strategy;
var bcrypt = require('bcrypt-nodejs');
const { AWS } = require('../config/config.js');
const client = require('./dynamo.js');
const rnd = require('../helpers/random.js');
const stripe = require('../helpers/stripe.js');

var dd = client
var userTableName = AWS.USERS_TABLE_NAME
var tokenTableName = AWS.TOKEN_TABLE_NAME

module.exports = signup = new LocalStrategy(
  {
    usernameField: 'email',
    passwordField: 'password',
    passReqToCallback: true,
  },
  async function (req, email, password, done) {
    try {
      const allowedTypes = ['user', 'tech', 'admin'];
      const userType = req.body.type;

      // Validazione tipo utente
      if (!allowedTypes.includes(userType)) {
        return done({
          error: new Error('Tipo utente non valido'),
          message: 'Il tipo utente deve essere uno tra: user, tech, admin.',
        }, false);
      }

      const params = {
        TableName: userTableName,
        Key: {
          userType,
          email,
        },
      };

      const userData = await dd.get(params).promise();
      if (userData.Item?.completed) {
        return done({ error: new Error('Utente già esistente!'), message: 'Email già utilizzata.' }, false);
      }

      const id = Math.floor(Math.random() * 4294967296).toString();

      const nome = formatName(req.body.nome);
      const cognome = formatName(req.body.cognome);
      const completed = !!(nome && cognome);
      const referralCode = completed ? rnd.string(7) : 'not-set';

      const customer = await stripe.customers.create({ email });

      let pId = 'empty';
      if (req.body.parentReferral) {
        try {
          pId = await handleReferral(req.body.parentReferral);

          // Controllo profondità
          const depth = await getReferralDepth(pId);
          if (depth >= 5) {
            console.warn(`Referral ignorato: profondità massima raggiunta (${depth})`);
            pId = 'empty'; // non blocca registrazione, solo il referral
          }

        } catch (err) {
          console.warn('Referral non valido:', err.message);
        }
      }

      const userParams = {
        TableName: userTableName,
        Key: { userType, email },
        UpdateExpression: `
          SET id = :id, password = :password, nome = :nome, cognome = :cognome,
              codFiscale = :codFiscale, dataNascita = :dataNascita, completed = :completed,
              context = :context, verified = :verified, referralCode = :referralCode,
              customerID = :customerID, numTel = :numTel, parentId = :pId
        `,
        ExpressionAttributeValues: {
          ':id': id,
          ':password': bcrypt.hashSync(password),
          ':nome': nome,
          ':cognome': cognome,
          ':codFiscale': req.body.codFiscale || '',
          ':dataNascita': req.body.dataNascita || '',
          ':completed': completed,
          ':referralCode': referralCode,
          ':verified': false,
          ':context': 'local',
          ':numTel': req.body.numTel || '',
          ':customerID': customer.id,
          ':pId': pId,
        },
      };

      if (completed) {
        const randomToken = bcrypt.genSaltSync(10);
        const transactionParams = {
          TransactItems: [
            {
              Put: {
                TableName: tokenTableName,
                Item: { userId: id, token: randomToken },
              },
            },
            { Update: userParams },
          ],
        };
        await dd.transactWrite(transactionParams).promise();
      } else {
        await dd.update(userParams).promise();
      }

      return done(null, {
        type: userType,
        id,
        email,
        nome,
        cognome,
        dataNascita: req.body.dataNascita || '',
        codFiscale: req.body.codFiscale || '',
        context: 'local',
        completed,
        numTel: req.body.numTel || '',
        verified: false,
      });
    } catch (err) {
      console.error('Errore nella registrazione:', err);
      return done({
        error: err,
        message: 'Ci scusiamo per il disagio, si prega di riprovare più tardi.',
      }, false);
    }
  }
);

const getReferralDepth = async (userId, depth = 0) => {
  console.log(`Checking referral depth for userId: ${userId}, current depth: ${depth}`);
  if (depth >= 5) return depth;

  const data = await dd.query({
    TableName: userTableName,
    IndexName: "id-index",
    KeyConditionExpression: "id = :id",
    ExpressionAttributeValues: {
      ":id": userId
    }
  }).promise();

  console.log(`Query result for userId ${userId}:`, data);

  if (data.Count === 0) {
    return depth;
  }

  const user = data.Items[0];
  if (!user.parentId || user.parentId === 'empty') {
    return depth;
  }

  return getReferralDepth(user.parentId, depth + 1);
};

// Helper per gestire la formattazione del nome
function formatName(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1).toLowerCase() : '';
}

// Funzione per gestire il referral
async function handleReferral(parentReferral) {
  const getParentParams = {
    TableName: userTableName,
    IndexName: 'referral-index',
    KeyConditionExpression: 'referralCode = :referral',
    ExpressionAttributeValues: { ':referral': parentReferral },
  };

  const data = await dd.query(getParentParams).promise();
  if (data.Count === 0) {
    throw new Error('Codice Referral non valido!');
  }

  return data.Items[0].id;
}
