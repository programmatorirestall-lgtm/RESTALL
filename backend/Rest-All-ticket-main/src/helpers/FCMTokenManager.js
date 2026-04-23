import {dynamoTokenClient} from "./aws.js";
import {appRestall, appRestallTech} from "./firebase.js";

function getAllAdmin(){
    return new Promise((resolve, reject) => {
        let FCMTokens = [];
        dynamoTokenClient.getItemsByType('admin')
        .then(tokens => {
            if(tokens.Count == 0) {return resolve([])}
            return Promise.all(tokens.Items.map(({token}) => {
                return new Promise((resolve) => {
                    FCMTokens.push(token.S);
                    resolve()
                })
            }))
        })
        .then(() => {
            return resolve(FCMTokens)
        })
        .catch(err => {console.log(err); return reject(err)})
    })
}

function getAllTech(){
    return new Promise((resolve, reject) => {
        let FCMTokens = [];
        dynamoTokenClient.getItemsByType('tech')
        .then(tokens => {
            if(tokens.Count == 0) {return resolve([])}
            return Promise.all(tokens.Items.map(({token}) => {
                return new Promise((resolve) => {
                    FCMTokens.push(token.S);
                    resolve()
                })
            }))
        })
        .then(() => {return resolve(FCMTokens)})
        .catch(err => {console.log(err); return reject(err)})
    })
}

function getById(userId){
    return new Promise((resolve, reject) => {
        let FCMTokens = []
        dynamoTokenClient.getItemById(userId)
        .then(tokens => {
            if(tokens.Count == 0) {return resolve([])}
            return Promise.all(tokens.Items.map(({token}) => {
                return new Promise((resolve) => {
                    FCMTokens.push(token.S)
                    resolve()
                })
            }))
            .then(() => {return resolve(FCMTokens)})
            .catch(err => {return reject(err)})
        })
        .catch(err => {
            console.log(err);
            return reject(err);
        })
    })
}

function sanitizeTokenTable(failureToken){
    return new Promise((resolve, reject) => {
        failureToken.forEach((token) => {
            dynamoTokenClient.deleteItemByToken(token)
            .then(result => {
                return resolve(result)
            })
        }) 
    })
    
}

const NotificationManager = {
    sendNotificationToTechsById: (techId, title, body) => {
        return new Promise((resolve, reject) => {
            getById(techId).then(tokens => {
                let message
                if(tokens.length == 0){ return resolve() }
                    message = {
                        notification: {
                            title: title,
                            body: body,
                        },
                        tokens: tokens
                    }

                    appRestallTech.messaging().sendEachForMulticast(message)
                    .then(response => {
                        return resolve(response)
                    })
                    .catch(err => {
                        console.log(err);
                        return reject(err)
                    })  
                
            })
        })
    },

    sendNotificationToUsersById: (userId, title, body) => {
        return new Promise((resolve, reject) => {
            getById(userId).then(tokens => {
                let message
                if(tokens.length == 0){ return resolve()}
                    message = {
                        notification: {
                            title: title,
                            body: body,
                        },
                        tokens: tokens
                    }

                    appRestall.messaging().sendEachForMulticast(message)
                    .then(response => {
                        return resolve(response)
                    })
                    .catch(err => {
                        console.log(err);
                        return reject(err)
                    })  
                
            })
        })
    },

    sendNotificationToAdmins: (title, body) => {
        return new Promise((resolve, reject) => {
            getAllAdmin()
            .then(tokens => {
                let message
                if(tokens.length == 0) {return resolve()}
                message = {
                    notification: {
                        title: title,
                        body: body,
                    },
                    tokens: tokens
                }

                appRestallTech.messaging().sendEachForMulticast(message)
                .then(response => {
                    return resolve(response)
                })
                .catch(err => reject(err))
            })
            .catch(err => {
                console.log(err)
                return reject(err)
            })
        })
    }
}

export default NotificationManager