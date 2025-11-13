//
//  cloud-monitoring.js
//  Tshiakani VTC
//
//  Configuration Cloud Monitoring pour GCP
//  Envoie les métriques personnalisées à Cloud Monitoring
//

const { MonitoringServiceV2Client } = require('@google-cloud/monitoring');
const logger = require('./logger');

/**
 * Service Cloud Monitoring pour GCP
 */
class CloudMonitoringService {
  constructor() {
    this.client = null;
    this.projectId = null;
    this.projectPath = null;
    this.isInitialized = false;

    // Initialiser seulement si on est sur GCP
    if (process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT) {
      this.initialize();
    }
  }

  /**
   * Initialise le service Cloud Monitoring
   */
  initialize() {
    try {
      this.projectId = process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
      
      if (!this.projectId) {
        logger.warn('Cloud Monitoring non initialisé: GCP_PROJECT_ID non défini');
        return;
      }

      this.client = new MonitoringServiceV2Client();
      this.projectPath = this.client.projectPath(this.projectId);

      this.isInitialized = true;
      logger.info('Cloud Monitoring initialisé', { projectId: this.projectId });
    } catch (error) {
      logger.error('Erreur initialisation Cloud Monitoring', {
        error: error.message,
        stack: error.stack
      });
      this.isInitialized = false;
    }
  }

  /**
   * Envoie une métrique de time series à Cloud Monitoring
   * @param {string} metricType - Type de métrique (ex: custom.googleapis.com/api/latency)
   * @param {number} value - Valeur de la métrique
   * @param {Object} labels - Labels de la métrique
   * @param {Date} timestamp - Timestamp (optionnel, défaut: maintenant)
   */
  async writeTimeSeries(metricType, value, labels = {}, timestamp = new Date()) {
    if (!this.isInitialized || !this.client) {
      return;
    }

    try {
      const dataPoint = {
        interval: {
          endTime: {
            seconds: Math.floor(timestamp.getTime() / 1000),
            nanos: (timestamp.getTime() % 1000) * 1000000
          },
          startTime: {
            seconds: Math.floor(timestamp.getTime() / 1000),
            nanos: (timestamp.getTime() % 1000) * 1000000
          }
        },
        value: {
          doubleValue: value
        }
      };

      const timeSeries = {
        metric: {
          type: metricType,
          labels: {
            service: process.env.K_SERVICE || 'tshiakani-vtc-backend',
            environment: process.env.NODE_ENV || 'production',
            ...labels
          }
        },
        resource: {
          type: 'cloud_run_revision',
          labels: {
            service_name: process.env.K_SERVICE || 'tshiakani-vtc-backend',
            revision_name: process.env.K_REVISION || 'unknown',
            location: process.env.GCP_REGION || 'us-central1',
            project_id: this.projectId
          }
        },
        points: [dataPoint]
      };

      const request = {
        name: this.projectPath,
        timeSeries: [timeSeries]
      };

      await this.client.createTimeSeries(request);
    } catch (error) {
      logger.error('Erreur envoi métrique Cloud Monitoring', {
        error: error.message,
        metricType,
        value
      });
    }
  }

  /**
   * Enregistre la latence de l'API
   * @param {string} endpoint - Endpoint de l'API
   * @param {number} latencyMs - Latence en millisecondes
   * @param {number} statusCode - Code de statut HTTP
   */
  async recordApiLatency(endpoint, latencyMs, statusCode = 200) {
    await this.writeTimeSeries(
      'custom.googleapis.com/api/latency',
      latencyMs,
      {
        endpoint: endpoint,
        method: 'GET', // À améliorer pour capturer la méthode HTTP
        status_code: statusCode.toString()
      }
    );
  }

  /**
   * Enregistre le nombre de requêtes
   * @param {string} endpoint - Endpoint de l'API
   * @param {number} statusCode - Code de statut HTTP
   */
  async recordApiRequest(endpoint, statusCode = 200) {
    await this.writeTimeSeries(
      'custom.googleapis.com/api/requests',
      1,
      {
        endpoint: endpoint,
        status_code: statusCode.toString()
      }
    );
  }

  /**
   * Enregistre une erreur
   * @param {string} errorType - Type d'erreur (payment_error, matching_error, etc.)
   * @param {string} errorMessage - Message d'erreur
   */
  async recordError(errorType, errorMessage) {
    await this.writeTimeSeries(
      'custom.googleapis.com/errors/count',
      1,
      {
        error_type: errorType,
        error_message: errorMessage.substring(0, 100) // Limiter la longueur
      }
    );
  }

  /**
   * Enregistre une métrique de paiement
   * @param {string} eventType - Type d'événement (success, failure, etc.)
   * @param {number} amount - Montant
   * @param {string} currency - Devise
   */
  async recordPaymentEvent(eventType, amount = 0, currency = 'CDF') {
    await this.writeTimeSeries(
      'custom.googleapis.com/payments/count',
      1,
      {
        event_type: eventType,
        currency: currency
      }
    );

    if (amount > 0) {
      await this.writeTimeSeries(
        'custom.googleapis.com/payments/amount',
        amount,
        {
          event_type: eventType,
          currency: currency
        }
      );
    }
  }

  /**
   * Enregistre une métrique de matching
   * @param {string} eventType - Type d'événement (success, failure, timeout)
   * @param {number} driverCount - Nombre de conducteurs trouvés
   * @param {number} score - Score du meilleur conducteur
   */
  async recordMatchingEvent(eventType, driverCount = 0, score = 0) {
    await this.writeTimeSeries(
      'custom.googleapis.com/matching/count',
      1,
      {
        event_type: eventType
      }
    );

    if (driverCount > 0) {
      await this.writeTimeSeries(
        'custom.googleapis.com/matching/driver_count',
        driverCount,
        {
          event_type: eventType
        }
      );
    }

    if (score > 0) {
      await this.writeTimeSeries(
        'custom.googleapis.com/matching/score',
        score,
        {
          event_type: eventType
        }
      );
    }
  }

  /**
   * Enregistre une métrique de course
   * @param {string} eventType - Type d'événement (created, completed, cancelled)
   * @param {number} distance - Distance en km
   * @param {number} price - Prix en CDF
   */
  async recordRideEvent(eventType, distance = 0, price = 0) {
    await this.writeTimeSeries(
      'custom.googleapis.com/rides/count',
      1,
      {
        event_type: eventType
      }
    );

    if (distance > 0) {
      await this.writeTimeSeries(
        'custom.googleapis.com/rides/distance',
        distance,
        {
          event_type: eventType
        }
      );
    }

    if (price > 0) {
      await this.writeTimeSeries(
        'custom.googleapis.com/rides/price',
        price,
        {
          event_type: eventType
        }
      );
    }
  }
}

// Singleton
let cloudMonitoringServiceInstance = null;

/**
 * Obtenir l'instance unique du service Cloud Monitoring
 * @returns {CloudMonitoringService} Instance du service Cloud Monitoring
 */
function getCloudMonitoringService() {
  if (!cloudMonitoringServiceInstance) {
    cloudMonitoringServiceInstance = new CloudMonitoringService();
  }
  return cloudMonitoringServiceInstance;
}

module.exports = {
  CloudMonitoringService,
  getCloudMonitoringService
};

