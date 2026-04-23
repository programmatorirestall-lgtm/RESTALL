import {Client} from "@googlemaps/google-maps-services-js";
import { MISC } from "../config/constants.js";
import { GOOGLE } from "../config/config.js";


const client = new Client({});

export const calculateDistanceFromBase = async (destination) => {
  try {
    if (!destination || destination.trim() === "") {
      console.error("Destinazione non valida:", destination);
      return 0;
    }

    const response = await client.distancematrix({
      params: {
        origins: [MISC.BASE_LEGAL_ADDRESS],
        destinations: [destination],
        key: GOOGLE.API_KEY,
      }
    });

    const element = response?.data?.rows?.[0]?.elements?.[0];

    if (element?.status !== "OK") {
      console.error("Errore Distance Matrix:", element?.status, response.data);
      return 0;
    }

    const distanceKM = element.distance.value / 1000;
    console.log(`Distanza: ${distanceKM} km`);
    return distanceKM;

  } catch (error) {
    console.error("Errore nel calcolo della distanza:", error);
    return 0;
  }
};
