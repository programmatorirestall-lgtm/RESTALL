import authMiddleware from '../middlewares/auth.js';
import notFoundMiddleware from '../middlewares/notFound.js';
import healthCheck from '../routes/healthCheck.js';
import addTicket from '../routes/tickets/createTicket.js';
import getAllTickets from '../routes/tickets/getAll.js';
import createTecnico from '../routes/tecnico/createTecnico.js';
import addTecnico from '../routes/tech_ticket/addTecnico.js';
import getTicketDetails from '../routes/tickets/getTicketDetails.js';
import startTicket from '../routes/tickets/startTicket.js';
import getTecnico from '../routes/tecnico/getTecnico.js';
import closeTicket from '../routes/tickets/closeTicket.js';
import getAllTech from '../routes/tecnico/getAll.js';
import getAllClosedTickets from '../routes/tickets/storicoTicket.js';
import uploadSig from '../routes/tickets/uploadSig.js'
import uploadAllegato from '../routes/tickets/uploadAllegati.js';
import cancelTicket from '../routes/tickets/cancelTicket.js';
import verifyTech from '../routes/tecnico/verifyTecnico.js'
import patchPagamentoOrario from '../routes/tecnico/patchPagamentoOrario.js'
import getAllSettings from '../routes/settings/getAll.js'
import patchSettingByID from '../routes/settings/patchByID.js'
import preview from '../routes/tickets/preview.js'
import createPreventivi from '../routes/preventivi/createPreventivi.js'
import getAllPreventivi from '../routes/preventivi/getAll.js'
import submitPreventivi from '../routes/preventivi/submitPreventivi.js'
import uploadAllegatoPreventivo from '../routes/preventivi/allegati/addAllegato.js'
import getDetails from '../routes/preventivi/getDetails.js'
import rifiutaPreventivo from '../routes/preventivi/rifiutaPreventivo.js'

class Router {
    constructor( app ){
        this.app = app;
        this.routerSchema = {
            '/health': healthCheck,
            '/api': [
                {
                    '/v1':[
                        {
                            '/ticket': [ 
                                authMiddleware,
                                addTicket,
                                getAllTickets,
                                {
                                    '/tecnico': [addTecnico],
                                    '/signature': [uploadSig],
                                    '/allegati': [uploadAllegato]
                                },
                                preview,
                                closeTicket,
                                startTicket,
                                getAllClosedTickets,
                                getTicketDetails,
                                cancelTicket    
                            ]
                        },
                        {
                            '/tecnico': [
                                authMiddleware,
                                getAllTech, 
                                getTecnico,
                                createTecnico,
                                verifyTech,
                                patchPagamentoOrario
                            ]
                        },
                        {
                            '/preventivi': [
                                authMiddleware,
                                createPreventivi,
                                getAllPreventivi,
                                submitPreventivi,
                                getDetails,
                                rifiutaPreventivo,
                                {
                                    '/allegato': [uploadAllegatoPreventivo]
                                }
                            ]
                        },
                        {
                            '/settings': [getAllSettings, patchSettingByID]
                        }
                    ]
                }
            ],
            '*': notFoundMiddleware,
        }
    }
    
    setAllRoutes(_route = '', routerSchema = this.routerSchema) {
        switch(routerSchema.constructor) {
            case ({}).constructor:
                Object.keys(routerSchema).forEach((route) => { this.setAllRoutes(_route + route, routerSchema[route]); });
                break;
            case ([]).constructor:
                routerSchema.forEach((element) => { this.setAllRoutes(_route, element); });
                break;
            default:  _route === '' ? this.app.use(routerSchema) : this.app.use(_route, routerSchema);
        }
    }
}

export default Router;