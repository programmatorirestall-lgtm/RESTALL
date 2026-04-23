import Router from 'express';
import Ticket from '../../models/ticket.js';
import moment from 'moment';
import { AUTOMATION_SETTINGS } from '../../config/constants.js';
import { calculateDistanceFromBase } from '../../helpers/googleMaps.js'
import Tecnico from '../../models/tecnico.js';

const router = new Router();

router.post('/preview/:id_ticket', async (req, res) => {
    req.body.operatori.push(+req.user.id)
    let costoChiamata, costoTrasferta;

    costoChiamata = AUTOMATION_SETTINGS.find((o) => o.id == 2).value
    let costoKM = (AUTOMATION_SETTINGS.find((o) => o.id == 1)).value
    let raggioNoTax = (AUTOMATION_SETTINGS.find((o) => o.id == 3)).value
    let distanceKM = await calculateDistanceFromBase(req.body.indirizzo);
    costoTrasferta = 0;
    
    if(distanceKM > raggioNoTax){
        let distanceAR = 2*distanceKM;
        costoTrasferta = Math.round(distanceAR*costoKM);
    }

    let costiOrariOperatori = [];
    if(req.body.operatori.length > 0){
        req.body.operatori.forEach(async (idTecnico) => {
            try{
                let techIst = await new Tecnico({
                    id: idTecnico
                })
                let tecnico = await techIst.getById()
                if(tecnico != undefined){
                    costiOrariOperatori.push(tecnico.pagamento_orario) 
                }
                
            } catch (err) {
                console.log(err)
            }
        })
    }

    new Ticket({
        id: req.params.id_ticket
    })
    .then(ticket => ticket.getById())
    .then(t => new Promise((resolve, reject) => {
        if(t.length == 0) return reject(new Error("Il ticket non esiste!"))

        if(t.stato !== 'In corso') return reject(new Error("Impossibile completare l'operazione!"))

        let summary = t.summary
        summary.push({
            dataInizio: moment().add(2, 'hours').format("YYYY-MM-DD HH:mm:ss"),
            dataFine: "",
            evento: "Chiuso"
        })

        let tot = 0;
        summary.forEach(e => {
            if(e.evento == 'In corso'){
                if(e.dataFine == ''){
                    e.dataFine = moment().add(2, 'hours').format("YYYY-MM-DD HH:mm:ss")
                }
                let totMinutes = moment(e.dataFine).diff(moment(e.dataInizio), 'minute');
                let workingMinutes = totMinutes - (960*moment(e.dataFine).diff(moment(e.dataInizio), 'days')); 
                costiOrariOperatori.forEach((costo) => {
                    tot += Math.round((costo/60)*workingMinutes);
                })
                e.oreLavorative = (workingMinutes < 60) ? 1 : workingMinutes;
            }
            else{e.oreLavorative = 0}
        });
        return resolve(tot);
    }))
    .then(tot => {
        return res.status(200).json({
            costiOperatori: costiOrariOperatori.reduce((a, b) => a + b, 0),
            totManodopera: tot,
            costoChiamata,
            costoTrasferta,
        })
    })
    .catch(err => {
        console.log(err)
        return res.status(500).json(err)
    })
});

export default router;