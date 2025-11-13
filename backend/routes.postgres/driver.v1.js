// Routes API v1 pour l'application Driver
// Endpoints: /api/v1/driver/*
const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { io, driverNamespace, notifyAvailableDrivers, getRealtimeRideService } = require('../server.postgres');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Générer un token JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

/**
 * POST /api/v1/driver/auth/login
 * Authentification du chauffeur avec email/mot de passe
 * Retourne un token JWT
 */
router.post('/auth/login', [
  body('email').isEmail().withMessage('Email invalide'),
  body('password').notEmpty().withMessage('Mot de passe requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    // Chercher l'utilisateur par email (ou phoneNumber si email n'existe pas)
    // Note: Pour l'instant, on utilise phoneNumber comme identifiant
    // Si vous avez un champ email dans User, utilisez-le
    let user = await userRepository.findOne({ 
      where: { 
        phoneNumber: email // Utiliser email comme phoneNumber pour compatibilité
      } 
    });

    // Si pas trouvé, chercher par email si le champ existe
    if (!user) {
      // Vous pouvez ajouter une recherche par email si vous avez ce champ
      // user = await userRepository.findOne({ where: { email } });
    }

    if (!user) {
      return res.status(401).json({ 
        error: 'Email ou mot de passe incorrect',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Vérifier que l'utilisateur est un conducteur
    if (user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Accès refusé. Compte conducteur requis.',
        code: 'NOT_DRIVER'
      });
    }

    // TODO: Vérifier le mot de passe (pour l'instant, on accepte n'importe quel mot de passe)
    // Si vous avez un système de hash de mot de passe, vérifiez-le ici
    // const isValidPassword = await bcrypt.compare(password, user.password);
    // if (!isValidPassword) {
    //   return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    // }

    // Générer le token JWT
    const token = generateToken(user.id);

    res.json({
      token,
      driver: {
        id: user.id.toString(),
        name: user.name,
        email: user.email || user.phoneNumber,
        phoneNumber: user.phoneNumber,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erreur login driver:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la connexion',
      message: error.message 
    });
  }
});

/**
 * POST /api/v1/driver/status/update
 * Mettre à jour le statut du conducteur (Offline/En ligne/Occupé)
 */
router.post('/status/update', auth, [
  body('status').isIn(['offline', 'available', 'pending_request', 'en_route_to_pickup', 'on_trip', 'finished_trip'])
    .withMessage('Statut invalide')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent modifier leur statut' 
      });
    }

    const { status } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    // Mettre à jour le statut dans driverInfo
    const driverInfo = req.user.driverInfo || {};
    driverInfo.status = status;
    driverInfo.isOnline = status !== 'offline';

    // Utiliser une requête SQL directe pour mettre à jour le JSONB
    await AppDataSource.query(
      `UPDATE users 
       SET driver_info = $1::jsonb, updated_at = NOW()
       WHERE id = $2`,
      [JSON.stringify(driverInfo), req.user.id]
    );

    // Notifier via WebSocket que le statut a changé
    io.emit('driver:status:update', {
      driverId: req.user.id,
      status: status,
      isOnline: driverInfo.isOnline,
      timestamp: new Date()
    });

    res.json({
      success: true,
      status: status,
      isOnline: driverInfo.isOnline,
      message: `Statut mis à jour: ${status}`
    });
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la mise à jour du statut',
      message: error.message 
    });
  }
});

/**
 * POST /api/v1/driver/location/sync
 * Synchronisation de la position GPS du conducteur en temps réel
 */
