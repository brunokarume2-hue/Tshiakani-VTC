#!/usr/bin/env node

/**
 * Script de test pour vérifier la communication Client ↔ Backend ↔ Driver
 * 
 * Ce script simule:
 * 1. Un client qui crée une course
 * 2. Un driver qui reçoit la notification et accepte la course
 * 3. La communication entre les deux via le backend (REST API et WebSocket)
 * 
 * Usage: node test-client-driver-communication.js
 */

require('dotenv').config();
const http = require('http');
const socketIo = require('socket.io-client');

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  magenta: '\x1b[35m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// Configuration
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const API_URL = `${BASE_URL}/api`;
const WS_URL = BASE_URL;

// État du test
let clientToken = null;
let driverToken = null;
let clientSocket = null;
let driverSocket = null;
let createdRideId = null;
let testResults = {
  passed: 0,
  failed: 0,
  warnings: 0
};

// Fonction pour faire une requête HTTP
function makeRequest(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_URL);
    const options = {
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const parsed = body ? JSON.parse(body) : {};
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve({ statusCode: res.statusCode, data: parsed });
          } else {
            reject({ statusCode: res.statusCode, data: parsed });
          }
        } catch (error) {
          reject({ statusCode: res.statusCode, error: error.message, body: body });
        }
      });
    });

    req.on('error', (error) => {
      reject({ error: error.message });
    });

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

// Test 1: Authentifier un client
async function test1_AuthenticateClient() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 1: Authentification Client', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  try {
    const response = await makeRequest('POST', '/auth/signin', {
      phoneNumber: '+243900000001',
      role: 'client',
      name: 'Test Client'
    });

    if (response.data.token) {
      clientToken = response.data.token;
      log('✅ Client authentifié avec succès', 'green');
      log(`   Token: ${clientToken.substring(0, 50)}...`, 'blue');
      testResults.passed++;
      return true;
    } else {
      log('❌ Échec: Token non reçu', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de l'authentification client: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    testResults.failed++;
    return false;
  }
}

// Test 2: Authentifier un driver
async function test2_AuthenticateDriver() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 2: Authentification Driver', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  try {
    const response = await makeRequest('POST', '/auth/signin', {
      phoneNumber: '+243900000002',
      role: 'driver',
      name: 'Test Driver'
    });

    if (response.data.token) {
      driverToken = response.data.token;
      log('✅ Driver authentifié avec succès', 'green');
      log(`   Token: ${driverToken.substring(0, 50)}...`, 'blue');
      testResults.passed++;
      return true;
    } else {
      log('❌ Échec: Token non reçu', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de l'authentification driver: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    testResults.failed++;
    return false;
  }
}

// Test 3: Driver se connecte au WebSocket
async function test3_DriverWebSocketConnection() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 3: Connexion WebSocket Driver', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  return new Promise((resolve) => {
    driverSocket = socketIo(`${WS_URL}/ws/driver`, {
      auth: { token: driverToken },
      transports: ['websocket']
    });

    const timeout = setTimeout(() => {
      log('❌ Timeout: Connexion WebSocket driver échouée', 'red');
      testResults.failed++;
      resolve(false);
    }, 5000);

    driverSocket.on('connect', () => {
      clearTimeout(timeout);
      log('✅ Driver connecté au WebSocket', 'green');
      testResults.passed++;
      resolve(true);
    });

    driverSocket.on('connect_error', (error) => {
      clearTimeout(timeout);
      log(`❌ Erreur de connexion WebSocket driver: ${error.message}`, 'red');
      testResults.failed++;
      resolve(false);
    });

    // Écouter les notifications de nouvelles courses
    driverSocket.on('ride:request', (data) => {
      log(`📨 Driver reçoit une demande de course: ${JSON.stringify(data)}`, 'magenta');
    });

    driverSocket.on('ride:new', (data) => {
      log(`📨 Driver reçoit une nouvelle course: ${JSON.stringify(data)}`, 'magenta');
    });
  });
}

