//
//  DriverMatchingService.js
//  Tshiakani VTC
//
//  Service IA pour le matching automatique de chauffeurs
//  Sélectionne le meilleur chauffeur selon plusieurs critères
//

const AppDataSource = require('../config/database');
const User = require('../entities/User');
const Ride = require('../entities/Ride');
const { getRedisService } = require('../server.postgres');
const logger = require('../utils/logger');

/**
 * Service de matching IA pour sélectionner automatiquement le meilleur chauffeur
 * Utilise Redis (Memorystore) en priorité pour le temps réel, puis PostGIS en fallback
 */
class DriverMatchingService {
  // Poids des critères dans le score total (somme = 100)
  static WEIGHTS = {
    DISTANCE: 40,      // Distance du client (40%)
    RATING: 25,        // Note du chauffeur (25%)
    AVAILABILITY: 15,  // Disponibilité immédiate (15%)
    PERFORMANCE: 10,   // Performance historique (10%)
    ACCEPTANCE_RATE: 10 // Taux d'acceptation (10%)
  };

  // Distances maximales (en km)
  static MAX_DISTANCE_KM = 5; // Distance maximale pour être éligible (réduit à 5 km comme demandé)
  static PREFERRED_DISTANCE_KM = 2; // Distance préférée (meilleur score)

  /**
   * Trouve et sélectionne automatiquement le meilleur chauffeur pour une course
   * Utilise Redis (Memorystore) en priorité pour récupérer les conducteurs disponibles
   * @param {Object} pickupLocation - {latitude, longitude}
   * @param {Object} dropoffLocation - {latitude, longitude}
   * @param {number} rideId - ID de la course
   * @returns {Promise<Object|null>} Chauffeur sélectionné avec score, ou null si aucun
   */
  static async findBestDriver(pickupLocation, dropoffLocation, rideId) {
    try {
      // 1. Essayer de récupérer depuis Redis (temps réel)
      let nearbyDrivers = [];
      const redisService = getRedisService();

      if (redisService && redisService.isReady && redisService.isReady()) {
        try {
          // Récupérer tous les conducteurs disponibles depuis Redis
          const availableDrivers = await redisService.getAvailableDrivers();

          // Calculer la distance pour chaque conducteur et filtrer par rayon
          nearbyDrivers = availableDrivers
            .map(driver => {
              // Calculer la distance (formule de Haversine)
              const distance = this.calculateHaversineDistance(
                { latitude: pickupLocation.latitude, longitude: pickupLocation.longitude },
                { latitude: driver.latitude, longitude: driver.longitude }
              );
              return {
                ...driver,
                distance_km: distance,
                id: driver.driverId
              };
            })
            .filter(driver => driver.distance_km <= this.MAX_DISTANCE_KM)
            .sort((a, b) => a.distance_km - b.distance_km);

          logger.debug('Conducteurs trouvés via Redis', {
            count: nearbyDrivers.length,
            radius: this.MAX_DISTANCE_KM
          });
        } catch (redisError) {
          logger.warn('Erreur récupération Redis, fallback vers PostGIS', {
            error: redisError.message
          });
        }
      }

      // 2. Fallback vers PostGIS si Redis n'est pas disponible ou si aucun conducteur trouvé
      if (nearbyDrivers.length === 0) {
        nearbyDrivers = await User.findNearbyDrivers(
          pickupLocation.latitude,
          pickupLocation.longitude,
          this.MAX_DISTANCE_KM,
          AppDataSource
        );

        logger.debug('Conducteurs trouvés via PostGIS', {
          count: nearbyDrivers.length,
          radius: this.MAX_DISTANCE_KM
        });
      }

      if (nearbyDrivers.length === 0) {
        return null;
      }

      // 2. Calculer le score pour chaque chauffeur
      const driversWithScores = await Promise.all(
        nearbyDrivers.map(async (driver) => {
          const score = await this.calculateDriverScore(
            driver,
            pickupLocation,
            dropoffLocation
          );
          return {
            driver,
            score: score.total,
            breakdown: score.breakdown
          };
        })
      );

      // 3. Trier par score décroissant
      driversWithScores.sort((a, b) => b.score - a.score);

      // 4. Sélectionner le meilleur (premier de la liste)
      const bestMatch = driversWithScores[0];

      if (!bestMatch || bestMatch.score < 30) {
        // Score trop faible, ne pas assigner automatiquement
        logger.debug('Aucun conducteur avec score suffisant', {
          driversCount: driversWithScores.length,
          bestScore: bestMatch?.score || 0
        });
        return null;
      }

      logger.debug('Meilleur conducteur trouvé', {
        driverId: bestMatch.driver.id,
        score: bestMatch.score,
        alternativesCount: driversWithScores.length - 1
      });

      return {
        driver: bestMatch.driver,
        score: bestMatch.score,
        breakdown: bestMatch.breakdown,
        alternatives: driversWithScores.slice(1, 4).map(d => ({
          id: d.driver.id,
          score: d.score
        }))
      };
    } catch (error) {
      logger.error('Erreur matching chauffeur', {
        error: error.message,
        stack: error.stack,
        pickupLocation,
        dropoffLocation
      });
      return null;
    }
  }

