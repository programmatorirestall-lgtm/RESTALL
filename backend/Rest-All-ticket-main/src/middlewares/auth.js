import jwt from '../helpers/jwt.js';
import { ERRORS } from '../config/constants.js';

const authMiddleware = (req, res, next) => {
    if (!req.headers.authorization || req.headers.authorization.split(' ')[0] !== 'Bearer') 
        return res.status(403).send({ error:'Forbidden' });
    
    const bearer = req.headers.authorization.split(' ')[1];

    jwt.verify(bearer)
        .then((verified) => {
            req.user = verified;
            next();
        })
        .catch((error) => { 
            console.log(error)
            const message = error.name === 'TokenExpiredError' ? ERRORS.TOKEN_EXPIRED : ERRORS.INVALID_ACCESS_TOKEN;
            return res.status(401).send({ error: message });
        });
};

export default authMiddleware;