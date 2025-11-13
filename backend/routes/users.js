const express = require('express');
const User = require('../models/User');
const { auth, adminAuth } = require('../middlewares/auth');

const router = express.Router();

// Obtenir le profil de l'utilisateur connecté
router.get('/me', auth, async (req, res) => {
  try {
    res.json({
      id: req.user._id,
      name: req.user.name,
      phoneNumber: req.user.phoneNumber,
      role: req.user.role,
      isVerified: req.user.isVerified,
      driverInfo: req.user.driverInfo
    });
  } catch (error) {
    console.error('Erreur récupération profil:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Obtenir tous les utilisateurs (admin)
router.get('/', adminAuth, async (req, res) => {
  try {
    const { role, page = 1, limit = 50 } = req.query;
    const query = role ? { role } : {};

    const users = await User.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit))
      .select('-__v');

    const total = await User.countDocuments(query);

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

// Bannir un utilisateur (admin)
router.post('/:userId/ban', adminAuth, async (req, res) => {
  try {
    const user = await User.findById(req.params.userId);

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Ici, vous pourriez ajouter un champ "isBanned" au modèle User
    // Pour l'instant, on peut simplement désactiver le compte
    user.isVerified = false;
    await user.save();

    res.json({ success: true, message: 'Utilisateur banni' });
  } catch (error) {
    console.error('Erreur bannissement:', error);
    res.status(500).json({ error: 'Erreur lors du bannissement' });
  }
});

module.exports = router;

