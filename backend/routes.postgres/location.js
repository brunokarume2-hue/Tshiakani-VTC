// Routes de localisation optimisées avec PostGIS et Redis
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { io, getRedisService } = require('../server.postgres');
const logger = require('../utils/logger');

const router = express.Router();

// Mettre à jour la position (conducteur) - avec PostGIS et Redis
router.post('/update', auth, [
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('address').optional().trim(),
  body('status').optional().isIn(['available', 'en_route_to_pickup', 'in_progress', 'offline']),
  body('heading').optional().isFloat({ min: 0, max: 360 }),
  body('speed').optional().isFloat({ min: 0 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent mettre à jour leur position' });
    }

    const { latitude, longitude, address, status, heading, speed } = req.body;
    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();

    // Créer le point PostGIS
    const locationPoint = {
      type: 'Point',
      coordinates: [longitude, latitude]
    };

    // 1. Mettre à jour dans PostgreSQL (persistant)
    req.user.location = locationPoint;
    
    // Mettre à jour le statut dans driverInfo si fourni
    if (status) {
      if (!req.user.driverInfo) {
        req.user.driverInfo = {};
      }
      req.user.driverInfo.status = status;
    }
    
    // Mettre à jour l'adresse si fournie
    if (address) {
      if (!req.user.driverInfo) {
        req.user.driverInfo = {};
      }
      req.user.driverInfo.currentLocation = {
          latitude,
          longitude,
          address,
          timestamp: new Date()
      };
    }
    
    await userRepository.save(req.user);

    // 2. Mettre à jour dans Redis (temps réel - toutes les 2-3 secondes)
    if (redisService && redisService.isReady()) {
      try {
        const driverStatus = status || req.user.driverInfo?.status || 'available';
        const rideId = req.user.driverInfo?.currentRideId || null;

        await redisService.updateDriverLocation(req.user.id, {
          latitude,
          longitude,
          status: driverStatus,
          currentRideId: rideId,
          heading: heading || 0,
          speed: speed || 0
        });

        logger.debug('Driver location updated in Redis', {
          driverId: req.user.id,
          latitude,
          longitude,
          status: driverStatus,
          currentRideId: rideId
        });
      } catch (redisError) {
        logger.warn('Failed to update driver location in Redis', {
          error: redisError.message,
          driverId: req.user.id
        });
      }
    }

    // 3. Distribuer la position via Socket.io (CIBLÉ - uniquement aux clients de la course active)
    if (io) {
      const { clientNamespace } = require('../server.postgres');
      
      try {
        // Récupérer le currentRideId depuis Redis ou driverInfo
        let currentRideId = req.user.driverInfo?.currentRideId || null;
        
        // Si pas dans driverInfo, récupérer depuis Redis
        if (!currentRideId && redisService && redisService.isReady()) {
          try {
            const driverLocation = await redisService.getDriverLocation(req.user.id);
            currentRideId = driverLocation?.currentRideId || null;
          } catch (redisReadError) {
            logger.debug('Impossible de récupérer currentRideId depuis Redis', {
              error: redisReadError.message,
              driverId: req.user.id
            });
          }
        }
        
        // Si le chauffeur a une course active, distribuer uniquement aux clients de cette course
        if (currentRideId && clientNamespace) {
          const locationData = {
            type: 'driver_location_update',
            driverId: req.user.id,
            rideId: currentRideId,
            location: {
              latitude,
              longitude,
              address: address || null,
              heading: heading || 0,
              speed: speed || 0
            },
            status: status || req.user.driverInfo?.status || 'available',
            timestamp: new Date().toISOString()
          };
          
          // Distribuer UNIQUEMENT aux clients qui suivent cette course (room ride:${rideId})
          clientNamespace.to(`ride:${currentRideId}`).emit('driver:location:update', locationData);
          
          logger.debug('Driver location distributed via /location/update', {
            driverId: req.user.id,
            rideId: currentRideId,
            latitude,
            longitude
          });
        } else {
          // Si le chauffeur n'a pas de course active, ne rien distribuer
          // Le broadcaster automatique gérera la distribution depuis Redis
          logger.debug('Driver location not distributed immediately (no active ride or no clients)', {
            driverId: req.user.id,
            hasRideId: !!currentRideId,
            hasClientNamespace: !!clientNamespace
          });
        }
      } catch (socketError) {
        logger.warn('Failed to distribute driver location via WebSocket', {
          error: socketError.message,
          driverId: req.user.id
        });
      }
    }

    res.json({ 
      success: true, 
      location: {
        latitude,
        longitude,
        address
      },
      status: status || req.user.driverInfo?.status || 'available'
    });
  } catch (error) {
    logger.error('Erreur mise à jour position', {
      error: error.message,
      stack: error.stack,
      userId: req.user?.id
    });
    res.status(500).json({ error: 'Erreur lors de la mise à jour de la position' });
  }
});

