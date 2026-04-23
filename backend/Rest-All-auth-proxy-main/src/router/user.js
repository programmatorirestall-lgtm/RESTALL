const Router = require('express').Router;
const client = require('../helpers/dynamo.js');
const { AWS, MISCELLANEOUS } = require('../config/config.js');
const bcrypt = require('bcryptjs')
const CryptoJS = require('crypto-js');
const jwtHelper = require('../helpers/jwt.js');
const checkIfAuth = require('../middlewares/auth.js')
const { upload } = require('../middlewares/multer.js');
const { s3_client } = require('../helpers/s3.js');
const { lambdaClient } = require('../helpers/lambda.js');
const { parseISO, addSeconds } = require('date-fns');
const stripe = require('../helpers/stripe.js');

const dd = client
const tableName = AWS.USERS_TABLE_NAME
const tokenTableName = AWS.TOKEN_TABLE_NAME
const pwdTokenTableName = AWS.PASSWORD_RESET_TOKEN_TABLE_NAME
const router = new Router();

router.get('/user', (req, res) => {
    if (!req.isAuthenticated()) {
        res.render('login.ejs');
        return
    } else {
        dd.get({
            "TableName": tableName,
            "Key": {
                "userType": req.user.userType,
                "email": req.user.email
            }
        }, (err, data) => {
            if (err) return res.status(500).json({
                message: err
            })
            res.render('profile.ejs', data.Item);
            return
        })

    }
})

router.get('/user/me', checkIfAuth, (req, res) => {

    dd.get({
        "TableName": tableName,
        "Key": {
            "userType": req.user.userType,
            "email": req.user.email
        }
    }, (err, data) => {
        if (err) return res.status(500).json({
            message: err
        })

        return res.status(200).json({
            user: {
                email: data.Item.email,
                nome: data.Item.nome,
                cognome: data.Item.cognome,
                dataNascita: data.Item.dataNascita,
                codFiscale: data.Item.codFiscale,
                numTel: data.Item.numTel,
                verified: data.Item.verified,
                completed: data.Item.completed,
                parentId: data.Item.parentId || null,
                referral: data.Item.referralCode,
                profitFromTicket: data.Item.profitFromTicket || 0,
                profitFromShop: data.Item.profitFromShop || 0,
                totalProfit: (data.Item.profitFromTicket || 0) + (data.Item.profitFromShop || 0),
            }
        })
    })
})

router.post('/user/delete', checkIfAuth, (req, res) => {
    lambdaClient.invoke({
        FunctionName: AWS.LAMBDA.ACCOUNT_DELETION_FUNC,
        Payload: JSON.stringify({
            userEmail: req.user.email
        })
    }).then(result => {
        return res.status(200).json({ 'message': 'Richiesta avvenuta con successo!' });
    })
        .catch(err => {
            return res.status(500).json({ 'message': "Errore nella richiesta, contattare l'amministratore!" })
        })
})

router.delete('/user/:id', checkIfAuth, async (req, res) => {
    if (req.params.id != req.user.id) {
        return res.status(500).json({ message: "Impossibile effettuare l'azione" });
    }

    try {
        // Recupera l'utente corrente
        const userData = await dd.get({
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email
            }
        }).promise();

        if (!userData.Item) {
            return res.status(404).json({ message: "Utente non trovato, contattare un amministratore!" });
        }

        // Ottieni il parentId dell'utente da eliminare
        const { parentId } = userData.Item;

        // Recupera tutti gli utenti nel network
        const userNetwork = await getUserNetwork(req.user.id);
        let adiacentUser = userNetwork.filter(user => user.level === 1);

        // Aggiorna il parentId per ogni utente nel network
        for (const user of adiacentUser) {
            await dd.update({
                TableName: tableName,
                Key: {
                    id: user.id
                },
                UpdateExpression: "SET parentId = :newParentId",
                ExpressionAttributeValues: {
                    ":newParentId": parentId || null // Se l'utente eliminato non ha un parentId, imposta null
                }
            }).promise();
        }

        // Elimina l'utente
        await dd.delete({
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email
            }
        }).promise();

        return res.status(200).json({ message: "Operazione completata con successo!" });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: "Errore nel completare l'operazione, contattare l'amministratore!" });
    }
});

