//
//  PaymentService.js
//  Tshiakani VTC
//
//  Service de paiement sécurisé avec tokens
//  L'API ne reçoit jamais de mot de passe ou d'information bancaire
//  Utilise uniquement des tokens de paiement générés côté client
//

const AppDataSource = require('../config/database');
const logger = require('../utils/logger');
const { getCloudLoggingService } = require('../utils/cloud-logging');
const { getCloudMonitoringService } = require('../utils/cloud-monitoring');

/**
 * Service de gestion des paiements sécurisés
 */
class PaymentService {
  /**
   * Valide un token de paiement
   * Le token doit être généré côté client par le prestataire (Stripe, etc.)
   * L'API ne stocke jamais d'informations bancaires
   * 
   * @param {string} paymentToken - Token de paiement du prestataire
   * @param {number} amount - Montant à valider
   * @returns {Promise<boolean>} True si le token est valide
   */
  static async validatePaymentToken(paymentToken, amount) {
    // IMPORTANT: Cette fonction doit être adaptée selon votre prestataire de paiement
    // Exemple avec Stripe (nécessite le SDK Stripe)
    
    try {
      // Vérifier que le token existe et n'est pas vide
      if (!paymentToken || typeof paymentToken !== 'string' || paymentToken.trim().length === 0) {
        throw new Error('Token de paiement invalide ou manquant');
      }

      // Vérifier le format du token (exemple: tokens Stripe commencent par "tok_")
      // Adaptez selon votre prestataire
      if (!paymentToken.startsWith('tok_') && !paymentToken.startsWith('pm_')) {
        // Pour d'autres prestataires, ajustez la validation
        console.warn('Format de token non standard:', paymentToken.substring(0, 10));
      }

      // Ici, vous devriez appeler l'API du prestataire pour valider le token
      // Exemple avec Stripe (décommentez et configurez si vous utilisez Stripe):
      /*
      const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
      try {
        const paymentMethod = await stripe.paymentMethods.retrieve(paymentToken);
        // Vérifier que le montant est cohérent
        // Vérifier que le token n'a pas été utilisé
        return true;
      } catch (stripeError) {
        throw new Error('Token de paiement invalide ou expiré');
      }
      */

      // Pour l'instant, validation basique (à remplacer par la vraie validation)
      return true;
    } catch (error) {
      // Enregistrer l'erreur dans Cloud Logging et Monitoring
      const cloudLogging = getCloudLoggingService();
      const cloudMonitoring = getCloudMonitoringService();
      
      await cloudLogging.logPaymentError({
        rideId: null,
        amount: amount || 0,
        currency: 'CDF',
        method: 'unknown'
      }, error);
      
      await cloudMonitoring.recordPaymentEvent('failure', amount || 0, 'CDF');
      await cloudMonitoring.recordError('payment_error', error.message);
      
      logger.error('Erreur validation token paiement', {
        error: error.message,
        stack: error.stack
      });
      throw error;
    }
  }

  /**
   * Traite un paiement avec un token
   * Crée la transaction dans la base de données après validation du token
   * 
   * @param {number} rideId - ID de la course
   * @param {number} amount - Montant à charger
   * @param {string} paymentToken - Token de paiement du prestataire
   * @returns {Promise<Object>} Transaction créée
   */
  static async processPayment(rideId, amount, paymentToken) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Valider le token de paiement
      await this.validatePaymentToken(paymentToken, amount);

      // 2. Vérifier que la course existe et est terminée
      const Ride = require('../entities/Ride');
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const ride = await rideRepository.findOne({ where: { id: rideId } });

      if (!ride) {
        throw new Error('Course non trouvée');
      }
      if (ride.status !== 'completed') {
        throw new Error('La course doit être terminée avant le paiement');
      }

      // 3. Vérifier qu'une transaction n'existe pas déjà (contrainte UNIQUE)
      const existingTransactionQuery = `
        SELECT id FROM transactions WHERE course_id = $1
      `;
      const existingTransaction = await queryRunner.manager.query(
        existingTransactionQuery,
        [rideId]
      );

      if (existingTransaction.length > 0) {
        throw new Error('Une transaction existe déjà pour cette course');
      }

