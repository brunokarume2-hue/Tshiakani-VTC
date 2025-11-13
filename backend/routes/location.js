const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middlewares/auth');
const { io } = require('../server');

const router = express.Router();

// Mettre à jour la position (conducteur)
router.post('/update', auth, [
  body('latitude').isFloat(),
  body('longitude').isFloat(),
  body('address').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent mettre à jour leur position' });
    }

    const { latitude, longitude, address } = req.body;

    req.user.driverInfo.currentLocation = {
      latitude,
      longitude,
      address,
      timestamp: new Date()
    };

    await req.user.save();

    // Diffuser la position via Socket.io
    io.emit('driver:location:update', {
      driverId: req.user._id,
      location: {
        latitude,
        longitude,
        address
      },
      timestamp: new Date()
    });

    res.json({ success: true, location: req.user.driverInfo.currentLocation });
  } catch (error) {
    console.error('Erreur mise à jour position:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de la position' });
  }
});

// Obtenir les conducteurs proches
router.get('/drivers/nearby', auth, async (req, res) => {
  try {
    const { latitude, longitude, radius = 5000 } = req.query;

    const drivers = await User.find({
      role: 'driver',
      'driverInfo.isOnline': true,
      'driverInfo.currentLocation': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: parseInt(radius)
        }
      }
    }).select('name phoneNumber driverInfo');

    res.json(drivers);
  } catch (error) {
    console.error('Erreur recherche conducteurs:', error);
    res.status(500).json({ error: 'Erreur lors de la recherche' });
  }
});

// Activer/désactiver le statut en ligne (conducteur)
router.post('/online', auth, [
  body('isOnline').isBoolean()
], async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ error: 'Seuls les conducteurs peuvent modifier leur statut' });
    }

    req.user.driverInfo.isOnline = req.body.isOnline;
    await req.user.save();

    res.json({ 
      success: true, 
      isOnline: req.user.driverInfo.isOnline 
    });
  } catch (error) {
    console.error('Erreur changement statut:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

module.exports = router;