  /**
   * Calcule le score d'un chauffeur selon plusieurs critères
   * @param {Object} driver - Objet chauffeur
   * @param {Object} pickupLocation - {latitude, longitude}
   * @param {Object} dropoffLocation - {latitude, longitude}
   * @returns {Promise<Object>} {total, breakdown}
   */
  static async calculateDriverScore(driver, pickupLocation, dropoffLocation) {
    const breakdown = {};

    // 1. Score de distance (0-40 points)
    const distanceScore = this.calculateDistanceScore(driver, pickupLocation);
    breakdown.distance = {
      score: distanceScore * this.WEIGHTS.DISTANCE / 100,
      raw: distanceScore
    };

    // 2. Score de note (0-25 points)
    const ratingScore = this.calculateRatingScore(driver);
    breakdown.rating = {
      score: ratingScore * this.WEIGHTS.RATING / 100,
      raw: ratingScore
    };

    // 3. Score de disponibilité (0-15 points)
    const availabilityScore = this.calculateAvailabilityScore(driver);
    breakdown.availability = {
      score: availabilityScore * this.WEIGHTS.AVAILABILITY / 100,
      raw: availabilityScore
    };

    // 4. Score de performance (0-10 points)
    const performanceScore = await this.calculatePerformanceScore(driver);
    breakdown.performance = {
      score: performanceScore * this.WEIGHTS.PERFORMANCE / 100,
      raw: performanceScore
    };

    // 5. Score de taux d'acceptation (0-10 points)
    const acceptanceScore = await this.calculateAcceptanceRateScore(driver);
    breakdown.acceptanceRate = {
      score: acceptanceScore * this.WEIGHTS.ACCEPTANCE_RATE / 100,
      raw: acceptanceScore
    };

    // Score total (0-100)
    const total = Object.values(breakdown).reduce(
      (sum, item) => sum + item.score,
      0
    );

    return {
      total: Math.round(total * 100) / 100,
      breakdown
    };
  }

  /**
   * Calcule le score de distance (0-100)
   * Plus proche = meilleur score
   */
  static calculateDistanceScore(driver, pickupLocation) {
    if (!driver.location || !pickupLocation) {
      return 0;
    }

    // Extraire la distance depuis les données du driver
    // (findNearbyDrivers ajoute distance_km dans les résultats)
    const distanceKm = driver.distance_km || 0;

    if (distanceKm > this.MAX_DISTANCE_KM) {
      return 0;
    }

    // Score optimal à 0 km, décroît linéairement jusqu'à MAX_DISTANCE_KM
    if (distanceKm <= this.PREFERRED_DISTANCE_KM) {
      // Distance préférée : score de 100
      return 100;
    } else {
      // Score décroît linéairement de 100 à 0
      const ratio = (this.MAX_DISTANCE_KM - distanceKm) / 
                   (this.MAX_DISTANCE_KM - this.PREFERRED_DISTANCE_KM);
      return Math.max(0, Math.min(100, ratio * 100));
    }
  }

  /**
   * Calcule le score de note (0-100)
   */
  static calculateRatingScore(driver) {
    const rating = driver.driverInfo?.rating || 0;
    
    if (rating === 0) {
      // Pas de note = score moyen (50)
      return 50;
    }

    // Convertir la note (1-5) en score (0-100)
    // 5 étoiles = 100, 4 étoiles = 80, 3 étoiles = 60, etc.
    return rating * 20;
  }