router.get('/user/:id/verify', (req, res) => {
    let decryptedToken = CryptoJS.AES.decrypt(req.query.token, MISCELLANEOUS.PWD_SECRET_KEY).toString(CryptoJS.enc.Utf8)

    dd.get({
        "TableName": tokenTableName,
        "Key": {
            "userId": req.params.id
        }
    }, (err, data) => {
        if (err) { return res.status(500).json({ err }) }
        if (data.Item.token != decryptedToken.substring(1, decryptedToken.length - 1)) return res.status(500).json({ message: "Impossibile verificare l'utente, contattare un amministratore" })

        let params = {
            ExpressionAttributeValues: {
                ':userId': req.params.id
            },
            FilterExpression: 'id = :userId',
            TableName: tableName
        };
        dd.scan(params, (err, data) => {
            if (err) { return res.status(500).json({ err }) }
            if (data.Count == 0) return res.status(404).json({ message: "Utente non trovato, contattare un amministratore!" })
            if (data.Items[0].verified) return res.status(410).json({ message: "Utente già verificato, puoi utilizzare i nostri servizi!" })

            let updateParams = {
                "TableName": tableName,
                "Key": {
                    "userType": data.Items[0].userType,
                    "email": data.Items[0].email
                },
                "UpdateExpression": "set verified = :v",
                "ExpressionAttributeValues": {
                    ":v": true
                }
            }

            dd.update(updateParams, (err, data) => {
                if (err) { return res.status(500).json({ err }) }
                return res.status(200).json({ message: "Utente verificato con successo! " })
            })
        })
    })
})

router.patch('/user/password', (req, res) => {
    if (!req.body.email || req.body.email == "") return res.status(500).json({ "message": "email required" })
    if (!req.body.type || req.body.type == "") return res.status(500).json({ "message": "type required" })

    dd.get({
        TableName: tableName,
        Key: {
            "userType": req.body.type,
            "email": req.body.email
        }
    }, (err, data) => {
        console.log(err)
        if (err) return res.status(500).json({ err })
        if (!data.Item) return res.status(500).json({ message: "Email non valida" })

        let token = bcrypt.genSaltSync(10)

        dd.put({
            TableName: pwdTokenTableName,
            Item: {
                "userId": data.Item.id,
                "token": token,
                "createdAt": Date.now().toString(),
                "expires": MISCELLANEOUS.RESET_PWD_TOKEN_EXPIRES
            }
        }, (err, data) => {
            if (err) return res.status(500).json({ message: "Impossibile completare la richiesta, contattare un amministratore" })

            return res.status(200).json({
                message: "Richiesta completata con successo!"
            })
        })
    })
})

router.post('/user/password', async (req, res) => {
    const { token, password, id } = req.body;

    try {
        const decodedToken = decodeURIComponent(token);
        console.log("Decoded token:", decodedToken);

        // Retrieve token data
        const tokenData = await dd.get({
            TableName: pwdTokenTableName,
            Key: { token: decodedToken }
        }).promise();

        if (!tokenData.Item) {
            return res.status(404).json({ message: "Token not found" });
        }

        const { createdAt, expires, userId } = tokenData.Item;

        if ((createdAt + expires) <= Date.now()) {
            return res.status(400).json({ message: "Richiesta scaduta!" });
        }

        if (userId !== id) {
            return res.status(400).json({ message: "Richiesta non valida!" });
        }

        // Fetch user data
        const userData = await dd.scan({
            TableName: tableName,
            ExpressionAttributeValues: { ':userId': userId },
            FilterExpression: 'id = :userId'
        }).promise();

        if (!userData.Items || userData.Items.length === 0) {
            return res.status(404).json({ message: "User not found" });
        }

        const user = userData.Items[0];

        // Update password
        await dd.update({
            TableName: tableName,
            Key: {
                userType: user.userType,
                email: user.email
            },
            UpdateExpression: "SET password = :pwd",
            ExpressionAttributeValues: {
                ':pwd': bcrypt.hashSync(password, 10)
            }
        }).promise();

        return res.status(200).json({
            message: "Password modificata con successo!"
        });

    } catch (error) {
        console.error("Error in /user/password endpoint:", error);
        return res.status(500).json({ message: "Internal server error", error: error.message });
    }
});

