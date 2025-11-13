//
//  RedisService.js
//  Tshiakani VTC
//
//  Service Redis pour le suivi temps réel des conducteurs
//  Supporte Upstash Redis (gratuit) et Redis local/Memorystore
//

const redis = require('redis');
const logger = require('../utils/logger');

/**
 * Service Redis pour le suivi temps réel des conducteurs
 */
class RedisService {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 10;
  }

  /**
   * Initialise la connexion Redis
   * Supporte Upstash Redis (via REDIS_URL) et Redis local/Memorystore (via REDIS_HOST)
   */
  async connect() {
    try {
      let redisConfig;
      
      // Priorité 1: Upstash Redis (REDIS_URL)
      if (process.env.REDIS_URL) {
        logger.info('Using Upstash Redis (REDIS_URL)');
        // Upstash Redis utilise rediss:// (avec TLS) ou redis://
        // Le client Redis détecte automatiquement TLS depuis l'URL
        redisConfig = {
          url: process.env.REDIS_URL,
          socket: {
            reconnectStrategy: (retries) => {
              if (retries > this.maxReconnectAttempts) {
                logger.error('Max reconnection attempts reached');
                return new Error('Max reconnection attempts reached');
              }
              const delay = Math.min(retries * 100, 3000);
              logger.info(`Reconnecting to Redis in ${delay}ms (attempt ${retries})`);
              return delay;
            },
            connectTimeout: parseInt(process.env.REDIS_CONNECT_TIMEOUT) || 10000,
            keepAlive: true
          }
        };
      } 
      // Priorité 2: Redis Local ou Memorystore (REDIS_HOST)
      else {
        logger.info('Using Redis Local/Memorystore (REDIS_HOST)');
        redisConfig = {
          host: process.env.REDIS_HOST || 'localhost',
          port: parseInt(process.env.REDIS_PORT) || 6379,
          password: process.env.REDIS_PASSWORD || undefined,
          socket: {
            reconnectStrategy: (retries) => {
              if (retries > this.maxReconnectAttempts) {
                logger.error('Max reconnection attempts reached');
                return new Error('Max reconnection attempts reached');
              }
              const delay = Math.min(retries * 100, 3000);
              logger.info(`Reconnecting to Redis in ${delay}ms (attempt ${retries})`);
              return delay;
            },
            connectTimeout: parseInt(process.env.REDIS_CONNECT_TIMEOUT) || 10000,
            keepAlive: true
          },
          // Désactiver les commandes non autorisées (pour Memorystore)
          disableClientInfo: true
        };
      }

      // Créer le client Redis
      this.client = redis.createClient(redisConfig);

      // Gestionnaires d'événements
      this.client.on('error', (error) => {
        logger.error('Redis client error', { error: error.message });
        this.isConnected = false;
      });

      this.client.on('connect', () => {
        logger.info('Redis client connecting...');
      });

      this.client.on('ready', () => {
        logger.info('Redis client ready');
        this.isConnected = true;
        this.reconnectAttempts = 0;
      });

      this.client.on('reconnecting', () => {
        this.reconnectAttempts++;
        logger.info(`Redis client reconnecting (attempt ${this.reconnectAttempts})`);
      });

      this.client.on('end', () => {
        logger.warn('Redis client connection ended');
        this.isConnected = false;
      });

      // Se connecter
      await this.client.connect();

      // Tester la connexion
      await this.client.ping();
      
      // Logger les informations de connexion
      if (process.env.REDIS_URL) {
        // Masquer le token dans les logs
        const maskedUrl = process.env.REDIS_URL.replace(/:[^:@]+@/, ':****@');
        logger.info('Redis connected successfully (Upstash)', {
          url: maskedUrl
        });
      } else {
        logger.info('Redis connected successfully (Local/Memorystore)', {
          host: redisConfig.host,
          port: redisConfig.port
        });
      }

      return true;
    } catch (error) {
      logger.error('Failed to connect to Redis', {
        error: error.message,
        stack: error.stack
      });
      this.isConnected = false;
      throw error;
    }
  }

  /**
   * Déconnecte le client Redis
   */
  async disconnect() {
    try {
      if (this.client && this.isConnected) {
        await this.client.quit();
        this.isConnected = false;
        logger.info('Redis disconnected');
      }
    } catch (error) {
      logger.error('Error disconnecting Redis', { error: error.message });
    }
  }

  /**
   * Vérifie si Redis est connecté
   */
  isReady() {
    // Vérifier si le client existe et est ouvert
    const clientReady = this.client && (this.client.isOpen || this.client.isReady || this.isConnected);
    return clientReady;
  }

  /**
   * ==================== GESTION DES CONDUCTEURS ====================
   */

  /**
   * Met à jour la position d'un conducteur
   * @param {number} driverId - ID du conducteur
   * @param {Object} locationData - Données de localisation
   * @param {number} locationData.latitude - Latitude
   * @param {number} locationData.longitude - Longitude
   * @param {string} locationData.status - Statut: 'available', 'en_route_to_pickup', 'in_progress', 'offline'
   * @param {number} locationData.currentRideId - ID de la course actuelle (optionnel)
   * @param {number} locationData.heading - Direction en degrés (optionnel)
   * @param {number} locationData.speed - Vitesse en km/h (optionnel)
   * @returns {Promise<boolean>} Succès
   */
  async updateDriverLocation(driverId, locationData) {
    try {
      if (!this.isReady()) {
        throw new Error('Redis is not connected');
      }

      const key = `driver:${driverId}`;
      const timestamp = new Date().toISOString();

      // Préparer les données à stocker
      const driverData = {
        lat: locationData.latitude.toString(),
        lon: locationData.longitude.toString(),
        status: locationData.status || 'available',
        last_update: timestamp,
        current_ride_id: locationData.currentRideId ? locationData.currentRideId.toString() : '',
        heading: locationData.heading ? locationData.heading.toString() : '0',
        speed: locationData.speed ? locationData.speed.toString() : '0'
      };

      // OPTIMISATION: Utiliser pipeline pour hSet et expire en une seule transaction
      const pipeline = this.client.multi();
      pipeline.hSet(key, driverData);
      pipeline.expire(key, 300); // 300 secondes = 5 minutes
      await pipeline.exec();

      logger.debug('Driver location updated in Redis', {
        driverId,
        key,
        locationData
      });

      return true;
    } catch (error) {
      logger.error('Error updating driver location in Redis', {
        error: error.message,
        driverId,
        locationData
      });
      throw error;
    }
  }

  /**
   * Récupère la position d'un conducteur
   * @param {number} driverId - ID du conducteur
   * @returns {Promise<Object|null>} Données du conducteur ou null
   */
  async getDriverLocation(driverId) {
    try {
      if (!this.isReady()) {
        throw new Error('Redis is not connected');
      }

      const key = `driver:${driverId}`;
      const driverData = await this.client.hGetAll(key);

      if (!driverData || Object.keys(driverData).length === 0) {
        return null;
      }

      return {
        driverId: parseInt(driverId),
        latitude: parseFloat(driverData.lat),
        longitude: parseFloat(driverData.lon),
        status: driverData.status,
        lastUpdate: driverData.last_update,
        currentRideId: driverData.current_ride_id ? parseInt(driverData.current_ride_id) : null,
        heading: driverData.heading ? parseFloat(driverData.heading) : 0,
        speed: driverData.speed ? parseFloat(driverData.speed) : 0
      };
    } catch (error) {
      logger.error('Error getting driver location from Redis', {
        error: error.message,
        driverId
      });
      return null;
    }
  }

  /**
   * Met à jour le statut d'un conducteur
   * @param {number} driverId - ID du conducteur
   * @param {string} status - Nouveau statut
   * @param {number} currentRideId - ID de la course actuelle (optionnel)
   * @returns {Promise<boolean>} Succès
   */
  async updateDriverStatus(driverId, status, currentRideId = null) {
    try {
      if (!this.isReady()) {
        throw new Error('Redis is not connected');
      }

      const key = `driver:${driverId}`;
      const timestamp = new Date().toISOString();

      const updates = {
        status: status,
        last_update: timestamp
      };

      if (currentRideId !== null) {
        updates.current_ride_id = currentRideId.toString();
      } else {
        updates.current_ride_id = '';
      }

      // OPTIMISATION: Utiliser pipeline pour hSet et expire en une seule transaction
      const pipeline = this.client.multi();
      pipeline.hSet(key, updates);
      pipeline.expire(key, 300); // Renouveler le TTL
      await pipeline.exec();

      logger.debug('Driver status updated in Redis', {
        driverId,
        status,
        currentRideId
      });

      return true;
    } catch (error) {
      logger.error('Error updating driver status in Redis', {
        error: error.message,
        driverId,
        status
      });
      throw error;
    }
  }

  /**
   * Récupère tous les conducteurs disponibles
   * @returns {Promise<Array>} Liste des conducteurs disponibles
   */
  async getAvailableDrivers() {
    try {
      if (!this.isReady()) {
        throw new Error('Redis is not connected');
      }

      // Récupérer toutes les clés driver:*
      const keys = await this.client.keys('driver:*');
      
      if (keys.length === 0) {
        return [];
      }

      // OPTIMISATION: Utiliser pipeline pour récupérer toutes les données en une seule fois
      const pipeline = this.client.multi();
      keys.forEach(key => {
        pipeline.hGetAll(key);
      });
      
      const results = await pipeline.exec();
      const drivers = [];

      // Traiter les résultats
      for (let i = 0; i < results.length; i++) {
        const result = results[i];
        if (result[0]) {
          // Erreur dans la commande
          logger.warn('Error in pipeline command', { error: result[0].message });
          continue;
        }
        
        const driverData = result[1];
        if (driverData && driverData.status === 'available') {
          const driverId = parseInt(keys[i].replace('driver:', ''));
          drivers.push({
            driverId: driverId,
            latitude: parseFloat(driverData.lat),
            longitude: parseFloat(driverData.lon),
            status: driverData.status,
            lastUpdate: driverData.last_update,
            heading: driverData.heading ? parseFloat(driverData.heading) : 0,
            speed: driverData.speed ? parseFloat(driverData.speed) : 0
          });
        }
      }

      return drivers;
    } catch (error) {
      logger.error('Error getting available drivers from Redis', {
        error: error.message
      });
      return [];
    }
  }

  /**
   * Supprime un conducteur de Redis (déconnexion)
   * @param {number} driverId - ID du conducteur
   * @returns {Promise<boolean>} Succès
   */
  async removeDriver(driverId) {
    try {
      if (!this.isReady()) {
        throw new Error('Redis is not connected');
      }

      const key = `driver:${driverId}`;
      await this.client.del(key);

      logger.debug('Driver removed from Redis', { driverId });

      return true;
    } catch (error) {
      logger.error('Error removing driver from Redis', {
        error: error.message,
        driverId
      });
      throw error;
    }
  }

  /**
   * Vérifie si un conducteur est en ligne
   * @param {number} driverId - ID du conducteur
   * @returns {Promise<boolean>} True si en ligne
   */
  async isDriverOnline(driverId) {
    try {
      if (!this.isReady()) {
        return false;
      }

      const key = `driver:${driverId}`;
      const exists = await this.client.exists(key);
      return exists === 1;
    } catch (error) {
      logger.error('Error checking if driver is online', {
        error: error.message,
        driverId
      });
      return false;
    }
  }

  /**
   * ==================== GESTION DES INSCRIPTIONS/CONNEXIONS EN ATTENTE ====================
   */

  /**
   * Stocke les données d'inscription en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {Object} data - Données d'inscription (name, phoneNumber, role)
   * @param {number} expiresIn - Durée d'expiration en secondes (défaut: 600 = 10 minutes)
   * @returns {Promise<boolean>} Succès
   */
  async storePendingRegistration(phoneNumber, data, expiresIn = 600) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot store pending registration', { phoneNumber });
        // Retourner false pour indiquer que le stockage a échoué
        // Les routes géreront cette erreur avec un try/catch
        return false;
      }

      const key = `pending:register:${phoneNumber}`;
      const registrationData = {
        name: data.name || '',
        phoneNumber: data.phoneNumber || phoneNumber,
        role: data.role || 'client',
        createdAt: new Date().toISOString()
      };

      // OPTIMISATION: Utiliser pipeline pour hSet et expire en une seule transaction
      const pipeline = this.client.multi();
      pipeline.hSet(key, registrationData);
      pipeline.expire(key, expiresIn);
      await pipeline.exec();

      logger.debug('Pending registration stored in Redis', {
        phoneNumber,
        key,
        expiresIn
      });

      return true;
    } catch (error) {
      logger.error('Error storing pending registration in Redis', {
        error: error.message,
        phoneNumber,
        data
      });
      // Retourner false au lieu de lancer une erreur pour permettre le fallback
      return false;
    }
  }

  /**
   * Récupère les données d'inscription en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<Object|null>} Données d'inscription ou null
   */
  async getPendingRegistration(phoneNumber) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot retrieve pending registration', { phoneNumber });
        return null;
      }

      const key = `pending:register:${phoneNumber}`;
      const registrationData = await this.client.hGetAll(key);

      if (!registrationData || Object.keys(registrationData).length === 0) {
        return null;
      }

      return {
        name: registrationData.name,
        phoneNumber: registrationData.phoneNumber,
        role: registrationData.role,
        createdAt: new Date(registrationData.createdAt)
      };
    } catch (error) {
      logger.error('Error getting pending registration from Redis', {
        error: error.message,
        phoneNumber
      });
      return null;
    }
  }

  /**
   * Supprime les données d'inscription en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<boolean>} Succès
   */
  async deletePendingRegistration(phoneNumber) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot delete pending registration', { phoneNumber });
        return false;
      }

      const key = `pending:register:${phoneNumber}`;
      await this.client.del(key);

      logger.debug('Pending registration deleted from Redis', { phoneNumber });

      return true;
    } catch (error) {
      logger.error('Error deleting pending registration from Redis', {
        error: error.message,
        phoneNumber
      });
      return false;
    }
  }

  /**
   * Stocke la demande de connexion en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {Object} data - Données de connexion (optionnel)
   * @param {number} expiresIn - Durée d'expiration en secondes (défaut: 600 = 10 minutes)
   * @returns {Promise<boolean>} Succès
   */
  async storePendingLogin(phoneNumber, data = {}, expiresIn = 600) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot store pending login', { phoneNumber });
        // Retourner false pour indiquer que le stockage a échoué
        // Les routes géreront cette erreur avec un try/catch
        return false;
      }

      const key = `pending:login:${phoneNumber}`;
      const loginData = {
        phoneNumber: phoneNumber,
        createdAt: new Date().toISOString(),
        ...data
      };

      // OPTIMISATION: Utiliser pipeline pour hSet et expire en une seule transaction
      const pipeline = this.client.multi();
      pipeline.hSet(key, loginData);
      pipeline.expire(key, expiresIn);
      await pipeline.exec();

      logger.debug('Pending login stored in Redis', {
        phoneNumber,
        key,
        expiresIn
      });

      return true;
    } catch (error) {
      logger.error('Error storing pending login in Redis', {
        error: error.message,
        phoneNumber,
        data
      });
      // Retourner false au lieu de lancer une erreur pour permettre le fallback
      return false;
    }
  }

  /**
   * Récupère la demande de connexion en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<Object|null>} Données de connexion ou null
   */
  async getPendingLogin(phoneNumber) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot retrieve pending login', { phoneNumber });
        return null;
      }

      const key = `pending:login:${phoneNumber}`;
      const loginData = await this.client.hGetAll(key);

      if (!loginData || Object.keys(loginData).length === 0) {
        return null;
      }

      return {
        phoneNumber: loginData.phoneNumber,
        createdAt: new Date(loginData.createdAt)
      };
    } catch (error) {
      logger.error('Error getting pending login from Redis', {
        error: error.message,
        phoneNumber
      });
      return null;
    }
  }

  /**
   * Supprime la demande de connexion en attente
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<boolean>} Succès
   */
  async deletePendingLogin(phoneNumber) {
    try {
      if (!this.isReady()) {
        logger.warn('Redis not available, cannot delete pending login', { phoneNumber });
        return false;
      }

      const key = `pending:login:${phoneNumber}`;
      await this.client.del(key);

      logger.debug('Pending login deleted from Redis', { phoneNumber });

      return true;
    } catch (error) {
      logger.error('Error deleting pending login from Redis', {
        error: error.message,
        phoneNumber
      });
      return false;
    }
  }

  /**
   * Vérifie et incrémente le compteur de rate limiting pour OTP
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {number} maxAttempts - Nombre maximum de tentatives (défaut: 3)
   * @param {number} windowSeconds - Fenêtre de temps en secondes (défaut: 3600 = 1 heure)
   * @returns {Promise<Object>} {allowed: boolean, remaining: number, resetAt: Date}
   */
  async checkOTPRateLimit(phoneNumber, maxAttempts = 3, windowSeconds = 3600) {
    try {
      if (!this.isReady()) {
        // Si Redis n'est pas disponible, autoriser la requête (fallback)
        logger.warn('Redis not available for rate limiting, allowing request');
        return { allowed: true, remaining: maxAttempts, resetAt: null };
      }

      const key = `otp:rate:${phoneNumber}`;
      const current = await this.client.get(key);
      const attempts = current ? parseInt(current) : 0;

      if (attempts >= maxAttempts) {
        const ttl = await this.client.ttl(key);
        const resetAt = new Date(Date.now() + ttl * 1000);
        return {
          allowed: false,
          remaining: 0,
          resetAt: resetAt
        };
      }

      // Incrémenter le compteur
      const newAttempts = attempts + 1;
      if (newAttempts === 1) {
        // Première tentative, définir le TTL
        await this.client.set(key, '1', { EX: windowSeconds });
      } else {
        // Incrémenter le compteur (le TTL reste le même)
        await this.client.incr(key);
      }

      const remaining = maxAttempts - newAttempts;
      const ttl = await this.client.ttl(key);
      const resetAt = new Date(Date.now() + ttl * 1000);

      return {
        allowed: true,
        remaining: remaining,
        resetAt: resetAt
      };
    } catch (error) {
      logger.error('Error checking OTP rate limit', {
        error: error.message,
        phoneNumber
      });
      // En cas d'erreur, autoriser la requête (fallback)
      return { allowed: true, remaining: maxAttempts, resetAt: null };
    }
  }

  /**
   * Réinitialise le compteur de rate limiting pour OTP
   * @param {string} phoneNumber - Numéro de téléphone
   * @returns {Promise<boolean>} Succès
   */
  async resetOTPRateLimit(phoneNumber) {
    try {
      if (!this.isReady()) {
        return true;
      }

      const key = `otp:rate:${phoneNumber}`;
      await this.client.del(key);

      logger.debug('OTP rate limit reset', { phoneNumber });

      return true;
    } catch (error) {
      logger.error('Error resetting OTP rate limit', {
        error: error.message,
        phoneNumber
      });
      return false;
    }
  }

  /**
   * ==================== UTILITAIRES ====================
   */

  /**
   * Nettoie les conducteurs expirés (hors ligne depuis plus de 5 minutes)
   * @returns {Promise<number>} Nombre de conducteurs supprimés
   */
  async cleanupExpiredDrivers() {
    try {
      if (!this.isReady()) {
        return 0;
      }

      const keys = await this.client.keys('driver:*');
      let cleaned = 0;

      for (const key of keys) {
        const ttl = await this.client.ttl(key);
        // Si TTL est -2, la clé n'existe plus
        // Si TTL est -1, la clé n'a pas de TTL (ne devrait pas arriver)
        if (ttl === -2) {
          cleaned++;
        }
      }

      if (cleaned > 0) {
        logger.info('Cleaned up expired drivers', { count: cleaned });
      }

      return cleaned;
    } catch (error) {
      logger.error('Error cleaning up expired drivers', {
        error: error.message
      });
      return 0;
    }
  }

  /**
   * Récupère les statistiques Redis
   * @returns {Promise<Object>} Statistiques
   */
  async getStats() {
    try {
      if (!this.isReady()) {
        return {
          connected: false,
          drivers: 0,
          available: 0,
          inProgress: 0
        };
      }

      const keys = await this.client.keys('driver:*');
      let available = 0;
      let inProgress = 0;

      for (const key of keys) {
        const driverData = await this.client.hGetAll(key);
        if (driverData.status === 'available') {
          available++;
        } else if (driverData.status === 'in_progress' || driverData.status === 'en_route_to_pickup') {
          inProgress++;
        }
      }

      return {
        connected: true,
        drivers: keys.length,
        available: available,
        inProgress: inProgress,
        offline: keys.length - available - inProgress
      };
    } catch (error) {
      logger.error('Error getting Redis stats', {
        error: error.message
      });
      return {
        connected: false,
        drivers: 0,
        available: 0,
        inProgress: 0
      };
    }
  }

  /**
   * Teste la connexion Redis
   * @returns {Promise<boolean>} True si la connexion fonctionne
   */
  async testConnection() {
    try {
      if (!this.isReady()) {
        return false;
      }

      await this.client.ping();
      return true;
    } catch (error) {
      logger.error('Redis connection test failed', {
        error: error.message
      });
      return false;
    }
  }
}

// Singleton
let redisServiceInstance = null;

/**
 * Obtenir l'instance unique du service Redis
 * @returns {RedisService} Instance du service Redis
 */
function getRedisService() {
  if (!redisServiceInstance) {
    redisServiceInstance = new RedisService();
  }
  return redisServiceInstance;
}

module.exports = {
  RedisService,
  getRedisService
};

