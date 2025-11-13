// Routes d'authentification avec PostgreSQL
const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const otpService = require('../services/OTPService');
const { getRedisService } = require('../services/RedisService');
const logger = require('../utils/logger');

const router = express.Router();

// Générer un token JWT
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

/**
 * @route POST /api/auth/register
 * @description Inscription avec OTP - Envoie un code OTP de confirmation
 */
router.post('/register', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('name').trim().notEmpty().withMessage('Le nom est requis'),
  body('role').optional().isIn(['client', 'driver']).withMessage('Rôle invalide')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber, name, role = 'client' } = req.body;
    
    // Formater le numéro de téléphone avec la méthode d'OTPService (cohérence)
    let formattedPhone;
    try {
      formattedPhone = otpService.formatPhoneNumberForTwilio(phoneNumber);
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Format de numéro invalide',
        message: error.message || 'Le numéro de téléphone est invalide. Format attendu: +243XXXXXXXXX'
      });
    }
    
    // Normaliser pour la base de données (sans le +)
    const normalizedPhone = formattedPhone.replace(/^\+/, '');

    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();

    // OPTIMISATION: Paralléliser les vérifications indépendantes
    const [existingUser, rateLimit] = await Promise.all([
      userRepository.findOne({ 
        where: { phoneNumber: normalizedPhone } 
      }),
      redisService.checkOTPRateLimit(formattedPhone, 3, 3600)
    ]);

    if (existingUser) {
      return res.status(400).json({ 
        success: false,
        error: 'Ce numéro de téléphone est déjà enregistré',
        message: 'Ce numéro de téléphone est déjà utilisé. Veuillez vous connecter.'
      });
    }
    if (!rateLimit.allowed) {
      const resetTime = new Date(rateLimit.resetAt).toLocaleTimeString('fr-FR');
      return res.status(429).json({
        success: false,
        error: 'Trop de tentatives',
        message: `Vous avez atteint la limite de tentatives. Veuillez réessayer après ${resetTime}.`,
        resetAt: rateLimit.resetAt
      });
    }

    // Stocker les données d'inscription dans Redis
    const stored = await redisService.storePendingRegistration(formattedPhone, {
      name: name,
      phoneNumber: normalizedPhone,
      role: role
    }, 600); // 10 minutes
    
    if (!stored) {
      logger.error('Impossible de stocker les données d\'inscription dans Redis', {
        phoneNumber: formattedPhone
      });
      return res.status(503).json({
        success: false,
        error: 'Service temporairement indisponible',
        message: 'Le service de stockage est temporairement indisponible. Veuillez réessayer dans quelques instants.'
      });
    }

    // Envoyer l'OTP
    try {
      await otpService.sendOTP(formattedPhone, 'whatsapp');
      
      logger.info('OTP envoyé pour inscription', { 
        phoneNumber: formattedPhone,
        name,
        role
      });

      res.json({
        success: true,
        message: 'Code de vérification envoyé par SMS/WhatsApp',
        phoneNumber: formattedPhone,
        remainingAttempts: rateLimit.remaining
      });
    } catch (otpError) {
      logger.error('Erreur envoi OTP inscription', {
        error: otpError.message,
        phoneNumber: formattedPhone
      });
      
      // Supprimer les données d'inscription en attente si l'envoi échoue
      try {
        await redisService.deletePendingRegistration(formattedPhone);
      } catch (deleteError) {
        logger.error('Erreur suppression données inscription', {
          error: deleteError.message
        });
      }

      res.status(500).json({
        success: false,
        error: 'Erreur lors de l\'envoi du code de vérification',
        message: otpError.message || 'Impossible d\'envoyer le code de vérification. Veuillez réessayer.'
      });
    }
  } catch (error) {
    logger.error('Erreur inscription:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de l\'inscription',
      message: error.message
    });
  }
});

/**
 * @route POST /api/auth/login
 * @description Connexion avec OTP - Envoie un code OTP de confirmation
 */
