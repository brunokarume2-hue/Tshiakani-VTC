// Métriques de performance et monitoring
const logger = require('./logger');

// Stockage des métriques en mémoire (à remplacer par Prometheus/StatsD en production)
const metrics = {
  requests: {
    total: 0,
    byMethod: {},
    byStatus: {},
    byRoute: {},
  },
  responseTime: {
    min: Infinity,
    max: 0,
    sum: 0,
    count: 0,
    average: 0,
  },
  errors: {
    total: 0,
    byType: {},
    byRoute: {},
  },
  database: {
    queries: 0,
    slowQueries: 0,
    errors: 0,
  },
  websocket: {
    connections: 0,
    messages: 0,
    errors: 0,
  },
};

// Middleware pour collecter les métriques
function metricsMiddleware(req, res, next) {
  const start = Date.now();
  const route = req.route ? req.route.path : req.path;
  
  // Incrémenter le compteur de requêtes
  metrics.requests.total++;
  metrics.requests.byMethod[req.method] = (metrics.requests.byMethod[req.method] || 0) + 1;
  metrics.requests.byRoute[route] = (metrics.requests.byRoute[route] || 0) + 1;
  
  // Capturer la réponse
  res.on('finish', () => {
    const duration = Date.now() - start;
    
    // Mettre à jour les métriques de temps de réponse
    metrics.responseTime.count++;
    metrics.responseTime.sum += duration;
    metrics.responseTime.min = Math.min(metrics.responseTime.min, duration);
    metrics.responseTime.max = Math.max(metrics.responseTime.max, duration);
    metrics.responseTime.average = metrics.responseTime.sum / metrics.responseTime.count;
    
    // Mettre à jour les métriques par statut
    const status = res.statusCode;
    metrics.requests.byStatus[status] = (metrics.requests.byStatus[status] || 0) + 1;
    
    // Log des requêtes lentes (> 1 seconde)
    if (duration > 1000) {
      logger.warn(`Requête lente détectée: ${req.method} ${req.originalUrl} - ${duration}ms`);
    }
    
    // Log des erreurs
    if (status >= 400) {
      metrics.errors.total++;
      metrics.errors.byRoute[route] = (metrics.errors.byRoute[route] || 0) + 1;
      metrics.errors.byType[status] = (metrics.errors.byType[status] || 0) + 1;
    }
  });
  
  next();
}

// Fonction pour obtenir les métriques
function getMetrics() {
  return {
    ...metrics,
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString(),
  };
}

// Fonction pour réinitialiser les métriques
function resetMetrics() {
  metrics.requests = {
    total: 0,
    byMethod: {},
    byStatus: {},
    byRoute: {},
  };
  metrics.responseTime = {
    min: Infinity,
    max: 0,
    sum: 0,
    count: 0,
    average: 0,
  };
  metrics.errors = {
    total: 0,
    byType: {},
    byRoute: {},
  };
  metrics.database = {
    queries: 0,
    slowQueries: 0,
    errors: 0,
  };
  metrics.websocket = {
    connections: 0,
    messages: 0,
    errors: 0,
  };
}

// Fonction pour enregistrer une requête de base de données
function recordDatabaseQuery(duration) {
  metrics.database.queries++;
  if (duration > 100) {
    metrics.database.slowQueries++;
    logger.warn(`Requête DB lente: ${duration}ms`);
  }
}

// Fonction pour enregistrer une erreur de base de données
function recordDatabaseError(error) {
  metrics.database.errors++;
  logger.error('Erreur DB', { error: error.message });
}

// Fonction pour enregistrer une connexion WebSocket
function recordWebSocketConnection() {
  metrics.websocket.connections++;
}

// Fonction pour enregistrer un message WebSocket
function recordWebSocketMessage() {
  metrics.websocket.messages++;
}

// Fonction pour enregistrer une erreur WebSocket
function recordWebSocketError(error) {
  metrics.websocket.errors++;
  logger.error('Erreur WebSocket', { error: error.message });
}

module.exports = {
  metricsMiddleware,
  getMetrics,
  resetMetrics,
  recordDatabaseQuery,
  recordDatabaseError,
  recordWebSocketConnection,
  recordWebSocketMessage,
  recordWebSocketError,
};