router.get('/user/renew', checkIfAuth, (req, res) => {
    if (!req.headers.authorization || req.headers.authorization.split(' ')[0] !== 'Bearer')
        return res.status(403).send({ error: 'Forbidden' });

    const refreshToken = req.headers.authorization.split(' ')[1];

    jwtHelper.verifyRefreshToken(refreshToken)
        .then(verified => {
            const jwt = jwtHelper.signAccessToken(req.user)
            const refreshToken = jwtHelper.signRefreshToken(req.user)

            res.cookie('jwt', jwt, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 60000 * 30,
            })

            res.cookie('refreshToken', refreshToken, {
                httpOnly: true,
                secure: true,
                sameSite: 'Strict',  // o 'Lax', dipende
                maxAge: 86400000 * 7,
            })
            res.send()
            res.end()
        })
        .catch(err => { console.log(err); return res.status(500).json({ err }) })
})

router.put('/user/:id', checkIfAuth, async (req, res) => {
    try {
        if (req.params.id !== req.user.id) {
            return res.status(403).json({ message: 'Non sei autorizzato a modificare questo utente.' });
        }

        const user = await getUserById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Utente non trovato.' });
        }

        let parentUser = null;
        const parentRef = req.body.parentRef?.trim();

        // Gestione parentId solo se l'utente attuale non ha già un parent
        if ((!user.parentId || user.parentId === '') && parentRef) {
            try {
                parentUser = await getUserByReferralCode(parentRef);
                if (!parentUser) {
                    console.warn(`Referral code '${parentRef}' non valido o non trovato.`);
                }
            } catch (err) {
                console.error('Errore nel recupero del referral:', err.message);
                // Non bloccare l'update, ma logga l'errore
            }
        }

        const expressionAttributes = {
            ':n': req.body.nome || '',
            ':c': req.body.cognome || '',
            ':d': req.body.dataNascita || '',
            ':cf': req.body.codFiscale || '',
            ':nt': req.body.numTel || '',
        };

        if (parentUser) {
            expressionAttributes[':pI'] = parentUser.id;
        }

        const updateExpression =
            'set nome = :n, cognome = :c, dataNascita = :d, codFiscale = :cf, numTel = :nt' +
            (parentUser ? ', parentId = :pI' : '');

        const updateParams = {
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email,
            },
            UpdateExpression: updateExpression,
            ExpressionAttributeValues: expressionAttributes,
        };

        await dd.update(updateParams).promise();

        return res.status(200).json({ message: 'Parametri modificati con successo!' });
    } catch (err) {
        console.error('Errore durante aggiornamento utente:', err);
        return res.status(500).json({
            message: 'Errore interno. Riprova più tardi.',
            error: err.message || err,
        });
    }
});

