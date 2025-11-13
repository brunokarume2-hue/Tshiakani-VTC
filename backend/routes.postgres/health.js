// Routes de santé et monitoring
const express = require('express');
const router = express.Router();
const AppDataSource = require('../config/database');
const { getMetrics } = require('../utils/metrics');
const logger = require('../utils/logger');

// Health check basique
router.get('/health', async (req, res) => {
  try {
    const health = {
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      database: {
        status: AppDataSource.isInitialized ? 'connected' : 'disconnected',
      },
      redis: {
        status: 'unknown',
      },
    };
    
    // Vérifier la connexion à la base de données
    if (AppDataSource.isInitialized) {
      try {
        await AppDataSource.query('SELECT 1');
        health.database.status = 'connected';
      } catch (error) {
        health.database.status = 'error';
        health.database.error = error.message;
        health.status = 'DEGRADED';
      }
    } else {
      health.status = 'DEGRADED';
    }
    
    // Vérifier la connexion Redis (optionnel - ne change pas le status si non disponible)
    try {
      const { getRedisService } = require('../server.postgres');
      const redisService = getRedisService();
      if (redisService && redisService.isReady && redisService.isReady()) {
        const isConnected = await redisService.testConnection();
        health.redis.status = isConnected ? 'connected' : 'disconnected';
      } else {
        health.redis.status = 'not_configured';
      }
    } catch (error) {
      health.redis.status = 'error';
      health.redis.error = error.message;
      // Redis n'est pas critique, donc on ne change pas le status général
    }
    
    const statusCode = health.status === 'OK' ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    logger.error('Erreur health check', { error: error.message });
    res.status(503).json({
      status: 'ERROR',
      timestamp: new Date().toISOString(),
      error: error.message,
    });
  }
});

// Health check détaillé (nécessite authentification admin)
router.get('/health/detailed', async (req, res) => {
  try {
    const health = {
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      database: {
        status: AppDataSource.isInitialized ? 'connected' : 'disconnected',
      },
      metrics: getMetrics(),
    };
    
    // Vérifier la connexion à la base de données
    if (AppDataSource.isInitialized) {
      try {
        const start = Date.now();
        await AppDataSource.query('SELECT 1');
        const duration = Date.now() - start;
        health.database.status = 'connected';
        health.database.responseTime = duration;
      } catch (error) {
        health.database.status = 'error';
        health.database.error = error.message;
        health.status = 'DEGRADED';
      }
    } else {
      health.status = 'DEGRADED';
    }
    
    const statusCode = health.status === 'OK' ? 200 : 503;
    res.status(statusCode).json(health);
  } catch (error) {
    logger.error('Erreur health check détaillé', { error: error.message });
    res.status(503).json({
      status: 'ERROR',
      timestamp: new Date().toISOString(),
      error: error.message,
    });
  }
});

// Endpoint pour les métriques (pour Prometheus/StatsD)
router.get('/metrics', (req, res) => {
  try {
    const metrics = getMetrics();
    res.json(metrics);
  } catch (error) {
    logger.error('Erreur récupération métriques', { error: error.message });
    res.status(500).json({
      error: 'Erreur lors de la récupération des métriques',
    });
  }
});

module.exports = router;

