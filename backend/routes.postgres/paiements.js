// Routes pour les paiements Stripe
const express = require('express');
const { body, validationResult } = require('express-validator');
const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const { auth } = require('../middlewares.postgres/auth');

const router = express.Router();

/**
 * @mvp true
 * @route POST /api/paiements/preauthorize
 * @description Pré-autorise un paiement avec Stripe (utilisé dans MVP)
 * Body:
 * - rideId: ID de la course
 * - stripeToken: Token Stripe généré côté client
 * - amount: Montant à pré-autoriser (optionnel, utilise le prix de la course si non fourni)
 */
router.post('/preauthorize', auth, [
  body('rideId').isInt().withMessage('rideId doit être un entier'),
  body('stripeToken').notEmpty().withMessage('stripeToken est requis'),
  body('amount').optional().isFloat({ min: 0 }).withMessage('amount doit être un nombre positif')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { rideId, stripeToken, amount } = req.body;

    // Vérifier que la course existe et appartient au client
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: parseInt(rideId) },
      relations: ['client']
    });

    if (!ride) {
      return res.status(404).json({
        success: false,
        error: 'Course non trouvée'
      });
    }

    // Vérifier que l'utilisateur est le client de la course
    if (ride.clientId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'Accès refusé : vous n\'êtes pas le client de cette course'
      });
    }

    // Vérifier que la course est terminée ou en cours
    if (!['inProgress', 'completed'].includes(ride.status)) {
      return res.status(400).json({
        success: false,
        error: 'Le paiement ne peut être effectué que pour une course en cours ou terminée'
      });
    }

    // Déterminer le montant
    const paymentAmount = amount || parseFloat(ride.finalPrice || ride.estimatedPrice);

    if (paymentAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Le montant doit être supérieur à 0'
      });
    }

    // IMPORTANT: Ici, vous devriez appeler l'API Stripe pour créer un PaymentIntent
    // Pour l'instant, on simule la création d'un PaymentIntent
    
    // Vérifier si Stripe est configuré
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    
    let paymentIntent;
    let stripeClient;

    if (stripeSecretKey) {
      try {
        // Initialiser Stripe (nécessite: npm install stripe)
        const stripe = require('stripe')(stripeSecretKey);
        stripeClient = stripe;

        // Créer un PaymentIntent avec Stripe
        paymentIntent = await stripe.paymentIntents.create({
          amount: Math.round(paymentAmount * 100), // Convertir en centimes
          currency: process.env.STRIPE_CURRENCY || 'cdf', // CDF pour Franc Congolais
          payment_method: stripeToken,
          confirmation_method: 'manual',
          confirm: false, // Pré-autorisation seulement
          metadata: {
            rideId: ride.id.toString(),
            userId: req.user.id.toString(),
            clientName: req.user.name
          }
        });
      } catch (stripeError) {
        console.error('Erreur Stripe:', stripeError);
        return res.status(500).json({
          success: false,
          error: 'Erreur lors de la communication avec Stripe',
          message: stripeError.message
        });
      }
    } else {
      // Mode simulation (pour le développement)
      console.warn('⚠️ STRIPE_SECRET_KEY non configuré - Mode simulation activé');
      paymentIntent = {
        id: `pi_sim_${Date.now()}`,
        client_secret: `pi_sim_${Date.now()}_secret_${Math.random().toString(36).substring(7)}`,
        status: 'requires_confirmation',
        amount: Math.round(paymentAmount * 100),
        currency: process.env.STRIPE_CURRENCY || 'cdf'
      };
    }

    // Enregistrer la transaction dans la base de données
    const transactionQuery = `
      INSERT INTO stripe_transactions (
        ride_id,
        payment_intent_id,
        amount,
        currency,
        status,
        stripe_token,
        metadata,
        created_at,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
      RETURNING *
    `;

    const transactionResult = await AppDataSource.query(transactionQuery, [
      ride.id,
      paymentIntent.id,
      paymentAmount,
      paymentIntent.currency,
      'pending',
      stripeToken.substring(0, 50), // Stocker seulement les 50 premiers caractères pour référence
      JSON.stringify({
        rideId: ride.id,
        userId: req.user.id,
        clientName: req.user.name
      })
    ]);

    const transaction = transactionResult[0];

    // Mettre à jour la course avec l'ID du PaymentIntent
    ride.stripePaymentIntentId = paymentIntent.id;
    await rideRepository.save(ride);

    // Réponse pour iOS
    res.json({
      success: true,
      paymentIntent: {
        id: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        status: paymentIntent.status,
        amount: paymentAmount,
        currency: paymentIntent.currency
      },
      transaction: {
        id: transaction.id,
        rideId: transaction.ride_id,
        amount: parseFloat(transaction.amount),
        status: transaction.status,
        createdAt: transaction.created_at
      },
      ride: {
        id: ride.id,
        status: ride.status,
        finalPrice: ride.finalPrice ? parseFloat(ride.finalPrice) : null,
        estimatedPrice: parseFloat(ride.estimatedPrice)
      }
    });
  } catch (error) {
    console.error('Erreur pré-autorisation paiement:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la pré-autorisation du paiement',
      message: error.message
    });
  }
});

