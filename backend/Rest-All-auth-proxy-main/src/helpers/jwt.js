const jwt = require('jsonwebtoken');
const {JWT} = require('../config/config.js');

const jwtHelper = {
    signAccessToken: (payload) => {
        return jwt.sign( payload, JWT.SECRET_KEY, { expiresIn: JWT.EXPIRES_IN, notBefore: '0', issuer:  JWT.ISSUER});
    },

    signRefreshToken: (payload) => {
        return jwt.sign( payload, JWT.REFRESH_SECRET_KEY, { expiresIn: JWT.REFRESH_EXPIRES, notBefore: '0', issuer:  JWT.ISSUER })
    },

    verifyAccessToken: (token) => {
        return new Promise((resolve, reject) => {
            jwt.verify(token, JWT.SECRET_KEY, {issuer: JWT.ISSUER}, (error, verified) => {
                error ? reject(error) : resolve(verified);
            });
        });
    },

    verifyRefreshToken: (refreshToken) => {
        return new Promise((resolve, reject) => {
            jwt.verify(refreshToken, JWT.REFRESH_SECRET_KEY, {issuer: JWT.ISSUER}, (err, verified) => {
                err ? reject(err) : resolve(verified)
            })
        })
    }
};

module.exports = jwtHelper;
