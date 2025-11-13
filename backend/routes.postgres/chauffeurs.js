// Route pour récupérer les chauffeurs (optimisée pour Render)
const express = require('express');
const AppDataSource = require('../config/database');
const User = require('../entities/User');

const router = express.Router();

/**
 * GET /api/chauffeurs
 * Récupère la liste des chauffeurs avec leurs localisations
 * Utilise PostGIS pour les requêtes géospatiales
 * 
 * Query params:
 * - lat: latitude (optionnel, pour filtrer par proximité)
 * - lon: longitude (optionnel, pour filtrer par proximité)
 * - radius: rayon en km (défaut: 5)
 * - online: true/false (filtrer par statut en ligne)
 * - limit: nombre de résultats (défaut: 50)
 */
router.get('/', async (req, res) => {
  try {
    const { lat, lon, radius = 5, online, limit = 50 } = req.query;
    const userRepository = AppDataSource.getRepository(User);

    let formattedDrivers = [];

    // OPTIMISATION: Si des coordonnées sont fournies, utiliser directement la fonction SQL optimisée
    if (lat && lon) {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lon);
      const radiusKm = parseFloat(radius);
      const queryLimit = Math.min(parseInt(limit), 50); // Limiter à 50 max

      try {
        // Utiliser la fonction SQL optimisée qui utilise les index GIST
        // Construction de la requête avec gestion correcte du filtre online
        let onlineFilter = '';
        const queryParams = [latitude, longitude, radiusKm, queryLimit];
        
        if (online === 'true') {
          onlineFilter = "AND u.driver_info->>'isOnline' = 'true'";
        } else if (online === 'false') {
          onlineFilter = "AND (u.driver_info->>'isOnline' IS NULL OR u.driver_info->>'isOnline' = 'false')";
        }
        // Si online n'est pas spécifié, on ne filtre pas par statut (onlineFilter reste vide)
        
        const sqlResult = await AppDataSource.query(
          `SELECT 
            u.id,
            u.name,
            u.phone_number,
            u.driver_info,
            u.fcm_token,
            u.is_verified,
            u.created_at,
            ST_Distance(
              u.location,
              ST_MakePoint($2, $1)::geography
            ) / 1000 AS distance_km,
            ST_Y(u.location::geometry) AS location_lat,
            ST_X(u.location::geometry) AS location_lon
          FROM users u
          WHERE u.role = 'driver'
            AND u.location IS NOT NULL
            ${onlineFilter}
            AND ST_DWithin(
              u.location,
              ST_MakePoint($2, $1)::geography,
              $3 * 1000
            )
          ORDER BY u.location <-> ST_MakePoint($2, $1)::geography
          LIMIT $4`,
          queryParams
        );

        // Formater les résultats
        formattedDrivers = sqlResult.map(driver => {
          const driverInfo = driver.driver_info || {};
          return {
            id: driver.id,
            name: driver.name,
            phoneNumber: driver.phone_number,
            isOnline: driverInfo.isOnline === true || driverInfo.isOnline === 'true',
            rating: parseFloat(driverInfo.rating) || 0,
            vehicle: driverInfo.vehicle || null,
            location: driver.location_lat && driver.location_lon ? {
              latitude: parseFloat(driver.location_lat),
              longitude: parseFloat(driver.location_lon)
            } : null,
            distanceKm: parseFloat(driver.distance_km) || 0,
            isVerified: driver.is_verified || false,
            createdAt: driver.created_at,
            fcmToken: driver.fcm_token || null
          };
        });
      } catch (error) {
        console.error('Erreur requête SQL PostGIS optimisée:', error);
        // En cas d'erreur, fallback sur TypeORM
        throw error;
      }
    } else {
      // Pas de coordonnées: utiliser TypeORM pour les requêtes simples
      let query = userRepository
        .createQueryBuilder('user')
        .where('user.role = :role', { role: 'driver' });

      // Filtrer par statut en ligne si spécifié
      if (online === 'true') {
        query = query.andWhere("user.driver_info->>'isOnline' = 'true'");
      } else if (online === 'false') {
        query = query.andWhere(
          "(user.driver_info->>'isOnline' IS NULL OR user.driver_info->>'isOnline' = 'false')"
        );
      }

      // Trier par date de création
      query = query.orderBy('user.createdAt', 'DESC');

      // Limiter les résultats
      query = query.limit(parseInt(limit));

      const drivers = await query.getMany();

      // Formater la réponse pour iOS et Dashboard
      formattedDrivers = drivers.map(driver => {
        const driverInfo = driver.driverInfo || {};
        let location = null;

        // Extraire les coordonnées si la localisation existe
        if (driver.location) {
          try {
            if (driver.location.coordinates) {
              location = {
                latitude: driver.location.coordinates[1],
                longitude: driver.location.coordinates[0]
              };
            }
          } catch (error) {
            console.error('Erreur extraction localisation:', error);
            location = null;
          }
        }

        return {
          id: driver.id,
          name: driver.name,
          phoneNumber: driver.phoneNumber,
          isOnline: driverInfo.isOnline === true || driverInfo.isOnline === 'true',
          rating: parseFloat(driverInfo.rating) || 0,
          vehicle: driverInfo.vehicle || null,
          location,
          distanceKm: null, // Pas de distance sans coordonnées
          isVerified: driver.isVerified,
          createdAt: driver.createdAt
        };
      });
    }

    res.json({
      success: true,
      count: formattedDrivers.length,
      drivers: formattedDrivers,
      filters: {
        lat: lat ? parseFloat(lat) : null,
        lon: lon ? parseFloat(lon) : null,
        radius: parseFloat(radius),
        online: online || null,
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Erreur récupération chauffeurs:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des chauffeurs',
      message: error.message
    });
  }
});

/**
 * GET /api/chauffeurs/:id
 * Récupère un chauffeur spécifique
 */
router.get('/:id', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.id),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({
        success: false,
        error: 'Chauffeur non trouvé'
      });
    }

    const driverInfo = driver.driverInfo || {};
    let location = null;

    if (driver.location) {
      try {
        if (driver.location.coordinates) {
          location = {
            latitude: driver.location.coordinates[1],
            longitude: driver.location.coordinates[0]
          };
        }
      } catch (error) {
        console.error('Erreur extraction localisation:', error);
      }
    }

    res.json({
      success: true,
      driver: {
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phoneNumber,
        isOnline: driverInfo.isOnline === true || driverInfo.isOnline === 'true',
        rating: parseFloat(driverInfo.rating) || 0,
        vehicle: driverInfo.vehicle || null,
        location,
        isVerified: driver.isVerified,
        createdAt: driver.createdAt
      }
    });
  } catch (error) {
    console.error('Erreur récupération chauffeur:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du chauffeur',
      message: error.message
    });
  }
});

module.exports = router;

