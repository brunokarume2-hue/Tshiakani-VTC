// Routes Share avec PostgreSQL
const express = require('express');
const { body, validationResult, param } = require('express-validator');
const AppDataSource = require('../config/database');
const SharedRide = require('../entities/SharedRide');
const Ride = require('../entities/Ride');
const { auth } = require('../middlewares.postgres/auth');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Note: La route GET /api/rides/:rideId/share pour générer un lien de partage
// est déjà définie dans routes.postgres/rides.js
// Cette route gère uniquement le partage avec des contacts et la récupération des courses partagées

// Partager une course avec des contacts
router.post('/ride', auth, [
  body('rideId').notEmpty().trim(),
  body('contacts').isArray().notEmpty(),
  body('link').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { rideId, contacts, link } = req.body;
    const sharedRideRepository = AppDataSource.getRepository(SharedRide);
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

    // Générer un lien de partage si non fourni
    const shareLink = link || `https://tshiakanivtc.com/share/${uuidv4()}`;

    // Créer un enregistrement de partage
    const sharedRide = sharedRideRepository.create({
      rideId: parseInt(rideId),
      userId: req.user.id,
      shareLink: shareLink,
      sharedWith: contacts,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // Expire dans 7 jours
    });

    await sharedRideRepository.save(sharedRide);

    res.status(201).json({
      success: true,
      sharedRide: {
        id: sharedRide.id.toString(),
        rideId: sharedRide.rideId.toString(),
        shareLink: sharedRide.shareLink,
        sharedWith: sharedRide.sharedWith,
        expiresAt: sharedRide.expiresAt?.toISOString(),
        createdAt: sharedRide.createdAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Erreur partage course:', error);
    res.status(500).json({ error: 'Erreur lors du partage de la course' });
  }
});

// Partager une position en temps réel
router.post('/location', auth, [
  body('rideId').notEmpty().trim(),
  body('location.latitude').isFloat(),
  body('location.longitude').isFloat()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { rideId, location } = req.body;
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

    // La position est partagée via Socket.io en temps réel
    // Cette route peut être utilisée pour enregistrer l'historique de partage
    
    res.json({
      success: true,
      message: 'Position partagée avec succès',
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      }
    });
  } catch (error) {
    console.error('Erreur partage position:', error);
    res.status(500).json({ error: 'Erreur lors du partage de la position' });
  }
});

// Récupérer les courses partagées
router.get('/rides', auth, async (req, res) => {
  try {
    const sharedRideRepository = AppDataSource.getRepository(SharedRide);
    
    const sharedRides = await sharedRideRepository.find({
      where: { userId: req.user.id },
      relations: ['ride'],
      order: { createdAt: 'DESC' }
    });

    // Filtrer les partages expirés
    const activeSharedRides = sharedRides.filter(sharedRide => {
      if (!sharedRide.expiresAt) return true;
      return new Date(sharedRide.expiresAt) > new Date();
    });

    const formattedSharedRides = activeSharedRides.map(sharedRide => ({
      id: sharedRide.id.toString(),
      rideId: sharedRide.rideId.toString(),
      shareLink: sharedRide.shareLink,
      sharedWith: sharedRide.sharedWith || [],
      createdAt: sharedRide.createdAt.toISOString(),
      expiresAt: sharedRide.expiresAt?.toISOString()
    }));

    res.json({
      success: true,
      sharedRides: formattedSharedRides
    });
  } catch (error) {
    console.error('Erreur récupération courses partagées:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des courses partagées' });
  }
});

module.exports = router;

