// Serveur avec PostgreSQL + PostGIS
require('dotenv').config();
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const AppDataSource = require('./config/database');

// Logger structuré et gestion d'erreurs
const logger = require('./utils/logger');
const { errorHandler } = require('./utils/errors');
const { metricsMiddleware, recordWebSocketConnection, recordWebSocketMessage, recordWebSocketError } = require('./utils/metrics');

const app = express();
const server = http.createServer(app);
// Configuration CORS pour Socket.io et Express
const corsOrigins = process.env.CORS_ORIGIN 
  ? process.env.CORS_ORIGIN.split(',').map(origin => origin.trim()).filter(origin => origin.length > 0)
  : ["http://localhost:3001", "http://localhost:5173", "capacitor://localhost", "ionic://localhost"];

const io = socketIo(server, {
  cors: {
    origin: corsOrigins,
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Middlewares
app.use(helmet());
app.use(compression()); // Compression gzip pour réduire la taille des réponses

// Configuration CORS pour Express
const expressCorsOrigins = process.env.CORS_ORIGIN 
  ? process.env.CORS_ORIGIN.split(',').map(origin => origin.trim()).filter(origin => origin.length > 0)
  : ["http://localhost:3001", "http://localhost:5173", "capacitor://localhost", "ionic://localhost"];

// Fonction pour vérifier si l'origine est autorisée
const corsOptions = {
  origin: function (origin, callback) {
    // Autoriser les requêtes sans origine (mobile apps, Postman, etc.)
    if (!origin) {
      return callback(null, true);
    }
    
    // Vérifier si l'origine est dans la liste autorisée
    if (expressCorsOrigins.indexOf(origin) !== -1 || expressCorsOrigins.includes('*')) {
      callback(null, true);
    } else {
      // En développement, autoriser toutes les origines
      if (process.env.NODE_ENV !== 'production') {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    }
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "X-ADMIN-API-KEY", "X-Requested-With"],
  exposedHeaders: ["Content-Length", "X-Foo", "X-Bar"],
  preflightContinue: false,
  optionsSuccessStatus: 204
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Métriques de performance
app.use(metricsMiddleware);

// Monitoring Cloud Logging et Cloud Monitoring (uniquement en production sur GCP)
if (process.env.NODE_ENV === 'production' && (process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT)) {
  try {
    const { monitoringMiddleware } = require('./middlewares.postgres/monitoring');
    app.use(monitoringMiddleware);
    logger.info('Middleware de monitoring Cloud Logging/Monitoring activé');
  } catch (error) {
    logger.warn('Impossible d\'activer le middleware de monitoring', {
      error: error.message
    });
  }
}

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
});
app.use('/api/', limiter);

// Routes
app.use('/api/auth', require('./routes.postgres/auth'));
app.use('/api/rides', require('./routes.postgres/rides'));
app.use('/api/courses', require('./routes.postgres/rides')); // Alias
app.use('/api/users', require('./routes.postgres/users'));
// app.use('/api/chauffeurs', require('./routes.postgres/chauffeurs')); // Route pour les chauffeurs - DÉSACTIVÉE (app driver séparée)
app.use('/api/location', require('./routes.postgres/location'));
app.use('/api/driver', require('./routes.postgres/driver')); // Routes spécifiques pour l'app Driver
app.use('/api/client', require('./routes.postgres/client')); // Routes spécifiques pour l'app Client
app.use('/api/notifications', require('./routes.postgres/notifications'));
app.use('/api/sos', require('./routes.postgres/sos'));
app.use('/api/admin', require('./routes.postgres/admin'));
app.use('/api/admin/pricing', require('./routes.postgres/pricing'));
app.use('/api/paiements', require('./routes.postgres/paiements')); // Route pour les paiements Stripe
app.use('/api/agent', require('./routes.postgres/agent')); // Route pour les agents
app.use('/api/documents', require('./routes.postgres/documents')); // Route pour les documents (Cloud Storage)
app.use('/api/support', require('./routes.postgres/support')); // Route pour le support
app.use('/api/favorites', require('./routes.postgres/favorites')); // Route pour les favoris
app.use('/api/chat', require('./routes.postgres/chat')); // Route pour le chat
app.use('/api/scheduled-rides', require('./routes.postgres/scheduled-rides')); // Route pour les courses programmées
app.use('/api/share', require('./routes.postgres/share')); // Route pour le partage

// Routes API v1 pour l'app Driver
app.use('/api/v1/driver', require('./routes.postgres/driver.v1'));

// Routes de santé et monitoring
app.use('/', require('./routes.postgres/health'));

// Gestion d'erreurs centralisée (DOIT être après toutes les routes)
app.use(errorHandler);

// Socket.io pour la géolocalisation en temps réel (legacy - conservé pour compatibilité)
io.on('connection', (socket) => {
  recordWebSocketConnection();
  logger.info('Client WebSocket connecté', { socketId: socket.id });

  socket.on('ride:join', (rideId) => {
    socket.join(`ride:${rideId}`);
    logger.info('Client rejoint la course', { socketId: socket.id, rideId });
  });

  socket.on('ride:status:update', (data) => {
    recordWebSocketMessage();
    const { rideId, status } = data;
    io.to(`ride:${rideId}`).emit('ride:status:changed', {
      rideId,
      status,
      timestamp: new Date()
    });
    logger.info('Statut de course mis à jour', { rideId, status });
  });

  socket.on('disconnect', () => {
    logger.info('Client WebSocket déconnecté', { socketId: socket.id });
  });

  socket.on('error', (error) => {
    recordWebSocketError(error);
    logger.error('Erreur WebSocket', { socketId: socket.id, error: error.message });
  });
});

// Namespace WebSocket pour l'app Driver
const driverNamespace = io.of('/ws/driver');
// Namespace WebSocket pour l'app Client
const clientNamespace = io.of('/ws/client');
const jwt = require('jsonwebtoken');
// AppDataSource est déjà importé en haut du fichier
const User = require('./entities/User');
const Ride = require('./entities/Ride');

driverNamespace.use(async (socket, next) => {
  try {
    // Récupérer le token depuis les query parameters
    const token = socket.handshake.query.token;
    
    if (!token) {
      return next(new Error('Token d\'authentification manquant'));
    }

    // Vérifier le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: decoded.userId } });

    if (!user) {
      return next(new Error('Utilisateur non trouvé'));
    }

    // Stocker l'utilisateur dans le socket
    socket.user = user;
    socket.driverId = user.id;
    
    next();
  } catch (error) {
    logger.error('Erreur authentification WebSocket driver', { error: error.message });
    next(new Error('Token invalide'));
  }
});

driverNamespace.on('connection', async (socket) => {
  const driverId = socket.driverId;
  const driverName = socket.user?.name || 'Conducteur';
  
  recordWebSocketConnection();
  logger.info('Conducteur connecté via WebSocket', { driverId, driverName });

  // Joindre la room du conducteur
  socket.join(`driver:${driverId}`);

  // Envoyer confirmation de connexion
  socket.emit('connected', {
    type: 'connected',
    message: 'Connexion établie',
    driverId: driverId
  });

  // Gérer les messages ping (keep-alive)
  socket.on('ping', () => {
    socket.emit('pong', { type: 'pong' });
  });

  // Gérer les déconnexions
  socket.on('disconnect', () => {
    logger.info('Conducteur déconnecté', { driverId });
  });

  // Gérer les erreurs
  socket.on('error', (error) => {
    recordWebSocketError(error);
    logger.error('Erreur WebSocket driver', { driverId, error: error.message });
  });

  // Fonction pour notifier un conducteur d'une nouvelle course
  // Cette fonction sera appelée depuis les routes API (legacy - conservée pour compatibilité)
  socket.notifyNewRide = async (ride) => {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);
      const fullRide = await rideRepository.findOne({
        where: { id: ride.id },
        relations: ['client']
      });

      if (!fullRide) {
        return;
      }

      const rideData = {
        type: 'ride_request',
        ride: {
          id: fullRide.id.toString(),
          pickupAddress: fullRide.pickupAddress,
          dropoffAddress: fullRide.dropoffAddress,
          pickupLatitude: fullRide.pickupLocation.coordinates[1],
          pickupLongitude: fullRide.pickupLocation.coordinates[0],
          dropoffLatitude: fullRide.dropoffLocation.coordinates[1],
          dropoffLongitude: fullRide.dropoffLocation.coordinates[0],
          estimatedDistance: fullRide.distance || 0,
          estimatedDuration: fullRide.estimatedDuration || 0,
          estimatedEarnings: fullRide.estimatedPrice || 0,
          passengerName: fullRide.client?.name || null,
          createdAt: fullRide.createdAt.toISOString()
        }
      };

      recordWebSocketMessage();
      socket.emit('ride_request', rideData);
      logger.info('Notification de course envoyée au conducteur', { rideId: ride.id, driverId });
    } catch (error) {
      recordWebSocketError(error);
      logger.error('Erreur lors de l\'envoi de la notification', { error: error.message, rideId: ride.id, driverId });
    }
  };
});

// Namespace WebSocket pour l'app Client
clientNamespace.use(async (socket, next) => {
  try {
    // Récupérer le token depuis les query parameters
    const token = socket.handshake.query.token;
    
    if (!token) {
      return next(new Error('Token d\'authentification manquant'));
    }

    // Vérifier le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: decoded.userId } });

    if (!user) {
      return next(new Error('Utilisateur non trouvé'));
    }

    // Vérifier que l'utilisateur est un client
    if (user.role !== 'client' && user.role !== 'admin') {
      return next(new Error('Accès refusé: rôle client requis'));
    }

    // Stocker l'utilisateur dans le socket
    socket.user = user;
    socket.clientId = user.id;
    
    next();
  } catch (error) {
    logger.error('Erreur authentification WebSocket client', { error: error.message });
    next(new Error('Token invalide'));
  }
});

clientNamespace.on('connection', async (socket) => {
  const clientId = socket.clientId;
  const clientName = socket.user?.name || 'Client';
  
  recordWebSocketConnection();
  logger.info('Client connecté via WebSocket', { clientId, clientName });

  // Joindre la room du client
  socket.join(`client:${clientId}`);

  // Envoyer confirmation de connexion
  socket.emit('connected', {
    type: 'connected',
    message: 'Connexion établie',
    clientId: clientId
  });

  // Le client rejoint la room de sa course pour recevoir les mises à jour en temps réel
  socket.on('ride:join', async (rideId) => {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);
      const ride = await rideRepository.findOne({
        where: { id: parseInt(rideId) },
        relations: ['client']
      });

      if (!ride) {
        socket.emit('error', {
          type: 'ride_not_found',
          message: 'Course non trouvée'
        });
        return;
      }

      // Vérifier que le client est propriétaire de cette course
      if (ride.clientId !== clientId && socket.user.role !== 'admin') {
        socket.emit('error', {
          type: 'access_denied',
          message: 'Accès refusé à cette course'
        });
        return;
      }

      // Rejoindre la room de la course
      socket.join(`ride:${rideId}`);
      logger.info('Client a rejoint la course', { clientId, rideId });

      // Envoyer confirmation
      socket.emit('ride:joined', {
        type: 'ride_joined',
        rideId: rideId,
        message: 'Vous suivez maintenant cette course'
      });
    } catch (error) {
      recordWebSocketError(error);
      logger.error('Erreur join ride', { error: error.message, clientId, rideId });
      socket.emit('error', {
        type: 'join_error',
        message: 'Erreur lors de la connexion à la course'
      });
    }
  });

  // Le client quitte la room de sa course
  socket.on('ride:leave', (rideId) => {
    socket.leave(`ride:${rideId}`);
    logger.info('Client a quitté la course', { clientId, rideId });
  });

  // Gérer les messages ping (keep-alive)
  socket.on('ping', () => {
    socket.emit('pong', { type: 'pong' });
  });

  // Gérer les déconnexions
  socket.on('disconnect', () => {
    logger.info('Client déconnecté', { clientId });
  });

  // Gérer les erreurs
  socket.on('error', (error) => {
    recordWebSocketError(error);
    logger.error('Erreur WebSocket client', { clientId, error: error.message });
  });
});

