//
//  TransactionService.js
//  Tshiakani VTC
//
//  Service pour gérer les transactions ACID PostgreSQL
//  Assure que les opérations critiques sont atomiques
//

const AppDataSource = require('../config/database');
const Ride = require('../entities/Ride');
const User = require('../entities/User');

/**
 * Service de gestion des transactions ACID
 */
class TransactionService {
  /**
   * Accepte une course avec transaction ACID
   * Met à jour le statut de la course ET le statut du chauffeur en une seule transaction
   * 
   * @param {number} rideId - ID de la course
   * @param {number} driverId - ID du chauffeur
   * @param {Object} driverLocation - Position actuelle du chauffeur {latitude, longitude}
   * @param {Object} pickupLocation - Point de départ {latitude, longitude}
   * @param {number} maxDistanceMeters - Distance maximale autorisée en mètres (défaut: 2000m)
   * @returns {Promise<Object>} Course mise à jour
   */
  static async acceptRideWithTransaction(
    rideId,
    driverId,
    driverLocation,
    pickupLocation,
    maxDistanceMeters = 2000
  ) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const userRepository = queryRunner.manager.getRepository(User);

      // 1. Vérifier que la course existe et est disponible
      const ride = await rideRepository.findOne({ where: { id: rideId } });
      if (!ride) {
        throw new Error('Course non trouvée');
      }
      if (ride.status !== 'pending') {
        throw new Error('Cette course n\'est plus disponible');
      }

      // 2. Vérifier la proximité du chauffeur (géofencing)
      const distanceQuery = `
        SELECT ST_Distance(
          ST_MakePoint($1, $2)::geography,
          ST_MakePoint($3, $4)::geography
        ) AS distance
      `;
      const distanceResult = await queryRunner.manager.query(distanceQuery, [
        driverLocation.longitude,
        driverLocation.latitude,
        pickupLocation.longitude,
        pickupLocation.latitude
      ]);

      const distanceMeters = distanceResult[0].distance;
      if (distanceMeters > maxDistanceMeters) {
        throw new Error(
          `Le chauffeur est trop éloigné du point de départ (${Math.round(distanceMeters)}m > ${maxDistanceMeters}m)`
        );
      }

      // 3. Vérifier que le chauffeur est disponible
      const driver = await userRepository.findOne({ where: { id: driverId } });
      if (!driver) {
        throw new Error('Chauffeur non trouvé');
      }
      if (driver.role !== 'driver') {
        throw new Error('L\'utilisateur n\'est pas un chauffeur');
      }
      if (driver.driverInfo?.isOnline !== true) {
        throw new Error('Le chauffeur n\'est pas en ligne');
      }

      // 4. Mettre à jour la course (dans la transaction)
      ride.driverId = driverId;
      ride.status = 'accepted';
      await rideRepository.save(ride);

      // 5. Mettre à jour le statut du chauffeur (dans la transaction)
      if (!driver.driverInfo) {
        driver.driverInfo = {};
      }
      driver.driverInfo.isOnline = true;
      driver.driverInfo.currentRideId = rideId;
      await userRepository.save(driver);

      // 6. Commit de la transaction
      await queryRunner.commitTransaction();

      return ride;
    } catch (error) {
      // Rollback en cas d'erreur
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      // Libérer la connexion
      await queryRunner.release();
    }
  }

  /**
   * Termine une course avec transaction ACID
   * Met à jour le statut de la course, le statut du chauffeur ET crée la transaction de paiement
   * 
   * @param {number} rideId - ID de la course
   * @param {number} finalPrice - Prix final de la course
   * @param {string} paymentToken - Token de paiement du prestataire (Stripe, etc.)
   * @returns {Promise<Object>} Course terminée et transaction créée
   */
  static async completeRideWithTransaction(rideId, finalPrice, paymentToken) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);

      // 1. Récupérer la course
      const ride = await rideRepository.findOne({
        where: { id: rideId },
        relations: ['driver']
      });

      if (!ride) {
        throw new Error('Course non trouvée');
      }
      if (ride.status === 'completed') {
        throw new Error('Cette course est déjà terminée');
      }

      // 2. Mettre à jour le statut de la course (dans la transaction)
      ride.status = 'completed';
      ride.completedAt = new Date();
      ride.finalPrice = finalPrice;
      await rideRepository.save(ride);

      // 3. Mettre à jour le statut du chauffeur à 'disponible' (dans la transaction)
      if (ride.driverId) {
        const userRepository = queryRunner.manager.getRepository(User);
        const driver = await userRepository.findOne({ where: { id: ride.driverId } });
        
        if (driver && driver.driverInfo) {
          driver.driverInfo.isOnline = true;
          driver.driverInfo.currentRideId = null;
          await userRepository.save(driver);
        }
      }

      // 4. Créer la transaction de paiement (dans la transaction)
      // Note: Assurez-vous que la table 'transactions' existe dans votre schéma
      const transactionQuery = `
        INSERT INTO transactions (course_id, montant_final, token_paiement, statut)
        VALUES ($1, $2, $3, 'charged')
        RETURNING *
      `;
      const transactionResult = await queryRunner.manager.query(transactionQuery, [
        rideId,
        finalPrice,
        paymentToken
      ]);

      // 5. Commit de la transaction
      await queryRunner.commitTransaction();

      return {
        ride,
        transaction: transactionResult[0]
      };
    } catch (error) {
      // Rollback en cas d'erreur
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      // Libérer la connexion
      await queryRunner.release();
    }
  }

  /**
   * Annule une course avec transaction ACID
   * Remet le chauffeur disponible si nécessaire
   * 
   * @param {number} rideId - ID de la course
   * @param {string} reason - Raison de l'annulation
   * @returns {Promise<Object>} Course annulée
   */
  static async cancelRideWithTransaction(rideId, reason) {
    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const rideRepository = queryRunner.manager.getRepository(Ride);
      const userRepository = queryRunner.manager.getRepository(User);

      // 1. Récupérer la course
      const ride = await rideRepository.findOne({ where: { id: rideId } });

      if (!ride) {
        throw new Error('Course non trouvée');
      }
      if (ride.status === 'completed') {
        throw new Error('Impossible d\'annuler une course terminée');
      }
      if (ride.status === 'cancelled') {
        throw new Error('Cette course est déjà annulée');
      }

      // 2. Mettre à jour le statut de la course (dans la transaction)
      ride.status = 'cancelled';
      ride.cancelledAt = new Date();
      ride.cancellationReason = reason;
      await rideRepository.save(ride);

      // 3. Remettre le chauffeur disponible si la course était acceptée (dans la transaction)
      if (ride.driverId && ride.status === 'accepted') {
        const driver = await userRepository.findOne({ where: { id: ride.driverId } });
        if (driver && driver.driverInfo) {
          driver.driverInfo.isOnline = true;
          driver.driverInfo.currentRideId = null;
          await userRepository.save(driver);
        }
      }

      // 4. Commit de la transaction
      await queryRunner.commitTransaction();

      return ride;
    } catch (error) {
      // Rollback en cas d'erreur
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      // Libérer la connexion
      await queryRunner.release();
    }
  }
}

module.exports = TransactionService;

