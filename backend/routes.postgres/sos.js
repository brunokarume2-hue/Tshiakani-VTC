// Routes SOS avec PostgreSQL + PostGIS
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const SOSReport = require('../entities/SOSReport');
const User = require('../entities/User');
const Ride = require('../entities/Ride');
const { auth, adminAuth } = require('../middlewares.postgres/auth');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Signaler une urgence SOS
router.post('/', auth, [
  body('latitude').isFloat(),
  body('longitude').isFloat(),
  body('rideId').optional().isInt(),
  body('message').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { latitude, longitude, rideId, message } = req.body;
    const sosRepository = AppDataSource.getRepository(SOSReport);

    // Créer le point PostGIS
    const locationPoint = {
      type: 'Point',
      coordinates: [longitude, latitude]
    };

    const sosReport = sosRepository.create({
      userId: req.user.id,
      location: locationPoint,
      rideId: rideId ? parseInt(rideId) : null,
      message: message || "Signalement d'urgence",
      status: 'active'
    });

    await sosRepository.save(sosReport);

    // Notifier les admins
    const userRepository = AppDataSource.getRepository(User);
    const admins = await userRepository.find({ where: { role: 'admin' } });
    
    for (const admin of admins) {
      if (admin.fcmToken) {
        await sendNotification(admin.fcmToken, {
          title: '🚨 ALERTE SOS',
          body: `${req.user.name} a signalé une urgence`,
          data: {
            type: 'sos',
            sosId: sosReport.id.toString(),
            userId: req.user.id.toString()
          }
        });
      }
    }

    // Si une course est en cours, notifier le conducteur
    if (rideId) {
      const rideRepository = AppDataSource.getRepository(Ride);
      const ride = await rideRepository.findOne({
        where: { id: parseInt(rideId) },
        relations: ['driver']
      });
      
      if (ride?.driver?.fcmToken) {
        await sendNotification(ride.driver.fcmToken, {
          title: 'Alerte sécurité',
          body: 'Le client a signalé une urgence',
          data: { type: 'sos_alert', rideId: rideId.toString() }
        });
      }
    }

    res.status(201).json({
      success: true,
      sosId: sosReport.id,
      message: 'Signalement d\'urgence envoyé'
    });
  } catch (error) {
    console.error('Erreur signalement SOS:', error);
    res.status(500).json({ error: 'Erreur lors du signalement' });
  }
});

// Obtenir les alertes SOS (admin)
router.get('/', adminAuth, async (req, res) => {
  try {
    const { status, limit = 50 } = req.query;
    const sosRepository = AppDataSource.getRepository(SOSReport);
    
    const query = sosRepository.createQueryBuilder('sos')
      .leftJoinAndSelect('sos.user', 'user')
      .leftJoinAndSelect('sos.ride', 'ride')
      .orderBy('sos.createdAt', 'DESC')
      .limit(parseInt(limit));

    if (status) {
      query.where('sos.status = :status', { status });
    }

    const sosReports = await query.getMany();
    res.json(sosReports);
  } catch (error) {
    console.error('Erreur récupération SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Désactiver une alerte SOS
router.post('/:userId/deactivate', auth, async (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    
    // Vérifier que l'utilisateur désactive sa propre alerte ou qu'il est admin
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const sosRepository = AppDataSource.getRepository(SOSReport);
    
    // Trouver les alertes SOS actives pour cet utilisateur
    const activeSOS = await sosRepository.find({
      where: { 
        userId: userId,
        status: 'active'
      }
    });

    if (activeSOS.length === 0) {
      return res.status(404).json({ error: 'Aucune alerte SOS active trouvée' });
    }

    // Désactiver toutes les alertes actives
    for (const sos of activeSOS) {
      sos.status = 'resolved';
      sos.resolvedAt = new Date();
      sos.resolvedById = req.user.role === 'admin' ? req.user.id : null;
      await sosRepository.save(sos);
    }

    res.json({ 
      success: true, 
      message: 'Alerte SOS désactivée avec succès',
      deactivatedCount: activeSOS.length
    });
  } catch (error) {
    console.error('Erreur désactivation SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la désactivation' });
  }
});

// Marquer un SOS comme résolu (admin)
// adminAuth désactivé temporairement
router.patch('/:sosId/resolve', async (req, res) => {
  try {
    const sosRepository = AppDataSource.getRepository(SOSReport);
    const sosReport = await sosRepository.findOne({ 
      where: { id: parseInt(req.params.sosId) } 
    });

    if (!sosReport) {
      return res.status(404).json({ error: 'Signalement non trouvé' });
    }

    sosReport.status = 'resolved';
    sosReport.resolvedAt = new Date();
    sosReport.resolvedById = 1; // Admin ID par défaut
    await sosRepository.save(sosReport);

    res.json({ success: true, sosReport });
  } catch (error) {
    console.error('Erreur résolution SOS:', error);
    res.status(500).json({ error: 'Erreur lors de la résolution' });
  }
});

module.exports = router;