router.post('/location/sync', auth, [
  body('latitude').isFloat().withMessage('Latitude invalide'),
  body('longitude').isFloat().withMessage('Longitude invalide'),
  body('timestamp').optional().isISO8601().withMessage('Timestamp invalide'),
  body('accuracy').optional().isFloat({ min: 0 }),
  body('speed').optional().isFloat({ min: 0 }),
  body('heading').optional().isFloat({ min: 0, max: 360 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent synchroniser leur position' 
      });
    }

    const { latitude, longitude, timestamp, accuracy, speed, heading } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    // Créer le point PostGIS
    const locationPoint = {
      type: 'Point',
      coordinates: [longitude, latitude]
    };

    // Mettre à jour la localisation
    req.user.location = locationPoint;

    // Mettre à jour driverInfo avec les détails de localisation
    const driverInfo = req.user.driverInfo || {};
    driverInfo.currentLocation = {
      latitude,
      longitude,
      timestamp: timestamp ? new Date(timestamp) : new Date(),
      accuracy: accuracy || null,
      speed: speed || null,
      heading: heading || null
    };

    // Utiliser une requête SQL directe pour mettre à jour
    await AppDataSource.query(
      `UPDATE users 
       SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326),
           driver_info = $3::jsonb,
           updated_at = NOW()
       WHERE id = $4`,
      [longitude, latitude, JSON.stringify(driverInfo), req.user.id]
    );

    // Diffuser la position via Socket.io
    io.emit('driver:location:update', {
      driverId: req.user.id,
      location: {
        latitude,
        longitude,
        accuracy,
        speed,
        heading
      },
      timestamp: new Date()
    });

    res.json({
      success: true,
      location: {
        latitude,
        longitude,
        timestamp: new Date().toISOString()
      }
    });
  } catch (error) {
    console.error('Erreur synchronisation position:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la synchronisation de la position',
      message: error.message 
    });
  }
});

/**
 * POST /api/v1/driver/course/accept/:ride_id
 * Accepter une course proposée
 */
router.post('/course/accept/:ride_id', auth, async (req, res) => {
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    if (req.user.role !== 'driver') {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent accepter une course' 
      });
    }

    const rideId = parseInt(req.params.ride_id);
    const rideRepository = queryRunner.manager.getRepository(Ride);
    const userRepository = queryRunner.manager.getRepository(User);

    // Récupérer la course avec relations
    const ride = await rideRepository.findOne({ 
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      await queryRunner.rollbackTransaction();
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      await queryRunner.rollbackTransaction();
      return res.status(400).json({ 
        error: 'Cette course n\'est plus disponible',
        currentStatus: ride.status
      });
    }

    // Assigner le conducteur à la course
    ride.driverId = req.user.id;
    ride.status = 'accepted';
    await queryRunner.manager.save(ride);

    // Mettre à jour le statut du conducteur
    const driverInfo = req.user.driverInfo || {};
    driverInfo.status = 'en_route_to_pickup';
    driverInfo.currentRideId = ride.id;
    driverInfo.isOnline = true;

    await queryRunner.manager.query(
      `UPDATE users 
       SET driver_info = $1::jsonb, updated_at = NOW()
       WHERE id = $2`,
      [JSON.stringify(driverInfo), req.user.id]
    );

    // Commit de la transaction
    await queryRunner.commitTransaction();

    // Notifier le client
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course acceptée !',
        body: `${req.user.name} a accepté votre course`,
        data: { 
          rideId: ride.id.toString(), 
          type: 'ride_accepted' 
        }
      });
    }

    // Émettre un événement Socket.io
    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: 'accepted',
      driverId: req.user.id
    });

    // Notifier via WebSocket le conducteur
    driverNamespace.to(`driver:${req.user.id}`).emit('ride:update', {
      type: 'ride_update',
      ride: {
        id: ride.id.toString(),
        status: 'accepted',
        pickupAddress: ride.pickupAddress,
        dropoffAddress: ride.dropoffAddress,
        pickupLatitude: ride.pickupLocation.coordinates[1],
        pickupLongitude: ride.pickupLocation.coordinates[0],
        dropoffLatitude: ride.dropoffLocation.coordinates[1],
        dropoffLongitude: ride.dropoffLocation.coordinates[0],
        estimatedDistance: ride.distance || 0,
        estimatedDuration: ride.estimatedDuration || 0,
        estimatedEarnings: ride.estimatedPrice || 0,
        passengerName: ride.client?.name || null,
        createdAt: ride.createdAt.toISOString()
      }
    });

    res.json({
      success: true,
      message: 'Course acceptée avec succès',
      ride: {
        id: ride.id.toString(),
        status: ride.status,
        driverId: ride.driverId,
        pickupAddress: ride.pickupAddress,
        dropoffAddress: ride.dropoffAddress,
        estimatedPrice: ride.estimatedPrice,
        estimatedDistance: ride.distance,
        estimatedDuration: ride.estimatedDuration
      }
    });
  } catch (error) {
    await queryRunner.rollbackTransaction();
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ 
      error: 'Erreur lors de l\'acceptation de la course',
      message: error.message 
    });
  } finally {
    await queryRunner.release();
  }
});