router.patch('/user/photo', checkIfAuth, upload.single('propic'), (req, res) => {
    dd.get({
        "TableName": tableName,
        "Key": {
            "userType": req.user.userType,
            "email": req.user.email
        }
    }, (err, getData) => {
        if (err) return res.status(500).json({ error: { message: err } })

        let key = `restall-propic-${Date.now()}-${req.file.originalname}`

        s3_client.upload(AWS.S3.PROPIC_BUCKET, req.file, key)
            .then(result => {
                let updateParams = {
                    "TableName": tableName,
                    "Key": {
                        "userType": req.user.userType,
                        "email": req.user.email
                    },
                    "UpdateExpression": "set propicLocation = :pL, propicKey = :pK",
                    "ExpressionAttributeValues": {
                        ":pL": result.location,
                        ":pK": key
                    }
                }
                dd.update(updateParams, (err, upData) => {
                    if (err) return res.status(500).json({ error: { message: err } })
                    if (getData.Item.propicLocation != "") {
                        s3_client.delete(AWS.S3.PROPIC_BUCKET, getData.Item.propicKey)
                            .then(deleteRes => deleteRes)
                            .catch(err => {
                                return res.status(500).json({
                                    error: {
                                        message: err
                                    }
                                })
                            })
                    }

                    return res.status(200).json({
                        file: {
                            originalname: req.file.originalname,
                            key: result.key,
                            location: result.location
                        }
                    })
                })
            })
            .catch(err => {
                return res.status(500).json({
                    error: {
                        message: err
                    }
                })
            })
    })

})

router.get('/user/photo', checkIfAuth, (req, res) => {
    dd.get({
        "TableName": tableName,
        "Key": {
            "userType": req.user.userType,
            "email": req.user.email
        }
    }, (err, data) => {
        if (err) { return res.status(500).json({ error: { message: err } }) }
        if (data.Item.propicLocation == "") { return res.status(204).json({ message: "Nessuna immagine profilo impostata! " }) }

        const params = new Proxy(new URLSearchParams(data.Item.propicLocation), {
            get: (searchParams, prop) => searchParams.get(prop),
        });
        let creationDate = parseISO(params['X-Amz-Date']);
        let expiresInSecs = Number(params['X-Amz-Expires']);
        let expiryDate = addSeconds(creationDate, expiresInSecs);

        if (expiryDate < new Date() || isNaN(expiryDate)) {
            console.log("lambda invoke")
            lambdaClient.invoke({
                FunctionName: AWS.LAMBDA.RENEW_LOCATION_FUNC,
                Payload: JSON.stringify({
                    fileKey: data.Item.propicKey,
                    bucket: AWS.S3.PROPIC_BUCKET
                })
            }).then(result => {
                let newFile = JSON.parse(Buffer.from(result.Payload));
                dd.update({
                    "TableName": tableName,
                    "Key": {
                        "userType": req.user.userType,
                        "email": req.user.email
                    },
                    "UpdateExpression": "set propicLocation = :pL",
                    "ExpressionAttributeValues": {
                        ":pL": newFile.body.location,
                    }
                }, (err, data) => {
                    if (err) return res.status(500).json({ error: { message: err } })

                    return res.status(200).json({
                        file: {
                            location: newFile.body.location
                        }
                    })
                })
            })
                .catch(err => { return res.status(500).json({ err }) })
        }
        else {
            return res.status(200).json({
                file: {
                    location: data.Item.propicLocation
                }
            })
        }
    })
})

