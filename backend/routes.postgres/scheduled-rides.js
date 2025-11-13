// Routes Scheduled Rides avec PostgreSQL + PostGIS
const express = require('express');
const { body, validationResult, param } = require('express-validator');
const AppDataSource = require('../config/database');
const ScheduledRide = require('../entities/ScheduledRide');
const Ride = require('../entities/Ride');
const { auth } = require('../middlewares.postgres/auth');
const PricingService = require('../services/PricingService');

const router = express.Router();

// Récupérer les courses programmées
router.get('/', auth, async (req, res) => {
  try {
    const scheduledRideRepository = AppDataSource.getRepository(ScheduledRide);
    
    const scheduledRides = await scheduledRideRepository.find({
      where: { clientId: req.user.id },
      order: { scheduledDate: 'ASC' }
    });

    // Convertir les coordonnées PostGIS en format JSON
    const formattedRides = scheduledRides.map(ride => {
      const pickupLocation = ride.pickupLocation;
      const dropoffLocation = ride.dropoffLocation;
      
      let pickupCoordinates = null;
      let dropoffCoordinates = null;
      
      if (pickupLocation && pickupLocation.coordinates) {
        pickupCoordinates = {
          latitude: pickupLocation.coordinates[1],
          longitude: pickupLocation.coordinates[0]
        };
      }
      
      if (dropoffLocation && dropoffLocation.coordinates) {
        dropoffCoordinates = {
          latitude: dropoffLocation.coordinates[1],
          longitude: dropoffLocation.coordinates[0]
        };
      }

      return {
        id: ride.id.toString(),
        pickupLocation: pickupCoordinates ? {
          latitude: pickupCoordinates.latitude,
          longitude: pickupCoordinates.longitude,
          address: ride.pickupAddress
        } : null,
        dropoffLocation: dropoffCoordinates ? {
          latitude: dropoffCoordinates.latitude,
          longitude: dropoffCoordinates.longitude,
          address: ride.dropoffAddress
        } : null,
        scheduledDate: ride.scheduledDate.toISOString(),
        vehicleType: ride.vehicleType,
        paymentMethod: ride.paymentMethod,
        status: ride.status,
        estimatedPrice: ride.estimatedPrice ? parseFloat(ride.estimatedPrice) : null,
        createdAt: ride.createdAt.toISOString()
      };
    });

    res.json({
      success: true,
      scheduledRides: formattedRides
    });
  } catch (error) {
    console.error('Erreur récupération courses programmées:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des courses programmées' });
  }
});

