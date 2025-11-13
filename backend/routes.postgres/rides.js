// Routes de courses avec PostgreSQL + PostGIS
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { io, notifyAvailableDrivers, getRealtimeRideService } = require('../server.postgres');
const { sendNotification } = require('../utils/notifications');
const PricingService = require('../services/PricingService');
const { v4: uuidv4 } = require('uuid');
// const DriverMatchingService = require('../services/DriverMatchingService'); // DÉSACTIVÉ (app driver séparée)

const router = express.Router();

// Cache simple en mémoire pour les prix estimés (TTL: 5 minutes)
const priceCache = new Map();
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes en millisecondes

// Fonction pour générer une clé de cache
function getCacheKey(pickupLocation, dropoffLocation) {
  // Arrondir les coordonnées à 4 décimales pour regrouper les trajets similaires
  const lat1 = Math.round(pickupLocation.latitude * 10000) / 10000;
  const lon1 = Math.round(pickupLocation.longitude * 10000) / 10000;
  const lat2 = Math.round(dropoffLocation.latitude * 10000) / 10000;
  const lon2 = Math.round(dropoffLocation.longitude * 10000) / 10000;
  return `${lat1}_${lon1}_${lat2}_${lon2}`;
}

// Nettoyer le cache toutes les 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of priceCache.entries()) {
    if (now - value.timestamp > CACHE_TTL) {
      priceCache.delete(key);
    }
  }
}, 10 * 60 * 1000);

// 🧠 Calculer le prix estimé (avant création de la course) - AVEC CACHE
router.post('/estimate-price', auth, [
  body('pickupLocation.latitude').isFloat(),
  body('pickupLocation.longitude').isFloat(),
  body('dropoffLocation.latitude').isFloat(),
  body('dropoffLocation.longitude').isFloat(),
  body('distance').optional().isFloat()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickupLocation, dropoffLocation, distance } = req.body;

    // Vérifier le cache
    const cacheKey = getCacheKey(pickupLocation, dropoffLocation);
    const cached = priceCache.get(cacheKey);
    const now = Date.now();

    if (cached && (now - cached.timestamp) < CACHE_TTL) {
      // Retourner les données en cache
      return res.json({
        ...cached.data,
        cached: true
      });
    }

    // Calculer la distance si non fournie
    let calculatedDistance = distance;
    if (!calculatedDistance) {
      const pickupPoint = {
        type: 'Point',
        coordinates: [pickupLocation.longitude, pickupLocation.latitude]
      };
      const dropoffPoint = {
        type: 'Point',
        coordinates: [dropoffLocation.longitude, dropoffLocation.latitude]
      };
      
      // Calcul approximatif de distance (formule de Haversine)
      const R = 6371; // Rayon de la Terre en km
      const dLat = (dropoffLocation.latitude - pickupLocation.latitude) * Math.PI / 180;
      const dLon = (dropoffLocation.longitude - pickupLocation.longitude) * Math.PI / 180;
      const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(pickupLocation.latitude * Math.PI / 180) * 
        Math.cos(dropoffLocation.latitude * Math.PI / 180) *
        Math.sin(dLon/2) * Math.sin(dLon/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      calculatedDistance = R * c;
    }

    // Calculer le prix dynamique avec IA
    const priceData = await PricingService.calculateDynamicPrice(
      calculatedDistance,
      new Date(),
      pickupLocation
    );

    const response = {
      price: priceData.price,
      basePrice: priceData.basePrice,
      distance: calculatedDistance,
      explanation: PricingService.getPriceExplanation(priceData),
      multipliers: priceData.multipliers,
      breakdown: priceData.breakdown
    };

    // Mettre en cache
    priceCache.set(cacheKey, {
      data: response,
      timestamp: now
    });

    res.json(response);
  } catch (error) {
    console.error('Erreur calcul prix:', error);
    res.status(500).json({ error: 'Erreur lors du calcul du prix' });
  }
});

