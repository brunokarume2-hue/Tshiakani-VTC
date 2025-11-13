//
//  monitoring.js
//  Tshiakani VTC
//
//  Middleware de monitoring pour les requêtes HTTP
//  Enregistre les métriques de performance et les logs
//

const { getCloudLoggingService } = require('../utils/cloud-logging');
const { getCloudMonitoringService } = require('../utils/cloud-monitoring');
const logger = require('../utils/logger');

/**
 * Middleware pour enregistrer les métriques de performance
 */
function monitoringMiddleware(req, res, next) {
  const startTime = Date.now();
  const startMemory = process.memoryUsage();

  // Capturer la réponse
  const originalSend = res.send;
  res.send = function(data) {
    res.send = originalSend;
    
    const responseTime = Date.now() - startTime;
    const endMemory = process.memoryUsage();
    const memoryDelta = endMemory.heapUsed - startMemory.heapUsed;

    // Enregistrer les métriques
    recordMetrics(req, res, responseTime, memoryDelta);

    // Envoyer la réponse
    return res.send(data);
  };

  next();
}

/**
 * Enregistre les métriques pour une requête
 */
async function recordMetrics(req, res, responseTime, memoryDelta) {
  try {
    const cloudLogging = getCloudLoggingService();
    const cloudMonitoring = getCloudMonitoringService();

    // Extraire l'endpoint
    const endpoint = req.originalUrl || req.url;
    const method = req.method;

    // Enregistrer la latence
    await cloudMonitoring.recordApiLatency(endpoint, responseTime, res.statusCode);

    // Enregistrer la requête
    await cloudMonitoring.recordApiRequest(endpoint, res.statusCode);

    // Enregistrer le log HTTP
    await cloudLogging.logHttpRequest(req, res, responseTime);

    // Enregistrer les erreurs
    if (res.statusCode >= 500) {
      await cloudMonitoring.recordError('http_error', `${method} ${endpoint} - ${res.statusCode}`);
    } else if (res.statusCode >= 400) {
      await cloudMonitoring.recordError('client_error', `${method} ${endpoint} - ${res.statusCode}`);
    }

    // Logger les métriques de performance
    logger.debug('Métriques de performance enregistrées', {
      endpoint,
      method,
      responseTime,
      statusCode: res.statusCode,
      memoryDelta
    });
  } catch (error) {
    // Ne pas faire échouer la requête si le monitoring échoue
    logger.error('Erreur enregistrement métriques', {
      error: error.message
    });
  }
}

module.exports = {
  monitoringMiddleware
};

