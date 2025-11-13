//
//  PricingService.js
//  Tshiakani VTC
//
//  Service IA pour le calcul de prix dynamique
//  Prend en compte : heure, jour, demande, distance
//

const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const PriceConfiguration = require('../entities/PriceConfiguration');
const GoogleMapsService = require('./GoogleMapsService');
const logger = require('../utils/logger');

/**
 * Service de pricing dynamique avec IA
 * Calcule le prix selon le temps, le moment et la demande
 * Utilise les tarifs configurables depuis la base de données
 */
class PricingService {
  // Valeurs par défaut (fallback si pas de configuration)
  static DEFAULT_BASE_PRICE = 500.0;
  static DEFAULT_PRICE_PER_KM = 200.0;
  static DEFAULT_RUSH_HOUR_MULTIPLIER = 1.5;
  static DEFAULT_NIGHT_MULTIPLIER = 1.3;
  static DEFAULT_WEEKEND_MULTIPLIER = 1.2;
  static DEFAULT_NORMAL_MULTIPLIER = 1.0;

  // Cache de la configuration (mis à jour toutes les 5 minutes)
  static configCache = null;
  static configCacheTime = null;
  static CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

  /**
   * Charge la configuration des prix depuis la base de données
   * @returns {Promise<Object>} Configuration des prix
   */
  static async loadPriceConfiguration() {
    // Vérifier le cache
    const now = Date.now();
    if (this.configCache && this.configCacheTime && (now - this.configCacheTime) < this.CACHE_DURATION) {
      return this.configCache;
    }

    try {
      const configRepository = AppDataSource.getRepository(PriceConfiguration);
      let config = await configRepository.findOne({
        where: { isActive: true },
        order: { updatedAt: 'DESC' }
      });

      // Si pas de configuration active, créer une par défaut
      if (!config) {
        config = configRepository.create({
          basePrice: this.DEFAULT_BASE_PRICE,
          pricePerKm: this.DEFAULT_PRICE_PER_KM,
          rushHourMultiplier: this.DEFAULT_RUSH_HOUR_MULTIPLIER,
          nightMultiplier: this.DEFAULT_NIGHT_MULTIPLIER,
          weekendMultiplier: this.DEFAULT_WEEKEND_MULTIPLIER,
          surgeLowDemandMultiplier: 0.9,
          surgeNormalMultiplier: 1.0,
          surgeHighMultiplier: 1.2,
          surgeVeryHighMultiplier: 1.4,
          surgeExtremeMultiplier: 1.6,
          description: 'Configuration par défaut - Kinshasa',
          isActive: true
        });
        await configRepository.save(config);
      }

      // Mettre en cache
      this.configCache = {
        basePrice: parseFloat(config.basePrice),
        pricePerKm: parseFloat(config.pricePerKm),
        rushHourMultiplier: parseFloat(config.rushHourMultiplier),
        nightMultiplier: parseFloat(config.nightMultiplier),
        weekendMultiplier: parseFloat(config.weekendMultiplier),
        surgeLowDemandMultiplier: parseFloat(config.surgeLowDemandMultiplier),
        surgeNormalMultiplier: parseFloat(config.surgeNormalMultiplier),
        surgeHighMultiplier: parseFloat(config.surgeHighMultiplier),
        surgeVeryHighMultiplier: parseFloat(config.surgeVeryHighMultiplier),
        surgeExtremeMultiplier: parseFloat(config.surgeExtremeMultiplier)
      };
      this.configCacheTime = now;

      return this.configCache;
    } catch (error) {
      console.error('Erreur chargement configuration prix:', error);
      // Retourner les valeurs par défaut en cas d'erreur
      return {
        basePrice: this.DEFAULT_BASE_PRICE,
        pricePerKm: this.DEFAULT_PRICE_PER_KM,
        rushHourMultiplier: this.DEFAULT_RUSH_HOUR_MULTIPLIER,
        nightMultiplier: this.DEFAULT_NIGHT_MULTIPLIER,
        weekendMultiplier: this.DEFAULT_WEEKEND_MULTIPLIER,
        surgeLowDemandMultiplier: 0.9,
        surgeNormalMultiplier: 1.0,
        surgeHighMultiplier: 1.2,
        surgeVeryHighMultiplier: 1.4,
        surgeExtremeMultiplier: 1.6
      };
    }
  }

  /**
   * Invalide le cache de configuration (appelé après mise à jour)
   */
  static invalidateCache() {
    this.configCache = null;
    this.configCacheTime = null;
  }