// Créer une demande de course
router.post('/create', auth, [
  body('pickupLocation.latitude').isFloat(),
  body('pickupLocation.longitude').isFloat(),
  body('dropoffLocation.latitude').isFloat(),
  body('dropoffLocation.longitude').isFloat(),
  body('distance').optional().isFloat()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'client') {
      return res.status(403).json({ error: 'Seuls les clients peuvent créer une course' });
    }

    const { pickupLocation, dropoffLocation, distance } = req.body;
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

    // Calculer la distance avec PostGIS si non fournie (méthode optimisée sans créer de ride temporaire)
    let calculatedDistance = distance;
    if (!calculatedDistance) {
      // Calcul direct avec PostGIS sans créer d'enregistrement
      const distanceQuery = `
        SELECT ST_Distance(
          ST_MakePoint($1, $2)::geography,
          ST_MakePoint($3, $4)::geography
        ) / 1000 AS distance_km
      `;
      const result = await AppDataSource.query(distanceQuery, [
        pickupLocation.longitude,
        pickupLocation.latitude,
        dropoffLocation.longitude,
        dropoffLocation.latitude
      ]);
      calculatedDistance = parseFloat(result[0]?.distance_km || 0);
    }

    // 🧠 ALGORITHME IA : Calculer le prix dynamique
    const priceData = await PricingService.calculateDynamicPrice(
      calculatedDistance,
      new Date(),
      pickupLocation
    );

    // Créer la course avec le prix calculé par IA
    const ride = rideRepository.create({
      clientId: req.user.id,
      pickupLocation: pickupPoint,
      dropoffLocation: dropoffPoint,
      pickupAddress: pickupLocation.address,
      dropoffAddress: dropoffLocation.address,
      estimatedPrice: priceData.price,
      distance: calculatedDistance,
      status: 'pending'
    });

    await rideRepository.save(ride);

    // 🚀 TEMPS RÉEL : Traiter la demande de course via le service temps réel
    // Cela enverra ride_offer à tous les chauffeurs proches via Socket.io
    const realtimeRideService = getRealtimeRideService();
    if (realtimeRideService) {
      await realtimeRideService.processRideRequest(ride);
    } else {
      // Fallback vers l'ancien système si le service n'est pas disponible
      await notifyAvailableDrivers(ride);
    }

    // Récupérer la course mise à jour depuis la base de données
    const updatedRide = await rideRepository.findOne({ 
      where: { id: ride.id },
      relations: ['client', 'driver']
    });

    // Formater la réponse pour iOS et dashboard
    const response = {
      id: updatedRide.id,
      clientId: updatedRide.clientId,
      driverId: updatedRide.driverId,
      pickupLocation: {
        latitude: pickupLocation.latitude,
        longitude: pickupLocation.longitude
      },
      dropoffLocation: {
        latitude: dropoffLocation.latitude,
        longitude: dropoffLocation.longitude
      },
      pickupAddress: updatedRide.pickupAddress,
      dropoffAddress: updatedRide.dropoffAddress,
      status: updatedRide.status,
      estimatedPrice: parseFloat(updatedRide.estimatedPrice),
      finalPrice: updatedRide.finalPrice ? parseFloat(updatedRide.finalPrice) : null,
      distance: updatedRide.distance ? parseFloat(updatedRide.distance) : null,
      createdAt: updatedRide.createdAt.toISOString(),
      pricing: {
        finalPrice: priceData.price,
        basePrice: priceData.basePrice,
        explanation: PricingService.getPriceExplanation(priceData),
        multipliers: priceData.multipliers,
        breakdown: priceData.breakdown
      }
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Erreur création course:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la course' });
  }
});