// Obtenir les conducteurs proches - OPTIMISÉ avec Redis (temps réel) + PostGIS (fallback)
router.get('/drivers/nearby', auth, async (req, res) => {
  try {
    const { latitude, longitude, radius = 5, limit = 20 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Latitude et longitude requises' });
    }

    // Limiter le rayon et le nombre de résultats pour optimiser les performances
    const searchRadius = Math.min(parseFloat(radius) || 5, 20); // Max 20 km
    const resultLimit = Math.min(parseInt(limit) || 20, 50); // Max 50 résultats

    const redisService = getRedisService();
    let drivers = [];

    // Stratégie hybride: Redis (temps réel) + PostGIS (fallback)
    if (redisService && redisService.isReady()) {
      try {
        // 1. Récupérer depuis Redis (temps réel)
        const availableDrivers = await redisService.getAvailableDrivers();

        // 2. Calculer la distance pour chaque conducteur
        const driversWithDistance = availableDrivers.map(driver => {
          // Calculer la distance (formule de Haversine simplifiée)
          const distance = calculateDistance(
            { latitude: parseFloat(latitude), longitude: parseFloat(longitude) },
            { latitude: driver.latitude, longitude: driver.longitude }
          );
          return {
            ...driver,
            distance_km: distance
          };
        });

        // 3. Filtrer par rayon et trier par distance
        drivers = driversWithDistance
          .filter(driver => driver.distance_km <= searchRadius)
          .sort((a, b) => a.distance_km - b.distance_km)
          .slice(0, resultLimit);

        logger.debug('Drivers found via Redis', {
          count: drivers.length,
          radius: searchRadius
        });
      } catch (redisError) {
        logger.warn('Failed to get drivers from Redis, falling back to PostGIS', {
          error: redisError.message
        });
      }
    }

    // Fallback vers PostGIS si Redis n'est pas disponible ou si aucun conducteur trouvé
    if (drivers.length === 0) {
    const AppDataSource = require('../config/database');
      const postgisDrivers = await User.findNearbyDrivers(
      parseFloat(latitude),
      parseFloat(longitude),
      searchRadius,
      AppDataSource
    );

      drivers = postgisDrivers.slice(0, resultLimit).map(driver => ({
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phoneNumber,
        driverInfo: driver.driverInfo,
        distance_km: driver.distance_km,
        latitude: driver.location ? driver.location.coordinates[1] : null,
        longitude: driver.location ? driver.location.coordinates[0] : null
      }));

      logger.debug('Drivers found via PostGIS', {
        count: drivers.length,
        radius: searchRadius
      });
    }

    // Formater la réponse
    const formattedDrivers = drivers.map(driver => ({
      id: driver.id || driver.driverId,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      driverInfo: driver.driverInfo || {},
      distance: driver.distance_km,
      location: {
        latitude: driver.latitude || (driver.location ? driver.location.coordinates[1] : null),
        longitude: driver.longitude || (driver.location ? driver.location.coordinates[0] : null)
      },
      status: driver.status || 'available',
      lastUpdate: driver.lastUpdate
    }));

    res.json({
      drivers: formattedDrivers,
      count: formattedDrivers.length,
      totalFound: drivers.length,
      radius: searchRadius,
      source: redisService && redisService.isReady() ? 'redis' : 'postgis'
    });
  } catch (error) {
    logger.error('Erreur recherche conducteurs', {
      error: error.message,
      stack: error.stack
    });
    res.status(500).json({ error: 'Erreur lors de la recherche' });
  }
});

// Fonction helper pour calculer la distance (formule de Haversine)
function calculateDistance(point1, point2) {
  const R = 6371; // Rayon de la Terre en kilomètres
  const dLat = (point2.latitude - point1.latitude) * Math.PI / 180;
  const dLon = (point2.longitude - point1.longitude) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(point1.latitude * Math.PI / 180) * Math.cos(point2.latitude * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Activer/désactiver le statut en ligne (conducteur)
router.post('/online', auth, [
  body('isOnline').isBoolean()
], async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent modifier leur statut' });
    }

    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();
    const isOnline = req.body.isOnline;

    // 1. Mettre à jour dans PostgreSQL
    if (!req.user.driverInfo) {
      req.user.driverInfo = {};
    }
    req.user.driverInfo.isOnline = isOnline;
    req.user.driverInfo.status = isOnline ? 'available' : 'offline';
    await userRepository.save(req.user);

    // 2. Mettre à jour dans Redis
    if (redisService && redisService.isReady()) {
      try {
        if (isOnline) {
          // Si le conducteur se connecte, mettre à jour Redis avec sa position actuelle
          if (req.user.location) {
            const coordinates = req.user.location.coordinates;
            await redisService.updateDriverLocation(req.user.id, {
              latitude: coordinates[1],
              longitude: coordinates[0],
              status: 'available',
              currentRideId: null,
              heading: 0,
              speed: 0
            });
          }
        } else {
          // Si le conducteur se déconnecte, supprimer de Redis
          await redisService.removeDriver(req.user.id);
        }
      } catch (redisError) {
        logger.warn('Failed to update driver status in Redis', {
          error: redisError.message,
          driverId: req.user.id
        });
      }
    }

    res.json({ 
      success: true, 
      isOnline: req.user.driverInfo.isOnline 
    });
  } catch (error) {
    logger.error('Erreur changement statut', {
      error: error.message,
      stack: error.stack,
      userId: req.user?.id
    });
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

module.exports = router;