router.post('/login', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber } = req.body;
    
    // Formater le numéro de téléphone avec la méthode d'OTPService (cohérence)
    let formattedPhone;
    try {
      formattedPhone = otpService.formatPhoneNumberForTwilio(phoneNumber);
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Format de numéro invalide',
        message: error.message || 'Le numéro de téléphone est invalide. Format attendu: +243XXXXXXXXX'
      });
    }
    
    // Normaliser pour la base de données (sans le +)
    const normalizedPhone = formattedPhone.replace(/^\+/, '');
    
    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();

    // OPTIMISATION: Paralléliser les vérifications indépendantes
    const [user, rateLimit] = await Promise.all([
      userRepository.findOne({ 
        where: { phoneNumber: normalizedPhone },
        select: ['id', 'name', 'phoneNumber', 'role', 'isVerified']
      }),
      redisService.checkOTPRateLimit(formattedPhone, 3, 3600)
    ]);

    if (!user) {
      // Ne pas révéler que l'utilisateur n'existe pas (sécurité)
      // Envoyer quand même un OTP pour éviter l'énumération de comptes
      logger.warn('Tentative de connexion avec numéro inexistant', { 
        phoneNumber: formattedPhone 
      });
    }
    if (!rateLimit.allowed) {
      const resetTime = new Date(rateLimit.resetAt).toLocaleTimeString('fr-FR');
      return res.status(429).json({
        success: false,
        error: 'Trop de tentatives',
        message: `Vous avez atteint la limite de tentatives. Veuillez réessayer après ${resetTime}.`,
        resetAt: rateLimit.resetAt
      });
    }

    // Stocker la demande de connexion dans Redis
    const stored = await redisService.storePendingLogin(formattedPhone, {
      phoneNumber: normalizedPhone
    }, 600); // 10 minutes
    
    if (!stored) {
      logger.error('Impossible de stocker la demande de connexion dans Redis', {
        phoneNumber: formattedPhone
      });
      return res.status(503).json({
        success: false,
        error: 'Service temporairement indisponible',
        message: 'Le service de stockage est temporairement indisponible. Veuillez réessayer dans quelques instants.'
      });
    }

    // Envoyer l'OTP
    try {
      await otpService.sendOTP(formattedPhone, 'whatsapp');
      
      logger.info('OTP envoyé pour connexion', { 
        phoneNumber: formattedPhone,
        userExists: !!user
      });

      // Réponse générique pour éviter l'énumération de comptes
      res.json({
        success: true,
        message: 'Si ce numéro est enregistré, vous recevrez un code de vérification par SMS/WhatsApp',
        phoneNumber: formattedPhone,
        remainingAttempts: rateLimit.remaining
      });
    } catch (otpError) {
      logger.error('Erreur envoi OTP connexion', {
        error: otpError.message,
        phoneNumber: formattedPhone
      });
      
      // Supprimer la demande de connexion en attente si l'envoi échoue
      try {
        await redisService.deletePendingLogin(formattedPhone);
      } catch (deleteError) {
        logger.error('Erreur suppression demande connexion', {
          error: deleteError.message
        });
      }

      res.status(500).json({
        success: false,
        error: 'Erreur lors de l\'envoi du code de vérification',
        message: otpError.message || 'Impossible d\'envoyer le code de vérification. Veuillez réessayer.'
      });
    }
  } catch (error) {
    logger.error('Erreur connexion:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de la connexion',
      message: error.message
    });
  }
});

/**
 * @route POST /api/auth/verify-otp
 * @description Vérifie l'OTP et finalise l'inscription ou la connexion
 */
