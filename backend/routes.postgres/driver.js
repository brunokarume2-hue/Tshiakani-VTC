// Routes spécifiques pour l'application Driver
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { io, getRealtimeRideService, driverNamespace, getRedisService } = require('../server.postgres');
const { sendNotification } = require('../utils/notifications');
const PaymentService = require('../services/PaymentService');

const router = express.Router();

/**
 * POST /api/driver/location/update
 * Mettre à jour la position du conducteur (toutes les 2-3 secondes)
 * Utilise Redis pour le temps réel + PostgreSQL pour la persistance
 */
router.post('/location/update', auth, [
  body('latitude').isFloat({ min: -90, max: 90 }),
  body('longitude').isFloat({ min: -180, max: 180 }),
  body('address').optional().trim(),
  body('status').optional().isIn(['available', 'en_route_to_pickup', 'in_progress', 'offline']),
  body('heading').optional().isFloat({ min: 0, max: 360 }),
  body('speed').optional().isFloat({ min: 0 }),
  body('currentRideId').optional().isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent mettre à jour leur position' 
      });
    }

    const { latitude, longitude, address, status, heading, speed, currentRideId } = req.body;
    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();
    const logger = require('../utils/logger');

    // Créer le point PostGIS
    const locationPoint = {
      type: 'Point',
      coordinates: [longitude, latitude]
    };

    // 1. Mettre à jour dans PostgreSQL (persistant - moins fréquent)
    // Ne mettre à jour PostgreSQL que toutes les 30 secondes pour réduire la charge
    const lastPostgresUpdate = req.user.driverInfo?.lastPostgresUpdate || 0;
    const now = Date.now();
    const shouldUpdatePostgres = (now - lastPostgresUpdate) > 30000; // 30 secondes

    if (shouldUpdatePostgres) {
      req.user.location = locationPoint;
      
      if (!req.user.driverInfo) {
        req.user.driverInfo = {};
      }
      
      if (status) {
        req.user.driverInfo.status = status;
      }
      
      if (currentRideId) {
        req.user.driverInfo.currentRideId = currentRideId;
      }
      
      req.user.driverInfo.lastPostgresUpdate = now;
      
      // Mettre à jour l'adresse si fournie
      if (address) {
        req.user.driverInfo.currentLocation = {
          latitude,
          longitude,
          address,
          timestamp: new Date()
        };
      }
      
      await userRepository.save(req.user);
    }

    // 2. Mettre à jour dans Redis (temps réel - toutes les 2-3 secondes)
    if (redisService && redisService.isReady()) {
      try {
        const driverStatus = status || req.user.driverInfo?.status || 'available';
        const rideId = currentRideId || req.user.driverInfo?.currentRideId || null;

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
        // Récupérer le currentRideId depuis les paramètres ou driverInfo
        const activeRideId = currentRideId || req.user.driverInfo?.currentRideId || null;
        
        // Si pas dans driverInfo, récupérer depuis Redis
        let finalRideId = activeRideId;
        if (!finalRideId && redisService && redisService.isReady()) {
          try {
            const driverLocation = await redisService.getDriverLocation(req.user.id);
            finalRideId = driverLocation?.currentRideId || null;
          } catch (redisReadError) {
            logger.debug('Impossible de récupérer currentRideId depuis Redis', {
              error: redisReadError.message,
              driverId: req.user.id
            });
          }
        }
        
        // Si le chauffeur a une course active, distribuer uniquement aux clients de cette course
        if (finalRideId && clientNamespace) {
          const locationData = {
            type: 'driver_location_update',
            driverId: req.user.id,
            rideId: finalRideId,
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
          // Utiliser clientNamespace (pas driverNamespace) pour envoyer aux clients
          clientNamespace.to(`ride:${finalRideId}`).emit('driver:location:update', locationData);
          
          logger.debug('Driver location distributed to ride clients', {
            driverId: req.user.id,
            rideId: finalRideId,
            latitude,
            longitude
          });
        } else {
          // Si le chauffeur n'a pas de course active, ne rien distribuer
          // Le broadcaster automatique gérera la distribution depuis Redis
          logger.debug('Driver location not distributed immediately (no active ride or no clients)', {
            driverId: req.user.id,
            hasRideId: !!finalRideId,
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
      status: status || req.user.driverInfo?.status || 'available',
      updatedIn: {
        redis: redisService && redisService.isReady(),
        postgres: shouldUpdatePostgres
      }
    });
  } catch (error) {
    const logger = require('../utils/logger');
    logger.error('Erreur mise à jour position', {
      error: error.message,
      stack: error.stack,
      userId: req.user?.id
    });
    res.status(500).json({ error: 'Erreur lors de la mise à jour de la position' });
  }
});

/**
 * GET /api/driver/rides/:rideId
 * Obtenir les détails d'une course
 * Permet au conducteur de voir toutes les informations de la course, incluant la méthode de paiement
 */
router.get('/rides/:rideId', auth, async (req, res) => {
  try {
    // Vérifier que l'utilisateur est un conducteur
    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent consulter les détails d\'une course' 
      });
    }

    const rideId = parseInt(req.params.rideId);
    const rideRepository = AppDataSource.getRepository(Ride);

    // Récupérer la course avec relations
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que le conducteur est bien assigné à cette course
    if (ride.driverId !== req.user.id) {
      return res.status(403).json({ 
        error: 'Vous n\'êtes pas assigné à cette course' 
      });
    }

    // Retourner les détails complets de la course
    res.json({
      id: ride.id,
      status: ride.status,
      pickupLocation: ride.pickupLocation ? {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      } : null,
      pickupAddress: ride.pickupAddress,
      dropoffLocation: ride.dropoffLocation ? {
        latitude: ride.dropoffLocation.coordinates[1],
        longitude: ride.dropoffLocation.coordinates[0]
      } : null,
      dropoffAddress: ride.dropoffAddress,
      estimatedPrice: ride.estimatedPrice ? parseFloat(ride.estimatedPrice) : null,
      finalPrice: ride.finalPrice ? parseFloat(ride.finalPrice) : null,
      distance: ride.distance ? parseFloat(ride.distance) : null,
      duration: ride.duration,
      paymentMethod: ride.paymentMethod, // 'cash', 'mpesa', 'orange_money', 'stripe', etc.
      rating: ride.rating,
      comment: ride.comment,
      client: ride.client ? {
        id: ride.client.id,
        name: ride.client.name,
        phoneNumber: ride.client.phoneNumber
      } : null,
      driver: ride.driver ? {
        id: ride.driver.id,
        name: ride.driver.name,
        phoneNumber: ride.driver.phoneNumber
      } : null,
      createdAt: ride.createdAt,
      startedAt: ride.startedAt,
      completedAt: ride.completedAt,
      cancelledAt: ride.cancelledAt,
      cancellationReason: ride.cancellationReason
    });
  } catch (error) {
    console.error('Erreur récupération détails course:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération des détails de la course',
      message: error.message 
    });
  }
});