// Initialiser le service de communication temps réel pour les courses
// DOIT être initialisé APRÈS la définition de driverNamespace
const RealtimeRideService = require('./modules/rides/realtimeService');
let realtimeRideService = null;

// Initialiser le service après la connexion à la base de données
function initializeRealtimeService() {
  if (!realtimeRideService) {
    realtimeRideService = new RealtimeRideService(io, driverNamespace, clientNamespace);
    realtimeRideService.initialize();
    
    // Nettoyer les courses expirées toutes les 5 minutes
    setInterval(() => {
      if (realtimeRideService) {
        realtimeRideService.cleanupExpiredRides();
      }
    }, 5 * 60 * 1000);
    
    logger.info('Service temps réel des courses initialisé');
  }
  return realtimeRideService;
}

// Fonction utilitaire pour notifier tous les conducteurs disponibles d'une nouvelle course
async function notifyAvailableDrivers(ride) {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const fullRide = await rideRepository.findOne({
      where: { id: ride.id },
      relations: ['client']
    });

    if (!fullRide) {
      return;
    }

    const rideData = {
      type: 'ride_request',
      ride: {
        id: fullRide.id.toString(),
        pickupAddress: fullRide.pickupAddress,
        dropoffAddress: fullRide.dropoffAddress,
        pickupLatitude: fullRide.pickupLocation.coordinates[1],
        pickupLongitude: fullRide.pickupLocation.coordinates[0],
        dropoffLatitude: fullRide.dropoffLocation.coordinates[1],
        dropoffLongitude: fullRide.dropoffLocation.coordinates[0],
        estimatedDistance: fullRide.distance || 0,
        estimatedDuration: fullRide.estimatedDuration || 0,
        estimatedEarnings: fullRide.estimatedPrice || 0,
        passengerName: fullRide.client?.name || null,
        createdAt: fullRide.createdAt.toISOString()
      }
    };

    // Envoyer à tous les conducteurs connectés dans le namespace
    driverNamespace.emit('ride_request', rideData);
    recordWebSocketMessage();
    logger.info('Notification de course envoyée à tous les conducteurs', { rideId: ride.id });
  } catch (error) {
    recordWebSocketError(error);
    logger.error('Erreur lors de la notification des conducteurs', { error: error.message, rideId: ride.id });
  }
}

