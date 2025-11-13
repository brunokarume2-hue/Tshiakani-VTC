// Routes spécifiques pour l'application Client
const express = require('express');
const { body, validationResult, query } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const PricingService = require('../services/PricingService');
const { io, clientNamespace, getRealtimeRideService } = require('../server.postgres');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Routeur pour les endpoints v1
const v1Router = express.Router();

/**
 * @mvp true
 * @route GET /api/client/track_driver/:rideId
 * @description Suivre la position du chauffeur en temps réel pour une course (utilisé dans MVP)
 * Retourne:
 * - Les coordonnées géospatiales (latitude, longitude) du chauffeur
 * - Le statut du chauffeur (en_route_to_pickup, on_trip, etc.)
 * - Le nom du chauffeur
 * - L'heure d'arrivée estimée (ETA) en minutes
 */
router.get('/track_driver/:rideId', auth, async (req, res) => {
  try {
    const rideId = parseInt(req.params.rideId);
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    // 1. Récupérer la course avec relations
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ 
        error: 'Course non trouvée' 
      });
    }

    // 2. Vérifier que l'utilisateur est le client de cette course
    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Vous n\'êtes pas autorisé à suivre cette course'
      });
    }

    // 3. Vérifier qu'un chauffeur est assigné
    if (!ride.driverId) {
      return res.status(404).json({ 
        error: 'Aucun chauffeur assigné',
        message: 'Aucun chauffeur n\'a encore accepté cette course'
      });
    }

    // 4. Récupérer les informations du chauffeur
    const driver = await userRepository.findOne({
      where: { id: ride.driverId }
    });

    if (!driver) {
      return res.status(404).json({ 
        error: 'Chauffeur non trouvé' 
      });
    }

    // 5. Extraire les coordonnées depuis PostGIS
    let location = null;
    if (driver.location && driver.location.coordinates) {
      const coordinates = driver.location.coordinates;
      location = {
        latitude: coordinates[1], // PostGIS stocke [longitude, latitude]
        longitude: coordinates[0],
        timestamp: driver.updatedAt || driver.createdAt
      };
    }

    // 6. Récupérer le statut du chauffeur depuis driverInfo
    const driverStatus = driver.driverInfo?.status || 'unknown';
    const isOnline = driver.driverInfo?.isOnline || false;

    // 7. Calculer l'ETA (temps d'arrivée estimé) si la position est disponible
    let estimatedArrivalMinutes = null;
    if (location && ride.pickupLocation && ride.pickupLocation.coordinates) {
      try {
        // Utiliser PostGIS pour calculer la distance réelle
        const distanceQuery = `
          SELECT ST_Distance(
            ST_MakePoint($1, $2)::geography,
            ST_MakePoint($3, $4)::geography
          ) / 1000 AS distance_km
        `;
        
        const result = await AppDataSource.query(distanceQuery, [
          location.longitude,
          location.latitude,
          ride.pickupLocation.coordinates[0], // longitude
          ride.pickupLocation.coordinates[1]  // latitude
        ]);
        
        const distanceKm = parseFloat(result[0]?.distance_km || 0);
        
        // Estimation: 2 minutes par km en moyenne (peut être ajusté)
        // Vitesse moyenne estimée: 30 km/h
        estimatedArrivalMinutes = Math.max(1, Math.ceil(distanceKm * 2));
      } catch (etaError) {
        console.error('Erreur calcul ETA:', etaError);
        // Ne pas faire échouer la requête si le calcul ETA échoue
      }
    }

    // 8. Formater la réponse
    const response = {
      success: true,
      rideId: ride.id,
      driver: {
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phoneNumber,
        status: driverStatus,
        isOnline: isOnline
      },
      location: location,
      estimatedArrivalMinutes: estimatedArrivalMinutes,
      rideStatus: ride.status,
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur suivi chauffeur:', error);
    res.status(500).json({ 
      error: 'Erreur lors du suivi du chauffeur',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route POST /api/v1/client/estimate
 * @description Calculer l'itinéraire, l'estimation de prix, la distance et le temps d'attente pour différentes catégories de véhicules (utilisé dans MVP)
 */
v1Router.post('/estimate', auth, [
  body('pickupLocation.latitude').isFloat({ min: -90, max: 90 }),
  body('pickupLocation.longitude').isFloat({ min: -180, max: 180 }),
  body('dropoffLocation.latitude').isFloat({ min: -90, max: 90 }),
  body('dropoffLocation.longitude').isFloat({ min: -180, max: 180 }),
  body('vehicleCategory').optional().isIn(['standard', 'premium', 'luxury'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Données invalides',
        details: errors.array() 
      });
    }

    const { pickupLocation, dropoffLocation, vehicleCategory = 'standard' } = req.body;

    // Calculer la distance avec PostGIS
    const distanceQuery = `
      SELECT ST_Distance(
        ST_MakePoint($1, $2)::geography,
        ST_MakePoint($3, $4)::geography
      ) / 1000 AS distance_km
    `;
    
    const distanceResult = await AppDataSource.query(distanceQuery, [
      pickupLocation.longitude,
      pickupLocation.latitude,
      dropoffLocation.longitude,
      dropoffLocation.latitude
    ]);

    const distanceKm = parseFloat(distanceResult[0]?.distance_km || 0);

    // Calculer le prix dynamique pour chaque catégorie
    const priceData = await PricingService.calculateDynamicPrice(
      distanceKm,
      new Date(),
      pickupLocation
    );

    // Multiplicateurs par catégorie de véhicule
    const categoryMultipliers = {
      standard: 1.0,
      premium: 1.3,
      luxury: 1.6
    };

    // Calculer les prix pour chaque catégorie
    const estimates = {};
    for (const [category, multiplier] of Object.entries(categoryMultipliers)) {
      estimates[category] = {
        priceRange: {
          min: Math.round(priceData.price * multiplier * 0.9),
          max: Math.round(priceData.price * multiplier * 1.1)
        },
        estimatedPrice: Math.round(priceData.price * multiplier),
        basePrice: Math.round(priceData.basePrice * multiplier),
        multiplier: multiplier
      };
    }

    // Estimation du temps de trajet (vitesse moyenne 30 km/h en ville)
    const estimatedDurationMinutes = Math.max(5, Math.ceil(distanceKm * 2));

    // Estimation du temps d'attente (recherche de chauffeur)
    // Trouver les chauffeurs disponibles à proximité
    const realtimeService = getRealtimeRideService();
    let estimatedWaitTimeMinutes = 5; // Par défaut 5 minutes
    let availableDriversCount = 0;

    if (realtimeService) {
      try {
        const nearbyDrivers = await realtimeService.findNearbyDrivers(
          pickupLocation.latitude,
          pickupLocation.longitude,
          10 // 10 km de rayon
        );
        availableDriversCount = nearbyDrivers.length;

        // Calculer le temps d'attente estimé selon le nombre de chauffeurs
        if (nearbyDrivers.length === 0) {
          estimatedWaitTimeMinutes = 10; // Aucun chauffeur proche
        } else if (nearbyDrivers.length < 3) {
          estimatedWaitTimeMinutes = 7; // Peu de chauffeurs
        } else {
          estimatedWaitTimeMinutes = 3; // Beaucoup de chauffeurs
        }
      } catch (error) {
        console.error('Erreur recherche chauffeurs pour estimation:', error);
      }
    }

    res.json({
      success: true,
      distance: {
        kilometers: Math.round(distanceKm * 100) / 100,
        meters: Math.round(distanceKm * 1000)
      },
      estimatedDuration: {
        minutes: estimatedDurationMinutes,
        seconds: estimatedDurationMinutes * 60
      },
      estimatedWaitTime: {
        minutes: estimatedWaitTimeMinutes,
        seconds: estimatedWaitTimeMinutes * 60
      },
      availableDriversCount: availableDriversCount,
      estimates: estimates,
      pricing: {
        breakdown: priceData.breakdown,
        explanation: PricingService.getPriceExplanation(priceData),
        multipliers: priceData.multipliers
      },
      route: {
        pickup: {
          latitude: pickupLocation.latitude,
          longitude: pickupLocation.longitude,
          address: pickupLocation.address || null
        },
        dropoff: {
          latitude: dropoffLocation.latitude,
          longitude: dropoffLocation.longitude,
          address: dropoffLocation.address || null
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Erreur estimation:', error);
    res.status(500).json({ 
      error: 'Erreur lors du calcul de l\'estimation',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route POST /api/v1/client/command/request
 * @description Passer une nouvelle commande de course. Enregistre la demande en base de données, la met en statut "Pending" et initie le processus d'attribution à un chauffeur (utilisé dans MVP)
 */
v1Router.post('/command/request', auth, [
  body('pickupLocation.latitude').isFloat({ min: -90, max: 90 }),
  body('pickupLocation.longitude').isFloat({ min: -180, max: 180 }),
  body('dropoffLocation.latitude').isFloat({ min: -90, max: 90 }),
  body('dropoffLocation.longitude').isFloat({ min: -180, max: 180 }),
  body('pickupLocation.address').optional().isString(),
  body('dropoffLocation.address').optional().isString(),
  body('paymentMethod').optional().isIn(['cash', 'mobile_money', 'card', 'mpesa', 'orange_money']),
  body('vehicleCategory').optional().isIn(['standard', 'premium', 'luxury'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Données invalides',
        details: errors.array() 
      });
    }

    if (req.user.role !== 'client') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Seuls les clients peuvent créer une commande' 
      });
    }

    const { 
      pickupLocation, 
      dropoffLocation, 
      paymentMethod = 'cash',
      vehicleCategory = 'standard'
    } = req.body;

    const rideRepository = AppDataSource.getRepository(Ride);

    // Créer les points PostGIS
    const pickupPoint = {
      type: 'Point',
      coordinates: [pickupLocation.longitude, pickupLocation.latitude]
    };
    
    const dropoffPoint = {
      type: 'Point',
      coordinates: [dropoffLocation.longitude, dropoffLocation.latitude]
    };

    // Calculer la distance avec PostGIS
    const distanceQuery = `
      SELECT ST_Distance(
        ST_MakePoint($1, $2)::geography,
        ST_MakePoint($3, $4)::geography
      ) / 1000 AS distance_km
    `;
    
    const distanceResult = await AppDataSource.query(distanceQuery, [
      pickupLocation.longitude,
      pickupLocation.latitude,
      dropoffLocation.longitude,
      dropoffLocation.latitude
    ]);

    const calculatedDistance = parseFloat(distanceResult[0]?.distance_km || 0);

    // Calculer le prix dynamique
    const priceData = await PricingService.calculateDynamicPrice(
      calculatedDistance,
      new Date(),
      pickupLocation
    );

    // Appliquer le multiplicateur de catégorie
    const categoryMultipliers = {
      standard: 1.0,
      premium: 1.3,
      luxury: 1.6
    };
    const multiplier = categoryMultipliers[vehicleCategory] || 1.0;
    const estimatedPrice = Math.round(priceData.price * multiplier);

    // Créer la course avec le statut "pending"
    const ride = rideRepository.create({
      clientId: req.user.id,
      pickupLocation: pickupPoint,
      dropoffLocation: dropoffPoint,
      pickupAddress: pickupLocation.address || null,
      dropoffAddress: dropoffLocation.address || null,
      estimatedPrice: estimatedPrice,
      distance: calculatedDistance,
      paymentMethod: paymentMethod,
      status: 'pending'
    });

    await rideRepository.save(ride);

    // Initier le processus d'attribution à un chauffeur
    const realtimeRideService = getRealtimeRideService();
    if (realtimeRideService) {
      await realtimeRideService.processRideRequest(ride);
    }

    // Récupérer la course mise à jour
    const updatedRide = await rideRepository.findOne({ 
      where: { id: ride.id },
      relations: ['client', 'driver']
    });

    // Formater la réponse
    const response = {
      success: true,
      ride: {
        id: updatedRide.id,
        status: updatedRide.status,
        clientId: updatedRide.clientId,
        driverId: updatedRide.driverId,
        pickupLocation: {
          latitude: pickupLocation.latitude,
          longitude: pickupLocation.longitude,
          address: updatedRide.pickupAddress
        },
        dropoffLocation: {
          latitude: dropoffLocation.latitude,
          longitude: dropoffLocation.longitude,
          address: updatedRide.dropoffAddress
        },
        estimatedPrice: parseFloat(updatedRide.estimatedPrice),
        distance: parseFloat(updatedRide.distance),
        paymentMethod: updatedRide.paymentMethod,
        vehicleCategory: vehicleCategory,
        createdAt: updatedRide.createdAt.toISOString()
      },
      pricing: {
        estimatedPrice: estimatedPrice,
        basePrice: Math.round(priceData.basePrice * multiplier),
        breakdown: priceData.breakdown,
        explanation: PricingService.getPriceExplanation(priceData)
      },
      message: 'Commande créée avec succès. Recherche de chauffeur en cours...'
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Erreur création commande:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la création de la commande',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route GET /api/v1/client/command/status/:ride_id
 * @description Récupérer le statut actuel de la course. Statuts possibles: Pending, Searching, Accepted, InProgress, Completed, Canceled (utilisé dans MVP)
 */
v1Router.get('/command/status/:ride_id', auth, async (req, res) => {
  try {
    const rideId = parseInt(req.params.ride_id);
    
    if (isNaN(rideId)) {
      return res.status(400).json({ 
        error: 'ID de course invalide' 
      });
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ 
        error: 'Course non trouvée',
        message: `Aucune course trouvée avec l'ID ${rideId}` 
      });
    }

    // Vérifier que l'utilisateur est le client de cette course
    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Vous n\'êtes pas autorisé à consulter cette course' 
      });
    }

    // Déterminer le statut détaillé
    let detailedStatus = ride.status;
    if (ride.status === 'pending' && !ride.driverId) {
      // Si pending sans chauffeur, c'est "Searching"
      detailedStatus = 'Searching';
    } else {
      // Mapper les statuts
      const statusMap = {
        'pending': 'Pending',
        'accepted': 'Accepted',
        'driverArriving': 'Accepted',
        'inProgress': 'InProgress',
        'completed': 'Completed',
        'cancelled': 'Canceled'
      };
      detailedStatus = statusMap[ride.status] || ride.status;
    }

    // Formater la réponse
    const response = {
      success: true,
      rideId: ride.id,
      status: detailedStatus,
      statusCode: ride.status,
      clientId: ride.clientId,
      driverId: ride.driverId,
      driver: ride.driver ? {
        id: ride.driver.id,
        name: ride.driver.name,
        phoneNumber: ride.driver.phoneNumber
      } : null,
      pickupLocation: ride.pickupLocation ? {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0],
        address: ride.pickupAddress
      } : null,
      dropoffLocation: ride.dropoffLocation ? {
        latitude: ride.dropoffLocation.coordinates[1],
        longitude: ride.dropoffLocation.coordinates[0],
        address: ride.dropoffAddress
      } : null,
      estimatedPrice: ride.estimatedPrice ? parseFloat(ride.estimatedPrice) : null,
      finalPrice: ride.finalPrice ? parseFloat(ride.finalPrice) : null,
      distance: ride.distance ? parseFloat(ride.distance) : null,
      paymentMethod: ride.paymentMethod,
      createdAt: ride.createdAt.toISOString(),
      startedAt: ride.startedAt ? ride.startedAt.toISOString() : null,
      completedAt: ride.completedAt ? ride.completedAt.toISOString() : null,
      cancelledAt: ride.cancelledAt ? ride.cancelledAt.toISOString() : null,
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur récupération statut:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération du statut',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route POST /api/v1/client/command/cancel/:ride_id
 * @description Annuler une course. Gère la logique des frais d'annulation si applicable (selon le statut) (utilisé dans MVP)
 */
v1Router.post('/command/cancel/:ride_id', auth, [
  body('reason').optional().isString().trim(),
  body('cancellationReason').optional().isString().trim()
], async (req, res) => {
  try {
    const rideId = parseInt(req.params.ride_id);
    
    if (isNaN(rideId)) {
      return res.status(400).json({ 
        error: 'ID de course invalide' 
      });
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ 
        error: 'Course non trouvée',
        message: `Aucune course trouvée avec l'ID ${rideId}` 
      });
    }

    // Vérifier que l'utilisateur est le client de cette course
    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Vous n\'êtes pas autorisé à annuler cette course' 
      });
    }

    // Vérifier que la course peut être annulée
    if (ride.status === 'completed') {
      return res.status(400).json({ 
        error: 'Impossible d\'annuler',
        message: 'Cette course est déjà terminée' 
      });
    }

    if (ride.status === 'cancelled') {
      return res.status(400).json({ 
        error: 'Déjà annulée',
        message: 'Cette course a déjà été annulée' 
      });
    }

    // Calculer les frais d'annulation selon le statut
    let cancellationFee = 0;
    const cancellationReason = req.body.reason || req.body.cancellationReason || 'Annulé par le client';

    // Règles de frais d'annulation:
    // - Avant acceptation (pending/searching): 0% (gratuit)
    // - Après acceptation mais avant départ (accepted): 20% du prix estimé
    // - En cours (inProgress): 50% du prix estimé
    if (ride.status === 'pending' || ride.status === 'searching') {
      cancellationFee = 0; // Gratuit avant acceptation
    } else if (ride.status === 'accepted' || ride.status === 'driverArriving') {
      cancellationFee = Math.round(parseFloat(ride.estimatedPrice) * 0.2); // 20%
    } else if (ride.status === 'inProgress') {
      cancellationFee = Math.round(parseFloat(ride.estimatedPrice) * 0.5); // 50%
    }

    // Mettre à jour la course
    ride.status = 'cancelled';
    ride.cancelledAt = new Date();
    ride.cancellationReason = cancellationReason;
    
    // Si des frais d'annulation sont appliqués, les enregistrer
    if (cancellationFee > 0) {
      ride.finalPrice = cancellationFee;
    }

    await rideRepository.save(ride);

    // Notifier le chauffeur si un chauffeur était assigné
    if (ride.driverId && ride.driver) {
      if (ride.driver.fcmToken) {
        await sendNotification(ride.driver.fcmToken, {
          title: 'Course annulée',
          body: `La course #${ride.id} a été annulée par le client`,
          data: {
            rideId: ride.id.toString(),
            type: 'ride_cancelled'
          }
        });
      }

      // Émettre un événement Socket.io au chauffeur
      io.to(`driver:${ride.driverId}`).emit('ride_update', {
        type: 'ride_cancelled',
        rideId: ride.id.toString(),
        message: 'Course annulée par le client',
        timestamp: new Date()
      });

      // Libérer le chauffeur (mettre à jour son statut)
      const userRepository = AppDataSource.getRepository(User);
      const driver = await userRepository.findOne({ where: { id: ride.driverId } });
      if (driver && driver.driverInfo) {
        const driverInfo = driver.driverInfo;
        driverInfo.currentRideId = null;
        driverInfo.status = 'available';
        
        await AppDataSource.query(
          `UPDATE users 
           SET driver_info = $1::jsonb, updated_at = NOW()
           WHERE id = $2`,
          [JSON.stringify(driverInfo), driver.id]
        );
      }
    }

    // Émettre un événement Socket.io au client (namespace principal et namespace client)
    io.to(`ride:${ride.id}`).emit('ride_update', {
      type: 'ride_cancelled',
      rideId: ride.id.toString(),
      message: 'Course annulée',
      cancellationFee: cancellationFee,
      timestamp: new Date()
    });

    // Émettre aussi vers le namespace client si disponible
    if (clientNamespace) {
      clientNamespace.to(`ride:${ride.id}`).emit('ride_update', {
        type: 'ride_cancelled',
        rideId: ride.id.toString(),
        message: 'Course annulée',
        cancellationFee: cancellationFee,
        timestamp: new Date()
      });
    }

    // Formater la réponse
    const response = {
      success: true,
      rideId: ride.id,
      status: 'Canceled',
      cancelledAt: ride.cancelledAt.toISOString(),
      cancellationReason: ride.cancellationReason,
      cancellationFee: cancellationFee,
      message: cancellationFee > 0 
        ? `Course annulée. Frais d'annulation: ${cancellationFee} CDF`
        : 'Course annulée sans frais',
      refundInfo: cancellationFee > 0 
        ? {
            amount: cancellationFee,
            currency: 'CDF',
            message: 'Les frais d\'annulation seront débités de votre compte'
          }
        : null
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur annulation course:', error);
    res.status(500).json({ 
      error: 'Erreur lors de l\'annulation de la course',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route GET /api/v1/client/driver/location/:driver_id
 * @description Récupérer la position GPS du chauffeur attribué en temps réel (utilisé dans MVP)
 */
v1Router.get('/driver/location/:driver_id', auth, async (req, res) => {
  try {
    const driverId = parseInt(req.params.driver_id);
    
    if (isNaN(driverId)) {
      return res.status(400).json({ 
        error: 'ID de chauffeur invalide' 
      });
    }

    const userRepository = AppDataSource.getRepository(User);
    const driver = await userRepository.findOne({
      where: { id: driverId }
    });

    if (!driver) {
      return res.status(404).json({ 
        error: 'Chauffeur non trouvé',
        message: `Aucun chauffeur trouvé avec l'ID ${driverId}` 
      });
    }

    // Vérifier que le chauffeur a le rôle driver
    if (driver.role !== 'driver') {
      return res.status(400).json({ 
        error: 'Utilisateur invalide',
        message: 'Cet utilisateur n\'est pas un chauffeur' 
      });
    }

    // Vérifier que le client a une course active avec ce chauffeur
    const rideRepository = AppDataSource.getRepository(Ride);
    const activeRide = await rideRepository
      .createQueryBuilder('ride')
      .where('ride.clientId = :clientId', { clientId: req.user.id })
      .andWhere('ride.driverId = :driverId', { driverId: driverId })
      .andWhere('ride.status IN (:...statuses)', { 
        statuses: ['accepted', 'driverArriving', 'inProgress'] 
      })
      .getOne();

    if (!activeRide && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Vous n\'avez pas de course active avec ce chauffeur' 
      });
    }

    // Extraire les coordonnées depuis PostGIS
    let location = null;
    if (driver.location && driver.location.coordinates) {
      const coordinates = driver.location.coordinates;
      location = {
        latitude: coordinates[1], // PostGIS stocke [longitude, latitude]
        longitude: coordinates[0],
        timestamp: driver.updatedAt || driver.createdAt,
        accuracy: null // Non disponible depuis PostGIS
      };
    }

    // Récupérer le statut du chauffeur
    const driverStatus = driver.driverInfo?.status || 'unknown';
    const isOnline = driver.driverInfo?.isOnline || false;

    // Formater la réponse
    const response = {
      success: true,
      driver: {
        id: driver.id,
        name: driver.name,
        phoneNumber: driver.phoneNumber,
        status: driverStatus,
        isOnline: isOnline
      },
      location: location,
      rideId: activeRide ? activeRide.id : null,
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur récupération position chauffeur:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération de la position',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route GET /api/v1/client/history
 * @description Récupérer l'historique des courses du client (utilisé dans MVP)
 */
v1Router.get('/history', auth, [
  query('page').optional().isInt({ min: 1 }),
  query('limit').optional().isInt({ min: 1, max: 100 }),
  query('status').optional().isIn(['pending', 'accepted', 'inProgress', 'completed', 'cancelled'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Paramètres invalides',
        details: errors.array() 
      });
    }

    if (req.user.role !== 'client' && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Seuls les clients peuvent consulter leur historique' 
      });
    }

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const status = req.query.status;
    const offset = (page - 1) * limit;

    const rideRepository = AppDataSource.getRepository(Ride);
    let queryBuilder = rideRepository.createQueryBuilder('ride')
      .leftJoinAndSelect('ride.client', 'client')
      .leftJoinAndSelect('ride.driver', 'driver')
      .where('ride.clientId = :clientId', { clientId: req.user.id })
      .orderBy('ride.createdAt', 'DESC')
      .skip(offset)
      .take(limit);

    // Filtrer par statut si fourni
    if (status) {
      queryBuilder = queryBuilder.andWhere('ride.status = :status', { status });
    }

    const [rides, total] = await queryBuilder.getManyAndCount();

    // Formater les courses
    const formattedRides = rides.map(ride => ({
      id: ride.id,
      status: ride.status,
      driver: ride.driver ? {
        id: ride.driver.id,
        name: ride.driver.name,
        phoneNumber: ride.driver.phoneNumber
      } : null,
      pickupLocation: ride.pickupLocation ? {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0],
        address: ride.pickupAddress
      } : null,
      dropoffLocation: ride.dropoffLocation ? {
        latitude: ride.dropoffLocation.coordinates[1],
        longitude: ride.dropoffLocation.coordinates[0],
        address: ride.dropoffAddress
      } : null,
      estimatedPrice: ride.estimatedPrice ? parseFloat(ride.estimatedPrice) : null,
      finalPrice: ride.finalPrice ? parseFloat(ride.finalPrice) : null,
      distance: ride.distance ? parseFloat(ride.distance) : null,
      paymentMethod: ride.paymentMethod,
      rating: ride.rating,
      comment: ride.comment,
      createdAt: ride.createdAt.toISOString(),
      startedAt: ride.startedAt ? ride.startedAt.toISOString() : null,
      completedAt: ride.completedAt ? ride.completedAt.toISOString() : null,
      cancelledAt: ride.cancelledAt ? ride.cancelledAt.toISOString() : null
    }));

    // Formater la réponse
    const response = {
      success: true,
      rides: formattedRides,
      pagination: {
        page: page,
        limit: limit,
        total: total,
        totalPages: Math.ceil(total / limit),
        hasNext: offset + limit < total,
        hasPrev: page > 1
      },
      filters: {
        status: status || null
      },
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur récupération historique:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération de l\'historique',
      message: error.message 
    });
  }
});

/**
 * @mvp true
 * @route POST /api/v1/client/rate/:ride_id
 * @description Soumettre l'évaluation (note et commentaire) du chauffeur après la course (utilisé dans MVP)
 */
v1Router.post('/rate/:ride_id', auth, [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('La note doit être entre 1 et 5'),
  body('comment').optional().isString().trim().isLength({ max: 500 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        error: 'Données invalides',
        details: errors.array() 
      });
    }

    const rideId = parseInt(req.params.ride_id);
    
    if (isNaN(rideId)) {
      return res.status(400).json({ 
        error: 'ID de course invalide' 
      });
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ 
        error: 'Course non trouvée',
        message: `Aucune course trouvée avec l'ID ${rideId}` 
      });
    }

    // Vérifier que l'utilisateur est le client de cette course
    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Seul le client peut évaluer cette course' 
      });
    }

    // Vérifier que la course est terminée
    if (ride.status !== 'completed') {
      return res.status(400).json({ 
        error: 'Impossible d\'évaluer',
        message: 'Seules les courses terminées peuvent être évaluées' 
      });
    }

    // Vérifier que la course n'a pas déjà été évaluée
    if (ride.rating !== null && ride.rating !== undefined) {
      return res.status(400).json({ 
        error: 'Déjà évaluée',
        message: 'Cette course a déjà été évaluée' 
      });
    }

    const { rating, comment } = req.body;

    // Mettre à jour la course
    ride.rating = rating;
    ride.comment = comment || null;
    await rideRepository.save(ride);

    // Mettre à jour la note moyenne du conducteur
    if (ride.driverId) {
      try {
        const avgRatingResult = await rideRepository
          .createQueryBuilder('ride')
          .select('AVG(ride.rating)', 'avg')
          .addSelect('COUNT(ride.rating)', 'count')
          .where('ride.driverId = :driverId', { driverId: ride.driverId })
          .andWhere('ride.rating IS NOT NULL')
          .getRawOne();

        const avgRating = parseFloat(avgRatingResult.avg) || 0;
        const ratingCount = parseInt(avgRatingResult.count) || 0;

        // Mettre à jour la note du chauffeur dans driverInfo
        const userRepository = AppDataSource.getRepository(User);
        const driver = await userRepository.findOne({ where: { id: ride.driverId } });
        
        if (driver) {
          const driverInfo = driver.driverInfo || {};
          driverInfo.rating = Math.round(avgRating * 10) / 10; // Arrondir à 1 décimale
          driverInfo.ratingCount = ratingCount;
          
          await AppDataSource.query(
            `UPDATE users 
             SET driver_info = $1::jsonb, updated_at = NOW()
             WHERE id = $2`,
            [JSON.stringify(driverInfo), driver.id]
          );
        }

        // Notifier le chauffeur de la nouvelle évaluation
        if (driver && driver.fcmToken) {
          await sendNotification(driver.fcmToken, {
            title: 'Nouvelle évaluation',
            body: `Vous avez reçu une note de ${rating}/5`,
            data: {
              rideId: ride.id.toString(),
              type: 'rating_received',
              rating: rating.toString()
            }
          });
        }
      } catch (error) {
        console.error('Erreur mise à jour note chauffeur:', error);
        // Ne pas faire échouer la requête si la mise à jour de la note échoue
      }
    }

    // Formater la réponse
    const response = {
      success: true,
      rideId: ride.id,
      rating: ride.rating,
      comment: ride.comment,
      driver: ride.driver ? {
        id: ride.driver.id,
        name: ride.driver.name,
        newAverageRating: ride.driver.driverInfo?.rating || null
      } : null,
      message: 'Évaluation enregistrée avec succès',
      timestamp: new Date().toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Erreur évaluation:', error);
    res.status(500).json({ 
      error: 'Erreur lors de l\'enregistrement de l\'évaluation',
      message: error.message 
    });
  }
});

// Monter le routeur v1 sur /v1/client
router.use('/v1/client', v1Router);

module.exports = router;

