// Script de test de connexion au backend Cloud Run pour l'app driver
// Usage: node test-cloud-run-driver.js

const axios = require('axios');

const BACKEND_URL = process.env.BACKEND_URL || 'https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app';
const API_URL = `${BACKEND_URL}/api`;
const DRIVER_PHONE = process.env.DRIVER_PHONE || '+243900000001';

let driverToken = '';
let driverId = '';

// Couleurs pour la console
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

function logInfo(message) {
  log(`ℹ️  ${message}`, 'blue');
}

// ============================================================================
// 1. TEST HEALTH CHECK
// ============================================================================
async function testHealthCheck() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('1. TEST HEALTH CHECK', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  try {
    const response = await axios.get(`${BACKEND_URL}/health`, {
      timeout: 10000
    });
    logSuccess(`Backend Cloud Run accessible sur ${BACKEND_URL}`);
    logInfo(`Statut: ${response.data.status || 'OK'}`);
    logInfo(`Base de données: ${response.data.database || 'N/A'}`);
    return true;
  } catch (error) {
    logError(`Backend Cloud Run non accessible: ${error.message}`);
    if (error.response) {
      logInfo(`Code HTTP: ${error.response.status}`);
      logInfo(`Réponse: ${JSON.stringify(error.response.data)}`);
    }
    return false;
  }
}

// ============================================================================
// 2. TEST AUTHENTIFICATION DRIVER
// ============================================================================
async function testDriverAuthentication() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('2. TEST AUTHENTIFICATION DRIVER', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  try {
    logInfo(`Authentification avec le numéro: ${DRIVER_PHONE}`);
    const response = await axios.post(`${API_URL}/auth/signin`, {
      phoneNumber: DRIVER_PHONE,
      role: 'driver'
    }, {
      timeout: 10000
    });
    
    if (response.data.token) {
      driverToken = response.data.token;
      driverId = response.data.user?.id || response.data.userId;
      logSuccess('Authentification driver réussie');
      logInfo(`Token JWT: ${driverToken.substring(0, 50)}...`);
      logInfo(`Driver ID: ${driverId}`);
      logInfo(`Nom: ${response.data.user?.name || 'N/A'}`);
      logInfo(`Rôle: ${response.data.user?.role || 'N/A'}`);
      return true;
    } else {
      logError('Token JWT non reçu dans la réponse');
      return false;
    }
  } catch (error) {
    logError(`Échec de l'authentification: ${error.response?.data?.error || error.message}`);
    if (error.response?.data) {
      logInfo(`Réponse: ${JSON.stringify(error.response.data, null, 2)}`);
    }
    return false;
  }
}

// ============================================================================
// 3. TEST PROFIL DRIVER
// ============================================================================
async function testDriverProfile() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('3. TEST PROFIL DRIVER', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  if (!driverToken) {
    logWarning('Token non disponible, test ignoré');
    return false;
  }
  
  try {
    const response = await axios.get(`${API_URL}/auth/profile`, {
      headers: {
        'Authorization': `Bearer ${driverToken}`
      },
      timeout: 10000
    });
    
    logSuccess('Profil driver récupéré');
    logInfo(`ID: ${response.data.id}`);
    logInfo(`Nom: ${response.data.name}`);
    logInfo(`Téléphone: ${response.data.phoneNumber}`);
    logInfo(`Rôle: ${response.data.role}`);
    
    if (response.data.driverInfo) {
      logInfo(`Statut: ${response.data.driverInfo.status || 'N/A'}`);
      logInfo(`En ligne: ${response.data.driverInfo.isOnline ? 'Oui' : 'Non'}`);
      logInfo(`Courses totales: ${response.data.driverInfo.totalRides || 0}`);
    }
    
    return true;
  } catch (error) {
    logError(`Échec de la récupération du profil: ${error.response?.data?.error || error.message}`);
    return false;
  }
}