// Initialiser l'agent principal backend
const BackendAgentPrincipal = require('./services/BackendAgentPrincipal');
const { getRedisService } = require('./services/RedisService');
let backendAgent = null;
let redisService = null;

function initializeBackendAgent() {
  if (!backendAgent) {
    backendAgent = new BackendAgentPrincipal(io, driverNamespace, clientNamespace);
    logger.info('Agent principal backend initialisé');
  }
  
  // Toujours essayer de définir le service temps réel (au cas où il serait initialisé après)
  if (realtimeRideService) {
    backendAgent.setRealtimeService(realtimeRideService);
  }
  
  return backendAgent;
}

// Initialiser le service de diffusion des positions
const DriverLocationBroadcaster = require('./services/DriverLocationBroadcaster');
let driverLocationBroadcaster = null;

function initializeDriverLocationBroadcaster() {
  if (!driverLocationBroadcaster) {
    // Vérifier que les dépendances sont disponibles
    if (!redisService) {
      redisService = getRedisService();
    }
    
    if (!redisService || !clientNamespace) {
      logger.warn('DriverLocationBroadcaster non initialisé (dépendances manquantes)', {
        hasRedis: !!redisService,
        hasClientNamespace: !!clientNamespace
      });
      return null;
    }
    
    // Vérifier que Redis est prêt
    if (!redisService.isReady()) {
      logger.warn('DriverLocationBroadcaster non initialisé (Redis non prêt)');
      return null;
    }
    
    driverLocationBroadcaster = new DriverLocationBroadcaster(
      io,
      clientNamespace,
      redisService
    );
    
    // Démarrer la diffusion automatique (toutes les 2 secondes)
    driverLocationBroadcaster.start(2000);
    
    logger.info('DriverLocationBroadcaster initialisé et démarré', {
      intervalMs: 2000
    });
  }
  return driverLocationBroadcaster;
}

