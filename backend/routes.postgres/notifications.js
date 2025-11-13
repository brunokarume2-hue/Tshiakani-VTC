// Routes notifications avec PostgreSQL
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Notification = require('../entities/Notification');
const User = require('../entities/User');
const { auth, adminAuth } = require('../middlewares.postgres/auth');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Obtenir les notifications
router.get('/', auth, async (req, res) => {
  try {
    const notificationRepository = AppDataSource.getRepository(Notification);
    const notifications = await notificationRepository.find({
      where: { userId: req.user.id },
      order: { createdAt: 'DESC' },
      take: 50
    });

    res.json(notifications);
  } catch (error) {
    console.error('Erreur récupération notifications:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Marquer comme lue
router.patch('/:notificationId/read', auth, async (req, res) => {
  try {
    const notificationRepository = AppDataSource.getRepository(Notification);
    const notification = await notificationRepository.findOne({
      where: { 
        id: parseInt(req.params.notificationId),
        userId: req.user.id
      }
    });

    if (!notification) {
      return res.status(404).json({ error: 'Notification non trouvée' });
    }

    notification.isRead = true;
    await notificationRepository.save(notification);

    res.json(notification);
  } catch (error) {
    console.error('Erreur mise à jour notification:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Marquer toutes comme lues
router.patch('/read-all', auth, async (req, res) => {
  try {
    const notificationRepository = AppDataSource.getRepository(Notification);
    await notificationRepository.update(
      { userId: req.user.id, isRead: false },
      { isRead: true }
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Erreur mise à jour notifications:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Obtenir toutes les notifications (admin)
// adminAuth désactivé temporairement
router.get('/all', async (req, res) => {
  try {
    const { limit = 100, type } = req.query;
    const notificationRepository = AppDataSource.getRepository(Notification);
    
    const query = notificationRepository.createQueryBuilder('notification')
      .leftJoinAndSelect('notification.user', 'user')
      .orderBy('notification.createdAt', 'DESC')
      .take(parseInt(limit));

    if (type) {
      query.where('notification.type = :type', { type });
    }

    const notifications = await query.getMany();
    res.json(notifications);
  } catch (error) {
    console.error('Erreur récupération notifications:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Envoyer une notification (admin)
// adminAuth désactivé temporairement
router.post('/send', [
  body('userId').optional().isInt(),
  body('type').isIn(['ride', 'promotion', 'security', 'system']),
  body('title').trim().notEmpty(),
  body('message').trim().notEmpty(),
  body('rideId').optional().isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId, type, title, message, rideId } = req.body;
    const notificationRepository = AppDataSource.getRepository(Notification);
    const userRepository = AppDataSource.getRepository(User);

    if (userId) {
      const user = await userRepository.findOne({ where: { id: userId } });
      if (!user) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }

      const notification = notificationRepository.create({
        userId,
        type,
        title,
        message,
        rideId: rideId ? parseInt(rideId) : null
      });
      await notificationRepository.save(notification);

      if (user.fcmToken) {
        await sendNotification(user.fcmToken, {
          title,
          body: message,
          data: { type, rideId: rideId?.toString() || '' }
        });
      }

      return res.json({ success: true, notification });
    }

    // Envoyer à tous les utilisateurs
    const users = await userRepository.find();
    const notifications = [];

    for (const user of users) {
      const notification = notificationRepository.create({
        userId: user.id,
        type,
        title,
        message,
        rideId: rideId ? parseInt(rideId) : null
      });
      await notificationRepository.save(notification);
      notifications.push(notification);

      if (user.fcmToken) {
        await sendNotification(user.fcmToken, {
          title,
          body: message,
          data: { type, rideId: rideId?.toString() || '' }
        });
      }
    }

    res.json({ success: true, count: notifications.length });
  } catch (error) {
    console.error('Erreur envoi notification:', error);
    res.status(500).json({ error: 'Erreur lors de l\'envoi' });
  }
});

module.exports = router;

