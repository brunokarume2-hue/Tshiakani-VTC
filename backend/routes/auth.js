const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middlewares/auth');

const router = express.Router();

// Générer un token JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

// Inscription / Connexion
router.post('/signin', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('name').optional().trim(),
  body('role').isIn(['client', 'driver']).withMessage('Rôle invalide')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phoneNumber, name, role } = req.body;

    // Normaliser le numéro de téléphone
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');

    // Chercher ou créer l'utilisateur
    let user = await User.findOne({ phoneNumber: normalizedPhone });

    if (user) {
      // Mettre à jour le rôle si nécessaire
      if (role && user.role !== role) {
        user.role = role;
        await user.save();
      }
    } else {
      // Créer un nouvel utilisateur
      user = new User({
        name: name || `Utilisateur ${normalizedPhone.slice(-4)}`,
        phoneNumber: normalizedPhone,
        role: role || 'client',
        isVerified: false
      });
      await user.save();
    }

    const token = generateToken(user._id);

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('Erreur signin:', error);
    res.status(500).json({ error: 'Erreur lors de la connexion' });
  }
});

// Vérifier le token
router.get('/verify', auth, async (req, res) => {
  res.json({
    user: {
      id: req.user._id,
      name: req.user.name,
      phoneNumber: req.user.phoneNumber,
      role: req.user.role,
      isVerified: req.user.isVerified
    }
  });
});

// Mettre à jour le profil
router.put('/profile', auth, [
  body('name').optional().trim(),
  body('fcmToken').optional().trim()
], async (req, res) => {
  try {
    const { name, fcmToken } = req.body;

    if (name) req.user.name = name;
    if (fcmToken) req.user.fcmToken = fcmToken;

    await req.user.save();

    res.json({
      user: {
        id: req.user._id,
        name: req.user.name,
        phoneNumber: req.user.phoneNumber,
        role: req.user.role
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour profil:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Connexion admin (simplifiée - pour le dashboard)
router.post('/admin/login', [
  body('phoneNumber').trim().notEmpty(),
  body('password').optional()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phoneNumber } = req.body;
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');

    // Chercher un utilisateur admin
    let user = await User.findOne({ 
      phoneNumber: normalizedPhone,
      role: 'admin'
    });

    if (!user) {
      // Pour le développement, créer un admin par défaut
      user = new User({
        name: 'Admin',
        phoneNumber: normalizedPhone,
        role: 'admin',
        isVerified: true
      });
      await user.save();
    }

    const token = generateToken(user._id);

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Erreur login admin:', error);
    res.status(500).json({ error: 'Erreur lors de la connexion' });
  }
});

module.exports = router;

