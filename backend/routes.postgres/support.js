// Routes Support avec PostgreSQL
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const SupportMessage = require('../entities/SupportMessage');
const SupportTicket = require('../entities/SupportTicket');
const User = require('../entities/User');
const { auth } = require('../middlewares.postgres/auth');
const { sendNotification } = require('../utils/notifications');

const router = express.Router();

// Envoyer un message de support
router.post('/message', auth, [
  body('message').notEmpty().trim().isLength({ min: 1, max: 5000 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { message } = req.body;
    const supportMessageRepository = AppDataSource.getRepository(SupportMessage);

    const supportMessage = supportMessageRepository.create({
      userId: req.user.id,
      message: message,
      isFromUser: true
    });

    await supportMessageRepository.save(supportMessage);

    // Notifier les admins
    const userRepository = AppDataSource.getRepository(User);
    const admins = await userRepository.find({ where: { role: 'admin' } });
    
    for (const admin of admins) {
      if (admin.fcmToken) {
        await sendNotification(admin.fcmToken, {
          title: 'Nouveau message de support',
          body: `${req.user.name} a envoyé un message`,
          data: {
            type: 'support_message',
            messageId: supportMessage.id.toString(),
            userId: req.user.id.toString()
          }
        });
      }
    }

    res.status(201).json({
      success: true,
      supportMessage: {
        id: supportMessage.id.toString(),
        message: supportMessage.message,
        isFromUser: supportMessage.isFromUser,
        timestamp: supportMessage.createdAt.toISOString()
      },
      message: 'Message envoyé avec succès'
    });
  } catch (error) {
    console.error('Erreur envoi message support:', error);
    res.status(500).json({ error: 'Erreur lors de l\'envoi du message' });
  }
});

// Récupérer les messages de support
router.get('/messages', auth, async (req, res) => {
  try {
    const supportMessageRepository = AppDataSource.getRepository(SupportMessage);
    
    const messages = await supportMessageRepository.find({
      where: { userId: req.user.id },
      order: { createdAt: 'ASC' }
    });

    // Formater les messages pour la réponse
    const formattedMessages = messages.map(msg => ({
      id: msg.id.toString(),
      message: msg.message,
      isFromUser: msg.isFromUser,
      timestamp: msg.createdAt.toISOString()
    }));

    res.json({
      success: true,
      messages: formattedMessages
    });
  } catch (error) {
    console.error('Erreur récupération messages support:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des messages' });
  }
});

// Créer un ticket de support
router.post('/ticket', auth, [
  body('subject').notEmpty().trim().isLength({ min: 1, max: 255 }),
  body('message').notEmpty().trim().isLength({ min: 1, max: 5000 }),
  body('category').optional().trim().isLength({ max: 100 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { subject, message, category } = req.body;
    const supportTicketRepository = AppDataSource.getRepository(SupportTicket);

    const supportTicket = supportTicketRepository.create({
      userId: req.user.id,
      subject: subject,
      message: message,
      category: category || 'general',
      status: 'open',
      priority: 'normal'
    });

    await supportTicketRepository.save(supportTicket);

    // Notifier les admins
    const userRepository = AppDataSource.getRepository(User);
    const admins = await userRepository.find({ where: { role: 'admin' } });
    
    for (const admin of admins) {
      if (admin.fcmToken) {
        await sendNotification(admin.fcmToken, {
          title: 'Nouveau ticket de support',
          body: `${req.user.name} a créé un ticket: ${subject}`,
          data: {
            type: 'support_ticket',
            ticketId: supportTicket.id.toString(),
            userId: req.user.id.toString()
          }
        });
      }
    }

    res.status(201).json({
      success: true,
      ticket: {
        id: supportTicket.id.toString(),
        subject: supportTicket.subject,
        message: supportTicket.message,
        category: supportTicket.category,
        status: supportTicket.status,
        createdAt: supportTicket.createdAt.toISOString(),
        updatedAt: supportTicket.updatedAt.toISOString()
      }
    });
  } catch (error) {
    console.error('Erreur création ticket support:', error);
    res.status(500).json({ error: 'Erreur lors de la création du ticket' });
  }
});

// Récupérer les tickets de support
router.get('/tickets', auth, async (req, res) => {
  try {
    const { status } = req.query;
    const supportTicketRepository = AppDataSource.getRepository(SupportTicket);
    
    const queryBuilder = supportTicketRepository.createQueryBuilder('ticket')
      .where('ticket.userId = :userId', { userId: req.user.id })
      .orderBy('ticket.createdAt', 'DESC');

    if (status) {
      queryBuilder.andWhere('ticket.status = :status', { status });
    }

    const tickets = await queryBuilder.getMany();

    res.json({
      success: true,
      tickets: tickets
    });
  } catch (error) {
    console.error('Erreur récupération tickets support:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des tickets' });
  }
});