router.post('/verify-otp', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('code').trim().notEmpty().withMessage('Le code de vérification est requis'),
  body('code').isLength({ min: 6, max: 6 }).withMessage('Le code doit contenir 6 chiffres'),
  body('type').isIn(['register', 'login']).withMessage('Le type doit être "register" ou "login"')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber, code, type } = req.body;
    
    // Formater le numéro de téléphone avec la méthode d'OTPService (cohérence)
    let formattedPhone;
    try {
      formattedPhone = otpService.formatPhoneNumberForTwilio(phoneNumber);
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Format de numéro invalide',
        message: error.message || 'Le numéro de téléphone est invalide. Format attendu: +243XXXXXXXXX'
      });
    }
    
    // Normaliser pour la base de données (sans le +)
    const normalizedPhone = formattedPhone.replace(/^\+/, '');

    const userRepository = AppDataSource.getRepository(User);
    const redisService = getRedisService();

    // Vérifier l'OTP
    const otpVerification = await otpService.verifyOTP(formattedPhone, code);
    
    if (!otpVerification.valid) {
      return res.status(400).json({ 
        success: false,
        error: 'Code de vérification invalide ou expiré',
        message: otpVerification.error || 'Le code fourni est incorrect ou a expiré. Veuillez demander un nouveau code.'
      });
    }

    // OPTIMISATION: Paralléliser la réinitialisation du rate limit et la récupération des données
    if (type === 'register') {
      // Paralléliser: réinitialiser rate limit + récupérer données d'inscription
      const [, registrationData] = await Promise.all([
        redisService.resetOTPRateLimit(formattedPhone),
        redisService.getPendingRegistration(formattedPhone)
      ]);
      
      if (!registrationData) {
        return res.status(400).json({ 
          success: false,
          error: 'Données d\'inscription non trouvées',
          message: 'Les données d\'inscription ont expiré. Veuillez recommencer l\'inscription.'
        });
      }

      // Vérifier si l'utilisateur existe déjà (race condition)
      const existingUser = await userRepository.findOne({ 
        where: { phoneNumber: registrationData.phoneNumber } 
      });

      if (existingUser) {
        // Supprimer les données d'inscription en attente
        await redisService.deletePendingRegistration(formattedPhone);
        return res.status(400).json({ 
          success: false,
          error: 'Ce numéro de téléphone est déjà enregistré',
          message: 'Ce numéro de téléphone est déjà utilisé. Veuillez vous connecter.'
        });
      }

      // Créer l'utilisateur
      const user = userRepository.create({
        name: registrationData.name,
        phoneNumber: registrationData.phoneNumber,
        role: registrationData.role,
        isVerified: true,
        password: null // Pas de mot de passe avec OTP-only
      });

      await userRepository.save(user);

      // OPTIMISATION: Paralléliser la suppression Redis et la génération du token
      const [, token] = await Promise.all([
        redisService.deletePendingRegistration(formattedPhone),
        Promise.resolve(generateToken(user.id))
      ]);

      logger.info('Utilisateur créé avec succès', { 
        userId: user.id,
        phoneNumber: user.phoneNumber,
        role: user.role
      });

      res.json({
        success: true,
        token,
        user: {
          id: user.id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          role: user.role,
          isVerified: user.isVerified
        }
      });
    } else if (type === 'login') {
      // OPTIMISATION: Paralléliser la réinitialisation du rate limit et la récupération des données
      const [, loginData] = await Promise.all([
        redisService.resetOTPRateLimit(formattedPhone),
        redisService.getPendingLogin(formattedPhone)
      ]);
      
      if (!loginData) {
        return res.status(400).json({ 
          success: false,
          error: 'Demande de connexion non trouvée',
          message: 'La demande de connexion a expiré. Veuillez recommencer la connexion.'
        });
      }

      // Chercher l'utilisateur
      const user = await userRepository.findOne({ 
        where: { phoneNumber: normalizedPhone },
        select: ['id', 'name', 'phoneNumber', 'role', 'isVerified']
      });

      if (!user) {
        // Supprimer la demande de connexion en attente
        await redisService.deletePendingLogin(formattedPhone);
        return res.status(404).json({ 
          success: false,
          error: 'Utilisateur non trouvé',
          message: 'Aucun compte n\'est associé à ce numéro de téléphone. Veuillez vous inscrire.'
        });
      }

      // Mettre à jour isVerified si nécessaire
      if (!user.isVerified) {
        user.isVerified = true;
        await userRepository.save(user);
      }

      // OPTIMISATION: Paralléliser la suppression Redis et la génération du token
      const [, token] = await Promise.all([
        redisService.deletePendingLogin(formattedPhone),
        Promise.resolve(generateToken(user.id))
      ]);

      logger.info('Utilisateur connecté avec succès', { 
        userId: user.id,
        phoneNumber: user.phoneNumber
      });

      res.json({
        success: true,
        token,
        user: {
          id: user.id,
          name: user.name,
          phoneNumber: user.phoneNumber,
          role: user.role,
          isVerified: user.isVerified
        }
      });
    } else {
      return res.status(400).json({ 
        success: false,
        error: 'Type invalide',
        message: 'Le type doit être "register" ou "login"'
      });
    }
  } catch (error) {
    logger.error('Erreur vérification OTP:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de la vérification',
      message: error.message
    });
  }
});

