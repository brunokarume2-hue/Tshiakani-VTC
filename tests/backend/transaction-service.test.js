/**
 * Tests unitaires pour TransactionService
 * 
 * Ce fichier teste les fonctionnalités du service de transaction ACID
 */

const { AppDataSource, createTestUser, createTestRide } = require('./setup');
const TransactionService = require('../../backend/services/TransactionService');
const Ride = require('../../backend/entities/Ride');
const User = require('../../backend/entities/User');

describe('TransactionService', () => {
  let client;
  let driver;

  beforeAll(async () => {
    client = await createTestUser('client');
    driver = await createTestUser('driver', {
      driverInfo: {
        isOnline: true,
        currentRideId: null,
        status: 'available'
      }
    });
  });

  describe('acceptRideWithTransaction', () => {
    test('DEVRAIT accepter une course valide', async () => {
      const ride = await createTestRide(client.id);
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      const updatedRide = await TransactionService.acceptRideWithTransaction(
        ride.id,
        driver.id,
        driverLocation,
        pickupLocation,
        2000
      );

      expect(updatedRide.status).toBe('accepted');
      expect(updatedRide.driverId).toBe(driver.id);
    });

    test('DEVRAIT mettre à jour le statut du chauffeur', async () => {
      const ride = await createTestRide(client.id);
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      await TransactionService.acceptRideWithTransaction(
        ride.id,
        driver.id,
        driverLocation,
        pickupLocation,
        2000
      );

      const userRepository = AppDataSource.getRepository(User);
      const updatedDriver = await userRepository.findOne({ where: { id: driver.id } });
      
      expect(updatedDriver.driverInfo.currentRideId).toBe(ride.id);
    });

    test('DEVRAIT rejeter si la course n\'existe pas', async () => {
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = { latitude: -4.3276, longitude: 15.3156 };

      await expect(
        TransactionService.acceptRideWithTransaction(
          99999, // ID inexistant
          driver.id,
          driverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow('Course non trouvée');
    });

    test('DEVRAIT rejeter si la course n\'est pas en statut "pending"', async () => {
      const ride = await createTestRide(client.id, { status: 'completed' });
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          ride.id,
          driver.id,
          driverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow('Cette course n\'est plus disponible');
    });

    test('DEVRAIT rejeter si le chauffeur est trop éloigné', async () => {
      const ride = await createTestRide(client.id);
      const farDriverLocation = { latitude: -5.0000, longitude: 16.0000 }; // Très loin
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          ride.id,
          driver.id,
          farDriverLocation,
          pickupLocation,
          2000 // 2 km max
        )
      ).rejects.toThrow('Le chauffeur est trop éloigné');
    });

    test('DEVRAIT rejeter si le chauffeur n\'est pas en ligne', async () => {
      const offlineDriver = await createTestUser('driver', {
        driverInfo: {
          isOnline: false,
          currentRideId: null
        }
      });

      const ride = await createTestRide(client.id);
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          ride.id,
          offlineDriver.id,
          driverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow('Le chauffeur n\'est pas en ligne');
    });
  });

  describe('completeRideWithTransaction', () => {
    let acceptedRide;

    beforeEach(async () => {
      // Créer une course acceptée
      acceptedRide = await createTestRide(client.id, {
        status: 'accepted',
        driverId: driver.id
      });
    });

    test('DEVRAIT terminer une course acceptée', async () => {
      const finalPrice = 5500;
      const paymentToken = 'test-token-123';

      const result = await TransactionService.completeRideWithTransaction(
        acceptedRide.id,
        finalPrice,
        paymentToken
      );

      expect(result.ride.status).toBe('completed');
      expect(result.ride.finalPrice).toBe(finalPrice);
      expect(result.ride.completedAt).toBeDefined();
    });

    test('DEVRAIT créer une transaction de paiement', async () => {
      const finalPrice = 5500;
      const paymentToken = 'test-token-456';

      const result = await TransactionService.completeRideWithTransaction(
        acceptedRide.id,
        finalPrice,
        paymentToken
      );

      expect(result.transaction).toBeDefined();
      expect(result.transaction.course_id).toBe(acceptedRide.id);
      expect(result.transaction.montant_final).toBe(finalPrice);
      expect(result.transaction.token_paiement).toBe(paymentToken);
      expect(result.transaction.statut).toBe('charged');
    });

    test('DEVRAIT remettre le chauffeur disponible', async () => {
      // Mettre le chauffeur comme occupé
      const userRepository = AppDataSource.getRepository(User);
      const driverUser = await userRepository.findOne({ where: { id: driver.id } });
      driverUser.driverInfo.currentRideId = acceptedRide.id;
      await userRepository.save(driverUser);

      const finalPrice = 5500;
      const paymentToken = 'test-token-789';

      await TransactionService.completeRideWithTransaction(
        acceptedRide.id,
        finalPrice,
        paymentToken
      );

      const updatedDriver = await userRepository.findOne({ where: { id: driver.id } });
      expect(updatedDriver.driverInfo.currentRideId).toBeNull();
      expect(updatedDriver.driverInfo.isOnline).toBe(true);
    });

    test('NE DEVRAIT PAS terminer une course déjà terminée', async () => {
      const completedRide = await createTestRide(client.id, {
        status: 'completed',
        driverId: driver.id,
        finalPrice: 5000
      });

      await expect(
        TransactionService.completeRideWithTransaction(
          completedRide.id,
          5500,
          'test-token'
        )
      ).rejects.toThrow('Cette course est déjà terminée');
    });

    test('DEVRAIT rejeter si la course n\'existe pas', async () => {
      await expect(
        TransactionService.completeRideWithTransaction(
          99999, // ID inexistant
          5500,
          'test-token'
        )
      ).rejects.toThrow('Course non trouvée');
    });
  });

  describe('cancelRideWithTransaction', () => {
    test('DEVRAIT annuler une course en attente', async () => {
      const ride = await createTestRide(client.id, { status: 'pending' });
      const reason = 'Client a annulé';

      const cancelledRide = await TransactionService.cancelRideWithTransaction(
        ride.id,
        reason
      );

      expect(cancelledRide.status).toBe('cancelled');
      expect(cancelledRide.cancellationReason).toBe(reason);
      expect(cancelledRide.cancelledAt).toBeDefined();
    });

    test('DEVRAIT annuler une course acceptée et libérer le chauffeur', async () => {
      const ride = await createTestRide(client.id, {
        status: 'accepted',
        driverId: driver.id
      });

      // Mettre le chauffeur comme occupé
      const userRepository = AppDataSource.getRepository(User);
      const driverUser = await userRepository.findOne({ where: { id: driver.id } });
      driverUser.driverInfo.currentRideId = ride.id;
      await userRepository.save(driverUser);

      const reason = 'Problème avec le client';
      const cancelledRide = await TransactionService.cancelRideWithTransaction(
        ride.id,
        reason
      );

      expect(cancelledRide.status).toBe('cancelled');

      // Vérifier que le chauffeur est libéré
      const updatedDriver = await userRepository.findOne({ where: { id: driver.id } });
      expect(updatedDriver.driverInfo.currentRideId).toBeNull();
    });

    test('NE DEVRAIT PAS annuler une course déjà terminée', async () => {
      const completedRide = await createTestRide(client.id, {
        status: 'completed',
        driverId: driver.id
      });

      await expect(
        TransactionService.cancelRideWithTransaction(
          completedRide.id,
          'Tentative d\'annulation'
        )
      ).rejects.toThrow('Impossible d\'annuler une course terminée');
    });

    test('NE DEVRAIT PAS annuler une course déjà annulée', async () => {
      const cancelledRide = await createTestRide(client.id, {
        status: 'cancelled'
      });

      await expect(
        TransactionService.cancelRideWithTransaction(
          cancelledRide.id,
          'Tentative d\'annulation'
        )
      ).rejects.toThrow('Cette course est déjà annulée');
    });
  });

  describe('Transactions ACID', () => {
    test('DEVRAIT effectuer un rollback en cas d\'erreur', async () => {
      const ride = await createTestRide(client.id);

      // Essayer d'accepter avec un chauffeur inexistant
      const driverLocation = { latitude: -4.3276, longitude: 15.3156 };
      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          ride.id,
          99999, // ID inexistant
          driverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow();

      // Vérifier que la course n'a pas été modifiée
      const rideRepository = AppDataSource.getRepository(Ride);
      const unchangedRide = await rideRepository.findOne({ where: { id: ride.id } });
      expect(unchangedRide.status).toBe('pending');
      expect(unchangedRide.driverId).toBeNull();
    });
  });
});