  /**
   * Calcule le score de disponibilité (0-100)
   */
  static calculateAvailabilityScore(driver) {
    const driverInfo = driver.driverInfo || {};

    // Chauffeur en ligne et disponible = 100
    if (driverInfo.isOnline && !driverInfo.currentRideId) {
      return 100;
    }

    // Chauffeur en ligne mais en course = 50
    if (driverInfo.isOnline && driverInfo.currentRideId) {
      return 50;
    }

    // Chauffeur hors ligne = 0
    return 0;
  }

  /**
   * Calcule le score de performance historique (0-100)
   */
  static async calculatePerformanceScore(driver) {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);

      // Compter les courses complétées dans les 30 derniers jours
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const completedRides = await rideRepository
        .createQueryBuilder('ride')
        .where('ride.driverId = :driverId', { driverId: driver.id })
        .andWhere('ride.status = :status', { status: 'completed' })
        .andWhere('ride.completedAt >= :date', { date: thirtyDaysAgo })
        .getCount();

      // Compter les annulations
      const cancelledRides = await rideRepository
        .createQueryBuilder('ride')
        .where('ride.driverId = :driverId', { driverId: driver.id })
        .andWhere('ride.status = :status', { status: 'cancelled' })
        .andWhere('ride.cancelledAt >= :date', { date: thirtyDaysAgo })
        .getCount();

      const totalRides = completedRides + cancelledRides;

      if (totalRides === 0) {
        // Pas d'historique = score moyen (50)
        return 50;
      }

      // Score basé sur le taux de complétion
      const completionRate = completedRides / totalRides;
      return completionRate * 100;
    } catch (error) {
      console.error('Erreur calcul performance:', error);
      return 50; // Score moyen en cas d'erreur
    }
  }

  /**
   * Calcule le score de taux d'acceptation (0-100)
   */
  static async calculateAcceptanceRateScore(driver) {
    try {
      const rideRepository = AppDataSource.getRepository(Ride);

      // Compter les courses acceptées dans les 7 derniers jours
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const acceptedRides = await rideRepository
        .createQueryBuilder('ride')
        .where('ride.driverId = :driverId', { driverId: driver.id })
        .andWhere('ride.status IN (:...statuses)', {
          statuses: ['accepted', 'inProgress', 'completed']
        })
        .andWhere('ride.createdAt >= :date', { date: sevenDaysAgo })
        .getCount();

      // Compter toutes les notifications reçues (approximation)
      // Note: Dans un système complet, on devrait tracker les notifications envoyées
      // Pour l'instant, on utilise les courses acceptées comme proxy
      const totalNotifications = acceptedRides * 2; // Estimation

      if (totalNotifications === 0) {
        return 50; // Score moyen
      }

      // Taux d'acceptation
      const acceptanceRate = acceptedRides / totalNotifications;
      return Math.min(100, acceptanceRate * 200); // Multiplier par 2 pour normaliser
    } catch (error) {
      console.error('Erreur calcul taux acceptation:', error);
      return 50; // Score moyen en cas d'erreur
    }
  }

  /**
   * Assigne automatiquement un chauffeur à une course
   * @param {number} rideId - ID de la course
   * @param {Object} bestMatch - Résultat de findBestDriver
   * @returns {Promise<Object>} Course mise à jour
   */
  static async assignDriverToRide(rideId, bestMatch) {
    if (!bestMatch || !bestMatch.driver) {
      throw new Error('Aucun chauffeur disponible pour cette course');
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    // Mettre à jour la course
    const ride = await rideRepository.findOne({ where: { id: rideId } });
    if (!ride) {
      throw new Error('Course non trouvée');
    }

    if (ride.status !== 'pending') {
      throw new Error('Cette course n\'est plus disponible');
    }

    ride.driverId = bestMatch.driver.id;
    ride.status = 'accepted';
    await rideRepository.save(ride);

    // Mettre à jour le statut du chauffeur
    const driver = await userRepository.findOne({
      where: { id: bestMatch.driver.id }
    });
    if (driver && driver.driverInfo) {
      driver.driverInfo.currentRideId = rideId;
      await userRepository.save(driver);
    }

    return {
      ride,
      driver: bestMatch.driver,
      score: bestMatch.score,
      breakdown: bestMatch.breakdown
    };
  }
}

module.exports = DriverMatchingService;