  /**
   * Calcule le prix dynamique d'une course
   * Utilise Google Maps Routes API pour calculer la distance et le temps réels
   * @param {number} distance - Distance en kilomètres (optionnel, sera calculée si non fournie)
   * @param {Date} timestamp - Date/heure de la demande
   * @param {Object} pickupLocation - Point de départ {latitude, longitude}
   * @param {Object} dropoffLocation - Point d'arrivée {latitude, longitude} (optionnel)
   * @returns {Promise<Object>} {price, basePrice, multipliers, surgeMultiplier, distance, duration}
   */
  static async calculateDynamicPrice(distance, timestamp = new Date(), pickupLocation = null, dropoffLocation = null) {
    // Charger la configuration depuis la base de données
    const config = await this.loadPriceConfiguration();

    let calculatedDistance = distance;
    let duration = null;

    // Si dropoffLocation est fourni, utiliser Google Maps Routes API pour calculer la distance et le temps réels
    if (dropoffLocation && pickupLocation) {
      try {
        const routeData = await GoogleMapsService.calculateRoute(
          pickupLocation,
          dropoffLocation,
          {
            travelMode: 'DRIVE',
            routingPreference: 'TRAFFIC_AWARE',
            language: 'fr'
          }
        );

        calculatedDistance = routeData.distance.kilometers;
        duration = routeData.duration;

        logger.debug('Distance et temps calculés via Google Maps Routes API', {
          distance: calculatedDistance,
          duration: duration.text
        });
      } catch (error) {
        logger.warn('Erreur calcul Google Maps Routes API, tentative avec Haversine', {
          error: error.message
        });
        
        // Fallback: Utiliser Haversine pour calculer une distance approximative
        try {
          const haversineResult = GoogleMapsService.calculateDistanceHaversine(
            pickupLocation,
            dropoffLocation
          );
          calculatedDistance = haversineResult.distance.kilometers;
          logger.debug('Distance calculée via Haversine (fallback)', {
            distance: calculatedDistance
          });
        } catch (haversineError) {
          logger.warn('Erreur calcul Haversine, utilisation de la distance fournie ou valeur par défaut', {
            error: haversineError.message
          });
        }
      }
    }

    // Validation: S'assurer que calculatedDistance est un nombre valide
    // Si ce n'est pas le cas, utiliser une valeur par défaut ou calculer avec Haversine
    if (calculatedDistance === null || calculatedDistance === undefined || isNaN(calculatedDistance)) {
      // Si les locations sont disponibles, utiliser Haversine comme dernier recours
      if (pickupLocation && dropoffLocation) {
        try {
          const haversineResult = GoogleMapsService.calculateDistanceHaversine(
            pickupLocation,
            dropoffLocation
          );
          calculatedDistance = haversineResult.distance.kilometers;
          logger.debug('Distance calculée via Haversine (validation)', {
            distance: calculatedDistance
          });
        } catch (error) {
          logger.warn('Impossible de calculer la distance, utilisation d\'une valeur par défaut', {
            error: error.message
          });
          // Valeur par défaut: 5 km (distance moyenne à Kinshasa)
          calculatedDistance = 5.0;
        }
      } else {
        // Pas de locations disponibles, utiliser une valeur par défaut
        logger.warn('Distance non fournie et locations non disponibles, utilisation d\'une valeur par défaut');
        calculatedDistance = 5.0; // Distance par défaut: 5 km
      }
    }

    // S'assurer que calculatedDistance est un nombre positif
    calculatedDistance = Math.max(0, parseFloat(calculatedDistance) || 0);

    // Prix de base selon la distance
    const basePrice = config.basePrice + (calculatedDistance * config.pricePerKm);

    // Calculer les multiplicateurs
    const timeMultiplier = await this.getTimeMultiplier(timestamp, config);
    const dayMultiplier = await this.getDayMultiplier(timestamp, config);
    
    // Calculer le multiplicateur de demande (surge pricing)
    const surgeMultiplier = await this.calculateSurgeMultiplier(
      pickupLocation,
      timestamp,
      config
    );

    // Prix final = prix de base × multiplicateurs
    const finalPrice = Math.round(
      basePrice * timeMultiplier * dayMultiplier * surgeMultiplier
    );

    return {
      price: finalPrice,
      basePrice: Math.round(basePrice),
      distance: calculatedDistance,
      duration: duration,
      multipliers: {
        time: timeMultiplier,
        day: dayMultiplier,
        surge: surgeMultiplier
      },
      breakdown: {
        base: config.basePrice,
        distance: calculatedDistance * config.pricePerKm,
        timeAdjustment: (timeMultiplier - 1) * 100, // Pourcentage
        dayAdjustment: (dayMultiplier - 1) * 100,
        surgeAdjustment: (surgeMultiplier - 1) * 100
      }
    };
  }

  /**
   * Obtient le multiplicateur selon l'heure de la journée
   * @param {Date} timestamp - Date/heure
   * @param {Object} config - Configuration des prix
   * @returns {Promise<number>} Multiplicateur
   */
  static async getTimeMultiplier(timestamp, config = null) {
    if (!config) {
      config = await this.loadPriceConfiguration();
    }

    const hour = timestamp.getHours();

    // Heures de pointe : 7h-9h et 17h-19h
    if ((hour >= 7 && hour < 9) || (hour >= 17 && hour < 19)) {
      return config.rushHourMultiplier;
    }

    // Nuit : 22h-6h
    if (hour >= 22 || hour < 6) {
      return config.nightMultiplier;
    }

    // Heures normales
    return this.DEFAULT_NORMAL_MULTIPLIER;
  }

