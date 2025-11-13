//
//  BackendAgentPrincipal.js
//  Tshiakani VTC
//
//  Agent Principal Backend - Orchestrateur central de toutes les opérations
//  Coordonne les services, gère les transactions, optimise les performances
//

const AppDataSource = require('../config/database');
const User = require('../entities/User');
const Ride = require('../entities/Ride');
const Notification = require('../entities/Notification');
const DriverMatchingService = require('./DriverMatchingService');
const PricingService = require('./PricingService');
const PaymentService = require('./PaymentService');
const GoogleMapsService = require('./GoogleMapsService');
const { sendNotification, sendMulticastNotification } = require('../utils/notifications');
const { getCloudMonitoringService } = require('../utils/cloud-monitoring');
const logger = require('../utils/logger');

/**
 * Agent Principal Backend
 * Orchestrateur central pour toutes les opérations du backend
 */
class BackendAgentPrincipal {
  constructor(io = null, driverNamespace = null, clientNamespace = null) {
    this.io = io;
    this.driverNamespace = driverNamespace;
    this.clientNamespace = clientNamespace;
    this.realtimeRideService = null;
  }

  /**
   * Initialise l'agent avec les services temps réel
   */
  setRealtimeService(realtimeService) {
    this.realtimeRideService = realtimeService;
  }

  /**
   * ==================== GESTION DES COURSES ====================
   */

  /**
   * Crée une nouvelle course avec pricing automatique et matching
   * @param {Object} rideData - Données de la course
   * @param {number} rideData.clientId - ID du client
   * @param {Object} rideData.pickupLocation - {latitude, longitude}
   * @param {Object} rideData.dropoffLocation - {latitude, longitude}
   * @param {string} rideData.pickupAddress - Adresse de départ
   * @param {string} rideData.dropoffAddress - Adresse d'arrivée
   * @param {string} rideData.paymentMethod - Méthode de paiement
   * @returns {Promise<Object>} Course créée avec pricing et matching
   */
  async createRide(rideData) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const userRepository = queryRunner.manager.getRepository(User);

      // 1. Vérifier que le client existe
      const client = await userRepository.findOne({
        where: { id: rideData.clientId }
      });

      if (!client) {
        throw new Error('Client non trouvé');
      }

      // 2. Calculer la distance et le temps avec Google Maps Routes API
      const routeData = await GoogleMapsService.calculateRoute(
        rideData.pickupLocation,
        rideData.dropoffLocation,
        {
          travelMode: 'DRIVE',
          routingPreference: 'TRAFFIC_AWARE',
          language: 'fr'
        }
      );

      const distance = routeData.distance.kilometers;
      const duration = routeData.duration;

      // 3. Calculer le prix dynamique avec distance et temps réels
      const pricing = await PricingService.calculateDynamicPrice(
        distance,
        new Date(),
        rideData.pickupLocation,
        rideData.dropoffLocation
      );

      // 4. Créer la course
      const ride = rideRepository.create({
        clientId: rideData.clientId,
        pickupLocation: {
          type: 'Point',
          coordinates: [rideData.pickupLocation.longitude, rideData.pickupLocation.latitude]
        },
        pickupAddress: rideData.pickupAddress,
        dropoffLocation: {
          type: 'Point',
          coordinates: [rideData.dropoffLocation.longitude, rideData.dropoffLocation.latitude]
        },
        dropoffAddress: rideData.dropoffAddress,
        status: 'pending',
        estimatedPrice: pricing.price,
        distance: distance,
        estimatedDuration: duration.minutes,
        paymentMethod: rideData.paymentMethod || 'cash'
      });

      const savedRide = await rideRepository.save(ride);

      // 5. Trouver les meilleurs conducteurs (matching automatique avec Redis)
      const bestMatch = await DriverMatchingService.findBestDriver(
        rideData.pickupLocation,
        rideData.dropoffLocation,
        savedRide.id
      );

