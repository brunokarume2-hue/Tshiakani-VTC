//
//  rides.secure.js
//  Tshiakani VTC
//
//  Routes de courses sécurisées avec transactions ACID, géofencing et tokens
//  Remplace rides.js avec les contraintes d'architecture
//

const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { verifyDriverProximityWithST_DWithin } = require('../middlewares.postgres/geofencing');
const TransactionService = require('../services/TransactionService');
const PaymentService = require('../services/PaymentService');
const { io } = require('../server.postgres');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Créer une demande de course
router.post('/create', auth, [
  body('pickupLocation.latitude').isFloat(),
  body('pickupLocation.longitude').isFloat(),
  body('dropoffLocation.latitude').isFloat(),
  body('dropoffLocation.longitude').isFloat(),
  body('estimatedPrice').isFloat().withMessage('Prix estimé requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'client') {
      return res.status(403).json({ error: 'Seuls les clients peuvent créer une course' });
    }

    const { pickupLocation, dropoffLocation, estimatedPrice, distance } = req.body;
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

    const ride = rideRepository.create({
      clientId: req.user.id,
      pickupLocation: pickupPoint,
      dropoffLocation: dropoffPoint,
      pickupAddress: pickupLocation.address,
      dropoffAddress: dropoffLocation.address,
      estimatedPrice,
      distance,
      status: 'pending'
    });

    await rideRepository.save(ride);
    
    // Calculer la distance avec PostGIS
    const calculatedDistance = await Ride.calculateDistance(ride.id, AppDataSource);
    if (calculatedDistance) {
      ride.distance = calculatedDistance;
      await rideRepository.save(ride);
    }

    // Notifier les conducteurs proches via Socket.io
    io.emit('ride:new', {
      rideId: ride.id,
      pickupLocation,
      estimatedPrice,
      distance
    });

    // Trouver les conducteurs proches avec PostGIS
    const nearbyDrivers = await User.findNearbyDrivers(
      pickupLocation.latitude,
      pickupLocation.longitude,
      5, // 5 km
      AppDataSource
    );

    // Envoyer des notifications push
    for (const driver of nearbyDrivers) {
      if (driver.fcmToken) {
        await sendNotification(driver.fcmToken, {
          title: 'Nouvelle demande de course',
          body: `Course disponible à ${pickupLocation.address || 'proximité'}`,
          data: { rideId: ride.id.toString(), type: 'new_ride_request' }
        });
      }
    }

    res.status(201).json(ride);
  } catch (error) {
    console.error('Erreur création course:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la course' });
  }
});

// Accepter une course avec transaction ACID et géofencing
router.put('/accept/:courseId', auth, [
  body('driverLocation.latitude').isFloat().withMessage('Latitude du chauffeur requise'),
  body('driverLocation.longitude').isFloat().withMessage('Longitude du chauffeur requise')
], verifyDriverProximityWithST_DWithin(2000), async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent accepter une course' });
    }

    const rideId = parseInt(req.params.courseId);
    const driverLocation = req.body.driverLocation;

    // Récupérer le point de départ pour la transaction
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ where: { id: rideId } });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const pickupLocation = {
      latitude: ride.pickupLocation.coordinates[1],
      longitude: ride.pickupLocation.coordinates[0]
    };

    // Utiliser le service de transaction ACID
    const updatedRide = await TransactionService.acceptRideWithTransaction(
      rideId,
      req.user.id,
      driverLocation,
      pickupLocation,
      2000 // Distance maximale: 2000m
    );

    // Notifier le client
    const client = await AppDataSource.getRepository(User).findOne({ 
      where: { id: updatedRide.clientId } 
    });
    
    if (client?.fcmToken) {
      await sendNotification(client.fcmToken, {
        title: 'Course acceptée !',
        body: `${req.user.name} a accepté votre course`,
        data: { rideId: updatedRide.id.toString(), type: 'ride_accepted' }
      });
    }

    io.to(`ride:${updatedRide.id}`).emit('ride:status:changed', {
      rideId: updatedRide.id,
      status: 'accepted',
      driverId: req.user.id
    });

    res.json({
      ...updatedRide,
      message: 'Course acceptée avec succès',
      proximity: req.driverProximity
    });
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur lors de l\'acceptation de la course'
    });
  }
});