/**
 * POST /api/v1/driver/course/refuse/:ride_id
 * Refuser une course proposée
 */
router.post('/course/refuse/:ride_id', auth, [
  body('reason').optional().trim()
], async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent refuser une course' 
      });
    }

    const rideId = parseInt(req.params.ride_id);
    const { reason } = req.body;
    const rideRepository = AppDataSource.getRepository(Ride);

    // Récupérer la course
    const ride = await rideRepository.findOne({ 
      where: { id: rideId },
      relations: ['client']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // La course reste en "pending" pour permettre à d'autres conducteurs de l'accepter
    // On ne change pas le statut de la course, on enregistre juste le refus

    // Notifier via WebSocket que le conducteur a refusé (pour relancer l'attribution)
    // Le backend peut alors chercher d'autres conducteurs disponibles
    io.emit('driver:ride:refused', {
      rideId: ride.id,
      driverId: req.user.id,
      reason: reason || 'driver_refused',
      timestamp: new Date()
    });

    res.json({
      success: true,
      message: 'Course refusée',
      rideId: ride.id,
      reason: reason || 'driver_refused'
    });
  } catch (error) {
    console.error('Erreur refus course:', error);
    res.status(500).json({ 
      error: 'Erreur lors du refus de la course',
      message: error.message 
    });
  }
});

/**
 * POST /api/v1/driver/course/progress/:ride_id
 * Mettre à jour les étapes de la course
 * progress: "arrived_at_pickup" | "start_ride" | "end_ride"
 */
router.post('/course/progress/:ride_id', auth, [
  body('progress').isIn(['arrived_at_pickup', 'start_ride', 'end_ride'])
    .withMessage('Progression invalide'),
  body('timestamp').optional().isISO8601().withMessage('Timestamp invalide')
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

    if (req.user.role !== 'driver') {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent mettre à jour la progression de la course' 
      });
    }

    const rideId = parseInt(req.params.ride_id);
    const { progress, timestamp } = req.body;
    const rideRepository = queryRunner.manager.getRepository(Ride);
    const userRepository = queryRunner.manager.getRepository(User);

    // Récupérer la course
    const ride = await rideRepository.findOne({
      where: { id: rideId },
      relations: ['client', 'driver']
    });

    if (!ride) {
      await queryRunner.rollbackTransaction();
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que le conducteur est assigné à cette course
    if (ride.driverId !== req.user.id) {
      await queryRunner.rollbackTransaction();
      return res.status(403).json({ 
        error: 'Vous n\'êtes pas assigné à cette course' 
      });
    }

    // Mettre à jour le statut de la course selon la progression
    let newStatus = ride.status;
    let driverStatus = 'available';

    switch (progress) {
      case 'arrived_at_pickup':
        newStatus = 'driverArriving';
        driverStatus = 'en_route_to_pickup';
        break;
      case 'start_ride':
        newStatus = 'inProgress';
        driverStatus = 'on_trip';
        break;
      case 'end_ride':
        newStatus = 'completed';
        ride.completedAt = new Date(timestamp || Date.now());
        driverStatus = 'available';
        // Remettre le conducteur à disponible
        const driverInfo = req.user.driverInfo || {};
        driverInfo.status = 'available';
        driverInfo.currentRideId = null;
        driverInfo.isOnline = true;

        // Mettre à jour les statistiques
        if (!driverInfo.totalRides) {
          driverInfo.totalRides = 0;
        }
        driverInfo.totalRides = (driverInfo.totalRides || 0) + 1;

        if (!driverInfo.totalEarnings) {
          driverInfo.totalEarnings = 0;
        }
        driverInfo.totalEarnings = (parseFloat(driverInfo.totalEarnings) || 0) + parseFloat(ride.estimatedPrice || 0);

        await queryRunner.manager.query(
          `UPDATE users 
           SET driver_info = $1::jsonb, updated_at = NOW()
           WHERE id = $2`,
          [JSON.stringify(driverInfo), req.user.id]
        );
        break;
    }

    ride.status = newStatus;
    await queryRunner.manager.save(ride);

    // Mettre à jour le statut du conducteur (sauf pour end_ride qui est déjà fait)
    if (progress !== 'end_ride') {
      const driverInfo = req.user.driverInfo || {};
      driverInfo.status = driverStatus;
      driverInfo.currentRideId = ride.id;

      await queryRunner.manager.query(
        `UPDATE users 
         SET driver_info = $1::jsonb, updated_at = NOW()
         WHERE id = $2`,
        [JSON.stringify(driverInfo), req.user.id]
      );
    }

    // Commit de la transaction
    await queryRunner.commitTransaction();

    // Notifier le client via Socket.io
    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: newStatus,
      progress: progress,
      timestamp: new Date()
    });

    // Notifier via WebSocket le conducteur
    driverNamespace.to(`driver:${req.user.id}`).emit('ride:update', {
      type: 'ride_update',
      ride: {
        id: ride.id.toString(),
        status: newStatus,
        progress: progress
      }
    });

    res.json({
      success: true,
      message: `Progression mise à jour: ${progress}`,
      ride: {
        id: ride.id.toString(),
        status: newStatus,
        progress: progress
      }
    });
  } catch (error) {
    await queryRunner.rollbackTransaction();
    console.error('Erreur mise à jour progression:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la mise à jour de la progression',
      message: error.message 
    });
  } finally {
    await queryRunner.release();
  }
});

