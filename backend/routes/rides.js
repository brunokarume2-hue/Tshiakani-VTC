const express = require('express');
const { body, validationResult } = require('express-validator');
const Ride = require('../models/Ride');
const User = require('../models/User');
const { auth } = require('../middlewares/auth');
const { io } = require('../server');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Créer une demande de course - alias pour compatibilité
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

    const ride = new Ride({
      clientId: req.user._id,
      pickupLocation,
      dropoffLocation,
      estimatedPrice,
      distance,
      status: 'pending'
    });

    await ride.save();

    // Notifier les conducteurs proches via Socket.io
    io.emit('ride:new', {
      rideId: ride._id,
      pickupLocation,
      estimatedPrice,
      distance
    });

    // Trouver les conducteurs proches et leur envoyer une notification
    const nearbyDrivers = await User.find({
      role: 'driver',
      'driverInfo.isOnline': true,
      'driverInfo.currentLocation': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [pickupLocation.longitude, pickupLocation.latitude]
          },
          $maxDistance: 5000 // 5 km
        }
      }
    });

    // Envoyer des notifications push aux conducteurs
    for (const driver of nearbyDrivers) {
      if (driver.fcmToken) {
        await sendNotification(driver.fcmToken, {
          title: 'Nouvelle demande de course',
          body: `Course disponible à ${pickupLocation.address || 'proximité'}`,
          data: { rideId: ride._id.toString(), type: 'new_ride_request' }
        });
      }
    }

    res.status(201).json(ride);
  } catch (error) {
    console.error('Erreur création course:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la course' });
  }
});

// Créer une demande de course
router.post('/', auth, [
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

    const ride = new Ride({
      clientId: req.user._id,
      pickupLocation,
      dropoffLocation,
      estimatedPrice,
      distance,
      status: 'pending'
    });

    await ride.save();

    // Notifier les conducteurs proches via Socket.io
    io.emit('ride:new', {
      rideId: ride._id,
      pickupLocation,
      estimatedPrice,
      distance
    });

    // Trouver les conducteurs proches et leur envoyer une notification
    const nearbyDrivers = await User.find({
      role: 'driver',
      'driverInfo.isOnline': true,
      'driverInfo.currentLocation': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [pickupLocation.longitude, pickupLocation.latitude]
          },
          $maxDistance: 5000 // 5 km
        }
      }
    });

    // Envoyer des notifications push aux conducteurs
    for (const driver of nearbyDrivers) {
      if (driver.fcmToken) {
        await sendNotification(driver.fcmToken, {
          title: 'Nouvelle demande de course',
          body: `Course disponible à ${pickupLocation.address || 'proximité'}`,
          data: { rideId: ride._id.toString(), type: 'new_ride_request' }
        });
      }
    }

    res.status(201).json(ride);
  } catch (error) {
    console.error('Erreur création course:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la course' });
  }
});

// Accepter une course (conducteur) - alias pour compatibilité
router.put('/accept/:courseId', auth, async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent accepter une course' });
    }

    const ride = await Ride.findById(req.params.courseId);

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ error: 'Cette course n\'est plus disponible' });
    }

    ride.driverId = req.user._id;
    ride.status = 'accepted';
    await ride.save();

    // Notifier le client
    const client = await User.findById(ride.clientId);
    if (client?.fcmToken) {
      await sendNotification(client.fcmToken, {
        title: 'Course acceptée !',
        body: `${req.user.name} a accepté votre course`,
        data: { rideId: ride._id.toString(), type: 'ride_accepted' }
      });
    }

    // Émettre via Socket.io
    io.to(`ride:${ride._id}`).emit('ride:status:changed', {
      rideId: ride._id,
      status: 'accepted',
      driverId: req.user._id
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'acceptation' });
  }
});

// Accepter une course (conducteur)
router.post('/:rideId/accept', auth, async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent accepter une course' });
    }

    const ride = await Ride.findById(req.params.rideId);

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.status !== 'pending') {
      return res.status(400).json({ error: 'Cette course n\'est plus disponible' });
    }

    ride.driverId = req.user._id;
    ride.status = 'accepted';
    await ride.save();

    // Notifier le client
    const client = await User.findById(ride.clientId);
    if (client?.fcmToken) {
      await sendNotification(client.fcmToken, {
        title: 'Course acceptée !',
        body: `${req.user.name} a accepté votre course`,
        data: { rideId: ride._id.toString(), type: 'ride_accepted' }
      });
    }

    // Émettre via Socket.io
    io.to(`ride:${ride._id}`).emit('ride:status:changed', {
      rideId: ride._id,
      status: 'accepted',
      driverId: req.user._id
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur acceptation course:', error);
    res.status(500).json({ error: 'Erreur lors de l\'acceptation' });
  }
});