      // 6. Si un conducteur est trouvé, l'assigner automatiquement
      if (bestMatch && bestMatch.driver) {
        savedRide.driverId = bestMatch.driver.id;
        savedRide.status = 'accepted';

        // Mettre à jour le statut du conducteur
        const driver = await userRepository.findOne({
          where: { id: bestMatch.driver.id }
        });

        if (driver) {
          // S'assurer que driverInfo existe
          if (!driver.driverInfo) {
            driver.driverInfo = {};
          }
          driver.driverInfo.currentRideId = savedRide.id;
          driver.driverInfo.status = 'en_route_to_pickup';
          if (!driver.driverInfo.isOnline) {
            driver.driverInfo.isOnline = true;
          }
          await userRepository.save(driver);
        }

        await rideRepository.save(savedRide);

        // Notifier le conducteur via WebSocket
        if (this.driverNamespace && driver) {
          this.driverNamespace.to(`driver:${driver.id}`).emit('ride_request', {
            type: 'ride_request',
            ride: {
              id: savedRide.id.toString(),
              pickupAddress: savedRide.pickupAddress,
              dropoffAddress: savedRide.dropoffAddress,
              pickupLatitude: rideData.pickupLocation.latitude,
              pickupLongitude: rideData.pickupLocation.longitude,
              dropoffLatitude: rideData.dropoffLocation.latitude,
              dropoffLongitude: rideData.dropoffLocation.longitude,
              estimatedDistance: distance,
              estimatedPrice: pricing.price,
              passengerName: client.name || null,
              createdAt: savedRide.createdAt.toISOString()
            }
          });
        }

        // Notifier le client via FCM
        if (client.fcmToken && driver) {
          await sendNotification(client.fcmToken, {
            title: 'Course acceptée',
            body: `${driver.name || 'Un conducteur'} a accepté votre course`,
            data: {
              type: 'ride_accepted',
              rideId: savedRide.id.toString(),
              driverId: driver.id.toString()
            }
          });
        }

        // Notifier le client via WebSocket
        if (this.clientNamespace) {
          this.clientNamespace.emit('ride:accepted', {
            rideId: savedRide.id.toString(),
            driverId: driver.id.toString(),
            driverName: driver.name,
            estimatedArrival: duration.text
          });
        }
      } else {
        // Aucun conducteur disponible - notifier les conducteurs les mieux placés via FCM
        // Récupérer les conducteurs disponibles depuis Redis
        const { getRedisService } = require('../server.postgres');
        const redisService = getRedisService();
        
        if (redisService && redisService.isReady && redisService.isReady()) {
          try {
            const availableDrivers = await redisService.getAvailableDrivers();
            
            // Trier par distance et prendre les 5 meilleurs
            const topDrivers = availableDrivers
              .map(driver => {
                const driverDistance = DriverMatchingService.calculateHaversineDistance(
                  rideData.pickupLocation,
                  { latitude: driver.latitude, longitude: driver.longitude }
                );
                return { ...driver, distance: driverDistance };
              })
              .filter(driver => driver.distance <= 5) // Dans un rayon de 5 km
              .sort((a, b) => a.distance - b.distance)
              .slice(0, 5); // Top 5

            // Récupérer les tokens FCM des conducteurs
            const driverIds = topDrivers.map(d => d.driverId);
            if (driverIds.length > 0) {
              const drivers = await userRepository
                .createQueryBuilder('user')
                .where('user.id IN (:...ids)', { ids: driverIds })
                .select(['user.id', 'user.fcmToken', 'user.name'])
                .getMany();

              const fcmTokens = drivers
                .filter(d => d.fcmToken)
                .map(d => d.fcmToken);

              // Envoyer les notifications push aux meilleurs conducteurs
              if (fcmTokens.length > 0) {
                await sendMulticastNotification(fcmTokens, {
                  title: 'Nouvelle course disponible 🚗',
                  body: `${rideData.pickupAddress} → ${rideData.dropoffAddress} (${Math.round(distance * 10) / 10} km, ${pricing.price} CDF)`,
                  data: {
                    type: 'ride_offer',
                    rideId: savedRide.id.toString(),
                    estimatedPrice: pricing.price.toString(),
                    estimatedDistance: distance.toString(),
                    estimatedDuration: duration.text
                  },
                  priority: 'high'
                });

                logger.info('Notifications FCM envoyées aux conducteurs', {
                  rideId: savedRide.id,
                  driversCount: fcmTokens.length
                });
              }
            }
          } catch (redisError) {
            logger.warn('Erreur envoi notifications FCM, fallback WebSocket', {
              error: redisError.message
            });
          }
        }

        // Notifier tous les conducteurs disponibles via WebSocket (fallback)
        if (this.driverNamespace) {
          this.driverNamespace.emit('ride_request', {
            type: 'ride_request',
            ride: {
              id: savedRide.id.toString(),
              pickupAddress: savedRide.pickupAddress,
              dropoffAddress: savedRide.dropoffAddress,
              pickupLatitude: rideData.pickupLocation.latitude,
              pickupLongitude: rideData.pickupLocation.longitude,
              dropoffLatitude: rideData.dropoffLocation.latitude,
              dropoffLongitude: rideData.dropoffLocation.longitude,
              estimatedDistance: distance,
              estimatedPrice: pricing.price,
              estimatedDuration: duration.text,
              passengerName: client.name || null,
              createdAt: savedRide.createdAt.toISOString()
            }
          });
        }
      }

