// Routes Chat avec PostgreSQL
const express = require('express');
const { body, validationResult, param } = require('express-validator');
const AppDataSource = require('../config/database');
const ChatMessage = require('../entities/ChatMessage');
const Ride = require('../entities/Ride');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { io, clientNamespace, driverNamespace } = require('../server.postgres');

const router = express.Router();

// Récupérer les messages d'une course
router.get('/:rideId/messages', auth, [
  param('rideId').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { rideId } = req.params;
    const rideRepository = AppDataSource.getRepository(Ride);
    const chatMessageRepository = AppDataSource.getRepository(ChatMessage);

    // Vérifier que l'utilisateur a accès à cette course
    const ride = await rideRepository.findOne({
      where: { id: parseInt(rideId) }
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que l'utilisateur est le client ou le conducteur
    if (ride.clientId !== req.user.id && ride.driverId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Récupérer les messages
    const messages = await chatMessageRepository.find({
      where: { rideId: parseInt(rideId) },
      order: { createdAt: 'ASC' }
    });

    // Formater les messages
    const formattedMessages = messages.map(msg => ({
      id: msg.id.toString(),
      message: msg.message,
      senderId: msg.senderId.toString(),
      senderName: msg.senderName,
      timestamp: msg.createdAt.toISOString(),
      isFromDriver: msg.isFromDriver,
      isRead: msg.isRead
    }));

    res.json({
      success: true,
      messages: formattedMessages
    });
  } catch (error) {
    console.error('Erreur récupération messages chat:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des messages' });
  }
});

// Envoyer un message
router.post('/:rideId/messages', auth, [
  param('rideId').isInt(),
  body('message').notEmpty().trim().isLength({ min: 1, max: 1000 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { rideId } = req.params;
    const { message } = req.body;
    const rideRepository = AppDataSource.getRepository(Ride);
    const chatMessageRepository = AppDataSource.getRepository(ChatMessage);
    const userRepository = AppDataSource.getRepository(User);

    // Vérifier que l'utilisateur a accès à cette course
    const ride = await rideRepository.findOne({
      where: { id: parseInt(rideId) },
      relations: ['client', 'driver']
    });

    if (!ride) {
      return res.status(404).json({ error: 'Course non trouvée' });
    }

    // Vérifier que l'utilisateur est le client ou le conducteur
    if (ride.clientId !== req.user.id && ride.driverId !== req.user.id) {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Déterminer si le message vient du conducteur
    const isFromDriver = ride.driverId === req.user.id;

    // Créer le message
    const chatMessage = chatMessageRepository.create({
      rideId: parseInt(rideId),
      senderId: req.user.id,
      senderName: req.user.name || 'Utilisateur',
      message: message,
      isFromDriver: isFromDriver,
      isRead: false
    });

    await chatMessageRepository.save(chatMessage);

    // Formater le message pour l'émettre
    const formattedMessage = {
      id: chatMessage.id.toString(),
      message: chatMessage.message,
      senderId: chatMessage.senderId.toString(),
      senderName: chatMessage.senderName,
      timestamp: chatMessage.createdAt.toISOString(),
      isFromDriver: chatMessage.isFromDriver,
      isRead: chatMessage.isRead
    };

    // Émettre le message via Socket.io
    try {
      if (isFromDriver) {
        // Le conducteur envoie, le client reçoit
        // Envoyer à la room de la course pour que le client reçoive
        if (clientNamespace) {
          clientNamespace.to(`ride:${rideId}`).emit('chat:message', {
            rideId: rideId,
            message: formattedMessage
          });
        }
        // Également envoyer via io global pour compatibilité
        if (io) {
          io.to(`ride:${rideId}`).emit('chat:message', {
            rideId: rideId,
            message: formattedMessage
          });
        }
      } else {
        // Le client envoie, le conducteur reçoit
        // Envoyer à la room de la course pour que le conducteur reçoive
        if (driverNamespace) {
          driverNamespace.to(`ride:${rideId}`).emit('chat:message', {
            rideId: rideId,
            message: formattedMessage
          });
        }
        // Également envoyer via io global pour compatibilité
        if (io) {
          io.to(`ride:${rideId}`).emit('chat:message', {
            rideId: rideId,
            message: formattedMessage
          });
        }
      }
    } catch (error) {
      console.error('Erreur lors de l\'émission du message via Socket.io:', error);
      // Continuer même si l'émission Socket.io échoue
    }

    res.status(201).json({
      success: true,
      message: formattedMessage
    });
  } catch (error) {
    console.error('Erreur envoi message chat:', error);
    res.status(500).json({ error: 'Erreur lors de l\'envoi du message' });
  }
});

// Marquer un message comme lu
router.put('/messages/:messageId/read', auth, [
  param('messageId').isInt()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { messageId } = req.params;
    const chatMessageRepository = AppDataSource.getRepository(ChatMessage);

    const chatMessage = await chatMessageRepository.findOne({
      where: { id: parseInt(messageId) },
      relations: ['ride']
    });

    if (!chatMessage) {
      return res.status(404).json({ error: 'Message non trouvé' });
    }

    // Vérifier que l'utilisateur a accès à cette course
    if (chatMessage.ride.clientId !== req.user.id && 
        chatMessage.ride.driverId !== req.user.id && 
        req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Ne marquer comme lu que si le message n'est pas de l'utilisateur
    if (chatMessage.senderId !== req.user.id) {
      chatMessage.isRead = true;
      chatMessage.readAt = new Date();
      await chatMessageRepository.save(chatMessage);
    }

    res.json({
      success: true,
      message: 'Message marqué comme lu'
    });
  } catch (error) {
    console.error('Erreur marquage message comme lu:', error);
    res.status(500).json({ error: 'Erreur lors du marquage du message' });
  }
});

module.exports = router;