// Terminer une course
router.put('/complete/:courseId', auth, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.courseId);

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier les permissions
    const isDriver = req.user._id.toString() === ride.driverId?.toString();
    const isClient = req.user._id.toString() === ride.clientId.toString();

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    ride.status = 'completed';
    ride.completedAt = new Date();
    ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
    await ride.save();

    // Notifier le client
    const client = await User.findById(ride.clientId);
    if (client?.fcmToken) {
      await sendNotification(client.fcmToken, {
        title: 'Course terminée',
        body: 'Votre course a été complétée. Merci d\'avoir utilisé Wewa Taxi !',
        data: { rideId: ride._id.toString(), type: 'ride_completed' }
      });
    }

    // Émettre via Socket.io
    io.to(`ride:${ride._id}`).emit('ride:status:changed', {
      rideId: ride._id,
      status: 'completed',
      timestamp: new Date()
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur complétion course:', error);
    res.status(500).json({ error: 'Erreur lors de la complétion' });
  }
});

// Mettre à jour le statut d'une course
router.patch('/:rideId/status', auth, [
  body('status').isIn(['driverArriving', 'inProgress', 'completed', 'cancelled'])
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status } = req.body;
    const ride = await Ride.findById(req.params.rideId);

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier les permissions
    const isDriver = req.user._id.toString() === ride.driverId?.toString();
    const isClient = req.user._id.toString() === ride.clientId.toString();

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    ride.status = status;

    if (status === 'inProgress') {
      ride.startedAt = new Date();
    } else if (status === 'completed') {
      ride.completedAt = new Date();
      ride.finalPrice = ride.finalPrice || ride.estimatedPrice;
    } else if (status === 'cancelled') {
      ride.cancelledAt = new Date();
    }

    await ride.save();

    // Notifier l'autre partie
    const otherUser = isDriver 
      ? await User.findById(ride.clientId)
      : await User.findById(ride.driverId);

    if (otherUser?.fcmToken) {
      const statusMessages = {
        driverArriving: 'Votre conducteur arrive',
        inProgress: 'Trajet commencé',
        completed: 'Trajet terminé',
        cancelled: 'Course annulée'
      };

      await sendNotification(otherUser.fcmToken, {
        title: statusMessages[status] || 'Mise à jour de course',
        body: `Le statut de votre course a été mis à jour`,
        data: { rideId: ride._id.toString(), type: 'ride_status_update' }
      });
    }

    // Émettre via Socket.io
    io.to(`ride:${ride._id}`).emit('ride:status:changed', {
      rideId: ride._id,
      status,
      timestamp: new Date()
    });

    res.json(ride);
  } catch (error) {
    console.error('Erreur mise à jour statut:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Obtenir l'historique des courses pour un utilisateur
router.get('/history/:userId', auth, async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Vérifier que l'utilisateur demande son propre historique ou est admin
    if (req.user._id.toString() !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const query = {};
    
    if (req.user.role === 'client') {
      query.clientId = userId;
    } else if (req.user.role === 'driver') {
      query.driverId = userId;
    } else {
      // Admin peut voir toutes les courses
      query.clientId = userId;
    }

    const rides = await Ride.find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('clientId', 'name phoneNumber')
      .populate('driverId', 'name phoneNumber driverInfo.rating');

    res.json(rides);
  } catch (error) {
    console.error('Erreur historique:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'historique' });
  }
});

// Obtenir l'historique des courses (route alternative)
router.get('/history', auth, async (req, res) => {
  try {
    const query = {};
    
    if (req.user.role === 'client') {
      query.clientId = req.user._id;
    } else if (req.user.role === 'driver') {
      query.driverId = req.user._id;
    }

    const rides = await Ride.find(query)
      .sort({ createdAt: -1 })
      .limit(50)
      .populate('clientId', 'name phoneNumber')
      .populate('driverId', 'name phoneNumber driverInfo.rating');

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

    const ride = await Ride.findById(req.params.rideId);

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    if (ride.clientId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ error: 'Seul le client peut noter cette course' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ error: 'Seules les courses terminées peuvent être notées' });
    }

    ride.rating = req.body.rating;
    ride.comment = req.body.comment;
    await ride.save();

    // Mettre à jour la note moyenne du conducteur
    if (ride.driverId) {
      const driverRides = await Ride.find({
        driverId: ride.driverId,
        rating: { $exists: true }
      });

      const avgRating = driverRides.reduce((sum, r) => sum + r.rating, 0) / driverRides.length;
      
      await User.findByIdAndUpdate(ride.driverId, {
        'driverInfo.rating': Math.round(avgRating * 10) / 10
      });
    }

    res.json(ride);
  } catch (error) {
    console.error('Erreur notation:', error);
    res.status(500).json({ error: 'Erreur lors de la notation' });
  }
});

// Obtenir une course spécifique
router.get('/:rideId', auth, async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.rideId)
      .populate('clientId', 'name phoneNumber')
      .populate('driverId', 'name phoneNumber driverInfo');

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier les permissions
    const isDriver = req.user._id.toString() === ride.driverId?.toString();
    const isClient = req.user._id.toString() === ride.clientId.toString();

    if (!isDriver && !isClient && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    res.json(ride);
  } catch (error) {
    console.error('Erreur récupération course:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

module.exports = router;

