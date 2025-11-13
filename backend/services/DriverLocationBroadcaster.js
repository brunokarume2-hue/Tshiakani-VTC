/**
 * Service de diffusion automatique des positions des chauffeurs
 * Distribue les positions depuis Redis vers les clients via WebSocket
 * 
 * Architecture optimisée pour VTC :
 * - Diffusion ciblée uniquement aux clients qui suivent une course active
 * - Utilise Redis comme source de vérité pour les positions temps réel
 * - Distribution automatique toutes les 2 secondes
 */

const logger = require('../utils/logger');

class DriverLocationBroadcaster {
  constructor(io, clientNamespace, redisService) {
    this.io = io;
    this.clientNamespace = clientNamespace;
    this.redisService = redisService;
    this.broadcastInterval = null;
    this.isRunning = false;
    this.broadcastIntervalMs = 2000; // 2 secondes par défaut
  }

  /**
   * Démarre la diffusion automatique des positions
   * @param {number} intervalMs - Intervalle de diffusion en millisecondes (défaut: 2000ms = 2s)
   */
  start(intervalMs = 2000) {
    if (this.isRunning) {
      logger.warn('DriverLocationBroadcaster déjà en cours d\'exécution');
      return;
    }

    this.broadcastIntervalMs = intervalMs;
    this.isRunning = true;
    logger.info('DriverLocationBroadcaster démarré', { intervalMs });

    // Diffuser toutes les 2 secondes (ou selon l'intervalle configuré)
    this.broadcastInterval = setInterval(async () => {
      await this.broadcastDriverLocations();
    }, intervalMs);
  }

  /**
   * Arrête la diffusion automatique
   */
  stop() {
    if (this.broadcastInterval) {
      clearInterval(this.broadcastInterval);
      this.broadcastInterval = null;
    }
    this.isRunning = false;
    logger.info('DriverLocationBroadcaster arrêté');
  }

  /**
   * Vérifie si le service est en cours d'exécution
   */
  isActive() {
    return this.isRunning;
  }

  /**
   * Diffuse les positions des chauffeurs actifs aux clients qui suivent leurs courses
   */
  async broadcastDriverLocations() {
    try {
      // Vérifier que Redis est disponible
      if (!this.redisService || !this.redisService.isReady()) {
        return;
      }

      // Vérifier que le namespace client est disponible
      if (!this.clientNamespace) {
        return;
      }

      // Récupérer tous les chauffeurs actifs depuis Redis
      const availableDrivers = await this.redisService.getAvailableDrivers();
      
      if (availableDrivers.length === 0) {
        return; // Aucun chauffeur actif
      }

      // Pour chaque chauffeur, vérifier s'il a une course active
      for (const driver of availableDrivers) {
        try {
          // Récupérer les détails complets depuis Redis
          const driverLocation = await this.redisService.getDriverLocation(driver.driverId);
          
          if (!driverLocation) {
            continue; // Données non disponibles, passer au suivant
          }

          // Vérifier si le chauffeur a une course active
          const rideId = driverLocation.currentRideId;
          
          if (!rideId) {
            continue; // Pas de course active, passer au suivant
          }

          // Vérifier si des clients suivent cette course
          // Utiliser adapter.rooms pour vérifier les rooms Socket.io
          const rideRoom = `ride:${rideId}`;
          
          // Vérifier si la room existe et contient des clients
          // Note: adapter.rooms peut ne pas être disponible selon l'adaptateur Socket.io
          // On essaie d'abord de vérifier, sinon on émet quand même (Socket.io filtrera)
          let shouldBroadcast = true;
          
          try {
            // Tenter de vérifier la room (si l'adaptateur le supporte)
            if (this.clientNamespace.adapter && this.clientNamespace.adapter.rooms) {
              const room = this.clientNamespace.adapter.rooms.get(rideRoom);
              if (!room || room.size === 0) {
                shouldBroadcast = false; // Aucun client ne suit cette course
              }
            }
          } catch (roomCheckError) {
            // Si la vérification échoue, on émet quand même (Socket.io gérera)
            logger.debug('Impossible de vérifier la room, émission quand même', {
              error: roomCheckError.message,
              rideRoom
            });
          }

          if (!shouldBroadcast) {
            continue; // Aucun client ne suit cette course
          }

          // Préparer les données de localisation
          const locationData = {
            type: 'driver_location_update',
            driverId: driverLocation.driverId,
            rideId: rideId,
            location: {
              latitude: driverLocation.latitude,
              longitude: driverLocation.longitude,
              heading: driverLocation.heading || 0,
              speed: driverLocation.speed || 0
            },
            status: driverLocation.status,
            timestamp: driverLocation.lastUpdate || new Date().toISOString()
          };

          // Distribuer la position aux clients de cette course
          this.clientNamespace.to(rideRoom).emit('driver:location:update', locationData);
          
          logger.debug('Driver location broadcasted', {
            driverId: driverLocation.driverId,
            rideId: rideId,
            latitude: driverLocation.latitude,
            longitude: driverLocation.longitude
          });
        } catch (driverError) {
          // Logger l'erreur mais continuer avec les autres chauffeurs
          logger.warn('Erreur lors de la diffusion pour un chauffeur', {
            error: driverError.message,
            driverId: driver?.driverId
          });
        }
      }
    } catch (error) {
      logger.error('Erreur lors de la diffusion des positions', {
        error: error.message,
        stack: error.stack
      });
    }
  }

  /**
   * Diffuse manuellement la position d'un chauffeur spécifique
   * @param {number} driverId - ID du chauffeur
   * @param {number} rideId - ID de la course
   */
  async broadcastDriverLocation(driverId, rideId) {
    try {
      if (!this.redisService || !this.redisService.isReady()) {
        logger.warn('Redis non disponible pour la diffusion manuelle', { driverId, rideId });
        return;
      }

      // Récupérer la position du chauffeur depuis Redis
      const driverLocation = await this.redisService.getDriverLocation(driverId);
      
      if (!driverLocation) {
        logger.warn('Position du chauffeur non trouvée dans Redis', { driverId, rideId });
        return;
      }

      // Préparer les données de localisation
      const locationData = {
        type: 'driver_location_update',
        driverId: driverLocation.driverId,
        rideId: rideId,
        location: {
          latitude: driverLocation.latitude,
          longitude: driverLocation.longitude,
          heading: driverLocation.heading || 0,
          speed: driverLocation.speed || 0
        },
        status: driverLocation.status,
        timestamp: driverLocation.lastUpdate || new Date().toISOString()
      };

      // Distribuer aux clients de cette course
      const rideRoom = `ride:${rideId}`;
      this.clientNamespace.to(rideRoom).emit('driver:location:update', locationData);
      
      logger.debug('Driver location broadcasted manually', {
        driverId,
        rideId,
        latitude: driverLocation.latitude,
        longitude: driverLocation.longitude
      });
    } catch (error) {
      logger.error('Erreur lors de la diffusion manuelle', {
        error: error.message,
        driverId,
        rideId
      });
    }
  }
}

module.exports = DriverLocationBroadcaster;