// Test 4: Client se connecte au WebSocket
async function test4_ClientWebSocketConnection() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 4: Connexion WebSocket Client', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  return new Promise((resolve) => {
    clientSocket = socketIo(`${WS_URL}/ws/client`, {
      auth: { token: clientToken },
      transports: ['websocket']
    });

    const timeout = setTimeout(() => {
      log('❌ Timeout: Connexion WebSocket client échouée', 'red');
      testResults.failed++;
      resolve(false);
    }, 5000);

    clientSocket.on('connect', () => {
      clearTimeout(timeout);
      log('✅ Client connecté au WebSocket', 'green');
      testResults.passed++;
      resolve(true);
    });

    clientSocket.on('connect_error', (error) => {
      clearTimeout(timeout);
      log(`❌ Erreur de connexion WebSocket client: ${error.message}`, 'red');
      testResults.failed++;
      resolve(false);
    });

    // Écouter les mises à jour de statut de course
    clientSocket.on('ride:status:changed', (data) => {
      log(`📨 Client reçoit une mise à jour de statut: ${JSON.stringify(data)}`, 'magenta');
    });

    clientSocket.on('ride:accepted', (data) => {
      log(`📨 Client reçoit une notification de course acceptée: ${JSON.stringify(data)}`, 'magenta');
    });

    clientSocket.on('driver:location:update', (data) => {
      log(`📨 Client reçoit une mise à jour de position du driver: ${JSON.stringify(data)}`, 'magenta');
    });
  });
}

// Test 5: Driver met à jour sa position
async function test5_DriverUpdateLocation() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 5: Driver met à jour sa position', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  try {
    const response = await makeRequest('POST', '/driver/location/update', {
      latitude: -4.3276,
      longitude: 15.3136,
      address: 'Kinshasa, RD Congo'
    }, driverToken);

    if (response.data.success) {
      log('✅ Position du driver mise à jour avec succès', 'green');
      log(`   Position: ${response.data.location.latitude}, ${response.data.location.longitude}`, 'blue');
      testResults.passed++;
      return true;
    } else {
      log('❌ Échec: Position non mise à jour', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de la mise à jour de position: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    testResults.failed++;
    return false;
  }
}

// Test 6: Client crée une course
async function test6_ClientCreateRide() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 6: Client crée une course', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  try {
    // D'abord, estimer le prix
    const estimateResponse = await makeRequest('POST', '/rides/estimate-price', {
      pickupLocation: {
        latitude: -4.3276,
        longitude: 15.3136,
        address: 'Point de départ, Kinshasa'
      },
      dropoffLocation: {
        latitude: -4.3296,
        longitude: 15.3156,
        address: 'Point d\'arrivée, Kinshasa'
      }
    }, clientToken);

    if (!estimateResponse.data.price) {
      log('⚠️  Avertissement: Impossible d\'estimer le prix', 'yellow');
      testResults.warnings++;
    } else {
      log(`✅ Prix estimé: ${estimateResponse.data.price} CDF`, 'green');
    }

    // Ensuite, créer la course
    const createResponse = await makeRequest('POST', '/rides/create', {
      pickupLocation: {
        latitude: -4.3276,
        longitude: 15.3136,
        address: 'Point de départ, Kinshasa'
      },
      dropoffLocation: {
        latitude: -4.3296,
        longitude: 15.3156,
        address: 'Point d\'arrivée, Kinshasa'
      },
      paymentMethod: 'cash'
    }, clientToken);

    if (createResponse.data.ride && createResponse.data.ride.id) {
      createdRideId = createResponse.data.ride.id;
      log('✅ Course créée avec succès', 'green');
      log(`   ID de la course: ${createdRideId}`, 'blue');
      log(`   Statut: ${createResponse.data.ride.status}`, 'blue');
      testResults.passed++;
      
      // Attendre un peu pour que les notifications soient envoyées
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      return true;
    } else {
      log('❌ Échec: Course non créée', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de la création de course: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    if (error.data) {
      log(`   Détails: ${JSON.stringify(error.data)}`, 'yellow');
    }
    testResults.failed++;
    return false;
  }
}

// Test 7: Driver accepte la course
async function test7_DriverAcceptRide() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 7: Driver accepte la course', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  if (!createdRideId) {
    log('⚠️  Avertissement: Aucune course créée, test ignoré', 'yellow');
    testResults.warnings++;
    return false;
  }

  try {
    const response = await makeRequest('POST', `/driver/accept_ride/${createdRideId}`, {}, driverToken);

    if (response.data.success || response.data.ride) {
      log('✅ Course acceptée avec succès', 'green');
      log(`   ID de la course: ${response.data.ride?.id || createdRideId}`, 'blue');
      log(`   Statut: ${response.data.ride?.status || 'accepted'}`, 'blue');
      testResults.passed++;
      
      // Attendre un peu pour que les notifications soient envoyées
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      return true;
    } else {
      log('❌ Échec: Course non acceptée', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de l'acceptation de course: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    if (error.data) {
      log(`   Détails: ${JSON.stringify(error.data)}`, 'yellow');
    }
    testResults.failed++;
    return false;
  }
}

