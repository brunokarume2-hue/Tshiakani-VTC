/**
 * Tests End-to-End du cycle complet d'une course
 * 
 * Ce fichier teste le cycle complet d'une course :
 * 1. Le client demande une course
 * 2. Un chauffeur reçoit et accepte
 * 3. La course démarre, se termine, puis est payée
 * 4. Le backend met à jour les statuts correctement
 */

const request = require('supertest');
const { AppDataSource, createTestUser, createTestRide, getTestToken } = require('./setup');
const TransactionService = require('../../backend/services/TransactionService');
const Ride = require('../../backend/entities/Ride');
const User = require('../../backend/entities/User');

// Mock de l'app Express (vous devrez adapter selon votre structure)
// Pour l'instant, on teste directement les services
describe('Cycle Complet d\'une Course', () => {
  let client;
  let driver;
  let ride;
  let clientToken;
  let driverToken;

  // Configuration avant tous les tests
  beforeAll(async () => {
    // Créer un client de test
    client = await createTestUser('client', {
      name: 'Client Test',
      phoneNumber: '+243900000001'
    });

    // Créer un chauffeur de test
    driver = await createTestUser('driver', {
      name: 'Chauffeur Test',
      phoneNumber: '+243900000002',
      driverInfo: {
        isOnline: true,
        currentRideId: null,
        status: 'available',
        currentLocation: {
          type: 'Point',
          coordinates: [15.3156, -4.3276] // Kinshasa, près du point de départ
        }
      }
    });

    // Générer les tokens JWT
    clientToken = getTestToken(client.id, 'client');
    driverToken = getTestToken(driver.id, 'driver');
  });

  describe('Étape 1: Demande de Course par le Client', () => {
    test('DEVRAIT créer une course avec le statut "pending"', async () => {
      ride = await createTestRide(client.id, {
        pickupLocation: {
          type: 'Point',
          coordinates: [15.3156, -4.3276] // Kinshasa
        },
        dropoffLocation: {
          type: 'Point',
          coordinates: [15.3256, -4.3376] // Kinshasa
        },
        estimatedPrice: 5000,
        distance: 2.5,
        status: 'pending'
      });

      expect(ride).toBeDefined();
      expect(ride.id).toBeDefined();
      expect(ride.clientId).toBe(client.id);
      expect(ride.status).toBe('pending');
      expect(ride.driverId).toBeNull();
      expect(ride.estimatedPrice).toBe(5000);
    });

    test('DEVRAIT avoir des coordonnées valides pour le point de départ', () => {
      expect(ride.pickupLocation).toBeDefined();
      expect(ride.pickupLocation.type).toBe('Point');
      expect(ride.pickupLocation.coordinates).toHaveLength(2);
      expect(ride.pickupLocation.coordinates[0]).toBeCloseTo(15.3156, 4);
      expect(ride.pickupLocation.coordinates[1]).toBeCloseTo(-4.3276, 4);
    });

    test('DEVRAIT avoir des coordonnées valides pour le point d\'arrivée', () => {
      expect(ride.dropoffLocation).toBeDefined();
      expect(ride.dropoffLocation.type).toBe('Point');
      expect(ride.dropoffLocation.coordinates).toHaveLength(2);
    });
  });

  describe('Étape 2: Acceptation par le Chauffeur', () => {
    test('DEVRAIT accepter la course avec transaction ACID', async () => {
      const driverLocation = {
        latitude: -4.3276,
        longitude: 15.3156
      };

      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      // Accepter la course via le service de transaction
      const updatedRide = await TransactionService.acceptRideWithTransaction(
        ride.id,
        driver.id,
        driverLocation,
        pickupLocation,
        2000 // Distance maximale: 2000m
      );

      expect(updatedRide).toBeDefined();
      expect(updatedRide.id).toBe(ride.id);
      expect(updatedRide.status).toBe('accepted');
      expect(updatedRide.driverId).toBe(driver.id);

      // Vérifier que le chauffeur a été mis à jour
      const userRepository = AppDataSource.getRepository(User);
      const updatedDriver = await userRepository.findOne({ where: { id: driver.id } });
      
      expect(updatedDriver.driverInfo).toBeDefined();
      expect(updatedDriver.driverInfo.currentRideId).toBe(ride.id);
      expect(updatedDriver.driverInfo.isOnline).toBe(true);

      // Mettre à jour la variable ride pour les tests suivants
      ride = updatedRide;
    });

    test('NE DEVRAIT PAS accepter si le chauffeur est trop éloigné', async () => {
      // Créer une nouvelle course
      const newRide = await createTestRide(client.id);

      const farDriverLocation = {
        latitude: -4.5000, // Très loin
        longitude: 15.5000
      };

      const pickupLocation = {
        latitude: newRide.pickupLocation.coordinates[1],
        longitude: newRide.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          newRide.id,
          driver.id,
          farDriverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow('Le chauffeur est trop éloigné');
    });

    test('NE DEVRAIT PAS accepter une course déjà acceptée', async () => {
      const driverLocation = {
        latitude: -4.3276,
        longitude: 15.3156
      };

      const pickupLocation = {
        latitude: ride.pickupLocation.coordinates[1],
        longitude: ride.pickupLocation.coordinates[0]
      };

      // Essayer d'accepter une course déjà acceptée
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
  });

  describe('Étape 3: Démarrage de la Course', () => {
    test('DEVRAIT mettre à jour le statut à "driverArriving"', async () => {
      const rideRepository = AppDataSource.getRepository(Ride);
      ride.status = 'driverArriving';
      await rideRepository.save(ride);

      const updatedRide = await rideRepository.findOne({ where: { id: ride.id } });
      expect(updatedRide.status).toBe('driverArriving');
    });

    test('DEVRAIT mettre à jour le statut à "inProgress"', async () => {
      const rideRepository = AppDataSource.getRepository(Ride);
      ride.status = 'inProgress';
      ride.startedAt = new Date();
      await rideRepository.save(ride);

      const updatedRide = await rideRepository.findOne({ where: { id: ride.id } });
      expect(updatedRide.status).toBe('inProgress');
      expect(updatedRide.startedAt).toBeDefined();
    });
  });

  describe('Étape 4: Fin de Course et Paiement', () => {
    test('DEVRAIT terminer la course avec transaction ACID', async () => {
      const finalPrice = 5500; // Prix final (peut différer du prix estimé)
      const paymentToken = 'test-payment-token-12345';

      const result = await TransactionService.completeRideWithTransaction(
        ride.id,
        finalPrice,
        paymentToken
      );

      expect(result).toBeDefined();
      expect(result.ride).toBeDefined();
      expect(result.ride.id).toBe(ride.id);
      expect(result.ride.status).toBe('completed');
      expect(result.ride.finalPrice).toBe(finalPrice);
      expect(result.ride.completedAt).toBeDefined();

      // Vérifier que la transaction de paiement a été créée
      expect(result.transaction).toBeDefined();
      expect(result.transaction.course_id).toBe(ride.id);
      expect(result.transaction.montant_final).toBe(finalPrice);
      expect(result.transaction.token_paiement).toBe(paymentToken);
      expect(result.transaction.statut).toBe('charged');

      // Vérifier que le chauffeur est maintenant disponible
      const userRepository = AppDataSource.getRepository(User);
      const updatedDriver = await userRepository.findOne({ where: { id: driver.id } });
      
      expect(updatedDriver.driverInfo).toBeDefined();
      expect(updatedDriver.driverInfo.currentRideId).toBeNull();
      expect(updatedDriver.driverInfo.isOnline).toBe(true);

      // Mettre à jour la variable ride
      ride = result.ride;
    });

    test('NE DEVRAIT PAS terminer une course déjà terminée', async () => {
      const finalPrice = 5500;
      const paymentToken = 'test-payment-token-67890';

      await expect(
        TransactionService.completeRideWithTransaction(
          ride.id,
          finalPrice,
          paymentToken
        )
      ).rejects.toThrow('Cette course est déjà terminée');
    });
  });

  describe('Validation des Statuts', () => {
    test('DEVRAIT avoir suivi la séquence de statuts correcte', async () => {
      // Vérifier l'historique des statuts
      // Note: Vous pourriez vouloir ajouter un système de log d'historique
      const rideRepository = AppDataSource.getRepository(Ride);
      const finalRide = await rideRepository.findOne({ where: { id: ride.id } });

      expect(finalRide.status).toBe('completed');
      expect(finalRide.driverId).toBe(driver.id);
      expect(finalRide.clientId).toBe(client.id);
      expect(finalRide.finalPrice).toBeDefined();
      expect(finalRide.completedAt).toBeDefined();
    });

    test('DEVRAIT avoir un prix final défini après complétion', () => {
      expect(ride.finalPrice).toBeDefined();
      expect(ride.finalPrice).toBeGreaterThan(0);
    });

    test('DEVRAIT avoir des timestamps corrects', () => {
      expect(ride.startedAt).toBeDefined();
      expect(ride.completedAt).toBeDefined();
      expect(new Date(ride.completedAt)).toBeInstanceOf(Date);
      expect(new Date(ride.completedAt).getTime()).toBeGreaterThan(
        new Date(ride.startedAt).getTime()
      );
    });
  });

  describe('Tests de Robustesse', () => {
    test('DEVRAIT gérer les erreurs de transaction avec rollback', async () => {
      // Créer une nouvelle course
      const testRide = await createTestRide(client.id);

      // Simuler une erreur en passant un ID de chauffeur invalide
      const driverLocation = {
        latitude: -4.3276,
        longitude: 15.3156
      };

      const pickupLocation = {
        latitude: testRide.pickupLocation.coordinates[1],
        longitude: testRide.pickupLocation.coordinates[0]
      };

      await expect(
        TransactionService.acceptRideWithTransaction(
          testRide.id,
          99999, // ID de chauffeur inexistant
          driverLocation,
          pickupLocation,
          2000
        )
      ).rejects.toThrow();

      // Vérifier que la course n'a pas été modifiée (rollback)
      const rideRepository = AppDataSource.getRepository(Ride);
      const unchangedRide = await rideRepository.findOne({ where: { id: testRide.id } });
      expect(unchangedRide.status).toBe('pending');
      expect(unchangedRide.driverId).toBeNull();
    });

    test('DEVRAIT valider les données d\'entrée', async () => {
      await expect(
        TransactionService.acceptRideWithTransaction(
          null, // ID invalide
          driver.id,
          { latitude: -4.3276, longitude: 15.3156 },
          { latitude: -4.3276, longitude: 15.3156 },
          2000
        )
      ).rejects.toThrow();
    });
  });
});

