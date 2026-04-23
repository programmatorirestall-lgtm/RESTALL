import notFoundMiddleware from "../middleware/notFound.js";
import getAllWarehouse from '../routes/warehouse/getAllProducts.js'
import getAllRientri from '../routes/rientri/getAll.js'
import putRientro from '../routes/rientri/putRientro.js'
import putScarico from '../routes/scarichi/putScarico.js'
import getAllScarichi from '../routes/scarichi/getAll.js'
import authMiddleware from "../middleware/auth.js";
import warehouseFromCSV from '../routes/warehouse/createFromCSV.js'
import getByCodeAn from '../routes/warehouse/getProdFromCodeAn.js'
import searchRoute from '../routes/warehouse/search.js'
import deleteAllRoute from '../routes/warehouse/delete.js'
import searchAzienda from '../routes/azienda/search.js' 
import addAzienda from '../routes/azienda/addAzienda.js'
import getMacchina from '../routes/warehouse/getMacchina.js'

class Router {
    constructor( app ){
        this.app = app;
        this.routerSchema = {
            '/warehouse': [
                authMiddleware,
                warehouseFromCSV, 
                getAllWarehouse,
                searchRoute,
                deleteAllRoute,
                {
                    '/code': [getByCodeAn]
                },
                {
                    '/rientri':[putRientro, getAllRientri],
                    '/scarichi':[putScarico, getAllScarichi]
                },
                {
                    '/azienda': [addAzienda, searchAzienda]
                },
                {
                    '/macchina': [getMacchina]
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