// Terminer une course avec transaction ACID et création de transaction de paiement
router.put('/complete/:courseId', auth, [
  body('finalPrice').isFloat().withMessage('Prix final requis'),
  body('paymentToken').notEmpty().withMessage('Token de paiement requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const rideId = parseInt(req.params.courseId);
    const { finalPrice, paymentToken } = req.body;

    // Vérifier les permissions
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ 
      where: { id: rideId },
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

    // Utiliser le service de transaction ACID pour terminer la course
    // Cela met à jour le statut de la course, le statut du chauffeur ET crée la transaction
    const result = await TransactionService.completeRideWithTransaction(
      rideId,
      finalPrice,
      paymentToken
    );

    // Notifier le client
    if (result.ride.client?.fcmToken) {
      await sendNotification(result.ride.client.fcmToken, {
        title: 'Course terminée',
        body: 'Votre course a été complétée. Merci d\'avoir utilisé Wewa Taxi !',
        data: { 
          rideId: result.ride.id.toString(), 
          type: 'ride_completed',
          transactionId: result.transaction.id
        }
      });
    }

    io.to(`ride:${result.ride.id}`).emit('ride:status:changed', {
      rideId: result.ride.id,
      status: 'completed',
      timestamp: new Date()
    });

    res.json({
      ride: result.ride,
      transaction: result.transaction,
      message: 'Course terminée et paiement traité avec succès'
    });
  } catch (error) {
    console.error('Erreur complétion course:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur lors de la complétion de la course'
    });
  }
});

// Annuler une course avec transaction ACID
router.put('/cancel/:courseId', auth, [
  body('reason').optional().trim()
], async (req, res) => {
  try {
    const rideId = parseInt(req.params.courseId);
    const reason = req.body.reason || 'Annulée par l\'utilisateur';

    // Vérifier les permissions
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ where: { id: rideId } });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    const isDriver = req.user.id === ride.driverId;
    const isClient = req.user.id === ride.clientId;

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Utiliser le service de transaction ACID pour annuler la course
    const cancelledRide = await TransactionService.cancelRideWithTransaction(
      rideId,
      reason
    );

    // Notifier l'autre partie
    const otherUserId = isDriver ? ride.clientId : ride.driverId;
    if (otherUserId) {
      const otherUser = await AppDataSource.getRepository(User).findOne({ 
        where: { id: otherUserId } 
      });
      
      if (otherUser?.fcmToken) {
        await sendNotification(otherUser.fcmToken, {
          title: 'Course annulée',
          body: `La course a été annulée: ${reason}`,
          data: { rideId: cancelledRide.id.toString(), type: 'ride_cancelled' }
        });
      }
    }

    io.to(`ride:${cancelledRide.id}`).emit('ride:status:changed', {
      rideId: cancelledRide.id,
      status: 'cancelled',
      timestamp: new Date()
    });

    res.json({
      ...cancelledRide,
      message: 'Course annulée avec succès'
    });
  } catch (error) {
    console.error('Erreur annulation course:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur lors de l\'annulation de la course'
    });
  }
});

// Traiter un paiement séparément (si nécessaire)
router.post('/:courseId/payment', auth, [
  body('amount').isFloat().withMessage('Montant requis'),
  body('paymentToken').notEmpty().withMessage('Token de paiement requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const rideId = parseInt(req.params.courseId);
    const { amount, paymentToken } = req.body;

    // Vérifier que l'utilisateur est le client de la course
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({ where: { id: rideId } });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Utiliser le service de paiement sécurisé
    const transaction = await PaymentService.processPayment(
      rideId,
      amount,
      paymentToken
    );

    res.json({
      transaction,
      message: 'Paiement traité avec succès'
    });
  } catch (error) {
    console.error('Erreur traitement paiement:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur lors du traitement du paiement'
    });
  }
});

// Rembourser un paiement
router.post('/transactions/:transactionId/refund', auth, [
  body('reason').optional().trim()
], async (req, res) => {
  try {
    const transactionId = parseInt(req.params.transactionId);
    const reason = req.body.reason || 'Remboursement demandé';

    // Vérifier que l'utilisateur est admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Seuls les administrateurs peuvent rembourser' });
    }

    // Utiliser le service de paiement pour le remboursement
    const refundedTransaction = await PaymentService.refundPayment(
      transactionId,
      reason
    );

    res.json({
      transaction: refundedTransaction,
      message: 'Remboursement effectué avec succès'
    });
  } catch (error) {
    console.error('Erreur remboursement:', error);
    res.status(500).json({ 
      error: error.message || 'Erreur lors du remboursement'
    });
  }
});

// Routes existantes (historique, notation, etc.) - à garder telles quelles
// ... (copier depuis rides.js si nécessaire)

module.exports = router;