router.get("/user/network/:rfCode", checkIfAuth, (req, res) => {
    if (!req.user) {
        return res.status(401).json({
            "message": "Utente non registrato!",
            "redirect": "https://api.restall.it/signup",
            "referral": req.params.rfCode
        })
    }

    dd.get({
        "TableName": tableName,
        "Key": {
            "userType": req.user.userType,
            "email": req.user.email
        }
    }, (err, data) => {
        if (err) { console.log(err); return res.status(500).json({ "message": "Qualcosa è andato storto!" }) }
        if (!data.Item) {
            return res.status(404).json({
                "message": "Utente non registrato!",
                "redirect": "https://api.restall.it/signup",
                "referral": req.params.rfCode
            })
        }
        if (!data.Item.completed) {
            return res.status(500).json({
                "message": "Utente non completato! Impossibile aggiungere l'utente alla network!",
                "referral": req.params.rfCode
            })
        }
    })

    let queryParams = {
        "TableName": tableName,
        "IndexName": "referral-index",
        "KeyConditions": {
            "referralCode": {
                "ComparisonOperator": "EQ",

                "AttributeValueList": [req.params.rfCode]
            }
        }
    }

    dd.query(queryParams, (err, result) => {
        if (err) { console.log(err); return res.status(500).json({ "message": "Qualcosa è andato storto!" }) }

        dd.get({
            "TableName": tableName,
            "Key": {
                "userType": req.user.userType,
                "email": req.user.email
            }
        }, (err, getResult) => {
            if (err) { console.log(err); return res.status(500).json({ "message": "Qualcosa è andato storto!" }) }
            if (getResult.Item.parentId !== "") { return res.status(500).json({ "message": "Impossibile cambiare network! Sei già affiliato a qualcuno!" }) }

            let updateParams = {
                "TableName": tableName,
                "Key": {
                    "userType": req.user.userType,
                    "email": req.user.email
                },
                "UpdateExpression": "set parentId = :pI",
                "ExpressionAttributeValues": {
                    ":pI": result.Items[0].id
                }
            }
            dd.update(updateParams, (err, upResult) => {
                if (err) { return res.status(500).json({ "message": "qualcosa è andato storto" }) }
                console.log(upResult)
                return res.status(200).json({ "message": "network aggiornato con successo!" })
            })
        })
    })

})

const getUserNetwork = async (userId, level = 0, network = []) => {
    try {
        // Trova gli utenti che hanno come parentId l'utente corrente
        const data = await dd.query({
            TableName: tableName,
            IndexName: "parentId-index",
            KeyConditionExpression: "parentId = :userId",
            ExpressionAttributeValues: {
                ":userId": userId
            }
        }).promise();

        if (data.Count === 0) {
            return network;
        }

        for (const user of data.Items) {
            network.push({
                id: user.id,
                nome: user.nome,
                cognome: user.cognome,
                level: level + 1
            });

            await getUserNetwork(user.id, level + 1, network);
        }

        return network;
    } catch (err) {
        console.error(err);
        throw err;
    }
};

const getParentUser = async (userId) => {
    try {
        const data = await dd.query({
            TableName: tableName,
            IndexName: "id-index",
            KeyConditionExpression: "id = :userId",
            ExpressionAttributeValues: {
                ":userId": userId
            }
        }).promise();

        if (data.Count === 0) {
            return null;
        }

        return (data.Items[0].parentId) ? getUserById(data.Items[0].parentId) : null;
    } catch (err) {
        console.error(err);
        throw err;
    }
};

const getUserById = async (userId) => {
    const data = await dd.query({
        TableName: tableName,
        IndexName: "id-index",
        KeyConditionExpression: "id = :userId",
        ExpressionAttributeValues: {
            ":userId": userId
        }
    }).promise();
    return data.Items[0];
};

const getUserByReferralCode = async (referralCode) => {
    try {
        const data = await dd.query({
            TableName: tableName,
            IndexName: "referral-index",
            KeyConditionExpression: "referralCode = :referralCode",
            ExpressionAttributeValues: {
                ":referralCode": referralCode
            }
        }).promise();

        if (data.Count === 0) {
            return null;
        }

        return data.Items[0];
    } catch (err) {
        console.error(err);
        throw err;
    }
};

