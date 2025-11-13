/**
 * Configuration des tests Jest pour le backend
 * 
 * Ce fichier configure l'environnement de test avec :
 * - Base de données de test
 * - Variables d'environnement de test
 * - Helpers et utilitaires
 */

const { AppDataSource } = require('../../backend/config/database');

// Configuration des variables d'environnement pour les tests
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-only';
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || 'postgresql://localhost:5432/tshiakani_vtc_test';

// Timeout global pour les tests
jest.setTimeout(30000);

// Configuration avant tous les tests
beforeAll(async () => {
  try {
    // Initialiser la connexion à la base de données de test
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
  } catch (error) {
    console.error('Erreur lors de l\'initialisation de la base de données de test:', error);
    throw error;
  }
});

// Nettoyage après tous les tests
afterAll(async () => {
  try {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  } catch (error) {
    console.error('Erreur lors de la fermeture de la base de données de test:', error);
  }
});

// Nettoyage après chaque test
afterEach(async () => {
  try {
    // Nettoyer les tables de test
    const entities = AppDataSource.entityMetadatas;
    
    for (const entity of entities) {
      const repository = AppDataSource.getRepository(entity.name);
      await repository.clear();
    }
  } catch (error) {
    console.error('Erreur lors du nettoyage de la base de données:', error);
  }
});

// Helpers pour créer des utilisateurs de test
const createTestUser = async (role = 'client', userData = {}) => {
  const User = require('../../backend/entities/User');
  const userRepository = AppDataSource.getRepository(User);
  
  const defaultUser = {
    name: `Test ${role}`,
    phoneNumber: `+24390000000${Math.floor(Math.random() * 10000)}`,
    role: role,
    isVerified: true,
    ...userData
  };
  
  if (role === 'driver') {
    defaultUser.driverInfo = {
      isOnline: true,
      currentRideId: null,
      status: 'available',
      ...userData.driverInfo
    };
  }
  
  const user = userRepository.create(defaultUser);
  return await userRepository.save(user);
};

// Helper pour créer une course de test
const createTestRide = async (clientId, rideData = {}) => {
  const Ride = require('../../backend/entities/Ride');
  const rideRepository = AppDataSource.getRepository(Ride);
  
  const defaultRide = {
    clientId: clientId,
    pickupLocation: {
      type: 'Point',
      coordinates: [15.3156, -4.3276] // Kinshasa
    },
    dropoffLocation: {
      type: 'Point',
      coordinates: [15.3256, -4.3376] // Kinshasa
    },
    status: 'pending',
    estimatedPrice: 5000,
    distance: 2.5,
    ...rideData
  };
  
  const ride = rideRepository.create(defaultRide);
  return await rideRepository.save(ride);
};

// Helper pour obtenir un token JWT de test
const getTestToken = (userId, role = 'client') => {
  const jwt = require('jsonwebtoken');
  return jwt.sign(
    { id: userId, role: role },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
};

module.exports = {
  createTestUser,
  createTestRide,
  getTestToken,
  AppDataSource
};

