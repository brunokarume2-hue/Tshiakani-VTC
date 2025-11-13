// Routes API Agent - Gestion des chauffeurs, courses et support client
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const SOSReport = require('../entities/SOSReport');
const { agentAuth } = require('../middlewares.postgres/auth');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Fonction helper pour obtenir io de manière lazy (évite la dépendance circulaire)
const getIo = () => {
  const { io } = require('../server.postgres');
  return io;
};

// Appliquer l'authentification agent à toutes les routes
router.use(agentAuth);

// ==================== STATISTIQUES ====================

/**
 * GET /api/agent/stats
 * Obtenir les statistiques générales pour les agents
 */
router.get('/stats', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalDrivers,
      activeDrivers,
      pendingDrivers,
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
      userRepository
        .createQueryBuilder('user')
        .where('user.role = :role', { role: 'driver' })
        .andWhere("user.driver_info->>'documentsStatus' = 'pending'")
        .getCount(),
      rideRepository.count(),
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.createdAt >= :today', { today })
        .getCount(),
      rideRepository.count({ where: { status: 'pending' } }),
      rideRepository
        .createQueryBuilder('ride')
        .where('ride.status IN (:...statuses)', { 
          statuses: ['accepted', 'driverArriving', 'inProgress'] 
        })
        .getCount(),
      rideRepository.count({ where: { status: 'completed' } }),
      rideRepository
        .createQueryBuilder('ride')
        .select('SUM(ride.finalPrice)', 'total')
        .where('ride.status = :status', { status: 'completed' })
        .getRawOne()
    ]);

    res.json({
      drivers: {
        total: totalDrivers,
        active: activeDrivers,
        pending: pendingDrivers
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
    });
  } catch (error) {
    console.error('Erreur statistiques agent:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

// ==================== GESTION DES CHAUFFEURS ====================

/**
 * GET /api/agent/drivers
 * Obtenir la liste des chauffeurs avec filtres
 */
router.get('/drivers', async (req, res) => {
  try {
    const { status, isOnline, page = 1, limit = 50, search } = req.query;
    const userRepository = AppDataSource.getRepository(User);

    let query = userRepository
      .createQueryBuilder('user')
      .where('user.role = :role', { role: 'driver' });

    // Filtrer par statut de documents
    if (status) {
      query = query.andWhere("user.driver_info->>'documentsStatus' = :status", { status });
    }

    // Filtrer par statut en ligne
    if (isOnline !== undefined) {
      const onlineValue = isOnline === 'true' ? 'true' : 'false';
      query = query.andWhere("user.driver_info->>'isOnline' = :online", { online: onlineValue });
    }

    // Recherche par nom ou numéro de téléphone
    if (search) {
      query = query.andWhere(
        '(user.name ILIKE :search OR user.phone_number ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    const [drivers, total] = await query
      .orderBy('user.createdAt', 'DESC')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit))
      .getManyAndCount();

    const formattedDrivers = drivers.map(driver => ({
      id: driver.id,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      isVerified: driver.isVerified,
      driverInfo: driver.driverInfo || {},
      location: driver.location ? {
        latitude: driver.location.coordinates[1],
        longitude: driver.location.coordinates[0]
      } : null,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt
    }));

    res.json({
      drivers: formattedDrivers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération chauffeurs:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des chauffeurs' });
  }
});

/**
 * GET /api/agent/drivers/:driverId
 * Obtenir les détails d'un chauffeur
 */
router.get('/drivers/:driverId', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);

    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    // Statistiques du chauffeur
    const totalRides = await rideRepository.count({
      where: { driverId: driver.id, status: 'completed' }
    });

    const ratingResult = await rideRepository
      .createQueryBuilder('ride')
      .select('AVG(ride.rating)', 'avg')
      .where('ride.driverId = :driverId', { driverId: driver.id })
      .andWhere('ride.rating IS NOT NULL')
      .getRawOne();

    const earningsResult = await rideRepository
      .createQueryBuilder('ride')
      .select('SUM(ride.finalPrice)', 'total')
      .where('ride.driverId = :driverId', { driverId: driver.id })
      .andWhere('ride.status = :status', { status: 'completed' })
      .getRawOne();

    // Dernières courses
    const recentRides = await rideRepository.find({
      where: { driverId: driver.id },
      relations: ['client'],
      order: { createdAt: 'DESC' },
      take: 10
    });

    res.json({
      id: driver.id,
      name: driver.name,
      phoneNumber: driver.phoneNumber,
      isVerified: driver.isVerified,
      driverInfo: driver.driverInfo || {},
      location: driver.location ? {
        latitude: driver.location.coordinates[1],
        longitude: driver.location.coordinates[0]
      } : null,
      stats: {
        totalRides,
        averageRating: ratingResult ? parseFloat(ratingResult.avg) : null,
        totalEarnings: earningsResult ? parseFloat(earningsResult.total) : 0
      },
      recentRides: recentRides.map(ride => ({
        id: ride.id,
        status: ride.status,
        pickupAddress: ride.pickupAddress,
        dropoffAddress: ride.dropoffAddress,
        estimatedPrice: ride.estimatedPrice,
        finalPrice: ride.finalPrice,
        createdAt: ride.createdAt,
        client: ride.client ? {
          id: ride.client.id,
          name: ride.client.name,
          phoneNumber: ride.client.phoneNumber
        } : null
      })),
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt
    });
  } catch (error) {
    console.error('Erreur récupération détails chauffeur:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

/**
 * POST /api/agent/drivers/:driverId/validate
 * Valider les documents d'un chauffeur
 */
router.post('/drivers/:driverId/validate', [
  body('documentType').optional().isString(),
  body('reason').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { documentType, reason } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    const documents = driverInfo.documents || {};

    if (documentType) {
      // Valider un document spécifique
      if (documents[documentType]) {
        documents[documentType].status = 'validated';
        documents[documentType].validatedAt = new Date();
        documents[documentType].validatedBy = req.user.id;
        if (reason) {
          documents[documentType].validationNote = reason;
        }
      }
    } else {
      // Valider tous les documents
      Object.keys(documents).forEach(key => {
        if (documents[key]) {
          documents[key].status = 'validated';
          documents[key].validatedAt = new Date();
          documents[key].validatedBy = req.user.id;
        }
      });
      driverInfo.documentsStatus = 'validated';
      driver.isVerified = true;
    }

    driverInfo.documents = documents;
    driver.driverInfo = driverInfo;
    await userRepository.save(driver);

    // Notifier le chauffeur
    if (driver.fcmToken) {
      await sendNotification(driver.fcmToken, {
        title: 'Documents validés',
        body: documentType 
          ? `Votre document ${documentType} a été validé`
          : 'Tous vos documents ont été validés',
        data: {
          type: 'documents_validated',
          driverId: driver.id.toString()
        }
      });
    }

    res.json({
      success: true,
      message: 'Documents validés avec succès',
      driver: {
        id: driver.id,
        driverInfo: driver.driverInfo
      }
    });
  } catch (error) {
    console.error('Erreur validation documents:', error);
    res.status(500).json({ error: 'Erreur lors de la validation' });
  }
});

/**
 * POST /api/agent/drivers/:driverId/reject
 * Rejeter les documents d'un chauffeur
 */
router.post('/drivers/:driverId/reject', [
  body('documentType').optional().isString(),
  body('reason').isString().withMessage('Une raison est requise')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { documentType, reason } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    const documents = driverInfo.documents || {};

    if (documentType) {
      // Rejeter un document spécifique
      if (documents[documentType]) {
        documents[documentType].status = 'rejected';
        documents[documentType].rejectedAt = new Date();
        documents[documentType].rejectedBy = req.user.id;
        documents[documentType].rejectionReason = reason;
      }
    } else {
      // Rejeter tous les documents
      Object.keys(documents).forEach(key => {
        if (documents[key]) {
          documents[key].status = 'rejected';
          documents[key].rejectedAt = new Date();
          documents[key].rejectedBy = req.user.id;
          documents[key].rejectionReason = reason;
        }
      });
      driverInfo.documentsStatus = 'rejected';
      driver.isVerified = false;
    }

    driverInfo.documents = documents;
    driver.driverInfo = driverInfo;
    await userRepository.save(driver);

    // Notifier le chauffeur
    if (driver.fcmToken) {
      await sendNotification(driver.fcmToken, {
        title: 'Documents rejetés',
        body: `Vos documents ont été rejetés: ${reason}`,
        data: {
          type: 'documents_rejected',
          driverId: driver.id.toString(),
          reason
        }
      });
    }

    res.json({
      success: true,
      message: 'Documents rejetés',
      driver: {
        id: driver.id,
        driverInfo: driver.driverInfo
      }
    });
  } catch (error) {
    console.error('Erreur rejet documents:', error);
    res.status(500).json({ error: 'Erreur lors du rejet' });
  }
});

/**
 * POST /api/agent/drivers/:driverId/activate
 * Activer un chauffeur
 */
router.post('/drivers/:driverId/activate', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);

    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    driverInfo.isOnline = true;
    driverInfo.status = 'available';
    driver.isVerified = true;
    driver.driverInfo = driverInfo;

    await userRepository.save(driver);

    // Notifier le chauffeur
    if (driver.fcmToken) {
      await sendNotification(driver.fcmToken, {
        title: 'Compte activé',
        body: 'Votre compte chauffeur a été activé. Vous pouvez maintenant accepter des courses.',
        data: {
          type: 'driver_activated',
          driverId: driver.id.toString()
        }
      });
    }

    res.json({
      success: true,
      message: 'Chauffeur activé avec succès',
      driver: {
        id: driver.id,
        driverInfo: driver.driverInfo
      }
    });
  } catch (error) {
    console.error('Erreur activation chauffeur:', error);
    res.status(500).json({ error: 'Erreur lors de l\'activation' });
  }
});