/**
 * @mvp false
 * @future true
 * @route POST /api/auth/signin
 * @description Inscription/Connexion legacy avec OTP (non utilisé dans MVP, réservé pour futures versions)
 */
// Inscription / Connexion (ancienne méthode - gardée pour compatibilité)
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
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');

    const userRepository = AppDataSource.getRepository(User);
    
    // Chercher ou créer l'utilisateur
    let user = await userRepository.findOne({ 
      where: { phoneNumber: normalizedPhone } 
    });

    if (user) {
      if (role && user.role !== role) {
        user.role = role;
        await userRepository.save(user);
      }
    } else {
      user = userRepository.create({
        name: name || `Utilisateur ${normalizedPhone.slice(-4)}`,
        phoneNumber: normalizedPhone,
        role: role || 'client',
        isVerified: false
      });
      await userRepository.save(user);
    }

    const token = generateToken(user.id);

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role,
        isVerified: user.isVerified,
        profileImageURL: user.profileImageURL || null
      }
    });
  } catch (error) {
    console.error('Erreur signin:', error);
    res.status(500).json({ error: 'Erreur lors de la connexion' });
  }
});

/**
 * @mvp true
 * @route GET /api/auth/verify
 * @description Vérifier le token JWT (utilisé dans MVP)
 */
// Vérifier le token
router.get('/verify', auth, async (req, res) => {
  res.json({
    user: {
      id: req.user.id,
      name: req.user.name,
      phoneNumber: req.user.phoneNumber,
      role: req.user.role,
      isVerified: req.user.isVerified,
      profileImageURL: req.user.profileImageURL || null
    }
  });
});

/**
 * @mvp false
 * @future true
 * @route PUT /api/auth/profile
 * @description Mettre à jour le profil (nom, fcmToken) - Non utilisé dans MVP simplifié, réservé pour futures versions
 */