/**
 * POST /api/driver/accept_ride/:rideId
 * Accepter une course
 * (Wrapper vers /api/rides/accept/:courseId pour cohérence avec l'app Driver)
 */
router.post('/accept_ride/:rideId', auth, async (req, res) => {
  try {
    // Vérifier que l'utilisateur est un conducteur
    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent accepter une course' 
      });
    }

    const rideId = parseInt(req.params.rideId);
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    // Récupérer la course avec relations
    const ride = await rideRepository.findOne({ 
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ 
        error: 'Cette course n\'est plus disponible' 
      });
    }

    // Utiliser le service temps réel si disponible pour gérer la concurrence
    const realtimeRideService = getRealtimeRideService();
    
    if (realtimeRideService && driverNamespace) {
      // Chercher le socket du chauffeur dans le namespace
      let driverSocket = null;
      driverNamespace.sockets.forEach((socket) => {
        if (socket.driverId === req.user.id) {
          driverSocket = socket;
        }
      });
      
      if (driverSocket) {
        // Utiliser le service temps réel pour gérer la concurrence
        await realtimeRideService.handleRideAcceptance(req.user.id, ride.id, driverSocket);
        
        // Récupérer la course mise à jour
        const updatedRide = await rideRepository.findOne({ 
          where: { id: ride.id },
          relations: ['client', 'driver']
        });
        
        // Vérifier si l'acceptation a réussi (le service temps réel peut refuser si déjà acceptée)
        if (updatedRide.status === 'accepted' && updatedRide.driverId === req.user.id) {
          return res.json({
            success: true,
            message: 'Course acceptée avec succès',
            ride: {
              id: updatedRide.id,
              status: updatedRide.status,
              driverId: updatedRide.driverId,
              paymentMethod: updatedRide.paymentMethod // Inclure la méthode de paiement
            }
          });
        } else {
          return res.status(409).json({
            error: 'Course non disponible',
            message: 'Cette course a déjà été acceptée par un autre conducteur'
          });
        }
      }
    }

    // Fallback: Si le service temps réel n'est pas disponible ou le driver n'est pas connecté via WebSocket
    // Utiliser une transaction pour éviter les conditions de course
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Re-vérifier le statut dans la transaction
      const rideInTransaction = await queryRunner.manager.findOne(Ride, {
        where: { id: rideId },
        relations: ['client', 'driver']
      });

      if (!rideInTransaction || rideInTransaction.status !== 'pending') {
        await queryRunner.rollbackTransaction();
        return res.status(400).json({ 
          error: 'Cette course n\'est plus disponible' 
        });
      }

      // Assigner le conducteur à la course (dans la transaction)
      rideInTransaction.driverId = req.user.id;
      rideInTransaction.status = 'accepted';
      await queryRunner.manager.save(rideInTransaction);

      // Mettre à jour le statut du conducteur dans driverInfo (dans la transaction)
      const driver = await queryRunner.manager.findOne(User, { 
        where: { id: req.user.id } 
      });

      if (driver) {
        const driverInfo = driver.driverInfo || {};
        driverInfo.status = 'en_route_to_pickup';
        driverInfo.currentRideId = rideInTransaction.id;
        driverInfo.isOnline = true;
        
        await queryRunner.manager.query(
          `UPDATE users 
           SET driver_info = $1::jsonb, updated_at = NOW()
           WHERE id = $2`,
          [JSON.stringify(driverInfo), driver.id]
        );
      }

      // Commit de la transaction
      await queryRunner.commitTransaction();

      // Notifier le client (hors transaction)
      if (rideInTransaction.client?.fcmToken) {
        await sendNotification(rideInTransaction.client.fcmToken, {
          title: 'Course acceptée !',
          body: `${req.user.name} a accepté votre course`,
          data: { 
            rideId: rideInTransaction.id.toString(), 
            type: 'ride_accepted' 
          }
        });
      }

      // Émettre un événement Socket.io (vers namespace client aussi)
      io.to(`ride:${rideInTransaction.id}`).emit('ride_update', {
        type: 'ride_accepted',
        rideId: rideInTransaction.id.toString(),
        driverId: req.user.id.toString(),
        driverName: req.user.name,
        timestamp: new Date()
      });

      res.json({
        success: true,
        message: 'Course acceptée avec succès',
        ride: {
          id: rideInTransaction.id,
          status: rideInTransaction.status,
          driverId: rideInTransaction.driverId,
          paymentMethod: rideInTransaction.paymentMethod // Inclure la méthode de paiement
        }
      });
    } catch (error) {
      await queryRunner.rollbackTransaction();
      console.error('Erreur acceptation course (transaction):', error);
      return res.status(500).json({ 
        error: 'Erreur lors de l\'acceptation',
        message: error.message 
      });
    } finally {
      await queryRunner.release();
    }
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ 
      error: 'Erreur lors de l\'acceptation',
      message: error.message 
    });
  }
});