/**
 * POST /api/agent/drivers/:driverId/deactivate
 * Désactiver un chauffeur
 */
router.post('/drivers/:driverId/deactivate', [
  body('reason').optional().isString()
], async (req, res) => {
  try {
    const { reason } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    const driver = await userRepository.findOne({
      where: {
        id: parseInt(req.params.driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    driverInfo.isOnline = false;
    driverInfo.status = 'offline';
    if (reason) {
      driverInfo.deactivationReason = reason;
      driverInfo.deactivatedAt = new Date();
      driverInfo.deactivatedBy = req.user.id;
    }
    driver.driverInfo = driverInfo;

    await userRepository.save(driver);

    // Notifier le chauffeur
    if (driver.fcmToken) {
      await sendNotification(driver.fcmToken, {
        title: 'Compte désactivé',
        body: reason || 'Votre compte chauffeur a été désactivé.',
        data: {
          type: 'driver_deactivated',
          driverId: driver.id.toString(),
          reason
        }
      });
    }

    res.json({
      success: true,
      message: 'Chauffeur désactivé avec succès',
      driver: {
        id: driver.id,
        driverInfo: driver.driverInfo
      }
    });
  } catch (error) {
    console.error('Erreur désactivation chauffeur:', error);
    res.status(500).json({ error: 'Erreur lors de la désactivation' });
  }
});

// ==================== GESTION DES COURSES ====================

/**
 * GET /api/agent/rides
 * Obtenir la liste des courses avec filtres
 */
router.get('/rides', async (req, res) => {
  try {
    const { status, page = 1, limit = 50, startDate, endDate, driverId, clientId } = req.query;
    const rideRepository = AppDataSource.getRepository(Ride);

    let query = rideRepository
      .createQueryBuilder('ride')
      .leftJoinAndSelect('ride.client', 'client')
      .leftJoinAndSelect('ride.driver', 'driver');

    if (status) {
      query = query.where('ride.status = :status', { status });
    }

    if (driverId) {
      query = query.andWhere('ride.driverId = :driverId', { driverId: parseInt(driverId) });
    }

    if (clientId) {
      query = query.andWhere('ride.clientId = :clientId', { clientId: parseInt(clientId) });
    }

    if (startDate) {
      query = query.andWhere('ride.createdAt >= :startDate', { startDate: new Date(startDate) });
    }

    if (endDate) {
      query = query.andWhere('ride.createdAt <= :endDate', { endDate: new Date(endDate) });
    }

    const [rides, total] = await query
      .orderBy('ride.createdAt', 'DESC')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit))
      .getManyAndCount();

    const formattedRides = rides.map(ride => ({
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
      estimatedPrice: ride.estimatedPrice,
      finalPrice: ride.finalPrice,
      distance: ride.distance,
      duration: ride.duration,
      paymentMethod: ride.paymentMethod,
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
    }));

    res.json({
      rides: formattedRides,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération courses:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des courses' });
  }
});

/**
 * GET /api/agent/rides/:rideId
 * Obtenir les détails d'une course
 */
router.get('/rides/:rideId', async (req, res) => {
  try {
    const rideRepository = AppDataSource.getRepository(Ride);

    const ride = await rideRepository.findOne({
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

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
      estimatedPrice: ride.estimatedPrice,
      finalPrice: ride.finalPrice,
      distance: ride.distance,
      duration: ride.duration,
      paymentMethod: ride.paymentMethod,
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
        phoneNumber: ride.driver.phoneNumber,
        driverInfo: ride.driver.driverInfo
      } : null,
      createdAt: ride.createdAt,
      startedAt: ride.startedAt,
      completedAt: ride.completedAt,
      cancelledAt: ride.cancelledAt,
      cancellationReason: ride.cancellationReason
    });
  } catch (error) {
    console.error('Erreur récupération détails course:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

/**
 * POST /api/agent/rides/:rideId/assign
 * Assigner manuellement un chauffeur à une course
 */
router.post('/rides/:rideId/assign', [
  body('driverId').isInt().withMessage('driverId doit être un entier')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { driverId } = req.body;
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    // Vérifier que la course existe
    const ride = await rideRepository.findOne({
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que le chauffeur existe et est disponible
    const driver = await userRepository.findOne({
      where: {
        id: parseInt(driverId),
        role: 'driver'
      }
    });

    if (!driver) {
      return res.status(404).json({ error: 'Chauffeur non trouvé' });
    }

    const driverInfo = driver.driverInfo || {};
    if (!driverInfo.isOnline || driverInfo.status !== 'available') {
      return res.status(400).json({ 
        error: 'Le chauffeur n\'est pas disponible' 
      });
    }

    // Assigner le chauffeur
    ride.driverId = parseInt(driverId);
    ride.status = 'accepted';
    await rideRepository.save(ride);

    // Mettre à jour le statut du chauffeur
    driverInfo.status = 'en_route_to_pickup';
    driverInfo.currentRideId = ride.id;
    driver.driverInfo = driverInfo;
    await userRepository.save(driver);

    // Notifier le client et le chauffeur
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course assignée',
        body: `${driver.name} a été assigné à votre course`,
        data: {
          rideId: ride.id.toString(),
          type: 'ride_assigned',
          driverId: driver.id.toString()
        }
      });
    }

    if (driver.fcmToken) {
      await sendNotification(driver.fcmToken, {
        title: 'Nouvelle course assignée',
        body: `Une course vous a été assignée manuellement`,
        data: {
          rideId: ride.id.toString(),
          type: 'ride_assigned_manual',
          clientId: ride.clientId.toString()
        }
      });
    }

    // Émettre un événement Socket.io
    const io = getIo();
    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: 'accepted',
      driverId: driver.id
    });

    res.json({
      success: true,
      message: 'Chauffeur assigné avec succès',
      ride: {
        id: ride.id,
        status: ride.status,
        driverId: ride.driverId
      }
    });
  } catch (error) {
    console.error('Erreur assignation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'assignation' });
  }
});

/**
 * POST /api/agent/rides/:rideId/cancel
 * Annuler une course (par un agent)
 */
router.post('/rides/:rideId/cancel', [
  body('reason').isString().withMessage('Une raison est requise')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { reason } = req.body;
    const rideRepository = AppDataSource.getRepository(Ride);
    const userRepository = AppDataSource.getRepository(User);

    const ride = await rideRepository.findOne({
      where: { id: parseInt(req.params.rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (['completed', 'cancelled'].includes(ride.status)) {
      return res.status(400).json({ 
        error: 'Impossible d\'annuler une course déjà terminée ou annulée' 
      });
    }

    // Annuler la course
    ride.status = 'cancelled';
    ride.cancelledAt = new Date();
    ride.cancellationReason = `Annulée par un agent: ${reason}`;
    await rideRepository.save(ride);

    // Remettre le chauffeur à disponible si assigné
    if (ride.driverId) {
      const driver = await userRepository.findOne({
        where: { id: ride.driverId }
      });

      if (driver) {
        const driverInfo = driver.driverInfo || {};
        driverInfo.status = 'available';
        driverInfo.currentRideId = null;
        driver.driverInfo = driverInfo;
        await userRepository.save(driver);

        // Notifier le chauffeur
        if (driver.fcmToken) {
          await sendNotification(driver.fcmToken, {
            title: 'Course annulée',
            body: 'La course a été annulée par un agent',
            data: {
              rideId: ride.id.toString(),
              type: 'ride_cancelled_by_agent'
            }
          });
        }
      }
    }

    // Notifier le client
    if (ride.client?.fcmToken) {
      await sendNotification(ride.client.fcmToken, {
        title: 'Course annulée',
        body: `Votre course a été annulée: ${reason}`,
        data: {
          rideId: ride.id.toString(),
          type: 'ride_cancelled_by_agent',
          reason
        }
      });
    }

    // Émettre un événement Socket.io
    const io = getIo();
    io.to(`ride:${ride.id}`).emit('ride:status:changed', {
      rideId: ride.id,
      status: 'cancelled',
      reason
    });

    res.json({
      success: true,
      message: 'Course annulée avec succès',
      ride: {
        id: ride.id,
        status: ride.status,
        cancelledAt: ride.cancelledAt,
        cancellationReason: ride.cancellationReason
      }
    });
  } catch (error) {
    console.error('Erreur annulation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'annulation' });
  }
});

// ==================== GESTION DES ALERTES SOS ====================

/**
 * GET /api/agent/sos
 * Obtenir la liste des alertes SOS
 */
router.get('/sos', async (req, res) => {
  try {
    const { status, page = 1, limit = 50 } = req.query;
    const sosRepository = AppDataSource.getRepository(SOSReport);

    let query = sosRepository
      .createQueryBuilder('sos')
      .leftJoinAndSelect('sos.user', 'user')
      .leftJoinAndSelect('sos.ride', 'ride')
      .orderBy('sos.createdAt', 'DESC');

    if (status) {
      query = query.where('sos.status = :status', { status });
    }

    const [sosReports, total] = await query
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit))
      .getManyAndCount();

    res.json({
      sosReports,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération alertes SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

/**
 * POST /api/agent/sos/:sosId/resolve
 * Résoudre une alerte SOS
 */
router.post('/sos/:sosId/resolve', [
  body('resolution').optional().isString()
], async (req, res) => {
  try {
    const { resolution } = req.body;
    const sosRepository = AppDataSource.getRepository(SOSReport);

    const sosReport = await sosRepository.findOne({
      where: { id: parseInt(req.params.sosId) },
      relations: ['user', 'ride']
    });

    if (!sosReport) {
      return res.status(404).json({ error: 'Alerte SOS non trouvée' });
    }

    sosReport.status = 'resolved';
    sosReport.resolvedAt = new Date();
    sosReport.resolvedById = req.user.id;
    // Note: Le champ 'resolution' n'existe pas dans l'entité SOSReport
    // Si nécessaire, on peut ajouter la résolution dans le message
    if (resolution) {
      sosReport.message = sosReport.message ? `${sosReport.message} - Résolution: ${resolution}` : `Résolu: ${resolution}`;
    }

    await sosRepository.save(sosReport);

    // Notifier l'utilisateur
    if (sosReport.user?.fcmToken) {
      await sendNotification(sosReport.user.fcmToken, {
        title: 'Alerte SOS résolue',
        body: resolution || 'Votre alerte SOS a été résolue',
        data: {
          sosId: sosReport.id.toString(),
          type: 'sos_resolved'
        }
      });
    }

    res.json({
      success: true,
      message: 'Alerte SOS résolue avec succès',
      sosReport
    });
  } catch (error) {
    console.error('Erreur résolution alerte SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la résolution' });
  }
});

// ==================== GESTION DES CLIENTS ====================

/**
 * GET /api/agent/clients
 * Obtenir la liste des clients
 */
router.get('/clients', async (req, res) => {
  try {
    const { page = 1, limit = 50, search } = req.query;
    const userRepository = AppDataSource.getRepository(User);

    let query = userRepository
      .createQueryBuilder('user')
      .where('user.role = :role', { role: 'client' });

    if (search) {
      query = query.andWhere(
        '(user.name ILIKE :search OR user.phone_number ILIKE :search)',
        { search: `%${search}%` }
      );
    }

    const [clients, total] = await query
      .orderBy('user.createdAt', 'DESC')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit))
      .getManyAndCount();

    const formattedClients = clients.map(client => ({
      id: client.id,
      name: client.name,
      phoneNumber: client.phoneNumber,
      isVerified: client.isVerified,
      createdAt: client.createdAt
    }));

    res.json({
      clients: formattedClients,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération clients:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des clients' });
  }
});

/**
 * GET /api/agent/clients/:clientId
 * Obtenir les détails d'un client
 */
router.get('/clients/:clientId', async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);

    const client = await userRepository.findOne({
      where: {
        id: parseInt(req.params.clientId),
        role: 'client'
      }
    });

    if (!client) {
      return res.status(404).json({ error: 'Client non trouvé' });
    }

    // Statistiques du client
    const totalRides = await rideRepository.count({
      where: { clientId: client.id }
    });

    const completedRides = await rideRepository.count({
      where: { clientId: client.id, status: 'completed' }
    });

    const spendingResult = await rideRepository
      .createQueryBuilder('ride')
      .select('SUM(ride.finalPrice)', 'total')
      .where('ride.clientId = :clientId', { clientId: client.id })
      .andWhere('ride.status = :status', { status: 'completed' })
      .getRawOne();

    // Dernières courses
    const recentRides = await rideRepository.find({
      where: { clientId: client.id },
      relations: ['driver'],
      order: { createdAt: 'DESC' },
      take: 10
    });

    res.json({
      id: client.id,
      name: client.name,
      phoneNumber: client.phoneNumber,
      isVerified: client.isVerified,
      stats: {
        totalRides,
        completedRides,
        totalSpending: spendingResult ? parseFloat(spendingResult.total) : 0
      },
      recentRides: recentRides.map(ride => ({
        id: ride.id,
        status: ride.status,
        pickupAddress: ride.pickupAddress,
        dropoffAddress: ride.dropoffAddress,
        estimatedPrice: ride.estimatedPrice,
        finalPrice: ride.finalPrice,
        createdAt: ride.createdAt,
        driver: ride.driver ? {
          id: ride.driver.id,
          name: ride.driver.name
        } : null
      })),
      createdAt: client.createdAt
    });
  } catch (error) {
    console.error('Erreur récupération détails client:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

module.exports = router;