// Créer une course programmée
router.post('/', auth, [
  body('pickupLocation.latitude').isFloat(),
  body('pickupLocation.longitude').isFloat(),
  body('dropoffLocation.latitude').isFloat(),
  body('dropoffLocation.longitude').isFloat(),
  body('scheduledDate').notEmpty(),
  body('vehicleType').notEmpty().trim(),
  body('paymentMethod').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { pickupLocation, dropoffLocation, scheduledDate, vehicleType, paymentMethod } = req.body;
    const scheduledRideRepository = AppDataSource.getRepository(ScheduledRide);

    // Créer les points PostGIS
    const pickupPoint = {
      type: 'Point',
      coordinates: [pickupLocation.longitude, pickupLocation.latitude]
    };
    
    const dropoffPoint = {
      type: 'Point',
      coordinates: [dropoffLocation.longitude, dropoffLocation.latitude]
    };

    // Calculer le prix estimé
    let estimatedPrice = null;
    try {
      const priceEstimate = await PricingService.calculatePrice(
        pickupLocation,
        dropoffLocation,
        vehicleType,
        new Date()
      );
      estimatedPrice = priceEstimate.price;
    } catch (error) {
      console.error('Erreur calcul prix:', error);
      // Continuer sans prix estimé
    }

    // Convertir la date
    const scheduledDateObj = new Date(scheduledDate);

    const scheduledRide = scheduledRideRepository.create({
      clientId: req.user.id,
      pickupLocation: pickupPoint,
      pickupAddress: pickupLocation.address || null,
      dropoffLocation: dropoffPoint,
      dropoffAddress: dropoffLocation.address || null,
      scheduledDate: scheduledDateObj,
      vehicleType: vehicleType,
      paymentMethod: paymentMethod || 'cash',
      status: 'pending',
      estimatedPrice: estimatedPrice
    });

    await scheduledRideRepository.save(scheduledRide);

    res.status(201).json({
      success: true,
      scheduledRide: {
        id: scheduledRide.id.toString(),
        pickupLocation: {
          latitude: pickupLocation.latitude,
          longitude: pickupLocation.longitude,
          address: pickupLocation.address
        },
        dropoffLocation: {
          latitude: dropoffLocation.latitude,
          longitude: dropoffLocation.longitude,
          address: dropoffLocation.address
        },
        scheduledDate: scheduledRide.scheduledDate.toISOString(),
        vehicleType: scheduledRide.vehicleType,
        paymentMethod: scheduledRide.paymentMethod,
        status: scheduledRide.status,
        estimatedPrice: scheduledRide.estimatedPrice ? parseFloat(scheduledRide.estimatedPrice) : null,
        createdAt: scheduledRide.createdAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Erreur création course programmée:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la course programmée' });
  }
});

// Mettre à jour une course programmée
router.put('/:id', auth, [
  param('id').isInt(),
  body('pickupLocation.latitude').optional().isFloat(),
  body('pickupLocation.longitude').optional().isFloat(),
  body('dropoffLocation.latitude').optional().isFloat(),
  body('dropoffLocation.longitude').optional().isFloat(),
  body('scheduledDate').optional().notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { pickupLocation, dropoffLocation, scheduledDate } = req.body;
    const scheduledRideRepository = AppDataSource.getRepository(ScheduledRide);

    const scheduledRide = await scheduledRideRepository.findOne({
      where: { 
        id: parseInt(id),
        clientId: req.user.id
      }
    });

    if (!scheduledRide) {
      return res.status(404).json({ error: 'Course programmée non trouvée' });
    }

    // Vérifier que la course n'a pas encore été convertie en course
    if (scheduledRide.status !== 'pending' && scheduledRide.status !== 'confirmed') {
      return res.status(400).json({ error: 'Impossible de modifier une course déjà traitée' });
    }

    // Mettre à jour les champs
    if (pickupLocation) {
      scheduledRide.pickupLocation = {
        type: 'Point',
        coordinates: [pickupLocation.longitude, pickupLocation.latitude]
      };
      if (pickupLocation.address) {
        scheduledRide.pickupAddress = pickupLocation.address;
      }
    }

    if (dropoffLocation) {
      scheduledRide.dropoffLocation = {
        type: 'Point',
        coordinates: [dropoffLocation.longitude, dropoffLocation.latitude]
      };
      if (dropoffLocation.address) {
        scheduledRide.dropoffAddress = dropoffLocation.address;
      }
    }

    if (scheduledDate) {
      scheduledRide.scheduledDate = new Date(scheduledDate);
    }

    // Recalculer le prix estimé si les locations ont changé
    if (pickupLocation || dropoffLocation) {
      try {
        const currentPickup = pickupLocation || {
          latitude: scheduledRide.pickupLocation.coordinates[1],
          longitude: scheduledRide.pickupLocation.coordinates[0]
        };
        const currentDropoff = dropoffLocation || {
          latitude: scheduledRide.dropoffLocation.coordinates[1],
          longitude: scheduledRide.dropoffLocation.coordinates[0]
        };
        
        const priceEstimate = await PricingService.calculatePrice(
          currentPickup,
          currentDropoff,
          scheduledRide.vehicleType,
          new Date()
        );
        scheduledRide.estimatedPrice = priceEstimate.price;
      } catch (error) {
        console.error('Erreur calcul prix:', error);
        // Continuer sans mettre à jour le prix
      }
    }

    await scheduledRideRepository.save(scheduledRide);

    res.json({
      success: true,
      scheduledRide: {
        id: scheduledRide.id.toString(),
        pickupLocation: {
          latitude: scheduledRide.pickupLocation.coordinates[1],
          longitude: scheduledRide.pickupLocation.coordinates[0],
          address: scheduledRide.pickupAddress
        },
        dropoffLocation: {
          latitude: scheduledRide.dropoffLocation.coordinates[1],
          longitude: scheduledRide.dropoffLocation.coordinates[0],
          address: scheduledRide.dropoffAddress
        },
        scheduledDate: scheduledRide.scheduledDate.toISOString(),
        vehicleType: scheduledRide.vehicleType,
        paymentMethod: scheduledRide.paymentMethod,
        status: scheduledRide.status,
        estimatedPrice: scheduledRide.estimatedPrice ? parseFloat(scheduledRide.estimatedPrice) : null,
        createdAt: scheduledRide.createdAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour course programmée:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de la course programmée' });
  }
});

// Annuler une course programmée
router.delete('/:id', auth, [
  param('id').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const scheduledRideRepository = AppDataSource.getRepository(ScheduledRide);

    const scheduledRide = await scheduledRideRepository.findOne({
      where: { 
        id: parseInt(id),
        clientId: req.user.id
      }
    });

    if (!scheduledRide) {
      return res.status(404).json({ error: 'Course programmée non trouvée' });
    }

    // Vérifier que la course n'a pas encore été convertie en course
    if (scheduledRide.rideId) {
      return res.status(400).json({ error: 'Impossible d\'annuler une course déjà convertie' });
    }

    scheduledRide.status = 'cancelled';
    await scheduledRideRepository.save(scheduledRide);

    res.json({
      success: true,
      message: 'Course programmée annulée avec succès'
    });
  } catch (error) {
    console.error('Erreur annulation course programmée:', error);
    res.status(500).json({ error: 'Erreur lors de l\'annulation de la course programmée' });
  }
});

module.exports = router;

