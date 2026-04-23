import Firebase from 'firebase-admin';
import serviceAccountRestAll from '../../res/restall-406515-firebase-adminsdk-n986o-6a14fd114e.json' assert {type: 'json'};
import serviceAccountRestAllTech from '../../res/restall-tech-firebase-adminsdk-tc2aj-8b6ec87c32.json' assert {type: 'json'};

if (!serviceAccountRestAll || !serviceAccountRestAllTech) {
    throw new Error("I file di credenziali non sono corretti o non esistono!");
}

const appRestall = Firebase.initializeApp({
    credential: Firebase.credential.cert(serviceAccountRestAll)
}, "RestAll")

const appRestallTech = Firebase.initializeApp({
    credential: Firebase.credential.cert(serviceAccountRestAllTech)
}, "RestAllTech")

export {
    appRestall,
    appRestallTech
};