  /**
   * Obtient le multiplicateur selon le jour de la semaine
   * @param {Date} timestamp - Date/heure
   * @param {Object} config - Configuration des prix
   * @returns {Promise<number>} Multiplicateur
   */
  static async getDayMultiplier(timestamp, config = null) {
    if (!config) {
      config = await this.loadPriceConfiguration();
    }

    const day = timestamp.getDay(); // 0 = Dimanche, 6 = Samedi

    // Week-end : Samedi (6) et Dimanche (0)
    if (day === 0 || day === 6) {
      return config.weekendMultiplier;
    }

    return this.DEFAULT_NORMAL_MULTIPLIER;
  }

  /**
   * Calcule le multiplicateur de demande (surge pricing)
   * Analyse la demande dans la zone pour ajuster le prix
   * @param {Object} pickupLocation - {latitude, longitude}
   * @param {Date} timestamp - Date/heure
   * @param {Object} config - Configuration des prix
   * @returns {Promise<number>} Multiplicateur de demande
   */
  static async calculateSurgeMultiplier(pickupLocation, timestamp, config = null) {
    if (!config) {
      config = await this.loadPriceConfiguration();
    }
    if (!pickupLocation) {
      return config ? config.surgeNormalMultiplier : this.DEFAULT_NORMAL_MULTIPLIER;
    }

    try {
      // Optimisation: Requête combinée pour éviter deux appels séparés
      const fifteenMinutesAgo = new Date(timestamp.getTime() - 15 * 60 * 1000);

      // Requête optimisée combinant le comptage des courses et des conducteurs
      const surgeQuery = `
        WITH nearby_rides AS (
          SELECT COUNT(*) as pending_count
          FROM rides
          WHERE status = 'pending'
            AND created_at >= $1
            AND ST_DWithin(
              pickup_location::geography,
              ST_MakePoint($2, $3)::geography,
              2000
            )
        ),
        nearby_drivers AS (
          SELECT COUNT(*) as driver_count
          FROM users
          WHERE role = 'driver'
            AND driver_info->>'isOnline' = 'true'
            AND location IS NOT NULL
            AND ST_DWithin(
              location::geography,
              ST_MakePoint($2, $3)::geography,
              5000
            )
        )
        SELECT 
          COALESCE((SELECT pending_count FROM nearby_rides), 0) as pending_rides,
          COALESCE((SELECT driver_count FROM nearby_drivers), 0) as available_drivers
      `;

      const result = await AppDataSource.query(surgeQuery, [
        fifteenMinutesAgo,
        pickupLocation.longitude,
        pickupLocation.latitude
      ]);

      const pendingRidesCount = parseInt(result[0]?.pending_rides || 0);
      const availableDriversCount = parseInt(result[0]?.available_drivers || 0);

      // Calculer le ratio demande/offre
      let demandSupplyRatio = 0;
      if (availableDriversCount > 0) {
        demandSupplyRatio = pendingRidesCount / availableDriversCount;
      } else if (pendingRidesCount > 0) {
        // Pas de conducteurs disponibles mais des demandes = forte demande
        demandSupplyRatio = 2.0;
      }

      // Appliquer le multiplicateur selon le ratio (utilise la configuration)
      if (demandSupplyRatio < 0.5) {
        return config.surgeLowDemandMultiplier;
      } else if (demandSupplyRatio <= 1.0) {
        return config.surgeNormalMultiplier;
      } else if (demandSupplyRatio <= 1.5) {
        return config.surgeHighMultiplier;
      } else if (demandSupplyRatio <= 2.0) {
        return config.surgeVeryHighMultiplier;
      } else {
        return config.surgeExtremeMultiplier;
      }
    } catch (error) {
      console.error('Erreur calcul surge pricing:', error);
      // En cas d'erreur, retourner le multiplicateur normal
      return config ? config.surgeNormalMultiplier : this.DEFAULT_NORMAL_MULTIPLIER;
    }
  }

  /**
   * Obtient une explication textuelle du prix
   * @param {Object} priceData} - Données du prix calculé
   * @returns {string} Explication
   */
  static getPriceExplanation(priceData) {
    const { multipliers, breakdown } = priceData;
    const reasons = [];

    if (multipliers.time > 1.0) {
      if (multipliers.time === this.RUSH_HOUR_MULTIPLIER) {
        reasons.push('Heures de pointe');
      } else if (multipliers.time === this.NIGHT_MULTIPLIER) {
        reasons.push('Tarif de nuit');
      }
    }

    if (multipliers.day > 1.0) {
      reasons.push('Week-end');
    }

    if (multipliers.surge > 1.0) {
      const surgePercent = Math.round((multipliers.surge - 1) * 100);
      reasons.push(`Demande élevée (+${surgePercent}%)`);
    } else if (multipliers.surge < 1.0) {
      reasons.push('Demande faible');
    }

    if (reasons.length === 0) {
      return 'Tarif standard';
    }

    return reasons.join(' • ');
  }
}

module.exports = PricingService;

