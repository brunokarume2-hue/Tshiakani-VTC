const express = require('express');
const { body, validationResult } = require('express-validator');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { auth, adminAuth } = require('../middlewares/auth');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Obtenir les notifications de l'utilisateur
router.get('/', auth, async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json(notifications);
  } catch (error) {
    console.error('Erreur récupération notifications:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération' });
  }
});

// Marquer une notification comme lue
router.patch('/:notificationId/read', auth, async (req, res) => {
  try {
    const notification = await Notification.findOne({
      _id: req.params.notificationId,
      userId: req.user._id
    });

    if (!notification) {
      return res.status(404).json({ error: 'Notification non trouvée' });
    }

    notification.isRead = true;
    await notification.save();

    res.json(notification);
  } catch (error) {
    console.error('Erreur mise à jour notification:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Marquer toutes les notifications comme lues
router.patch('/read-all', auth, async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.user._id, isRead: false },
      { isRead: true }
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Erreur mise à jour notifications:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
});

// Envoyer une notification (admin)
router.post('/send', adminAuth, [
  body('userId').optional().isString(),
  body('type').isIn(['ride', 'promotion', 'security', 'system']),
  body('title').trim().notEmpty(),
  body('message').trim().notEmpty(),
  body('rideId').optional().isString()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId, type, title, message, rideId } = req.body;

    // Si userId est spécifié, envoyer à un utilisateur spécifique
    if (userId) {
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }

      // Créer la notification
      const notification = new Notification({
        userId,
        type,
        title,
        message,
        rideId
      });
      await notification.save();

      // Envoyer la notification push
      if (user.fcmToken) {
        await sendNotification(user.fcmToken, {
          title,
          body: message,
          data: { type, rideId: rideId || '' }
        });
      }

      return res.json({ success: true, notification });
    }

    // Sinon, envoyer à tous les utilisateurs
    const users = await User.find();
    const notifications = [];

    for (const user of users) {
      const notification = new Notification({
        userId: user._id,
        type,
        title,
        message,
        rideId
      });
      await notification.save();
      notifications.push(notification);

      // Envoyer la notification push
      if (user.fcmToken) {
        await sendNotification(user.fcmToken, {
          title,
          body: message,
          data: { type, rideId: rideId || '' }
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