router.get('/user/network', checkIfAuth, async (req, res) => {
    try {
        let parentUser = await getParentUser(req.user.id);
        let network = [{
            id: req.user.id,
            nome: req.user.nome,
            cognome: req.user.cognome,
            level: 0
        }];

        if (parentUser) {
            network.push({
                id: parentUser.id,
                nome: parentUser.nome,
                cognome: parentUser.cognome,
                level: -1
            });
        }

        network = await getUserNetwork(req.user.id, 0, network);
        const payload = JSON.stringify({ userId: req.user.id });

        await lambdaClient.invoke({
            FunctionName: AWS.LAMBDA.NETWORK_LAMBDA_NAME,
            InvocationType: "Event",
            Payload: Buffer.from(payload)
        });

        return res.status(200).json({ network });
    } catch (error) {
        console.error(error);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
});

// Crea / reindirizza account venditore Stripe
router.post('/user/create-seller', checkIfAuth, async (req, res) => {
    try {
        // Recupera utente dal DB
        const userData = await dd.get({
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email
            }
        }).promise();

        const user = userData.Item;
        if (!user) return res.status(404).json({ message: "Utente non trovato" });

        // L'utente deve essere verificato prima di diventare venditore
        if (!user.verified) {
            return res.status(403).json({ message: "Devi prima verificare l'account" });
        }

        // ---- IMPORTANTE ----
        // Usa la chiave corretta: connectAccountId
        let connectAccountId = user.connectAccountId;

        // Se non esiste un account Connect → crealo
        if (!connectAccountId) {
            const account = await stripe.accounts.create({
                type: "express",
                country: "IT",
                email: user.email,
                capabilities: {
                    transfers: { requested: true },
                },
                metadata: {
                    platformUserId: user.id
                }
            });

            connectAccountId = account.id;

            // Salva nel DB
            await dd.update({
                TableName: tableName,
                Key: {
                    userType: user.userType,
                    email: user.email
                },
                UpdateExpression: "SET connectAccountId = :id",
                ExpressionAttributeValues: {
                    ":id": connectAccountId
                }
            }).promise();
        }

        // Crea il link di onboarding
        const accountLink = await stripe.accountLinks.create({
            account: connectAccountId,
            refresh_url: "https://restall.it/seller/error",
            return_url: "https://restall.it/seller/success",
            type: "account_onboarding",
            collect: "eventually_due"
        });

        return res.status(200).json({
            message: "Redirect utente a Stripe per completare setup venditore",
            url: accountLink.url
        });

    } catch (err) {
        console.error("Stripe Connect error:", err);
        return res.status(500).json({ message: "Errore Stripe", error: err.message });
    }
});

router.get('/user/seller-status', checkIfAuth, async (req, res) => {
    try {
        const userData = await dd.get({
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email
            }
        }).promise();

        const user = userData.Item;
        if (!user || !user.connectAccountId) {
            return res.status(400).json({ message: "Account venditore non trovato" });
        }

        const account = await stripe.accounts.retrieve(user.connectAccountId);

        return res.json({
            charges_enabled: account.charges_enabled,
            payouts_enabled: account.payouts_enabled,
            details_submitted: account.details_submitted
        });

    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: "Errore", error: err.message });
    }
});

// Restituisce il link alla dashboard Stripe Express del venditore
router.get('/user/seller-dashboard', checkIfAuth, async (req, res) => {
    try {
        // Recupera utente dal DB
        const userData = await dd.get({
            TableName: tableName,
            Key: {
                userType: req.user.userType,
                email: req.user.email
            }
        }).promise();

        const user = userData.Item;

        if (!user || !user.connectAccountId) {
            return res.status(400).json({
                message: "Account venditore non trovato"
            });
        }

        const account = await stripe.accounts.retrieve(user.connectAccountId);

        if (!account.details_submitted) {
            return res.status(403).json({
                message: "Completa prima la configurazione Stripe"
            });
        }

        // Crea login link Stripe Express
        const loginLink = await stripe.accounts.createLoginLink(
            user.connectAccountId
        );

        return res.status(200).json({
            url: loginLink.url
        });

    } catch (err) {
        console.error("Errore creazione login link Stripe:", err);
        return res.status(500).json({
            message: "Errore nel recupero della dashboard venditore",
            error: err.message
        });
    }
});




module.exports = router;