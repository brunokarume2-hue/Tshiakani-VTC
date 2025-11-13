// Classes d'erreur personnalisées
const logger = require('./logger');

// Classe de base pour les erreurs personnalisées
class AppError extends Error {
  constructor(message, statusCode, code = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code || this.constructor.name;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

// Erreur de validation
class ValidationError extends AppError {
  constructor(message, errors = []) {
    super(message, 400, 'VALIDATION_ERROR');
    this.errors = errors;
  }
}

// Erreur d'authentification
class AuthenticationError extends AppError {
  constructor(message = 'Authentification requise') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

// Erreur d'autorisation
class AuthorizationError extends AppError {
  constructor(message = 'Accès non autorisé') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

// Erreur de ressource non trouvée
class NotFoundError extends AppError {
  constructor(resource = 'Ressource') {
    super(`${resource} non trouvé(e)`, 404, 'NOT_FOUND');
  }
}

// Erreur de conflit
class ConflictError extends AppError {
  constructor(message = 'Conflit de ressources') {
    super(message, 409, 'CONFLICT_ERROR');
  }
}

// Erreur de géofencing
class GeofencingError extends AppError {
  constructor(message = 'Position hors zone autorisée') {
    super(message, 400, 'GEOFENCING_ERROR');
  }
}

// Erreur de service externe
class ExternalServiceError extends AppError {
  constructor(service, message = 'Erreur du service externe') {
    super(`${service}: ${message}`, 502, 'EXTERNAL_SERVICE_ERROR');
    this.service = service;
  }
}

// Erreur de base de données
class DatabaseError extends AppError {
  constructor(message = 'Erreur de base de données') {
    super(message, 500, 'DATABASE_ERROR');
  }
}

// Format d'erreur pour la réponse API
function formatError(error, req) {
  const isDevelopment = process.env.NODE_ENV === 'development';
  
  const formatted = {
    success: false,
    error: {
      code: error.code || 'INTERNAL_ERROR',
      message: error.message || 'Une erreur est survenue',
      ...(isDevelopment && { stack: error.stack }),
      ...(error.errors && { errors: error.errors }),
      ...(error.service && { service: error.service }),
    },
    timestamp: new Date().toISOString(),
    path: req.originalUrl,
    method: req.method,
  };
  
  return formatted;
}

// Middleware de gestion d'erreurs
function errorHandler(err, req, res, next) {
  // Enregistrer l'erreur dans Cloud Logging et Monitoring (si disponible)
  if (process.env.NODE_ENV === 'production' && (process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT)) {
    try {
      const { getCloudLoggingService } = require('./cloud-logging');
      const { getCloudMonitoringService } = require('./cloud-monitoring');
      const cloudLogging = getCloudLoggingService();
      const cloudMonitoring = getCloudMonitoringService();
      
      // Déterminer le type d'erreur
      const errorType = err.code || 'unknown_error';
      const isPaymentError = errorType.includes('PAYMENT') || err.message.includes('paiement') || err.message.includes('payment');
      const isMatchingError = errorType.includes('MATCHING') || err.message.includes('conducteur') || err.message.includes('driver') || err.message.includes('matching');
      
      // Enregistrer dans Cloud Logging
      if (isPaymentError) {
        cloudLogging.logPaymentError({
          rideId: req.body?.rideId || req.params?.rideId || null,
          amount: req.body?.amount || 0,
          currency: req.body?.currency || 'CDF',
          method: req.body?.paymentMethod || 'unknown'
        }, err, {
          requestMethod: req.method,
          requestUrl: req.originalUrl || req.url,
          status: err.statusCode || 500
        });
      } else if (isMatchingError) {
        cloudLogging.logMatchingError({
          rideId: req.body?.rideId || req.params?.rideId || null,
          clientId: req.user?.id || null,
          pickupLocation: req.body?.pickupLocation,
          dropoffLocation: req.body?.dropoffLocation
        }, err, {
          requestMethod: req.method,
          requestUrl: req.originalUrl || req.url,
          status: err.statusCode || 500
        });
      } else {
        cloudLogging.error(err.message || 'Erreur inconnue', {
          error: {
            message: err.message,
            code: err.code,
            stack: err.stack
          },
          request: {
            method: req.method,
            url: req.originalUrl || req.url,
            userId: req.user?.id || null
          }
        }, {
          requestMethod: req.method,
          requestUrl: req.originalUrl || req.url,
          status: err.statusCode || 500
        });
      }
      
      // Enregistrer dans Cloud Monitoring
      cloudMonitoring.recordError(errorType, err.message);
      
      if (isPaymentError) {
        cloudMonitoring.recordPaymentEvent('failure', req.body?.amount || 0, req.body?.currency || 'CDF');
      } else if (isMatchingError) {
        cloudMonitoring.recordMatchingEvent('failure', 0, 0);
      }
    } catch (monitoringError) {
      // Ne pas faire échouer la requête si le monitoring échoue
      logger.error('Erreur enregistrement monitoring', {
        error: monitoringError.message
      });
    }
  }
  
  // Log de l'erreur
  if (err.isOperational) {
    logger.warn(`${err.code}: ${err.message}`, {
      statusCode: err.statusCode,
      path: req.originalUrl,
      method: req.method,
      stack: err.stack,
    });
  } else {
    logger.error('Erreur non opérationnelle', {
      error: err.message,
      stack: err.stack,
      path: req.originalUrl,
      method: req.method,
    });
  }
  
  // Format de l'erreur
  const errorResponse = formatError(err, req);
  
  // Réponse avec le statut approprié
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json(errorResponse);
}

// Wrapper pour les routes async
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  GeofencingError,
  ExternalServiceError,
  DatabaseError,
  formatError,
  errorHandler,
  asyncHandler,
};

