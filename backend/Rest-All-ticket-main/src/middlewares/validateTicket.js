import { Validator } from 'node-input-validator';

const ticketValidator = (req, res, next) => {
    return new Promise(() => {
        const v = new Validator(req.body, {
            tipo_macchina: 'required|in:Freddo,Climatizzazione,Aspirazione,Caldo,Altro',
            stato_macchina: 'required|in:Funzionante,Rallentato,Fermo'
        })

        v.check()
        .then((match) => {
            if(!match){
                return res.status(422).json({message: v.errors});
            }
            next()
        })
    })
}

export default ticketValidator