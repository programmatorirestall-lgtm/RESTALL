import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { RefoundRequest } from '../models/RefoundRequest';
import CONSTANTS from '../config/constants';

export const AppDataSource = new DataSource({
  type: 'mysql', // cambia in 'postgres' se usi PostgreSQL
  host: CONSTANTS.RDS.HOST,
  port: CONSTANTS.RDS.PORT, // 5432 per PostgreSQL
  username: CONSTANTS.RDS.USER,
  password: CONSTANTS.RDS.PASSWORD,
  database: CONSTANTS.RDS.DATABASE,
  synchronize: false, // disattivare in produzione
  logging: false,
  entities: [RefoundRequest],
  migrations: [],
  subscribers: [],
});