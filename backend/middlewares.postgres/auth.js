// Middleware d'authentification avec PostgreSQL
const jwt = require('jsonwebtoken');
const AppDataSource = require('../config/database');
const User = require('../entities/User');

const auth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({ error: 'Token d\'authentification manquant' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: decoded.userId } });

    if (!user) {
      return res.status(401).json({ error: 'Utilisateur non trouvé' });
    }

    req.user = user;
    req.userId = user.id;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token invalide' });
  }
};

const adminAuth = async (req, res, next) => {
  try {
    await auth(req, res, () => {
      if (req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Accès refusé. Rôle admin requis.' });
      }
      next();
    });
  } catch (error) {
    res.status(401).json({ error: 'Authentification requise' });
  }
};

const agentAuth = async (req, res, next) => {
  try {
    await auth(req, res, () => {
      if (req.user.role !== 'agent' && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Accès refusé. Rôle agent ou admin requis.' });
      }
      next();
    });
  } catch (error) {
    res.status(401).json({ error: 'Authentification requise' });
  }
};

module.exports = { auth, adminAuth, agentAuth };