/**
 * POST /api/driver/reject_ride/:rideId
 * Rejeter une course (avec transaction ACID)
 * 
 * Logique:
 * 1. Vérifier que la course existe et appartient au conducteur
 * 2. Mettre à jour le statut de la course à 'rejected'
 * 3. Remettre le conducteur à 'disponible' dans driverInfo
 * 4. Tout dans une transaction ACID
 */
router.post('/reject_ride/:rideId', auth, async (req, res) => {
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    // Vérifier que l'utilisateur est un conducteur
    if (req.user.role !== 'driver') {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent rejeter une course' 
      });
    }

    const rideId = parseInt(req.params.rideId);
    const rideRepository = queryRunner.manager.getRepository(Ride);
    const userRepository = queryRunner.manager.getRepository(User);

    // 1. Récupérer la course avec relations
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      await queryRunner.rollbackTransaction();
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que le conducteur est bien assigné à cette course
    if (ride.driverId !== req.user.id) {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Vous n\'êtes pas assigné à cette course' 
      });
    }

    // Vérifier que la course peut être rejetée
    if (!['pending', 'accepted', 'driverArriving'].includes(ride.status)) {
      await queryRunner.rollbackTransaction();
      return res.status(400).json({ 
        error: `Impossible de rejeter une course avec le statut: ${ride.status}` 
      });
    }

    // 2. Mettre à jour le statut de la course à 'rejected' (dans la transaction)
    ride.status = 'rejected';
    ride.cancelledAt = new Date();
    ride.cancellationReason = 'Rejetée par le conducteur';
    await queryRunner.manager.save(ride);

    // 3. Remettre le conducteur à 'disponible' dans driverInfo (dans la transaction)
    const driver = await userRepository.findOne({ 
      where: { id: req.user.id } 
    });

    if (driver) {
      // Mettre à jour driverInfo pour remettre le statut à 'disponible'
      const driverInfo = driver.driverInfo || {};
      driverInfo.isOnline = true;
      driverInfo.status = 'available';
      driverInfo.currentRideId = null;
      
      // Utiliser une requête SQL directe pour mettre à jour le JSONB
      await queryRunner.manager.query(
        `UPDATE users 
         SET driver_info = $1::jsonb, updated_at = NOW()
         WHERE id = $2`,
        [JSON.stringify(driverInfo), driver.id]
      );
    }

    // 4. Commit de la transaction ACID
    await queryRunner.commitTransaction();

    // Notifier le client via Socket.io (hors transaction)
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course rejetée',
        body: 'Le conducteur a rejeté votre course. Nous recherchons un autre conducteur...',
        data: { 
          rideId: ride.id.toString(), 
          type: 'ride_rejected' 
        }
      });
    }

    // Émettre un événement Socket.io pour notifier les autres clients
    io.emit('ride:rejected', {
      rideId: ride.id,
      driverId: req.user.id,
      timestamp: new Date()
    });

    // Émettre un événement pour notifier qu'un nouveau conducteur est disponible
    io.emit('driver:available', {
      driverId: req.user.id,
      location: driver?.location ? {
        latitude: driver.location.coordinates[1],
        longitude: driver.location.coordinates[0]
      } : null
    });

    res.json({
      success: true,
      message: 'Course rejetée avec succès',
      ride: {
        id: ride.id,
        status: ride.status,
        cancelledAt: ride.cancelledAt
      },
      driver: {
        id: req.user.id,
        status: 'available'
      }
    });

  } catch (error) {
    // Rollback en cas d'erreur
    await queryRunner.rollbackTransaction();
    console.error('Erreur rejet course:', error);
    res.status(500).json({ 
      error: 'Erreur lors du rejet de la course',
      message: error.message 
    });
  } finally {
    await queryRunner.release();
  }
});

