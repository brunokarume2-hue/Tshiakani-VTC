// Routes Favorites avec PostgreSQL + PostGIS
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const FavoriteAddress = require('../entities/FavoriteAddress');
const { auth } = require('../middlewares.postgres/auth');

const router = express.Router();

// Récupérer les adresses favorites
router.get('/', auth, async (req, res) => {
  try {
    const favoriteAddressRepository = AppDataSource.getRepository(FavoriteAddress);
    
    const favorites = await favoriteAddressRepository.find({
      where: { 
        userId: req.user.id,
        isFavorite: true
      },
      order: { createdAt: 'DESC' }
    });

    // Convertir les coordonnées PostGIS en format JSON
    const favoritesWithCoordinates = favorites.map(favorite => {
      const location = favorite.location;
      let coordinates = null;
      
      if (location && location.coordinates) {
        coordinates = {
          latitude: location.coordinates[1],
          longitude: location.coordinates[0]
        };
      }

      return {
        id: favorite.id.toString(),
        name: favorite.name,
        address: favorite.address,
        location: coordinates,
        icon: favorite.icon,
        isFavorite: favorite.isFavorite,
        createdAt: favorite.createdAt
      };
    });

    res.json({
      success: true,
      favorites: favoritesWithCoordinates
    });
  } catch (error) {
    console.error('Erreur récupération adresses favorites:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des adresses favorites' });
  }
});

// Ajouter une adresse favorite
router.post('/', auth, [
  body('name').notEmpty().trim().isLength({ min: 1, max: 255 }),
  body('address').notEmpty().trim(),
  body('location.latitude').isFloat(),
  body('location.longitude').isFloat(),
  body('icon').optional().trim().isLength({ max: 50 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, address, location, icon } = req.body;
    const favoriteAddressRepository = AppDataSource.getRepository(FavoriteAddress);

    // Créer le point PostGIS
    const locationPoint = {
      type: 'Point',
      coordinates: [location.longitude, location.latitude]
    };

    const favoriteAddress = favoriteAddressRepository.create({
      userId: req.user.id,
      name: name,
      address: address,
      location: locationPoint,
      icon: icon || 'mappin.circle.fill',
      isFavorite: true
    });

    await favoriteAddressRepository.save(favoriteAddress);

    res.status(201).json({
      success: true,
      favorite: {
        id: favoriteAddress.id.toString(),
        name: favoriteAddress.name,
        address: favoriteAddress.address,
        location: {
          latitude: location.latitude,
          longitude: location.longitude
        },
        icon: favoriteAddress.icon,
        isFavorite: favoriteAddress.isFavorite,
        createdAt: favoriteAddress.createdAt
      }
    });
  } catch (error) {
    console.error('Erreur ajout adresse favorite:', error);
    res.status(500).json({ error: 'Erreur lors de l\'ajout de l\'adresse favorite' });
  }
});

// Mettre à jour une adresse favorite
router.put('/:id', auth, [
  body('name').optional().trim().isLength({ min: 1, max: 255 }),
  body('address').optional().trim(),
  body('location.latitude').optional().isFloat(),
  body('location.longitude').optional().isFloat(),
  body('icon').optional().trim().isLength({ max: 50 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { name, address, location, icon } = req.body;
    const favoriteAddressRepository = AppDataSource.getRepository(FavoriteAddress);

    const favoriteAddress = await favoriteAddressRepository.findOne({
      where: { 
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!favoriteAddress) {
      return res.status(404).json({ error: 'Adresse favorite non trouvée' });
    }

    if (name) favoriteAddress.name = name;
    if (address) favoriteAddress.address = address;
    if (icon) favoriteAddress.icon = icon;
    if (location) {
      favoriteAddress.location = {
        type: 'Point',
        coordinates: [location.longitude, location.latitude]
      };
    }

    await favoriteAddressRepository.save(favoriteAddress);

    res.json({
      success: true,
      favorite: {
        id: favoriteAddress.id.toString(),
        name: favoriteAddress.name,
        address: favoriteAddress.address,
        location: location ? {
          latitude: location.latitude,
          longitude: location.longitude
        } : (favoriteAddress.location?.coordinates ? {
          latitude: favoriteAddress.location.coordinates[1],
          longitude: favoriteAddress.location.coordinates[0]
        } : null),
        icon: favoriteAddress.icon,
        isFavorite: favoriteAddress.isFavorite,
        createdAt: favoriteAddress.createdAt
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour adresse favorite:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de l\'adresse favorite' });
  }
});

// Supprimer une adresse favorite
router.delete('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const favoriteAddressRepository = AppDataSource.getRepository(FavoriteAddress);

    const favoriteAddress = await favoriteAddressRepository.findOne({
      where: { 
        id: parseInt(id),
        userId: req.user.id
      }
    });

    if (!favoriteAddress) {
      return res.status(404).json({ error: 'Adresse favorite non trouvée' });
    }

    await favoriteAddressRepository.remove(favoriteAddress);

    res.json({
      success: true,
      message: 'Adresse favorite supprimée avec succès'
    });
  } catch (error) {
    console.error('Erreur suppression adresse favorite:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'adresse favorite' });
  }
});

module.exports = router;