// Mettre à jour le profil
router.put('/profile', auth, [
  body('name').optional().trim(),
  body('fcmToken').optional().trim(),
  body('profileImageURL').optional().trim()
], async (req, res) => {
  try {
    const { name, fcmToken, profileImageURL } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    if (name) req.user.name = name;
    if (fcmToken) req.user.fcmToken = fcmToken;
    if (profileImageURL !== undefined) req.user.profileImageURL = profileImageURL;

    await userRepository.save(req.user);

    res.json({
      user: {
        id: req.user.id,
        name: req.user.name,
        phoneNumber: req.user.phoneNumber,
        role: req.user.role,
        profileImageURL: req.user.profileImageURL
      }
    });
  } catch (error) {
    console.error('Erreur mise à jour profil:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

/**
 * @mvp false
 * @future true
 * @route POST /api/auth/google
 * @description Authentification avec Google - Non utilisé dans MVP, réservé pour futures versions
 */
// Authentification Google
router.post('/google', [
  body('idToken').notEmpty().withMessage('Token Google requis'),
  body('email').isEmail().withMessage('Email invalide'),
  body('name').trim().notEmpty().withMessage('Nom requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { idToken, email, name, photoURL } = req.body;
    const userRepository = AppDataSource.getRepository(User);
    
    // TODO: Vérifier le token Google avec Google API
    // Pour l'instant, on fait confiance au token envoyé par le client
    // En production, vérifiez le token avec: https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=TOKEN
    
    // Chercher l'utilisateur par email
    let user = await userRepository.findOne({ 
      where: { email: email } 
    });

    if (!user) {
      // Créer un nouvel utilisateur
      user = userRepository.create({
        name: name,
        email: email,
        phoneNumber: null, // Pas de numéro de téléphone pour les comptes Google
        role: 'client',
        isVerified: true, // Les comptes Google sont vérifiés
        profileImageURL: photoURL
      });
      await userRepository.save(user);
    } else {
      // Mettre à jour les informations si nécessaire
      if (user.name !== name) {
        user.name = name;
      }
      if (photoURL && user.profileImageURL !== photoURL) {
        user.profileImageURL = photoURL;
      }
      if (!user.isVerified) {
        user.isVerified = true;
      }
      await userRepository.save(user);
    }

    const token = generateToken(user.id);

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        email: user.email,
        role: user.role,
        isVerified: user.isVerified
      }
    });
  } catch (error) {
    console.error('Erreur authentification Google:', error);
    res.status(500).json({ error: 'Erreur lors de l\'authentification Google' });
  }
});

/**
 * @mvp false
 * @future true
 * @route POST /api/auth/admin/login
 * @description Connexion admin - Réservé pour dashboard admin (non utilisé dans app client iOS MVP)
 */
// Connexion admin
router.post('/admin/login', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('password').notEmpty().withMessage('Le mot de passe est requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { phoneNumber, password } = req.body;
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');
    const userRepository = AppDataSource.getRepository(User);

    // Chercher l'utilisateur admin avec le mot de passe inclus
    let user = await userRepository.findOne({ 
      where: { 
        phoneNumber: normalizedPhone,
        role: 'admin'
      },
      select: ['id', 'name', 'phoneNumber', 'role', 'isVerified', 'password'] // Inclure password explicitement
    });

    if (!user) {
      return res.status(401).json({ 
        error: 'Numéro de téléphone ou mot de passe incorrect',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Vérifier le mot de passe
    if (user.password) {
      const isValidPassword = await bcrypt.compare(password, user.password);
      if (!isValidPassword) {
        return res.status(401).json({ 
          error: 'Numéro de téléphone ou mot de passe incorrect',
          code: 'INVALID_CREDENTIALS'
        });
      }
    } else {
      // Si pas de mot de passe défini, créer un nouveau mot de passe
      const hashedPassword = await bcrypt.hash(password, 10);
      user.password = hashedPassword;
      await userRepository.save(user);
    }

    const token = generateToken(user.id);

    res.json({
      token,
      user: {
        id: user.id,
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

/**
 * @mvp true
 * @route POST /api/auth/forgot-password
 * @description Demande de réinitialisation de mot de passe (utilisé dans MVP)
 */
// Demande de réinitialisation de mot de passe (envoie un code OTP)
router.post('/forgot-password', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber } = req.body;
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');
    
    const userRepository = AppDataSource.getRepository(User);

    // Vérifier si l'utilisateur existe
    const user = await userRepository.findOne({ 
      where: { phoneNumber: normalizedPhone } 
    });

    if (!user) {
      // Ne pas révéler que l'utilisateur n'existe pas (sécurité)
      return res.json({
        success: true,
        message: 'Si ce numéro est enregistré, vous recevrez un code de réinitialisation'
      });
    }

    // Envoyer un code OTP pour la réinitialisation
    try {
      const formattedPhone = normalizedPhone.startsWith('+') 
        ? normalizedPhone 
        : `+${normalizedPhone}`;
      
      await otpService.sendOTP(formattedPhone, 'sms');

      res.json({
        success: true,
        message: 'Code de réinitialisation envoyé par SMS'
      });
    } catch (error) {
      console.error('Erreur envoi OTP réinitialisation:', error);
      res.status(500).json({ 
        success: false,
        error: 'Erreur lors de l\'envoi du code',
        message: error.message
      });
    }
  } catch (error) {
    console.error('Erreur forgot-password:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de la demande de réinitialisation',
      message: error.message
    });
  }
});

/**
 * @mvp true
 * @route POST /api/auth/reset-password
 * @description Réinitialisation de mot de passe avec code OTP (utilisé dans MVP)
 */
// Réinitialisation de mot de passe avec code OTP
router.post('/reset-password', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('code').trim().notEmpty().withMessage('Le code de vérification est requis'),
  body('newPassword').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber, code, newPassword } = req.body;
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');
    const formattedPhone = normalizedPhone.startsWith('+') 
      ? normalizedPhone 
      : `+${normalizedPhone}`;
    
    const userRepository = AppDataSource.getRepository(User);

    // Vérifier le code OTP
    const otpVerification = await otpService.verifyOTP(formattedPhone, code);
    
    if (!otpVerification.valid) {
      return res.status(400).json({ 
        success: false,
        error: 'Code de vérification invalide ou expiré',
        message: otpVerification.error || 'Le code fourni est incorrect ou a expiré. Veuillez demander un nouveau code.'
      });
    }

    // Trouver l'utilisateur
    const user = await userRepository.findOne({ 
      where: { phoneNumber: normalizedPhone } 
    });

    if (!user) {
      return res.status(404).json({ 
        success: false,
        error: 'Utilisateur non trouvé',
        message: 'Aucun compte n\'est associé à ce numéro de téléphone'
      });
    }

    // Hasher le nouveau mot de passe
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await userRepository.save(user);

    // Le code OTP a déjà été supprimé par verifyOTP

    res.json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès'
    });
  } catch (error) {
    console.error('Erreur reset-password:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de la réinitialisation',
      message: error.message
    });
  }
});

