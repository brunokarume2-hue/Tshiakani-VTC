// Routes pour la gestion de la configuration des prix
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const PriceConfiguration = require('../entities/PriceConfiguration');
const PricingService = require('../services/PricingService');
const { adminAuth } = require('../middlewares.postgres/auth');

const router = express.Router();

// Obtenir la configuration actuelle des prix
router.get('/', adminAuth, async (req, res) => {
  try {
    const configRepository = AppDataSource.getRepository(PriceConfiguration);
    const config = await configRepository.findOne({
      where: { isActive: true },
      order: { updatedAt: 'DESC' }
    });

    if (!config) {
      return res.status(404).json({ error: 'Aucune configuration active trouvée' });
    }

    res.json({
      id: config.id,
      basePrice: parseFloat(config.basePrice),
      pricePerKm: parseFloat(config.pricePerKm),
      rushHourMultiplier: parseFloat(config.rushHourMultiplier),
      nightMultiplier: parseFloat(config.nightMultiplier),
      weekendMultiplier: parseFloat(config.weekendMultiplier),
      surgeLowDemandMultiplier: parseFloat(config.surgeLowDemandMultiplier),
      surgeNormalMultiplier: parseFloat(config.surgeNormalMultiplier),
      surgeHighMultiplier: parseFloat(config.surgeHighMultiplier),
      surgeVeryHighMultiplier: parseFloat(config.surgeVeryHighMultiplier),
      surgeExtremeMultiplier: parseFloat(config.surgeExtremeMultiplier),
      description: config.description,
      isActive: config.isActive,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt
    });
  } catch (error) {
    console.error('Erreur récupération configuration:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Mettre à jour la configuration des prix
router.put('/', adminAuth, [
  body('basePrice').optional().isFloat({ min: 0 }),
  body('pricePerKm').optional().isFloat({ min: 0 }),
  body('rushHourMultiplier').optional().isFloat({ min: 0.5, max: 3.0 }),
  body('nightMultiplier').optional().isFloat({ min: 0.5, max: 3.0 }),
  body('weekendMultiplier').optional().isFloat({ min: 0.5, max: 3.0 }),
  body('surgeLowDemandMultiplier').optional().isFloat({ min: 0.1, max: 1.0 }),
  body('surgeNormalMultiplier').optional().isFloat({ min: 0.5, max: 2.0 }),
  body('surgeHighMultiplier').optional().isFloat({ min: 1.0, max: 3.0 }),
  body('surgeVeryHighMultiplier').optional().isFloat({ min: 1.0, max: 3.0 }),
  body('surgeExtremeMultiplier').optional().isFloat({ min: 1.0, max: 5.0 }),
  body('description').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const configRepository = AppDataSource.getRepository(PriceConfiguration);
    
    // Trouver la configuration active
    let config = await configRepository.findOne({
      where: { isActive: true },
      order: { updatedAt: 'DESC' }
    });

    // Si pas de configuration, en créer une nouvelle
    if (!config) {
      config = configRepository.create({
        basePrice: 500.0,
        pricePerKm: 200.0,
        rushHourMultiplier: 1.5,
        nightMultiplier: 1.3,
        weekendMultiplier: 1.2,
        surgeLowDemandMultiplier: 0.9,
        surgeNormalMultiplier: 1.0,
        surgeHighMultiplier: 1.2,
        surgeVeryHighMultiplier: 1.4,
        surgeExtremeMultiplier: 1.6,
        isActive: true
      });
    }

    // Mettre à jour les champs fournis
    if (req.body.basePrice !== undefined) config.basePrice = req.body.basePrice;
    if (req.body.pricePerKm !== undefined) config.pricePerKm = req.body.pricePerKm;
    if (req.body.rushHourMultiplier !== undefined) config.rushHourMultiplier = req.body.rushHourMultiplier;
    if (req.body.nightMultiplier !== undefined) config.nightMultiplier = req.body.nightMultiplier;
    if (req.body.weekendMultiplier !== undefined) config.weekendMultiplier = req.body.weekendMultiplier;
    if (req.body.surgeLowDemandMultiplier !== undefined) config.surgeLowDemandMultiplier = req.body.surgeLowDemandMultiplier;
    if (req.body.surgeNormalMultiplier !== undefined) config.surgeNormalMultiplier = req.body.surgeNormalMultiplier;
    if (req.body.surgeHighMultiplier !== undefined) config.surgeHighMultiplier = req.body.surgeHighMultiplier;
    if (req.body.surgeVeryHighMultiplier !== undefined) config.surgeVeryHighMultiplier = req.body.surgeVeryHighMultiplier;
    if (req.body.surgeExtremeMultiplier !== undefined) config.surgeExtremeMultiplier = req.body.surgeExtremeMultiplier;
    if (req.body.description !== undefined) config.description = req.body.description;

    await configRepository.save(config);

    // Invalider le cache pour forcer le rechargement
    PricingService.invalidateCache();

    res.json({
      id: config.id,
      basePrice: parseFloat(config.basePrice),
      pricePerKm: parseFloat(config.pricePerKm),
      rushHourMultiplier: parseFloat(config.rushHourMultiplier),
      nightMultiplier: parseFloat(config.nightMultiplier),
      weekendMultiplier: parseFloat(config.weekendMultiplier),
      surgeLowDemandMultiplier: parseFloat(config.surgeLowDemandMultiplier),
      surgeNormalMultiplier: parseFloat(config.surgeNormalMultiplier),
      surgeHighMultiplier: parseFloat(config.surgeHighMultiplier),
      surgeVeryHighMultiplier: parseFloat(config.surgeVeryHighMultiplier),
      surgeExtremeMultiplier: parseFloat(config.surgeExtremeMultiplier),
      description: config.description,
      isActive: config.isActive,
      updatedAt: config.updatedAt
    });
  } catch (error) {
    console.error('Erreur mise à jour configuration:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Obtenir l'historique des configurations
router.get('/history', adminAuth, async (req, res) => {
  try {
    const configRepository = AppDataSource.getRepository(PriceConfiguration);
    const configs = await configRepository.find({
      order: { updatedAt: 'DESC' },
      take: 20
    });

    res.json(configs.map(config => ({
      id: config.id,
      basePrice: parseFloat(config.basePrice),
      pricePerKm: parseFloat(config.pricePerKm),
      description: config.description,
      isActive: config.isActive,
      createdAt: config.createdAt,
      updatedAt: config.updatedAt
    })));
  } catch (error) {
    console.error('Erreur historique configurations:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

module.exports = router;