// Accepter une course (route pour l'app Driver - POST /api/rides/:id/accept)
// NOTE: Cette route est maintenant principalement utilisée comme fallback API
// L'acceptation se fait normalement via Socket.io (ride:accept) dans le service temps réel
router.post('/:id/accept', auth, async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);
    
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.id) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ error: 'Cette course n\'est plus disponible' });
    }

    // Vérifier la concurrence : utiliser le service temps réel si disponible
    const realtimeRideService = getRealtimeRideService();
    const { driverNamespace } = require('../server.postgres');
    
    if (realtimeRideService && driverNamespace) {
      // Chercher le socket du chauffeur dans le namespace
      let driverSocket = null;
      driverNamespace.sockets.forEach((socket) => {
        if (socket.driverId === req.user.id) {
          driverSocket = socket;
        }
      });
      
      if (driverSocket) {
        await realtimeRideService.handleRideAcceptance(req.user.id, ride.id, driverSocket);
      } else {
        // Si le chauffeur n'est pas connecté via Socket.io, traiter directement
        ride.driverId = req.user.id;
        ride.status = 'accepted';
        await rideRepository.save(ride);

        // Mettre à jour le statut du chauffeur
        const driver = await userRepository.findOne({ where: { id: req.user.id } });
        if (driver) {
          const driverInfo = driver.driverInfo || {};
          driverInfo.status = 'en_route_to_pickup';
          driverInfo.currentRideId = ride.id;
          driverInfo.isOnline = true;
          
          await AppDataSource.query(
            `UPDATE users 
             SET driver_info = $1::jsonb, updated_at = NOW()
             WHERE id = $2`,
            [JSON.stringify(driverInfo), driver.id]
          );
        }

        // Notifier le client
        if (ride.client?.fcmToken) {
          await sendNotification(ride.client.fcmToken, {
            title: 'Course acceptée !',
            body: `${req.user.name} a accepté votre course`,
            data: { rideId: ride.id.toString(), type: 'ride_accepted' }
          });
        }

        io.to(`ride:${ride.id}`).emit('ride_update', {
          type: 'ride_accepted',
          rideId: ride.id.toString(),
          driverId: req.user.id.toString(),
          timestamp: new Date()
        });
      }
    } else {
      // Fallback vers l'ancien système
      ride.driverId = req.user.id;
      ride.status = 'accepted';
      await rideRepository.save(ride);

      // Notifier le client
      if (ride.client?.fcmToken) {
        await sendNotification(ride.client.fcmToken, {
          title: 'Course acceptée !',
          body: `${req.user.name} a accepté votre course`,
          data: { rideId: ride.id.toString(), type: 'ride_accepted' }
        });
      }

      io.to(`ride:${ride.id}`).emit('ride:status:changed', {
        rideId: ride.id,
        status: 'accepted',
        driverId: req.user.id
      });
    }

    // Récupérer la course mise à jour
    const updatedRide = await rideRepository.findOne({ 
      where: { id: ride.id },
      relations: ['client', 'driver']
    });

    res.json(updatedRide);
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'acceptation' });
  }
});

// Accepter une course (route legacy - PUT /api/rides/accept/:courseId)
router.put('/accept/:courseId', auth, async (req, res) => {
  try {
    // Note: Cette route est maintenant utilisée par l'app driver séparée
    // if (req.user.role !== 'driver') {
    //   return res.status(403).json({ error: 'Seuls les conducteurs peuvent accepter une course' });
    // }

    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.courseId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ error: 'Cette course n\'est plus disponible' });
    }

    ride.driverId = req.user.id;
    ride.status = 'accepted';
    await rideRepository.save(ride);

    // Notifier le client
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course acceptée !',
        body: `${req.user.name} a accepté votre course`,
        data: { rideId: ride.id.toString(), type: 'ride_accepted' }
      });
    }

    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: 'accepted',
      driverId: req.user.id
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'acceptation' });
  }
});

// Refuser une course (route pour l'app Driver - POST /api/rides/:id/reject)
router.post('/:id/reject', auth, async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.id) },
      relations: ['client']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ error: 'Cette course n\'est plus disponible' });
    }

    // Marquer la course comme refusée par ce conducteur
    // Note: On ne change pas le statut global, juste on enregistre le refus
    // Le backend peut ensuite proposer la course à d'autres conducteurs
    
    // Option 1: Changer le statut à 'rejected' si c'est le dernier conducteur
    // Option 2: Garder 'pending' et laisser le système proposer à d'autres conducteurs
    // Pour l'instant, on garde 'pending' pour permettre à d'autres conducteurs d'accepter
    
    console.log(`Conducteur ${req.user.id} a refusé la course ${ride.id}`);

    // Notifier le client si nécessaire (optionnel)
    // if (ride.client?.fcmToken) {
    //   await sendNotification(ride.client.fcmToken, {
    //     title: 'Course refusée',
    //     body: 'Un conducteur a refusé votre course. Recherche d\'un autre conducteur...',
    //     data: { rideId: ride.id.toString(), type: 'ride_rejected' }
    //   });
    // }

    res.json({ 
      message: 'Course refusée',
      rideId: ride.id,
      status: ride.status // Toujours 'pending' pour permettre à d'autres de l'accepter
    });
  } catch (error) {
    console.error('Erreur refus course:', error);
    res.status(500).json({ error: 'Erreur lors du refus de la course' });
  }
});