      // 7. Commiter la transaction
      await queryRunner.commitTransaction();

      // Enregistrer les métriques de succès (en arrière-plan, ne pas bloquer)
      try {
        const cloudMonitoringService = getCloudMonitoringService();
        if (cloudMonitoringService && cloudMonitoringService.isInitialized) {
          // Ne pas attendre pour ne pas bloquer la réponse
          Promise.all([
            cloudMonitoringService.recordRideEvent('created', distance, pricing.price),
            bestMatch && bestMatch.driver 
              ? cloudMonitoringService.recordMatchingEvent('success', 1, bestMatch.score)
              : cloudMonitoringService.recordMatchingEvent('no_driver', 0, 0)
          ]).catch(err => {
            logger.warn('Erreur enregistrement métriques (non bloquant)', {
              error: err.message
            });
          });
        }
      } catch (monitoringError) {
        // Ne pas faire échouer la création de course si le monitoring échoue
        logger.warn('Erreur enregistrement métriques (non bloquant)', {
          error: monitoringError.message
        });
      }
      
      logger.info('Course créée avec succès', {
        rideId: savedRide.id,
        clientId: rideData.clientId,
        driverId: bestMatch?.driver?.id || null,
        price: pricing.price,
        distance: distance
      });

      return {
        ride: savedRide,
        pricing: pricing,
        matching: bestMatch ? {
          driver: {
            id: bestMatch.driver.id,
            name: bestMatch.driver.name
          },
          score: bestMatch.score,
          breakdown: bestMatch.breakdown
        } : null
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      
      // Enregistrer l'erreur dans Cloud Logging et Monitoring
      const { getCloudLoggingService } = require('../utils/cloud-logging');
      const { getCloudMonitoringService } = require('../utils/cloud-monitoring');
      const cloudLogging = getCloudLoggingService();
      const cloudMonitoring = getCloudMonitoringService();
      
      // Déterminer le type d'erreur
      if (error.message.includes('paiement') || error.message.includes('payment')) {
        await cloudLogging.logPaymentError({
          rideId: rideData.rideId || null,
          amount: pricing?.price || 0,
          currency: 'CDF',
          method: rideData.paymentMethod || 'unknown'
        }, error);
        await cloudMonitoring.recordPaymentEvent('failure', pricing?.price || 0, 'CDF');
        await cloudMonitoring.recordError('payment_error', error.message);
      } else if (error.message.includes('conducteur') || error.message.includes('driver') || error.message.includes('matching')) {
        await cloudLogging.logMatchingError({
          rideId: null,
          clientId: rideData.clientId,
          pickupLocation: rideData.pickupLocation,
          dropoffLocation: rideData.dropoffLocation
        }, error);
        await cloudMonitoring.recordMatchingEvent('failure', 0, 0);
        await cloudMonitoring.recordError('matching_error', error.message);
      } else {
        await cloudLogging.error('Erreur création course', {
          error: error.message,
          stack: error.stack,
          rideData: {
            clientId: rideData.clientId,
            pickupLocation: rideData.pickupLocation,
            dropoffLocation: rideData.dropoffLocation
          }
        });
        await cloudMonitoring.recordError('ride_creation_error', error.message);
      }
      
      logger.error('Erreur création course', {
        error: error.message,
        stack: error.stack,
        rideData
      });
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Accepte une course par un conducteur
   * @param {number} rideId - ID de la course
   * @param {number} driverId - ID du conducteur
   * @returns {Promise<Object>} Course mise à jour
   */
  async acceptRide(rideId, driverId) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const userRepository = queryRunner.manager.getRepository(User);

      // 1. Vérifier que la course existe et est disponible
      const ride = await rideRepository.findOne({
        where: { id: rideId },
        relations: ['client', 'driver']
      });

      if (!ride) {
        throw new Error('Course non trouvée');
      }

      if (ride.status !== 'pending') {
        throw new Error('Cette course n\'est plus disponible');
      }

      // 2. Vérifier que le conducteur existe et est disponible
      const driver = await userRepository.findOne({
        where: { id: driverId, role: 'driver' }
      });

      if (!driver) {
        throw new Error('Conducteur non trouvé');
      }

      // S'assurer que driverInfo existe
      if (!driver.driverInfo) {
        driver.driverInfo = {};
      }
      
      const driverInfo = driver.driverInfo;
      if (!driverInfo.isOnline || driverInfo.status !== 'available') {
        throw new Error('Le conducteur n\'est pas disponible');
      }

      // 3. Assigner la course au conducteur
      ride.driverId = driverId;
      ride.status = 'accepted';
      await rideRepository.save(ride);

      // 4. Mettre à jour le statut du conducteur
      driverInfo.currentRideId = rideId;
      driverInfo.status = 'en_route_to_pickup';
      driver.driverInfo = driverInfo;
      await userRepository.save(driver);

      // 5. Notifier le client
      if (ride.client) {
        if (this.clientNamespace) {
          this.clientNamespace.to(`client:${ride.clientId}`).emit('ride:status:changed', {
            rideId: ride.id,
            status: 'accepted',
            driver: {
              id: driver.id,
              name: driver.name,
              phoneNumber: driver.phoneNumber
            }
          });
        }

        if (ride.client.fcmToken) {
          await sendNotification(ride.client.fcmToken, {
            title: 'Course acceptée',
            body: `${driver.name} a accepté votre course`,
            data: {
              type: 'ride_accepted',
              rideId: ride.id.toString(),
              driverId: driver.id.toString()
            }
          });
        }
      }

      // 6. Commiter la transaction
      await queryRunner.commitTransaction();

      logger.info('Course acceptée', {
        rideId: ride.id,
        driverId: driverId
      });

      return {
        ride: ride,
        driver: {
          id: driver.id,
          name: driver.name,
          phoneNumber: driver.phoneNumber
        }
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();
      logger.error('Erreur acceptation course', {
        error: error.message,
        rideId,
        driverId
      });
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Met à jour le statut d'une course
   * @param {number} rideId - ID de la course
   * @param {string} status - Nouveau statut
   * @param {Object} options - Options supplémentaires
   * @returns {Promise<Object>} Course mise à jour
   */
  async updateRideStatus(rideId, status, options = {}) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const userRepository = queryRunner.manager.getRepository(User);

      const ride = await rideRepository.findOne({
        where: { id: rideId },
        relations: ['client', 'driver']
      });

      if (!ride) {
        throw new Error('Course non trouvée');
      }

      const oldStatus = ride.status;
      ride.status = status;

      // Mettre à jour les timestamps selon le statut
      if (status === 'inProgress' && !ride.startedAt) {
        ride.startedAt = new Date();
      } else if (status === 'completed' && !ride.completedAt) {
        ride.completedAt = new Date();
        ride.finalPrice = options.finalPrice || ride.estimatedPrice;
      } else if (status === 'cancelled' && !ride.cancelledAt) {
        ride.cancelledAt = new Date();
        ride.cancellationReason = options.reason || null;
      }

      await rideRepository.save(ride);

      // Mettre à jour le statut du conducteur
      if (ride.driverId) {
        const driver = await userRepository.findOne({
          where: { id: ride.driverId }
        });

        if (driver) {
          // S'assurer que driverInfo existe
          if (!driver.driverInfo) {
            driver.driverInfo = {};
          }

          if (status === 'inProgress') {
            driver.driverInfo.status = 'in_progress';
          } else if (status === 'completed' || status === 'cancelled') {
            driver.driverInfo.status = 'available';
            driver.driverInfo.currentRideId = null;
          }

          await userRepository.save(driver);
        }
      }

      // Notifier les clients via WebSocket
      if (this.clientNamespace) {
        this.clientNamespace.to(`ride:${rideId}`).emit('ride:status:changed', {
          rideId: ride.id,
          status: status,
          timestamp: new Date()
        });
      }

      // Notifier le conducteur
      if (ride.driverId && this.driverNamespace) {
        this.driverNamespace.to(`driver:${ride.driverId}`).emit('ride:status:changed', {
          rideId: ride.id,
          status: status,
          timestamp: new Date()
        });
      }

      // Envoyer des notifications push
      if (ride.client && ride.client.fcmToken) {
        const statusMessages = {
          'accepted': 'Votre course a été acceptée',
          'driverArriving': 'Le conducteur arrive',
          'inProgress': 'Course en cours',
          'completed': 'Course terminée',
          'cancelled': 'Course annulée'
        };

        await sendNotification(ride.client.fcmToken, {
          title: 'Mise à jour de course',
          body: statusMessages[status] || 'Statut de course mis à jour',
          data: {
            type: 'ride_status_changed',
            rideId: ride.id.toString(),
            status: status
          }
        });
      }

      // 6. Commiter la transaction
      await queryRunner.commitTransaction();

      logger.info('Statut de course mis à jour', {
        rideId: ride.id,
        oldStatus: oldStatus,
        newStatus: status
      });

      return ride;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      logger.error('Erreur mise à jour statut course', {
        error: error.message,
        rideId,
        status
      });
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * ==================== GESTION DES CONDUCTEURS ====================
   */

  /**
   * Met à jour la position d'un conducteur
   * @param {number} driverId - ID du conducteur
   * @param {Object} location - {latitude, longitude}
   * @returns {Promise<Object>} Conducteur mis à jour
   */
  async updateDriverLocation(driverId, location) {
    try {
      const userRepository = AppDataSource.getRepository(User);

      const driver = await userRepository.findOne({
        where: { id: driverId, role: 'driver' }
      });

      if (!driver) {
        throw new Error('Conducteur non trouvé');
      }

      driver.location = {
        type: 'Point',
        coordinates: [location.longitude, location.latitude]
      };

      await userRepository.save(driver);

      // Notifier les clients qui suivent une course avec ce conducteur
      if (driver.driverInfo && driver.driverInfo.currentRideId) {
        const rideRepository = AppDataSource.getRepository(Ride);
        const ride = await rideRepository.findOne({
          where: { id: driver.driverInfo.currentRideId },
          relations: ['client']
        });

        if (ride && ride.clientId && this.clientNamespace) {
          this.clientNamespace.to(`ride:${ride.id}`).emit('driver:location:update', {
            rideId: ride.id,
            driverId: driverId,
            location: {
              latitude: location.latitude,
              longitude: location.longitude
            },
            timestamp: new Date()
          });
        }
      }

      logger.debug('Position conducteur mise à jour', {
        driverId: driverId,
        location: location
      });

      return driver;
    } catch (error) {
      logger.error('Erreur mise à jour position conducteur', {
        error: error.message,
        driverId,
        location
      });
      throw error;
    }
  }

  /**
   * Met à jour le statut de disponibilité d'un conducteur
   * @param {number} driverId - ID du conducteur
   * @param {boolean} isOnline - Statut en ligne
   * @returns {Promise<Object>} Conducteur mis à jour
   */
  async updateDriverAvailability(driverId, isOnline) {
    try {
      const userRepository = AppDataSource.getRepository(User);

      const driver = await userRepository.findOne({
        where: { id: driverId, role: 'driver' }
      });

      if (!driver) {
        throw new Error('Conducteur non trouvé');
      }

      // S'assurer que driverInfo existe
      if (!driver.driverInfo) {
        driver.driverInfo = {};
      }
      
      driver.driverInfo.isOnline = isOnline;
      driver.driverInfo.status = isOnline ? 'available' : 'offline';

      // Si le conducteur se déconnecte, libérer sa course en cours
      if (!isOnline && driver.driverInfo.currentRideId) {
        const rideRepository = AppDataSource.getRepository(Ride);
        const ride = await rideRepository.findOne({
          where: { id: driver.driverInfo.currentRideId }
        });

        if (ride && (ride.status === 'pending' || ride.status === 'accepted')) {
          ride.status = 'cancelled';
          ride.cancelledAt = new Date();
          ride.cancellationReason = 'Conducteur déconnecté';
          await rideRepository.save(ride);
        }

        driver.driverInfo.currentRideId = null;
      }

      await userRepository.save(driver);

      logger.info('Disponibilité conducteur mise à jour', {
        driverId: driverId,
        isOnline: isOnline
      });

      return driver;
    } catch (error) {
      logger.error('Erreur mise à jour disponibilité conducteur', {
        error: error.message,
        driverId,
        isOnline
      });
      throw error;
    }
  }

  /**
   * ==================== UTILITAIRES ====================
   */

  /**
   * Calcule la distance entre deux points (utilise Google Maps Routes API ou Haversine)
   * @param {Object} point1 - {latitude, longitude}
   * @param {Object} point2 - {latitude, longitude}
   * @returns {Promise<number>} Distance en kilomètres
   */
  async calculateDistance(point1, point2) {
    try {
      // Utiliser Google Maps Routes API pour une distance précise
      const routeData = await GoogleMapsService.calculateRoute(point1, point2, {
        travelMode: 'DRIVE',
        routingPreference: 'TRAFFIC_AWARE'
      });
      return routeData.distance.kilometers;
    } catch (error) {
      // Fallback vers Haversine en cas d'erreur
      logger.warn('Erreur calcul distance Google Maps, utilisation Haversine', {
        error: error.message
      });
      return GoogleMapsService.calculateDistanceHaversine(point1, point2).distance.kilometers;
    }
  }

  /**
   * Obtient les statistiques globales
   * @returns {Promise<Object>} Statistiques
   */
  async getStatistics() {
    try {
      const userRepository = AppDataSource.getRepository(User);
      const rideRepository = AppDataSource.getRepository(Ride);

      const [
        totalDrivers,
        activeDrivers,
        totalClients,
        totalRides,
        todayRides,
        pendingRides,
        activeRides,
        completedRides,
        totalRevenue
      ] = await Promise.all([
        userRepository.count({ where: { role: 'driver' } }),
        userRepository
          .createQueryBuilder('user')
          .where('user.role = :role', { role: 'driver' })
          .andWhere("user.driver_info->>'isOnline' = 'true'")
          .getCount(),
        userRepository.count({ where: { role: 'client' } }),
        rideRepository.count(),
        rideRepository
          .createQueryBuilder('ride')
          .where('ride.createdAt >= :today', {
            today: new Date(new Date().setHours(0, 0, 0, 0))
          })
          .getCount(),
        rideRepository.count({ where: { status: 'pending' } }),
        rideRepository
          .createQueryBuilder('ride')
          .where('ride.status IN (:...statuses)', {
            statuses: ['accepted', 'driverArriving', 'inProgress']
          })
          .getCount(),
        rideRepository.count({ where: { status: 'completed' } }),
        // Utiliser une requête SQL brute pour éviter les problèmes de mapping TypeORM
        AppDataSource.query(
          `SELECT SUM(final_price) as total
           FROM rides
           WHERE status = $1`,
          ['completed']
        ).then(result => result[0] || { total: null })
         .catch(() => ({ total: null }))
      ]);

      return {
        drivers: {
          total: totalDrivers,
          active: activeDrivers
        },
        clients: {
          total: totalClients
        },
        rides: {
          total: totalRides,
          today: todayRides,
          pending: pendingRides,
          active: activeRides,
          completed: completedRides
        },
        revenue: {
          total: parseFloat(totalRevenue?.total || 0)
        }
      };
    } catch (error) {
      logger.error('Erreur récupération statistiques', {
        error: error.message
      });
      throw error;
    }
  }
}

module.exports = BackendAgentPrincipal;
