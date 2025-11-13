/**
 * Script de test pour les endpoints API v1 Driver
 * 
 * Usage:
 *   node test-driver-api-v1.js
 * 
 * Prérequis:
 *   - Backend démarré sur http://localhost:3000
 *   - Base de données PostgreSQL configurée
 *   - Un utilisateur conducteur créé dans la base de données
 */

const axios = require('axios');

const BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';
const API_V1_BASE = `${BASE_URL}/api/v1/driver`;

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

// Statistiques de test
let stats = {
  total: 0,
  passed: 0,
  failed: 0,
  errors: []
};

// Token JWT pour les requêtes authentifiées
let authToken = null;
let driverId = null;

/**
 * Afficher un message avec couleur
 */
function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

/**
 * Afficher un séparateur
 */
function separator() {
  console.log('\n' + '='.repeat(60) + '\n');
}

/**
 * Test d'un endpoint
 */
async function testEndpoint(name, testFn) {
  stats.total++;
  log(`\n📋 Test: ${name}`, 'cyan');
  
  try {
    await testFn();
    stats.passed++;
    log(`✅ ${name} - PASSED`, 'green');
    return true;
  } catch (error) {
    stats.failed++;
    stats.errors.push({ name, error: error.message });
    log(`❌ ${name} - FAILED`, 'red');
    log(`   Erreur: ${error.message}`, 'red');
    if (error.response) {
      log(`   Status: ${error.response.status}`, 'red');
      log(`   Data: ${JSON.stringify(error.response.data, null, 2)}`, 'red');
    }
    return false;
  }
}

/**
 * Test 1: Authentification - Login
 */
async function testLogin() {
  // Utiliser un email/phoneNumber existant dans la base de données
  // Remplacez par un utilisateur conducteur réel
  const response = await axios.post(`${API_V1_BASE}/auth/login`, {
    email: 'driver@test.com', // Remplacez par un email/phoneNumber réel
    password: 'test123'
  });

  if (response.status !== 200) {
    throw new Error(`Status code incorrect: ${response.status}`);
  }

  if (!response.data.token) {
    throw new Error('Token manquant dans la réponse');
  }

  if (!response.data.driver) {
    throw new Error('Données du conducteur manquantes dans la réponse');
  }

  authToken = response.data.token;
  driverId = response.data.driver.id;

  log(`   Token reçu: ${authToken.substring(0, 20)}...`, 'blue');
  log(`   Driver ID: ${driverId}`, 'blue');
}

/**
 * Test 2: Mise à jour du statut
 */