/**
 * POST /api/driver/complete_ride/:rideId
 * Compléter une course (avec transaction ACID critique)
 * 
 * Logique ACID:
 * 1. Vérifier que la course existe et appartient au conducteur
 * 2. Mettre à jour le statut de la course à 'completed'
 * 3. Enregistrer la transaction de paiement (si applicable)
 * 4. Remettre le conducteur à 'disponible' dans driverInfo
 * 5. Tout dans une transaction PostgreSQL unique et sécurisée
 */
router.post('/complete_ride/:rideId', auth, [
  body('finalPrice').optional().isFloat({ min: 0 }).withMessage('finalPrice doit être un nombre positif'),
  body('paymentToken').optional().isString().withMessage('paymentToken doit être une chaîne'),
  body('paymentMethod').optional().isIn(['cash', 'mobile_money', 'card', 'mpesa', 'orange_money']).withMessage('paymentMethod invalide')
], async (req, res) => {
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      await queryRunner.rollbackTransaction();
      return res.status(400).json({ errors: errors.array() });
    }

    // Vérifier que l'utilisateur est un conducteur
    if (req.user.role !== 'driver') {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent compléter une course' 
      });
    }

    const rideId = parseInt(req.params.rideId);
    const { finalPrice, paymentToken, paymentMethod } = req.body;
    const rideRepository = queryRunner.manager.getRepository(Ride);
    const userRepository = queryRunner.manager.getRepository(User);

    // 1. Récupérer la course avec relations (dans la transaction)
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      await queryRunner.rollbackTransaction();
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que le conducteur est bien assigné à cette course
    if (ride.driverId !== req.user.id) {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Vous n\'êtes pas assigné à cette course' 
      });
    }

    // Vérifier que la course peut être complétée
    if (!['accepted', 'driverArriving', 'inProgress'].includes(ride.status)) {
      await queryRunner.rollbackTransaction();
      return res.status(400).json({ 
        error: `Impossible de compléter une course avec le statut: ${ride.status}` 
      });
    }

    // 2. Mettre à jour le statut de la course à 'completed' (dans la transaction)
    ride.status = 'completed';
    ride.completedAt = new Date();
    
    // Mettre à jour le prix final si fourni
    if (finalPrice !== undefined) {
      ride.finalPrice = parseFloat(finalPrice);
    } else if (!ride.finalPrice) {
      // Utiliser le prix estimé si aucun prix final n'est fourni
      ride.finalPrice = ride.estimatedPrice;
    }

    // Mettre à jour la méthode de paiement si fournie
    if (paymentMethod) {
      ride.paymentMethod = paymentMethod;
    }

    await queryRunner.manager.save(ride);

    // 3. Enregistrer la transaction de paiement (si paymentToken fourni)
    let paymentTransaction = null;
    if (paymentToken && paymentMethod !== 'cash') {
      try {
        // Utiliser le service de paiement pour traiter le paiement
        // Note: PaymentService.processPayment utilise déjà une transaction,
        // donc on doit l'appeler hors de notre transaction principale
        // ou adapter le code pour utiliser queryRunner
        
        // Pour l'instant, on enregistre juste la transaction dans notre transaction
        const transactionQuery = `
          INSERT INTO stripe_transactions (
            ride_id,
            payment_intent_id,
            amount,
            currency,
            status,
            stripe_token,
            metadata,
            created_at,
            updated_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
          RETURNING *
        `;

        const transactionResult = await queryRunner.manager.query(transactionQuery, [
          ride.id,
          paymentToken,
          parseFloat(ride.finalPrice),
          process.env.STRIPE_CURRENCY || 'cdf',
          'pending',
          paymentToken.substring(0, 50),
          JSON.stringify({
            rideId: ride.id,
            driverId: req.user.id,
            clientId: ride.clientId,
            completedAt: ride.completedAt
          })
        ]);

        paymentTransaction = transactionResult[0];
      } catch (paymentError) {
        console.error('Erreur enregistrement transaction paiement:', paymentError);
        // Ne pas faire échouer la complétion de la course si le paiement échoue
        // Le paiement pourra être traité plus tard
      }
    }

    // 4. Remettre le conducteur à 'disponible' dans driverInfo (dans la transaction)
    const driver = await userRepository.findOne({ 
      where: { id: req.user.id } 
    });

    if (driver) {
      const driverInfo = driver.driverInfo || {};
      driverInfo.isOnline = true;
      driverInfo.status = 'available';
      driverInfo.currentRideId = null;
      
      // Mettre à jour les statistiques du conducteur
      if (!driverInfo.totalRides) {
        driverInfo.totalRides = 0;
      }
      driverInfo.totalRides = (driverInfo.totalRides || 0) + 1;

      // Calculer les revenus totaux
      if (!driverInfo.totalEarnings) {
        driverInfo.totalEarnings = 0;
      }
      driverInfo.totalEarnings = (parseFloat(driverInfo.totalEarnings) || 0) + parseFloat(ride.finalPrice);

      // Utiliser une requête SQL directe pour mettre à jour le JSONB
      await queryRunner.manager.query(
        `UPDATE users 
         SET driver_info = $1::jsonb, updated_at = NOW()
         WHERE id = $2`,
        [JSON.stringify(driverInfo), driver.id]
      );
    }

    // 5. Commit de la transaction ACID critique
    await queryRunner.commitTransaction();

    // Notifier le client via Socket.io (hors transaction)
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course terminée',
        body: `Votre course a été complétée. Montant: ${ride.finalPrice} ${process.env.STRIPE_CURRENCY || 'CDF'}`,
        data: { 
          rideId: ride.id.toString(), 
          type: 'ride_completed',
          finalPrice: ride.finalPrice
        }
      });
    }

    // Émettre un événement Socket.io
    io.emit('ride:completed', {
      rideId: ride.id,
      driverId: req.user.id,
      finalPrice: ride.finalPrice,
      timestamp: new Date()
    });

    // Émettre un événement pour notifier qu'un nouveau conducteur est disponible
    io.emit('driver:available', {
      driverId: req.user.id,
      location: driver?.location ? {
        latitude: driver.location.coordinates[1],
        longitude: driver.location.coordinates[0]
      } : null
    });

    res.json({
      success: true,
      message: 'Course complétée avec succès',
      ride: {
        id: ride.id,
        status: ride.status,
        finalPrice: parseFloat(ride.finalPrice),
        completedAt: ride.completedAt,
        paymentMethod: ride.paymentMethod
      },
      payment: paymentTransaction ? {
        id: paymentTransaction.id,
        status: paymentTransaction.status,
        amount: parseFloat(paymentTransaction.amount)
      } : null,
      driver: {
        id: req.user.id,
        status: 'available',
        totalRides: driver?.driverInfo?.totalRides || 0,
        totalEarnings: driver?.driverInfo?.totalEarnings || 0
      }
    });

  } catch (error) {
    // Rollback en cas d'erreur
    await queryRunner.rollbackTransaction();
    console.error('Erreur complétion course:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la complétion de la course',
      message: error.message 
    });
  } finally {
    await queryRunner.release();
  }
});

module.exports = router;

