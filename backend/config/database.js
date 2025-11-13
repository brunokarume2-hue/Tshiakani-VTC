// Configuration TypeORM pour PostgreSQL + PostGIS
const { DataSource } = require('typeorm');
const path = require('path');

// Importer les entités
const User = require('../entities/User');
const Ride = require('../entities/Ride');
const Notification = require('../entities/Notification');
const SOSReport = require('../entities/SOSReport');
const PriceConfiguration = require('../entities/PriceConfiguration');
const SupportMessage = require('../entities/SupportMessage');
const SupportTicket = require('../entities/SupportTicket');
const FavoriteAddress = require('../entities/FavoriteAddress');
const ChatMessage = require('../entities/ChatMessage');
const ScheduledRide = require('../entities/ScheduledRide');
const SharedRide = require('../entities/SharedRide');

// Configuration pour Cloud SQL (socket Unix) ou connexion TCP standard
const isCloudSQL = process.env.INSTANCE_CONNECTION_NAME;
const dbConfig = {
  type: 'postgres',
  username: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_NAME || 'TshiakaniVTC',
};

if (isCloudSQL) {
  // Utiliser le socket Unix pour Cloud SQL
  dbConfig.host = `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`;
  dbConfig.extra = {
    socketPath: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`,
  };
} else {
  // Connexion TCP standard
  dbConfig.host = process.env.DB_HOST || 'localhost';
  dbConfig.port = parseInt(process.env.DB_PORT) || 5432;
}

const AppDataSource = new DataSource({
  ...dbConfig,
  // Désactiver synchronize en production (utiliser les migrations SQL)
  synchronize: (process.env.NODE_ENV === 'development' || process.env.DB_SYNC === 'true') && process.env.NODE_ENV !== 'production',
  logging: process.env.NODE_ENV === 'development' 
    ? ['error', 'warn', 'schema', 'migration']
    : ['error', 'warn'], // Logging des erreurs et warnings en production
  entities: [User, Ride, Notification, SOSReport, PriceConfiguration, SupportMessage, SupportTicket, FavoriteAddress, ChatMessage, ScheduledRide, SharedRide],
  migrations: [path.join(__dirname, '../migrations/*.js')],
  // Connection pooling - TypeORM délègue le pooling au driver pg
  // Les paramètres dans 'extra' sont passés directement au constructeur pg.Pool
  extra: {
    ...(dbConfig.extra || {}),
    // Configuration PostGIS
    application_name: 'tshiakani-vtc-api',
    // Connection pooling (paramètres du driver pg.Pool)
    max: parseInt(process.env.DB_POOL_MAX) || 20, // Nombre max de connexions dans le pool (défaut pg: 10)
    connectionTimeoutMillis: parseInt(process.env.DB_POOL_CONNECTION_TIMEOUT) || 2000, // Timeout pour établir une connexion (ms)
    idleTimeoutMillis: parseInt(process.env.DB_POOL_IDLE_TIMEOUT) || 30000, // Timeout avant fermeture connexion inactive (ms, défaut: 10000)
    // Options PostgreSQL
    statement_timeout: parseInt(process.env.DB_STATEMENT_TIMEOUT) || 30000 // Timeout max par requête (ms)
  }
});

module.exports = AppDataSource;