/**
 * @mvp true
 * @route POST /api/auth/change-password
 * @description Changer le mot de passe (authentifié) - Utilisé dans MVP
 */
// Changer le mot de passe (nécessite authentification)
router.post('/change-password', auth, [
  body('currentPassword').notEmpty().withMessage('Le mot de passe actuel est requis'),
  body('newPassword').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { currentPassword, newPassword } = req.body;
    const userRepository = AppDataSource.getRepository(User);

    // Récupérer l'utilisateur avec le mot de passe
    const user = await userRepository.findOne({ 
      where: { id: req.user.id },
      select: ['id', 'password']
    });

    if (!user || !user.password) {
      return res.status(400).json({ 
        success: false,
        error: 'Mot de passe non défini',
        message: 'Vous devez d\'abord définir un mot de passe'
      });
    }

    // Vérifier le mot de passe actuel
    const isValidPassword = await bcrypt.compare(currentPassword, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ 
        success: false,
        error: 'Mot de passe actuel incorrect',
        message: 'Le mot de passe actuel fourni est incorrect'
      });
    }

    // Hasher le nouveau mot de passe
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await userRepository.save(user);

    res.json({
      success: true,
      message: 'Mot de passe modifié avec succès'
    });
  } catch (error) {
    console.error('Erreur change-password:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors du changement de mot de passe',
      message: error.message
    });
  }
});

/**
 * @mvp true
 * @route POST /api/auth/set-password
 * @description Définir un mot de passe pour les utilisateurs existants sans mot de passe (utilisé dans MVP)
 */