// Exporter les éléments nécessaires pour les routes
module.exports.app = app;
module.exports.io = io;
module.exports.driverNamespace = driverNamespace;
module.exports.clientNamespace = clientNamespace;
module.exports.AppDataSource = AppDataSource;
module.exports.notifyAvailableDrivers = notifyAvailableDrivers;

// Exporter une fonction pour obtenir le service temps réel (lazy initialization)
module.exports.getRealtimeRideService = () => {
  if (!realtimeRideService) {
    return initializeRealtimeService();
  }
  return realtimeRideService;
};

// Exporter l'agent principal backend
module.exports.getBackendAgent = () => {
  if (!backendAgent) {
    return initializeBackendAgent();
  }
  return backendAgent;
};
module.exports.BackendAgentPrincipal = BackendAgentPrincipal;

// Exporter le service Redis
module.exports.getRedisService = () => {
  if (!redisService) {
    redisService = getRedisService();
  }
  return redisService;
};

// Exporter le service de diffusion des positions
module.exports.getDriverLocationBroadcaster = () => {
  if (!driverLocationBroadcaster) {
    return initializeDriverLocationBroadcaster();
  }
  return driverLocationBroadcaster;
};

// Initialiser TypeORM et démarrer le serveur
AppDataSource.initialize()
  .then(async () => {
    logger.info('Connecté à PostgreSQL avec PostGIS');
    
    // Vérifier que PostGIS est activé
    const postgisResult = await AppDataSource.query("SELECT PostGIS_version();");
    logger.info('PostGIS version', { version: postgisResult[0].postgis_version });
    
    // Note: La colonne 'name' doit être ajoutée manuellement via SQL
    // Exécutez: ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255);
    
    // Initialiser le service temps réel après la connexion à la base de données
    initializeRealtimeService();
    
    // Initialiser Redis
    redisService = getRedisService();
    redisService.connect()
      .then(() => {
        logger.info('Redis connecté avec succès');
        // Démarrer le broadcaster après connexion Redis
        initializeDriverLocationBroadcaster();
      })
      .catch((error) => {
        logger.error('Erreur connexion Redis', { error: error.message });
        // Essayer de démarrer quand même après un délai (mode dégradé)
        setTimeout(() => {
          if (redisService && redisService.isReady()) {
            initializeDriverLocationBroadcaster();
          } else {
            logger.warn('DriverLocationBroadcaster non démarré (Redis non disponible)');
          }
        }, 10000); // Attendre 10 secondes avant de réessayer
      });
    
    // Initialiser l'agent principal backend (après le service temps réel)
    // L'agent récupérera automatiquement le service temps réel
    initializeBackendAgent();
    
    const PORT = process.env.PORT || 8080; // Render utilise PORT automatiquement, 8080 par défaut
    const HOST = process.env.HOST || '0.0.0.0'; // Écouter sur toutes les interfaces pour Cloud Run
    server.listen(PORT, HOST, () => {
      logger.info('Serveur démarré', {
        port: PORT,
        host: HOST,
        env: process.env.NODE_ENV || 'development',
      });
      logger.info('WebSocket namespaces disponibles', {
        driver: '/ws/driver',
        client: '/ws/client',
      });
      logger.info('API disponible', { url: `http://${HOST}:${PORT}/api` });
    });
  })
  .catch((error) => {
    logger.error('Erreur de connexion PostgreSQL', { error: error.message, stack: error.stack });
    process.exit(1);
  });

// L'export final inclut getRealtimeRideService qui est déjà défini ligne 372
// Ne pas réécrire module.exports ici car cela écraserait les exports précédents
// Les exports sont déjà définis ligne 372: module.exports.getRealtimeRideService