// Terminer une course
router.put('/complete/:courseId', auth, async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.courseId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    ride.status = 'completed';
    ride.completedAt = new Date();
    ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
    await rideRepository.save(ride);

    // Notifier le client
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course terminée',
        body: 'Votre course a été complétée. Merci d\'avoir utilisé Wewa Taxi !',
        data: { rideId: ride.id.toString(), type: 'ride_completed' }
      });
    }

    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: 'completed',
      timestamp: new Date()
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur complétion course:', error);
    res.status(500).json({ error: 'Erreur lors de la complétion' });
  }
});

// Mettre à jour le statut (route pour l'app Driver - POST /api/rides/:id/status)
router.post('/:id/status', auth, [
  body('status').isIn(['driverArriving', 'driver_arriving', 'inProgress', 'in_progress', 'completed', 'cancelled', 'rejected'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Normaliser le statut: convertir snake_case en camelCase pour compatibilité
    let { status } = req.body;
    const statusMap = {
      'driver_arriving': 'driverArriving',
      'in_progress': 'inProgress'
    };
    if (statusMap[status]) {
      status = statusMap[status];
    }
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.id) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    ride.status = status;

    if (status === 'inProgress') {
      ride.startedAt = new Date();
    } else if (status === 'completed') {
      ride.completedAt = new Date();
      ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
    } else if (status === 'cancelled' || status === 'rejected') {
      ride.cancelledAt = new Date();
    }

    await rideRepository.save(ride);

    // Notifier l'autre partie
    const otherUser = isDriver ? ride.client : ride.driver;
    if (otherUser?.fcmToken) {
      const statusMessages = {
        driverArriving: 'Votre conducteur arrive',
        inProgress: 'Trajet commencé',
        completed: 'Trajet terminé',
        cancelled: 'Course annulée',
        rejected: 'Course refusée'
      };

      await sendNotification(otherUser.fcmToken, {
        title: statusMessages[status] || 'Mise à jour de course',
        body: `Le statut de votre course a été mis à jour`,
        data: { rideId: ride.id.toString(), type: 'ride_status_update' }
      });
    }

    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status,
      timestamp: new Date()
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur lors de la mise à jour:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Mettre à jour le statut (route legacy - PATCH /api/rides/:rideId/status)
router.patch('/:rideId/status', auth, [
  body('status').isIn(['driverArriving', 'driver_arriving', 'inProgress', 'in_progress', 'completed', 'cancelled', 'rejected'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Normaliser le statut: convertir snake_case en camelCase pour compatibilité
    let { status } = req.body;
    const statusMap = {
      'driver_arriving': 'driverArriving',
      'in_progress': 'inProgress'
    };
    if (statusMap[status]) {
      status = statusMap[status];
    }
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    ride.status = status;

    if (status === 'inProgress') {
      ride.startedAt = new Date();
    } else if (status === 'completed') {
      ride.completedAt = new Date();
      ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
    } else if (status === 'cancelled' || status === 'rejected') {
      ride.cancelledAt = new Date();
    }

    await rideRepository.save(ride);

    // Notifier l'autre partie
    const otherUser = isDriver ? ride.client : ride.driver;
    if (otherUser?.fcmToken) {
      const statusMessages = {
        driverArriving: 'Votre conducteur arrive',
        inProgress: 'Trajet commencé',
        completed: 'Trajet terminé',
        cancelled: 'Course annulée',
        rejected: 'Course refusée'
      };

      await sendNotification(otherUser.fcmToken, {
        title: statusMessages[status] || 'Mise à jour de course',
        body: `Le statut de votre course a été mis à jour`,
        data: { rideId: ride.id.toString(), type: 'ride_status_update' }
      });
    }

    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status,
      timestamp: new Date()
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Historique des courses
router.get('/history/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (req.user.id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    let query = rideRepository.createQueryBuilder('ride')
      .leftJoinAndSelect('ride.client', 'client')
      .leftJoinAndSelect('ride.driver', 'driver')
      .orderBy('ride.createdAt', 'DESC')
      .limit(50);

    if (req.user.role === 'client') {
      query = query.where('ride.clientId = :userId', { userId });
    } else if (req.user.role === 'driver') {
      query = query.where('ride.driverId = :userId', { userId });
    } else {
      query = query.where('ride.clientId = :userId', { userId });
    }

    const rides = await query.getMany();
    res.json(rides);
  } catch (error) {
    console.error('Erreur historique:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'historique' });
  }
});

// Noter une course
router.post('/:rideId/rate', auth, [
  body('rating').isInt({ min: 1, max: 5 }),
  body('comment').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: parseInt(req.params.rideId) },
      relations: ['driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.clientId !== req.user.id) {
      return res.status(403).json({ error: 'Seul le client peut noter cette course' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ error: 'Seules les courses terminées peuvent être notées' });
    }

    ride.rating = req.body.rating;
    ride.comment = req.body.comment;
    await rideRepository.save(ride);

    // Mettre à jour la note moyenne du conducteur
    if (ride.driverId) {
      const avgRating = await rideRepository
        .createQueryBuilder('ride')
        .select('AVG(ride.rating)', 'avg')
        .where('ride.driverId = :driverId', { driverId: ride.driverId })
        .andWhere('ride.rating IS NOT NULL')
        .getRawOne();

      // Note: La mise à jour de la note du driver est maintenant gérée par l'app driver séparée
      // const userRepository = AppDataSource.getRepository(User);
      // const driver = await userRepository.findOne({ where: { id: ride.driverId } });
      // if (driver && driver.driverInfo) {
      //   driver.driverInfo.rating = Math.round(parseFloat(avgRating.avg) * 10) / 10;
      //   await userRepository.save(driver);
      // }
    }

    res.json(ride);
  } catch (error) {
    console.error('Erreur notation:', error);
    res.status(500).json({ error: 'Erreur lors de la notation' });
  }
});

// Obtenir une course
router.get('/:rideId', auth, async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    res.json(ride);
  } catch (error) {
    console.error('Erreur récupération course:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Obtenir la position du chauffeur pour une course
router.get('/:rideId/driver-location', auth, async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);
    
    const ride = await rideRepository.findOne({
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Si aucun chauffeur n'est assigné
    if (!ride.driverId) {
      return res.status(404).json({ error: 'Aucun chauffeur assigné à cette course' });
    }

    // Récupérer la position du chauffeur depuis la base de données
    const driver = await userRepository.findOne({
      where: { id: ride.driverId }
    });

    if (!driver || !driver.location) {
      return res.status(404).json({ error: 'Position du chauffeur non disponible' });
    }

    // Extraire les coordonnées depuis PostGIS
    const coordinates = driver.location.coordinates;
    
    res.json({
      driverId: driver.id,
      driverName: driver.name,
      location: {
        latitude: coordinates[1], // PostGIS stocke [longitude, latitude]
        longitude: coordinates[0],
        timestamp: driver.updatedAt || driver.createdAt
      },
      status: 'online' // Le statut est maintenant géré par l'app driver séparée
    });
  } catch (error) {
    console.error('Erreur récupération position chauffeur:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de la position' });
  }
});

// Générer un lien de partage pour une course
router.get('/:rideId/share', auth, async (req, res) => {
  try {
    const { rideId } = req.params;
    const rideRepository = AppDataSource.getRepository(Ride);

    // Vérifier que la course existe et appartient à l'utilisateur
    const ride = await rideRepository.findOne({
      where: { 
        id: parseInt(rideId),
        clientId: req.user.id
      }
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Générer un lien de partage unique
    const shareLink = `https://tshiakanivtc.com/share/${rideId}-${uuidv4()}`;

    res.json({
      shareLink: shareLink
    });
  } catch (error) {
    console.error('Erreur génération lien de partage:', error);
    res.status(500).json({ error: 'Erreur lors de la génération du lien de partage' });
  }
});

module.exports = router;