/**
 * @mvp true
 * @route POST /api/paiements/confirm
 * @description Confirme un paiement pré-autorisé (utilisé dans MVP)
 */
router.post('/confirm', auth, [
  body('paymentIntentId').notEmpty().withMessage('paymentIntentId est requis')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { paymentIntentId } = req.body;

    // Récupérer la transaction
    const transactionQuery = `
      SELECT * FROM stripe_transactions 
      WHERE payment_intent_id = $1
    `;
    const transactions = await AppDataSource.query(transactionQuery, [paymentIntentId]);

    if (transactions.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Transaction non trouvée'
      });
    }

    const transaction = transactions[0];

    // Vérifier les permissions
    const rideRepository = AppDataSource.getRepository(Ride);
    const ride = await rideRepository.findOne({
      where: { id: transaction.ride_id }
    });

    if (!ride || (ride.clientId !== req.user.id && req.user.role !== 'admin')) {
      return res.status(403).json({
        success: false,
        error: 'Accès refusé'
      });
    }

    // Confirmer le paiement avec Stripe
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    
    if (stripeSecretKey) {
      try {
        const stripe = require('stripe')(stripeSecretKey);
        const confirmedIntent = await stripe.paymentIntents.confirm(paymentIntentId);

        // Mettre à jour la transaction
        const updateQuery = `
          UPDATE stripe_transactions
          SET status = $1, updated_at = NOW()
          WHERE payment_intent_id = $2
          RETURNING *
        `;
        const updated = await AppDataSource.query(updateQuery, [
          confirmedIntent.status,
          paymentIntentId
        ]);

        res.json({
          success: true,
          paymentIntent: {
            id: confirmedIntent.id,
            status: confirmedIntent.status,
            amount: parseFloat(transaction.amount)
          },
          transaction: updated[0]
        });
      } catch (stripeError) {
        console.error('Erreur confirmation Stripe:', stripeError);
        return res.status(500).json({
          success: false,
          error: 'Erreur lors de la confirmation du paiement',
          message: stripeError.message
        });
      }
    } else {
      // Mode simulation
      const updateQuery = `
        UPDATE stripe_transactions
        SET status = 'succeeded', updated_at = NOW()
        WHERE payment_intent_id = $1
        RETURNING *
      `;
      const updated = await AppDataSource.query(updateQuery, [paymentIntentId]);

      res.json({
        success: true,
        paymentIntent: {
          id: paymentIntentId,
          status: 'succeeded',
          amount: parseFloat(transaction.amount)
        },
        transaction: updated[0]
      });
    }
  } catch (error) {
    console.error('Erreur confirmation paiement:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la confirmation du paiement',
      message: error.message
    });
  }
});

module.exports = router;