// Définir un mot de passe pour les utilisateurs existants sans mot de passe
router.post('/set-password', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('code').trim().notEmpty().withMessage('Le code de vérification est requis'),
  body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber, code, password } = req.body;
    const normalizedPhone = phoneNumber.replace(/\s+/g, '').replace(/[+\-]/g, '');
    const formattedPhone = normalizedPhone.startsWith('+') 
      ? normalizedPhone 
      : `+${normalizedPhone}`;
    
    const userRepository = AppDataSource.getRepository(User);

    // Vérifier le code OTP (utiliser le même système que reset-password)
    const otpVerification = await otpService.verifyOTP(formattedPhone, code);
    
    if (!otpVerification.valid) {
      return res.status(400).json({ 
        success: false,
        error: 'Code de vérification invalide ou expiré',
        message: otpVerification.error || 'Le code fourni est incorrect ou a expiré. Veuillez demander un nouveau code.'
      });
    }

    // Trouver l'utilisateur
    const user = await userRepository.findOne({ 
      where: { phoneNumber: normalizedPhone },
      select: ['id', 'password']
    });

    if (!user) {
      return res.status(404).json({ 
        success: false,
        error: 'Utilisateur non trouvé',
        message: 'Aucun compte n\'est associé à ce numéro de téléphone'
      });
    }

    // Vérifier que l'utilisateur n'a pas déjà un mot de passe
    if (user.password) {
      return res.status(400).json({ 
        success: false,
        error: 'Mot de passe déjà défini',
        message: 'Ce compte a déjà un mot de passe. Utilisez "Mot de passe oublié" pour le réinitialiser.'
      });
    }

    // Hasher le nouveau mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);
    user.password = hashedPassword;
    await userRepository.save(user);

    // Le code OTP a déjà été supprimé par verifyOTP

    // Générer un token pour connecter automatiquement l'utilisateur
    const token = generateToken(user.id);

    res.json({
      success: true,
      token,
      message: 'Mot de passe défini avec succès',
      user: {
        id: user.id,
        phoneNumber: user.phoneNumber
      }
    });
  } catch (error) {
    console.error('Erreur set-password:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de la définition du mot de passe',
      message: error.message
    });
  }
});

/**
 * @route POST /api/auth/send-otp
 * @description Envoie un code OTP au numéro de téléphone (endpoint standalone)
 */
router.post('/send-otp', [
  body('phoneNumber').trim().notEmpty().withMessage('Le numéro de téléphone est requis'),
  body('channel').optional().isIn(['whatsapp', 'sms']).withMessage('Le canal doit être whatsapp ou sms')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false,
        errors: errors.array(),
        message: 'Données invalides'
      });
    }

    const { phoneNumber, channel = 'whatsapp' } = req.body;
    
    // Formater le numéro de téléphone
    let formattedPhone;
    try {
      formattedPhone = otpService.formatPhoneNumberForTwilio(phoneNumber);
    } catch (error) {
      return res.status(400).json({
        success: false,
        error: 'Format de numéro invalide',
        message: error.message || 'Le numéro de téléphone est invalide. Format attendu: +243XXXXXXXXX'
      });
    }

    const redisService = getRedisService();

    // Vérifier le rate limiting pour OTP
    const rateLimit = await redisService.checkOTPRateLimit(formattedPhone, 3, 3600);
    if (!rateLimit.allowed) {
      const resetTime = new Date(rateLimit.resetAt).toLocaleTimeString('fr-FR');
      return res.status(429).json({
        success: false,
        error: 'Trop de tentatives',
        message: `Vous avez atteint la limite de tentatives. Veuillez réessayer après ${resetTime}.`,
        resetAt: rateLimit.resetAt
      });
    }

    // Envoyer l'OTP
    try {
      const otpResult = await otpService.sendOTP(formattedPhone, channel);
      
      logger.info('OTP envoyé via send-otp endpoint', { 
        phoneNumber: formattedPhone,
        channel
      });

      res.json({
        success: true,
        message: 'Code de vérification envoyé',
        channel: channel,
        expiresIn: otpResult.expiresIn || 600, // 10 minutes par défaut
        code: otpResult.code || null // Seulement en développement
      });
    } catch (otpError) {
      logger.error('Erreur envoi OTP', {
        error: otpError.message,
        phoneNumber: formattedPhone
      });

      res.status(500).json({
        success: false,
        error: 'Erreur lors de l\'envoi du code de vérification',
        message: otpError.message || 'Impossible d\'envoyer le code de vérification. Veuillez réessayer.'
      });
    }
  } catch (error) {
    logger.error('Erreur send-otp:', error);
    res.status(500).json({ 
      success: false,
      error: 'Erreur lors de l\'envoi du code',
      message: error.message
    });
  }
});

module.exports = router;

