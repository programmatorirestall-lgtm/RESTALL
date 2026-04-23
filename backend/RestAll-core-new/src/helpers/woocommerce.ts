import WooCommerceRestApi, {WooRestApiOptions} from "woocommerce-rest-ts-api";
import CONSTANTS from "../config/constants";

const opt:WooRestApiOptions = {
    url: CONSTANTS.WOOCOMMERCE.BASE_URL,
    consumerKey:  CONSTANTS.WOOCOMMERCE.WOOCOMMERCE_USER_KEY,
    consumerSecret:  CONSTANTS.WOOCOMMERCE.WOOCOMMERCE_USER_SECRET,
    version: "wc/v3",
    queryStringAuth: false // Force Basic Authentication as query string true and using under
}

const WC = new WooCommerceRestApi(opt);

export default WC;