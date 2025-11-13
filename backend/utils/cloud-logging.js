//
//  cloud-logging.js
//  Tshiakani VTC
//
//  Configuration Cloud Logging pour GCP
//  Envoie les logs structurés à Cloud Logging
//

const { Logging } = require('@google-cloud/logging');
const logger = require('./logger');

/**
 * Service Cloud Logging pour GCP
 */
class CloudLoggingService {
  constructor() {
    this.logging = null;
    this.log = null;
    this.isInitialized = false;

    // Initialiser seulement si on est sur GCP
    if (process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT) {
      this.initialize();
    }
  }

  /**
   * Initialise le service Cloud Logging
   */
  initialize() {
    try {
      const projectId = process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
      
      if (!projectId) {
        logger.warn('Cloud Logging non initialisé: GCP_PROJECT_ID non défini');
        return;
      }

      this.logging = new Logging({
        projectId: projectId
      });

      // Créer ou récupérer le log
      const logName = process.env.CLOUD_LOGGING_LOG_NAME || 'tshiakani-vtc-backend';
      this.log = this.logging.log(logName);

      this.isInitialized = true;
      logger.info('Cloud Logging initialisé', { projectId, logName });
    } catch (error) {
      logger.error('Erreur initialisation Cloud Logging', {
        error: error.message,
        stack: error.stack
      });
      this.isInitialized = false;
    }
  }

  /**
   * Envoie un log structuré à Cloud Logging
   * @param {string} severity - Niveau de sévérité (DEBUG, INFO, WARNING, ERROR, CRITICAL)
   * @param {string} message - Message du log
   * @param {Object} metadata - Métadonnées additionnelles
   * @param {Object} httpRequest - Informations de requête HTTP (optionnel)
   */
  async writeLog(severity, message, metadata = {}, httpRequest = null) {
    if (!this.isInitialized || !this.log) {
      // Si Cloud Logging n'est pas initialisé, utiliser le logger local
      const logLevel = severity.toLowerCase();
      if (logger[logLevel]) {
        logger[logLevel](message, metadata);
      }
      return;
    }

    try {
      // Préparer les métadonnées (sans httpRequest pour éviter la duplication)
      const entryMetadata = {
        severity: severity,
        resource: {
          type: 'cloud_run_revision',
          labels: {
            service_name: process.env.K_SERVICE || 'tshiakani-vtc-backend',
            revision_name: process.env.K_REVISION || 'unknown',
            location: process.env.GCP_REGION || process.env.REGION || 'us-central1',
            project_id: process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT
          }
        },
        labels: {
          environment: process.env.NODE_ENV || 'production',
          version: process.env.K_REVISION || 'unknown'
        },
        ...metadata
      };

      // Ajouter httpRequest si fourni
      if (httpRequest) {
        entryMetadata.httpRequest = httpRequest;
      }

      const entry = this.log.entry(entryMetadata, message);

      await this.log.write(entry);
    } catch (error) {
      // En cas d'erreur, utiliser le logger local (mode silencieux en production)
      if (process.env.NODE_ENV === 'development') {
        logger.error('Erreur envoi log Cloud Logging', {
          error: error.message,
          originalMessage: message
        });
      }
    }
  }

  /**
   * Log d'erreur critique
   */
  async error(message, metadata = {}, httpRequest = null) {
    await this.writeLog('ERROR', message, metadata, httpRequest);
  }

  /**
   * Log d'avertissement
   */
  async warning(message, metadata = {}, httpRequest = null) {
    await this.writeLog('WARNING', message, metadata, httpRequest);
  }

  /**
   * Log d'information
   */
  async info(message, metadata = {}, httpRequest = null) {
    await this.writeLog('INFO', message, metadata, httpRequest);
  }

  /**
   * Log de débogage
   */
  async debug(message, metadata = {}, httpRequest = null) {
    await this.writeLog('DEBUG', message, metadata, httpRequest);
  }

  /**
   * Log d'erreur de paiement
   */
  async logPaymentError(paymentData, error, httpRequest = null) {
    await this.error('Échec de paiement', {
      payment: {
        rideId: paymentData.rideId,
        amount: paymentData.amount,
        currency: paymentData.currency,
        method: paymentData.method
      },
      error: {
        message: error.message,
        code: error.code,
        stack: error.stack
      },
      timestamp: new Date().toISOString()
    }, httpRequest);
  }

  /**
   * Log d'échec de matching
   */
  async logMatchingError(rideData, error, httpRequest = null) {
    await this.error('Échec de matching de conducteur', {
      ride: {
        rideId: rideData.rideId,
        clientId: rideData.clientId,
        pickupLocation: rideData.pickupLocation,
        dropoffLocation: rideData.dropoffLocation
      },
      error: {
        message: error.message,
        stack: error.stack
      },
      timestamp: new Date().toISOString()
    }, httpRequest);
  }

  /**
   * Log de métrique de performance
   */
  async logPerformanceMetric(metricName, value, metadata = {}) {
    await this.info(`Métrique de performance: ${metricName}`, {
      metric: {
        name: metricName,
        value: value,
        unit: metadata.unit || 'ms',
        ...metadata
      },
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Log de requête HTTP
   */
  async logHttpRequest(req, res, responseTime) {
    const httpRequest = {
      requestMethod: req.method,
      requestUrl: req.originalUrl || req.url,
      requestSize: req.headers['content-length'] || 0,
      status: res.statusCode,
      responseSize: res.get('content-length') || 0,
      userAgent: req.headers['user-agent'],
      remoteIp: req.ip || req.connection.remoteAddress,
      latency: `${responseTime / 1000}s`,
      protocol: req.protocol
    };

    const severity = res.statusCode >= 500 ? 'ERROR' : 
                    res.statusCode >= 400 ? 'WARNING' : 'INFO';

    await this.writeLog(severity, `${req.method} ${req.originalUrl || req.url}`, {
      httpRequest: httpRequest,
      userId: req.user?.id || null,
      userRole: req.user?.role || null
    }, httpRequest);
  }
}

// Singleton
let cloudLoggingServiceInstance = null;

/**
 * Obtenir l'instance unique du service Cloud Logging
 * @returns {CloudLoggingService} Instance du service Cloud Logging
 */
function getCloudLoggingService() {
  if (!cloudLoggingServiceInstance) {
    cloudLoggingServiceInstance = new CloudLoggingService();
  }
  return cloudLoggingServiceInstance;
}

module.exports = {
  CloudLoggingService,
  getCloudLoggingService
};

