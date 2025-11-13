const express = require('express');
const { body, validationResult } = require('express-validator');
const { auth } = require('../middlewares/auth');
const { sendNotification } = require('../utils/notifications');
const User = require('../models/User');
const Ride = require('../models/Ride');

const router = express.Router();

// Modèle SOS (à créer si nécessaire)
const SOSReport = require('../models/SOSReport');

// Signaler une urgence SOS
router.post('/', auth, [
  body('latitude').isFloat(),
  body('longitude').isFloat(),
  body('rideId').optional().isString(),
  body('message').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { latitude, longitude, rideId, message } = req.body;

    // Créer un rapport SOS
    const sosReport = new SOSReport({
      userId: req.user._id,
      location: {
        latitude,
        longitude,
        timestamp: new Date()
      },
      rideId: rideId || null,
      message: message || 'Signalement d\'urgence',
      status: 'active',
      createdAt: new Date()
    });

    await sosReport.save();

    // Notifier les admins
    const admins = await User.find({ role: 'admin' });
    for (const admin of admins) {
      if (admin.fcmToken) {
        await sendNotification(admin.fcmToken, {
          title: '🚨 ALERTE SOS',
          body: `${req.user.name} a signalé une urgence`,
          data: {
            type: 'sos',
            sosId: sosReport._id.toString(),
            userId: req.user._id.toString()
          }
        });
      }
    }

    // Si une course est en cours, notifier le conducteur
    if (rideId) {
      const ride = await Ride.findById(rideId).populate('driverId');
      if (ride?.driverId?.fcmToken) {
        await sendNotification(ride.driverId.fcmToken, {
          title: 'Alerte sécurité',
          body: 'Le client a signalé une urgence',
          data: { type: 'sos_alert', rideId }
        });
      }
    }

    res.status(201).json({
      success: true,
      sosId: sosReport._id,
      message: 'Signalement d\'urgence envoyé'
    });
  } catch (error) {
    console.error('Erreur signalement SOS:', error);
    res.status(500).json({ error: 'Erreur lors du signalement' });
  }
});

// Obtenir les alertes SOS (admin)
router.get('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const { status, limit = 50 } = req.query;
    const query = status ? { status } : {};

    const sosReports = await SOSReport.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .populate('userId', 'name phoneNumber')
      .populate('rideId');

    res.json(sosReports);
  } catch (error) {
    console.error('Erreur récupération SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Marquer un SOS comme résolu (admin)
router.patch('/:sosId/resolve', auth, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const sosReport = await SOSReport.findById(req.params.sosId);
    if (!sosReport) {
      return res.status(404).json({ error: 'Signalement non trouvé' });
    }

    sosReport.status = 'resolved';
    sosReport.resolvedAt = new Date();
    sosReport.resolvedBy = req.user._id;
    await sosReport.save();

    res.json({ success: true, sosReport });
  } catch (error) {
    console.error('Erreur résolution SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la résolution' });
  }
});

module.exports = router;