// ============================================================================
// 4. TEST MISE À JOUR POSITION
// ============================================================================
async function testUpdateLocation() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('4. TEST MISE À JOUR POSITION', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  if (!driverToken) {
    logWarning('Token non disponible, test ignoré');
    return false;
  }
  
  try {
    const location = {
      latitude: -4.3276,
      longitude: 15.3136,
      address: 'Kinshasa, RD Congo'
    };
    
    logInfo(`Mise à jour position: ${location.latitude}, ${location.longitude}`);
    const response = await axios.post(`${API_URL}/driver/location/update`, location, {
      headers: {
        'Authorization': `Bearer ${driverToken}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    
    if (response.data.success) {
      logSuccess('Position mise à jour avec succès');
      logInfo(`Latitude: ${response.data.location?.latitude}`);
      logInfo(`Longitude: ${response.data.location?.longitude}`);
      if (response.data.location?.address) {
        logInfo(`Adresse: ${response.data.location.address}`);
      }
      return true;
    } else {
      logError('Échec de la mise à jour de la position');
      return false;
    }
  } catch (error) {
    logError(`Échec de la mise à jour: ${error.response?.data?.error || error.message}`);
    if (error.response?.data) {
      logInfo(`Réponse: ${JSON.stringify(error.response.data, null, 2)}`);
    }
    return false;
  }
}

// ============================================================================
// 5. TEST PROTECTION DES ROUTES
// ============================================================================
async function testRouteProtection() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('5. TEST PROTECTION DES ROUTES', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  const routes = [
    { method: 'post', url: `${API_URL}/driver/location/update`, data: { latitude: 0, longitude: 0 } },
    { method: 'post', url: `${API_URL}/driver/accept_ride/1`, data: {} },
    { method: 'post', url: `${API_URL}/driver/reject_ride/1`, data: {} },
    { method: 'post', url: `${API_URL}/driver/complete_ride/1`, data: {} }
  ];
  
  let allProtected = true;
  
  for (const route of routes) {
    try {
      await axios[route.method](route.url, route.data, {
        headers: { 'Content-Type': 'application/json' },
        timeout: 5000
      });
      logError(`Route ${route.url} non protégée (devrait retourner 401/403)`);
      allProtected = false;
    } catch (error) {
      const status = error.response?.status;
      if (status === 401 || status === 403) {
        logSuccess(`Route ${route.url} protégée (code: ${status})`);
      } else {
        logWarning(`Route ${route.url} retourne un code inattendu: ${status}`);
      }
    }
  }
  
  return allProtected;
}

// ============================================================================
// 6. TEST VÉRIFICATION RÔLE
// ============================================================================
async function testRoleVerification() {
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('6. TEST VÉRIFICATION RÔLE', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  if (!driverToken) {
    logWarning('Token non disponible, test ignoré');
    return false;
  }
  
  try {
    const response = await axios.post(`${API_URL}/driver/location/update`, {
      latitude: -4.3276,
      longitude: 15.3136
    }, {
      headers: {
        'Authorization': `Bearer ${driverToken}`
      },
      timeout: 10000
    });
    
    if (response.data.success) {
      logSuccess('Token driver accepté pour les routes driver');
      return true;
    } else {
      logError('Token driver rejeté');
      return false;
    }
  } catch (error) {
    const status = error.response?.status;
    if (status === 403) {
      logError(`Token driver rejeté (code 403)`);
      logInfo(`Message: ${error.response?.data?.error || 'Accès refusé'}`);
      return false;
    } else {
      logError(`Erreur inattendue: ${error.message}`);
      return false;
    }
  }
}

// ============================================================================
// FONCTION PRINCIPALE
// ============================================================================
async function runAllTests() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('🔍 TEST CONNEXION BACKEND CLOUD RUN - APP DRIVER', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  log(`Backend URL: ${BACKEND_URL}`);
  log(`API URL: ${API_URL}`);
  log(`Driver Phone: ${DRIVER_PHONE}`);
  
  const results = {
    healthCheck: false,
    authentication: false,
    profile: false,
    updateLocation: false,
    routeProtection: false,
    roleVerification: false
  };
  
  // Exécuter les tests
  results.healthCheck = await testHealthCheck();
  if (!results.healthCheck) {
    logError('Le backend n\'est pas accessible. Arrêt des tests.');
    return;
  }
  
  results.authentication = await testDriverAuthentication();
  if (!results.authentication) {
    logError('L\'authentification a échoué. Certains tests seront ignorés.');
  }
  
  if (results.authentication) {
    results.profile = await testDriverProfile();
    results.updateLocation = await testUpdateLocation();
    results.roleVerification = await testRoleVerification();
  }
  
  results.routeProtection = await testRouteProtection();
  
  // Résumé
  log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  log('RÉSUMÉ DES TESTS', 'cyan');
  log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', 'cyan');
  
  const totalTests = Object.keys(results).length;
  const passedTests = Object.values(results).filter(r => r).length;
  
  for (const [test, result] of Object.entries(results)) {
    if (result) {
      logSuccess(`${test}: OK`);
    } else {
      logError(`${test}: ÉCHEC`);
    }
  }
  
  log(`\n✅ Tests réussis: ${passedTests}/${totalTests}`, 'green');
  
  if (passedTests === totalTests) {
    log('\n✅ Tous les tests sont passés avec succès!', 'green');
    log(`🌐 Le backend Cloud Run est accessible et fonctionne correctement`, 'green');
    process.exit(0);
  } else {
    log('\n❌ Certains tests ont échoué.', 'red');
    process.exit(1);
  }
}

// Exécuter les tests
runAllTests().catch((error) => {
  logError(`Erreur fatale: ${error.message}`);
  console.error(error);
  process.exit(1);
});