// Test 8: Client suit le driver
async function test8_ClientTrackDriver() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 8: Client suit le driver', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  if (!createdRideId) {
    log('⚠️  Avertissement: Aucune course créée, test ignoré', 'yellow');
    testResults.warnings++;
    return false;
  }

  try {
    const response = await makeRequest('GET', `/client/track_driver/${createdRideId}`, null, clientToken);

    if (response.data.driver || response.data.ride) {
      log('✅ Suivi du driver réussi', 'green');
      if (response.data.driver) {
        log(`   Driver ID: ${response.data.driver.id}`, 'blue');
        log(`   Statut: ${response.data.driver.status || 'N/A'}`, 'blue');
      }
      if (response.data.eta) {
        log(`   ETA: ${response.data.eta} minutes`, 'blue');
      }
      testResults.passed++;
      return true;
    } else {
      log('⚠️  Avertissement: Données de suivi incomplètes', 'yellow');
      testResults.warnings++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors du suivi du driver: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    testResults.failed++;
    return false;
  }
}

// Test 9: Driver met à jour sa position pendant la course
async function test9_DriverUpdateLocationDuringRide() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('TEST 9: Driver met à jour sa position pendant la course', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  try {
    const response = await makeRequest('POST', '/driver/location/update', {
      latitude: -4.3280,
      longitude: 15.3140,
      address: 'Kinshasa, RD Congo (en route)'
    }, driverToken);

    if (response.data.success) {
      log('✅ Position mise à jour avec succès', 'green');
      log(`   Nouvelle position: ${response.data.location.latitude}, ${response.data.location.longitude}`, 'blue');
      testResults.passed++;
      
      // Attendre un peu pour que les notifications soient envoyées
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return true;
    } else {
      log('❌ Échec: Position non mise à jour', 'red');
      testResults.failed++;
      return false;
    }
  } catch (error) {
    log(`❌ Erreur lors de la mise à jour de position: ${error.error || error.data?.error || 'Erreur inconnue'}`, 'red');
    testResults.failed++;
    return false;
  }
}

// Nettoyage
function cleanup() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('Nettoyage', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  
  if (clientSocket) {
    clientSocket.disconnect();
    log('✅ Connexion WebSocket client fermée', 'green');
  }
  
  if (driverSocket) {
    driverSocket.disconnect();
    log('✅ Connexion WebSocket driver fermée', 'green');
  }
}

// Fonction principale
async function runTests() {
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  log('🧪 TEST DE COMMUNICATION CLIENT ↔ BACKEND ↔ DRIVER', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  log(`\nURL Backend: ${BASE_URL}`, 'blue');
  log(`URL API: ${API_URL}`, 'blue');
  log(`URL WebSocket: ${WS_URL}`, 'blue');
  
  try {
    // Tests séquentiels
    await test1_AuthenticateClient();
    await test2_AuthenticateDriver();
    await test3_DriverWebSocketConnection();
    await test4_ClientWebSocketConnection();
    await test5_DriverUpdateLocation();
    await test6_ClientCreateRide();
    await test7_DriverAcceptRide();
    await test8_ClientTrackDriver();
    await test9_DriverUpdateLocationDuringRide();
    
    // Résumé
    log('\n═══════════════════════════════════════════════════════════════', 'cyan');
    log('📊 RÉSUMÉ DES TESTS', 'cyan');
    log('═══════════════════════════════════════════════════════════════', 'cyan');
    log(`✅ Tests réussis: ${testResults.passed}`, 'green');
    log(`❌ Tests échoués: ${testResults.failed}`, testResults.failed > 0 ? 'red' : 'green');
    log(`⚠️  Avertissements: ${testResults.warnings}`, testResults.warnings > 0 ? 'yellow' : 'green');
    
    const totalTests = testResults.passed + testResults.failed;
    const successRate = totalTests > 0 ? (testResults.passed / totalTests * 100).toFixed(1) : 0;
    log(`\n📈 Taux de réussite: ${successRate}%`, successRate >= 80 ? 'green' : 'yellow');
    
    if (testResults.failed === 0) {
      log('\n✅ Tous les tests critiques sont passés!', 'green');
      log('✅ La communication Client ↔ Backend ↔ Driver fonctionne correctement!', 'green');
    } else {
      log('\n❌ Certains tests ont échoué. Vérifiez les logs ci-dessus.', 'red');
    }
    
  } catch (error) {
    log(`\n❌ Erreur fatale: ${error.message}`, 'red');
    console.error(error);
  } finally {
    cleanup();
  }
}

// Gérer l'interruption
process.on('SIGINT', () => {
  log('\n\n⚠️  Interruption détectée, nettoyage...', 'yellow');
  cleanup();
  process.exit(0);
});

// Exécuter les tests
runTests().then(() => {
  process.exit(testResults.failed > 0 ? 1 : 0);
}).catch((error) => {
  log(`\n❌ Erreur fatale: ${error.message}`, 'red');
  console.error(error);
  cleanup();
  process.exit(1);
});