/**
 * GET /api/v1/driver/new_ride
 * Endpoint pour recevoir les nouvelles courses (mécanisme push via WebSocket)
 * Note: Cet endpoint n'est pas vraiment utilisé car les nouvelles courses sont
 * envoyées automatiquement via WebSocket quand une course est créée.
 * Cet endpoint peut être utilisé pour polling si nécessaire.
 */
router.get('/new_ride', auth, async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ 
        error: 'Seuls les conducteurs peuvent recevoir des nouvelles courses' 
      });
    }

    // Vérifier que le conducteur est en ligne
    const driverInfo = req.user.driverInfo || {};
    if (!driverInfo.isOnline || driverInfo.status === 'offline') {
      return res.json({
        message: 'Conducteur hors ligne',
        rides: []
      });
    }

    // Récupérer les courses en attente
    const rideRepository = AppDataSource.getRepository(Ride);
    const pendingRides = await rideRepository.find({
      where: { status: 'pending' },
      relations: ['client'],
      order: { createdAt: 'DESC' },
      take: 10 // Limiter à 10 courses
    });

    // Formater les courses
    const formattedRides = pendingRides.map(ride => ({
      id: ride.id.toString(),
      pickupAddress: ride.pickupAddress,
      dropoffAddress: ride.dropoffAddress,
      pickupLatitude: ride.pickupLocation.coordinates[1],
      pickupLongitude: ride.pickupLocation.coordinates[0],
      dropoffLatitude: ride.dropoffLocation.coordinates[1],
      dropoffLongitude: ride.dropoffLocation.coordinates[0],
      estimatedDistance: ride.distance || 0,
      estimatedDuration: ride.estimatedDuration || 0,
      estimatedEarnings: ride.estimatedPrice || 0,
      passengerName: ride.client?.name || null,
      createdAt: ride.createdAt.toISOString()
    }));

    res.json({
      rides: formattedRides,
      count: formattedRides.length
    });
  } catch (error) {
    console.error('Erreur récupération nouvelles courses:', error);
    res.status(500).json({ 
      error: 'Erreur lors de la récupération des nouvelles courses',
      message: error.message 
    });
  }
});

module.exports = router;