// Signaler un problème
router.post('/report', auth, [
  body('description').notEmpty().trim().isLength({ min: 1, max: 5000 }),
  body('category').optional().trim().isLength({ max: 100 })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { description, category } = req.body;
    const supportTicketRepository = AppDataSource.getRepository(SupportTicket);

    const supportTicket = supportTicketRepository.create({
      userId: req.user.id,
      subject: `Rapport de problème - ${category || 'General'}`,
      message: description,
      category: category || 'problem',
      status: 'open',
      priority: 'high'
    });

    await supportTicketRepository.save(supportTicket);

    // Notifier les admins
    const userRepository = AppDataSource.getRepository(User);
    const admins = await userRepository.find({ where: { role: 'admin' } });
    
    for (const admin of admins) {
      if (admin.fcmToken) {
        await sendNotification(admin.fcmToken, {
          title: '🚨 Rapport de problème',
          body: `${req.user.name} a signalé un problème`,
          data: {
            type: 'problem_report',
            ticketId: supportTicket.id.toString(),
            userId: req.user.id.toString()
          }
        });
      }
    }

    res.status(201).json({
      success: true,
      ticket: supportTicket,
      message: 'Problème signalé avec succès'
    });
  } catch (error) {
    console.error('Erreur signalement problème:', error);
    res.status(500).json({ error: 'Erreur lors du signalement du problème' });
  }
});

// Récupérer la FAQ
router.get('/faq', async (req, res) => {
  try {
    // FAQ statique pour l'instant
    const faqItems = [
      {
        id: '1',
        question: 'Comment commander une course ?',
        answer: 'Pour commander une course, ouvrez l\'application, entrez votre destination, sélectionnez votre point de départ, et confirmez votre réservation.'
      },
      {
        id: '2',
        question: 'Quels sont les moyens de paiement acceptés ?',
        answer: 'Nous acceptons les paiements en espèces, mobile money (Orange Money, M-Pesa, Airtel Money), et les cartes bancaires via Stripe.'
      },
      {
        id: '3',
        question: 'Comment annuler une course ?',
        answer: 'Vous pouvez annuler une course depuis l\'écran de suivi en appuyant sur le bouton "Annuler". Les frais d\'annulation peuvent s\'appliquer selon le moment de l\'annulation.'
      },
      {
        id: '4',
        question: 'Comment contacter un conducteur ?',
        answer: 'Vous pouvez appeler le conducteur directement depuis l\'application en appuyant sur le bouton d\'appel dans l\'écran de suivi de course.'
      },
      {
        id: '5',
        question: 'Comment évaluer un conducteur ?',
        answer: 'Après la fin de votre course, vous pouvez évaluer le conducteur en donnant une note de 1 à 5 étoiles et en laissant un commentaire optionnel.'
      }
    ];

    res.json({
      success: true,
      faq: faqItems
    });
  } catch (error) {
    console.error('Erreur récupération FAQ:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de la FAQ' });
  }
});

module.exports = router;