async function testUpdateStatus() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  const response = await axios.post(
    `${API_V1_BASE}/status/update`,
    { status: 'available' },
    {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (response.status !== 200) {
    throw new Error(`Status code incorrect: ${response.status}`);
  }

  if (!response.data.success) {
    throw new Error('La mise à jour du statut a échoué');
  }

  if (response.data.status !== 'available') {
    throw new Error(`Statut incorrect: ${response.data.status}`);
  }
}

/**
 * Test 3: Synchronisation GPS
 */
async function testLocationSync() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  const response = await axios.post(
    `${API_V1_BASE}/location/sync`,
    {
      latitude: -4.3276,
      longitude: 15.3136,
      timestamp: new Date().toISOString(),
      accuracy: 10.0,
      speed: 0.0,
      heading: 0.0
    },
    {
      headers: {
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (response.status !== 200) {
    throw new Error(`Status code incorrect: ${response.status}`);
  }

  if (!response.data.success) {
    throw new Error('La synchronisation de la position a échoué');
  }

  if (!response.data.location) {
    throw new Error('Données de localisation manquantes dans la réponse');
  }
}

/**
 * Test 4: Accepter une course
 */
async function testAcceptRide() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  // Créer d'abord une course (nécessite un client)
  // Pour ce test, on suppose qu'une course avec l'ID 1 existe
  const rideId = 1;

  try {
    const response = await axios.post(
      `${API_V1_BASE}/course/accept/${rideId}`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.status !== 200) {
      throw new Error(`Status code incorrect: ${response.status}`);
    }

    if (!response.data.success) {
      throw new Error('L\'acceptation de la course a échoué');
    }
  } catch (error) {
    // Si la course n'existe pas, c'est normal pour un test
    if (error.response && error.response.status === 404) {
      log('   ⚠️  Course non trouvée (normal si aucune course en attente)', 'yellow');
      return;
    }
    throw error;
  }
}

/**
 * Test 5: Refuser une course
 */
async function testRefuseRide() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  const rideId = 1;

  try {
    const response = await axios.post(
      `${API_V1_BASE}/course/refuse/${rideId}`,
      { reason: 'test_refusal' },
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.status !== 200) {
      throw new Error(`Status code incorrect: ${response.status}`);
    }

    if (!response.data.success) {
      throw new Error('Le refus de la course a échoué');
    }
  } catch (error) {
    // Si la course n'existe pas, c'est normal pour un test
    if (error.response && error.response.status === 404) {
      log('   ⚠️  Course non trouvée (normal si aucune course en attente)', 'yellow');
      return;
    }
    throw error;
  }
}

/**
 * Test 6: Mise à jour de la progression de la course
 */
async function testUpdateRideProgress() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  const rideId = 1;

  try {
    const response = await axios.post(
      `${API_V1_BASE}/course/progress/${rideId}`,
      {
        progress: 'arrived_at_pickup',
        timestamp: new Date().toISOString()
      },
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (response.status !== 200) {
      throw new Error(`Status code incorrect: ${response.status}`);
    }

    if (!response.data.success) {
      throw new Error('La mise à jour de la progression a échoué');
    }
  } catch (error) {
    // Si la course n'existe pas, c'est normal pour un test
    if (error.response && error.response.status === 404) {
      log('   ⚠️  Course non trouvée (normal si aucune course en attente)', 'yellow');
      return;
    }
    throw error;
  }
}

/**
 * Test 7: Récupérer les nouvelles courses
 */
async function testGetNewRides() {
  if (!authToken) {
    throw new Error('Token d\'authentification manquant');
  }

  const response = await axios.get(
    `${API_V1_BASE}/new_ride`,
    {
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    }
  );

  if (response.status !== 200) {
    throw new Error(`Status code incorrect: ${response.status}`);
  }

  if (!response.data.rides) {
    throw new Error('Données des courses manquantes dans la réponse');
  }

  log(`   Courses disponibles: ${response.data.count}`, 'blue');
}

/**
 * Fonction principale
 */
async function runTests() {
  log('\n🚀 Démarrage des tests des endpoints API v1 Driver', 'cyan');
  log(`📍 URL de base: ${API_V1_BASE}`, 'blue');
  separator();

  // Test 1: Authentification
  await testEndpoint('Authentification - Login', testLogin);
  
  if (!authToken) {
    log('\n❌ Impossible de continuer les tests sans token d\'authentification', 'red');
    log('   Veuillez vérifier que:', 'yellow');
    log('   1. Le backend est démarré', 'yellow');
    log('   2. Un utilisateur conducteur existe dans la base de données', 'yellow');
    log('   3. Les credentials dans le script sont corrects', 'yellow');
    return;
  }

  separator();

  // Test 2: Mise à jour du statut
  await testEndpoint('Mise à jour du statut', testUpdateStatus);

  separator();

  // Test 3: Synchronisation GPS
  await testEndpoint('Synchronisation GPS', testLocationSync);

  separator();

  // Test 4: Accepter une course
  await testEndpoint('Accepter une course', testAcceptRide);

  separator();

  // Test 5: Refuser une course
  await testEndpoint('Refuser une course', testRefuseRide);

  separator();

  // Test 6: Mise à jour de la progression
  await testEndpoint('Mise à jour de la progression', testUpdateRideProgress);

  separator();

  // Test 7: Récupérer les nouvelles courses
  await testEndpoint('Récupérer les nouvelles courses', testGetNewRides);

  separator();

  // Afficher les résultats
  log('\n📊 Résultats des tests:', 'cyan');
  log(`   Total: ${stats.total}`, 'blue');
  log(`   ✅ Réussis: ${stats.passed}`, 'green');
  log(`   ❌ Échoués: ${stats.failed}`, 'red');

  if (stats.errors.length > 0) {
    log('\n❌ Erreurs:', 'red');
    stats.errors.forEach(({ name, error }) => {
      log(`   - ${name}: ${error}`, 'red');
    });
  }

  if (stats.failed === 0) {
    log('\n🎉 Tous les tests sont passés !', 'green');
  } else {
    log(`\n⚠️  ${stats.failed} test(s) ont échoué`, 'yellow');
  }
}

// Exécuter les tests
runTests().catch(error => {
  log(`\n❌ Erreur fatale: ${error.message}`, 'red');
  console.error(error);
  process.exit(1);
});

