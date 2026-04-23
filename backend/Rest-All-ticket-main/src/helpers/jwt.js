import jwt from 'jsonwebtoken';
import {JWT}  from '../config/constants.js';

const jwtHelper = {
    signAccessToken: (payload) => {
        return jwt.sign( payload, JWT.SECRET_KEY, { expiresIn: JWT.EXPIRES_IN, notBefore: '0', issuer:  JWT.ISSUER});
    },

    verify: (token) => {
        return new Promise((resolve, reject) => {
            jwt.verify(token, JWT.SECRET_KEY, {issuer: JWT.ISSUER}, (error, verified) => {
                error ? reject(error) : resolve(verified);
            });
        });
    },
};

export default jwtHelper;