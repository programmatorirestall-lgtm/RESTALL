import {pool} from '../helpers/mysql.js';

class Eventi{
    constructor(evento){
        return new Promise((resolve) => {
            this.idTicket = evento.idTicket
            this.dataInizio = evento.dataInizio
            this.dataFine = evento.dataFine
            this.evento = evento.evento
            resolve(this)
        })
    }
}

export default Eventi;