//
//  geofencing.js
//  Tshiakani VTC
//
//  Middleware de géofencing pour vérifier la proximité du chauffeur
//  Utilise ST_DWithin de PostGIS pour la sécurité
//

const AppDataSource = require('../config/database');

/**
 * Middleware pour vérifier que le chauffeur est proche du point de départ
 * Empêche la fraude et les annulations tardives
 * 
 * @param {number} maxDistanceMeters - Distance maximale autorisée en mètres (défaut: 2000m)
 * @returns {Function} Middleware Express
 */
const verifyDriverProximity = (maxDistanceMeters = 2000) => {
  return async (req, res, next) => {
    try {
      // Vérifier que l'utilisateur est un chauffeur
      if (req.user.role !== 'driver') {
        return res.status(403).json({ 
          error: 'Seuls les conducteurs peuvent effectuer cette action' 
        });
      }

      // Récupérer la position actuelle du chauffeur depuis la requête
      const driverLocation = req.body.driverLocation || req.body.location;
      if (!driverLocation || !driverLocation.latitude || !driverLocation.longitude) {
        return res.status(400).json({ 
          error: 'Position du chauffeur requise (driverLocation: {latitude, longitude})' 
        });
      }

      // Récupérer le point de départ depuis la requête ou les paramètres
      let pickupLocation;
      
      if (req.body.pickupLocation) {
        pickupLocation = req.body.pickupLocation;
      } else if (req.params.rideId || req.params.courseId) {
        // Récupérer la course depuis la base de données
        const Ride = require('../entities/Ride');
        const rideRepository = AppDataSource.getRepository(Ride);
        const rideId = parseInt(req.params.rideId || req.params.courseId);
        const ride = await rideRepository.findOne({ where: { id: rideId } });

        if (!ride) {
          return res.status(404).json({ error: 'Course non trouvée' });
        }

        // Extraire les coordonnées du point de départ depuis PostGIS
        if (ride.pickupLocation && ride.pickupLocation.coordinates) {
          pickupLocation = {
            latitude: ride.pickupLocation.coordinates[1],
            longitude: ride.pickupLocation.coordinates[0]
          };
        } else {
          return res.status(400).json({ 
            error: 'Point de départ de la course non trouvé' 
          });
        }
      } else {
        return res.status(400).json({ 
          error: 'Point de départ requis (pickupLocation ou rideId)' 
        });
      }

      // Vérifier la distance avec ST_DWithin de PostGIS
      const distanceQuery = `
        SELECT ST_Distance(
          ST_MakePoint($1, $2)::geography,
          ST_MakePoint($3, $4)::geography
        ) AS distance
      `;

      const result = await AppDataSource.manager.query(distanceQuery, [
        driverLocation.longitude,
        driverLocation.latitude,
        pickupLocation.longitude,
        pickupLocation.latitude
      ]);

      const distanceMeters = result[0].distance;

      if (distanceMeters > maxDistanceMeters) {
        return res.status(403).json({
          error: `Le chauffeur est trop éloigné du point de départ`,
          details: {
            distance: Math.round(distanceMeters),
            maxAllowed: maxDistanceMeters,
            distanceKm: (distanceMeters / 1000).toFixed(2)
          }
        });
      }

      // Ajouter les informations de distance à la requête pour utilisation ultérieure
      req.driverProximity = {
        distance: distanceMeters,
        isValid: true
      };

      next();
    } catch (error) {
      console.error('Erreur vérification géofencing:', error);
      res.status(500).json({ 
        error: 'Erreur lors de la vérification de proximité' 
      });
    }
  };
};

/**
 * Middleware pour vérifier la proximité avec ST_DWithin (plus performant)
 * Utilise directement ST_DWithin pour une vérification plus rapide
 * 
 * @param {number} maxDistanceMeters - Distance maximale autorisée en mètres
 * @returns {Function} Middleware Express
 */
const verifyDriverProximityWithST_DWithin = (maxDistanceMeters = 2000) => {
  return async (req, res, next) => {
    try {
      if (req.user.role !== 'driver') {
        return res.status(403).json({ 
          error: 'Seuls les conducteurs peuvent effectuer cette action' 
        });
      }

      const driverLocation = req.body.driverLocation || req.body.location;
      if (!driverLocation || !driverLocation.latitude || !driverLocation.longitude) {
        return res.status(400).json({ 
          error: 'Position du chauffeur requise' 
        });
      }

      let pickupLocation;
      
      if (req.body.pickupLocation) {
        pickupLocation = req.body.pickupLocation;
      } else if (req.params.rideId || req.params.courseId) {
        const Ride = require('../entities/Ride');
        const rideRepository = AppDataSource.getRepository(Ride);
        const rideId = parseInt(req.params.rideId || req.params.courseId);
        const ride = await rideRepository.findOne({ where: { id: rideId } });

        if (!ride) {
          return res.status(404).json({ error: 'Course non trouvée' });
        }

        if (ride.pickupLocation && ride.pickupLocation.coordinates) {
          pickupLocation = {
            latitude: ride.pickupLocation.coordinates[1],
            longitude: ride.pickupLocation.coordinates[0]
          };
        } else {
          return res.status(400).json({ 
            error: 'Point de départ de la course non trouvé' 
          });
        }
      } else {
        return res.status(400).json({ 
          error: 'Point de départ requis' 
        });
      }

      // Utiliser ST_DWithin pour une vérification plus rapide
      const proximityQuery = `
        SELECT ST_DWithin(
          ST_MakePoint($1, $2)::geography,
          ST_MakePoint($3, $4)::geography,
          $5
        ) AS is_within_range
      `;

      const result = await AppDataSource.manager.query(proximityQuery, [
        driverLocation.longitude,
        driverLocation.latitude,
        pickupLocation.longitude,
        pickupLocation.latitude,
        maxDistanceMeters
      ]);

      const isWithinRange = result[0].is_within_range;

      if (!isWithinRange) {
        // Calculer la distance exacte pour le message d'erreur
        const distanceQuery = `
          SELECT ST_Distance(
            ST_MakePoint($1, $2)::geography,
            ST_MakePoint($3, $4)::geography
          ) AS distance
        `;
        const distanceResult = await AppDataSource.manager.query(distanceQuery, [
          driverLocation.longitude,
          driverLocation.latitude,
          pickupLocation.longitude,
          pickupLocation.latitude
        ]);
        const distanceMeters = distanceResult[0].distance;

        return res.status(403).json({
          error: `Le chauffeur est trop éloigné du point de départ`,
          details: {
            distance: Math.round(distanceMeters),
            maxAllowed: maxDistanceMeters,
            distanceKm: (distanceMeters / 1000).toFixed(2)
          }
        });
      }

      req.driverProximity = {
        isValid: true
      };

      next();
    } catch (error) {
      console.error('Erreur vérification géofencing:', error);
      res.status(500).json({ 
        error: 'Erreur lors de la vérification de proximité' 
      });
    }
  };
};

module.exports = {
  verifyDriverProximity,
  verifyDriverProximityWithST_DWithin
};