      // 4. Ici, vous devriez appeler l'API du prestataire pour charger le paiement
      // Exemple avec Stripe (décommentez et configurez si vous utilisez Stripe):
      /*
      const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
      const charge = await stripe.charges.create({
        amount: Math.round(amount * 100), // Convertir en centimes
        currency: 'cdf', // ou 'usd' selon votre devise
        source: paymentToken,
        description: `Paiement course #${rideId}`
      });
      */

      // 5. Créer la transaction dans la base de données (dans la transaction)
      const transactionQuery = `
        INSERT INTO transactions (course_id, montant_final, token_paiement, statut)
        VALUES ($1, $2, $3, 'charged')
        RETURNING *
      `;
      const transactionResult = await queryRunner.manager.query(transactionQuery, [
        rideId,
        amount,
        paymentToken
      ]);

      // 6. Commit de la transaction
      await queryRunner.commitTransaction();

      // Enregistrer le succès du paiement
      const cloudMonitoring = getCloudMonitoringService();
      await cloudMonitoring.recordPaymentEvent('success', amount, 'CDF');
      
      logger.info('Paiement traité avec succès', {
        rideId,
        amount,
        transactionId: transactionResult[0].id
      });
      
      return transactionResult[0];
    } catch (error) {
      // Rollback en cas d'erreur
      await queryRunner.rollbackTransaction();
      
      // Enregistrer l'erreur dans Cloud Logging et Monitoring
      const cloudLogging = getCloudLoggingService();
      const cloudMonitoring = getCloudMonitoringService();
      
      await cloudLogging.logPaymentError({
        rideId,
        amount,
        currency: 'CDF',
        method: 'unknown'
      }, error);
      
      await cloudMonitoring.recordPaymentEvent('failure', amount, 'CDF');
      await cloudMonitoring.recordError('payment_error', error.message);
      
      logger.error('Erreur traitement paiement', {
        error: error.message,
        stack: error.stack,
        rideId,
        amount
      });
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Rembourse un paiement
   * 
   * @param {number} transactionId - ID de la transaction
   * @param {string} reason - Raison du remboursement
   * @returns {Promise<Object>} Transaction remboursée
   */
  static async refundPayment(transactionId, reason) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Récupérer la transaction
      const transactionQuery = `
        SELECT * FROM transactions WHERE id = $1
      `;
      const transactionResult = await queryRunner.manager.query(transactionQuery, [
        transactionId
      ]);

      if (transactionResult.length === 0) {
        throw new Error('Transaction non trouvée');
      }

      const transaction = transactionResult[0];

      if (transaction.statut !== 'charged') {
        throw new Error('Seules les transactions chargées peuvent être remboursées');
      }

      // 2. Appeler l'API du prestataire pour le remboursement
      // Exemple avec Stripe (décommentez et configurez si vous utilisez Stripe):
      /*
      const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
      const refund = await stripe.refunds.create({
        charge: transaction.token_paiement,
        amount: Math.round(transaction.montant_final * 100),
        reason: reason
      });
      */

      // 3. Mettre à jour le statut de la transaction (dans la transaction)
      const updateQuery = `
        UPDATE transactions 
        SET statut = 'refunded'
        WHERE id = $1
        RETURNING *
      `;
      const updatedResult = await queryRunner.manager.query(updateQuery, [transactionId]);

      // 4. Commit de la transaction
      await queryRunner.commitTransaction();

      // Enregistrer le remboursement
      const cloudMonitoring = getCloudMonitoringService();
      await cloudMonitoring.recordPaymentEvent('refund', transaction.montant_final, 'CDF');
      
      logger.info('Paiement remboursé avec succès', {
        transactionId,
        amount: transaction.montant_final,
        reason
      });
      
      return updatedResult[0];
    } catch (error) {
      // Rollback en cas d'erreur
      await queryRunner.rollbackTransaction();
      
      // Enregistrer l'erreur
      const cloudLogging = getCloudLoggingService();
      const cloudMonitoring = getCloudMonitoringService();
      
      await cloudLogging.error('Erreur remboursement paiement', {
        error: error.message,
        stack: error.stack,
        transactionId,
        reason
      });
      
      await cloudMonitoring.recordError('payment_refund_error', error.message);
      
      logger.error('Erreur remboursement paiement', {
        error: error.message,
        stack: error.stack,
        transactionId
      });
      throw error;
    } finally {
      await queryRunner.release();
    }
  }
}

module.exports = PaymentService;

