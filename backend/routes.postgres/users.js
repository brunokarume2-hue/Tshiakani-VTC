// Routes utilisateurs avec PostgreSQL
const express = require('express');
const AppDataSource = require('../config/database');
const User = require('../entities/User');
const { auth, adminAuth } = require('../middlewares.postgres/auth');

const router = express.Router();

/**
 * @mvp true
 * @route GET /api/users/me
 * @description Récupérer le profil de l'utilisateur connecté (utilisé dans MVP)
 */
// Obtenir le profil
router.get('/me', auth, async (req, res) => {
  try {
    res.json({
      id: req.user.id,
      name: req.user.name,
      phoneNumber: req.user.phoneNumber,
      role: req.user.role,
      isVerified: req.user.isVerified,
      profileImageURL: req.user.profileImageURL || null
      // driverInfo supprimé (app driver séparée)
    });
  } catch (error) {
    console.error('Erreur récupération profil:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

/**
 * @mvp false
 * @future true
 * @route GET /api/users
 * @description Liste des utilisateurs (admin) - Réservé pour dashboard admin (non utilisé dans app client iOS MVP)
 */
// Obtenir tous les utilisateurs (admin)
// adminAuth désactivé temporairement
router.get('/', async (req, res) => {
  try {
    const { role, page = 1, limit = 50 } = req.query;
    const userRepository = AppDataSource.getRepository(User);
    
    const query = userRepository.createQueryBuilder('user');
    
    if (role) {
      query.where('user.role = :role', { role });
    }
    
    const [users, total] = await query
      .skip((parseInt(page) - 1) * parseInt(limit))
      .take(parseInt(limit))
      .getManyAndCount();

    res.json({
      users,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Erreur récupération utilisateurs:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

/**
 * @mvp false
 * @future true
 * @route POST /api/users/:userId/ban
 * @description Bannir un utilisateur (admin) - Réservé pour dashboard admin (non utilisé dans app client iOS MVP)
 */
// Bannir un utilisateur (admin)
router.post('/:userId/ban', adminAuth, async (req, res) => {
  try {
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ 
      where: { id: parseInt(req.params.userId) } 
    });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    user.isVerified = false;
    await userRepository.save(user);

    res.json({ success: true, message: 'Utilisateur banni' });
  } catch (error) {
    console.error('Erreur bannissement:', error);
    res.status(500).json({ error: 'Erreur lors du bannissement' });
  }
});

module.exports = router;

