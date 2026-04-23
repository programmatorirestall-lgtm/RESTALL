import { Validator } from 'node-input-validator';

const preventiviValidator = (req, res, next) => {
    const v = new Validator(req.body, {
        descrizione: 'string',
        ragSocialeAzienda: 'required|string',
        numCellulare: 'required|string',
        doc: 'string',
        stato: 'in:APERTO,IN LAVORAZIONE,CONSEGNATO'
    });

    v.check()
    .then((match) => {
        if (!match) {
            return res.status(422).json({ message: v.errors });
        }
        next();
    });
};

export default preventiviValidator;
