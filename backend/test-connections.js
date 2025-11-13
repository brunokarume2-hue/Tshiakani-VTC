#!/usr/bin/env node

/**
 * Script de test pour vérifier les connexions end-to-end
 * Usage: node test-connections.js
 */

const http = require('http');
const WebSocket = require('socket.io-client');

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const WS_URL = process.env.WS_URL || 'http://localhost:3000';

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

// Test 1: Vérifier que le serveur est démarré
async function testServerHealth() {
  return new Promise((resolve, reject) => {
    log('\n📡 Test 1: Vérification du serveur...', 'cyan');
    
    const req = http.get(`${BASE_URL}/health`, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const health = JSON.parse(data);
          if (health.status === 'OK') {
            log('✅ Serveur accessible', 'green');
            log(`   Base de données: ${health.database}`, 'blue');
            resolve(true);
          } else {
            log('❌ Serveur en erreur', 'red');
            reject(new Error('Serveur en erreur'));
          }
        } catch (error) {
          log('❌ Erreur parsing réponse', 'red');
          reject(error);
        }
      });
    });
    
    req.on('error', (error) => {
      log('❌ Impossible de se connecter au serveur', 'red');
      log(`   Assurez-vous que le serveur est démarré sur ${BASE_URL}`, 'yellow');
      reject(error);
    }));
    
    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Timeout'));
    });
  });
}

// Test 2: Tester la connexion WebSocket
async function testWebSocketConnection(token) {
  return new Promise((resolve, reject) => {
    log('\n🔌 Test 2: Connexion WebSocket...', 'cyan');
    
    if (!token) {
      log('⚠️  Token manquant - test WebSocket ignoré', 'yellow');
      log('   Pour tester WebSocket, fournissez un token valide', 'yellow');
      resolve(false);
      return;
    }
    
    const socket = WebSocket(`${WS_URL}/ws/driver?token=${token}`, {
      transports: ['websocket']
    });
    
    const timeout = setTimeout(() => {
      socket.disconnect();
      log('❌ Timeout lors de la connexion WebSocket', 'red');
      reject(new Error('Timeout WebSocket'));
    }, 5000);
    
    socket.on('connect', () => {
      clearTimeout(timeout);
      log('✅ WebSocket connecté', 'green');
      socket.disconnect();
      resolve(true);
    });
    
    socket.on('connected', (data) => {
      log(`✅ Message 'connected' reçu: ${JSON.stringify(data)}`, 'green');
    });
    
    socket.on('connect_error', (error) => {
      clearTimeout(timeout);
      log('❌ Erreur de connexion WebSocket', 'red');
      log(`   ${error.message}`, 'red');
      if (error.message.includes('Token')) {
        log('   Vérifiez que le token est valide', 'yellow');
      }
      reject(error);
    });
    
    socket.on('disconnect', () => {
      log('⚠️  WebSocket déconnecté', 'yellow');
    });
  });
}

// Test 3: Tester les routes API
async function testAPIRoutes(token) {
  log('\n🌐 Test 3: Routes API...', 'cyan');
  
  if (!token) {
    log('⚠️  Token manquant - tests API ignorés', 'yellow');
    log('   Pour tester les routes API, fournissez un token valide', 'yellow');
    return;
  }
  
  const routes = [
    { method: 'POST', path: '/api/location/update', name: 'Mise à jour position' },
    { method: 'POST', path: '/api/location/online', name: 'Statut en ligne' },
    { method: 'GET', path: '/api/rides/1', name: 'Récupérer une course' }
  ];
  
  for (const route of routes) {
    try {
      await testRoute(route.method, route.path, route.name, token);
    } catch (error) {
      log(`❌ Erreur test ${route.name}: ${error.message}`, 'red');
    }
  }
}

async function testRoute(method, path, name, token) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      method: method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(url, options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          log(`✅ ${name}: OK (${res.statusCode})`, 'green');
          resolve(true);
        } else if (res.statusCode === 401 || res.statusCode === 403) {
          log(`⚠️  ${name}: Non autorisé (${res.statusCode}) - Token invalide ou permissions insuffisantes`, 'yellow');
          resolve(false);
        } else if (res.statusCode === 404) {
          log(`⚠️  ${name}: Non trouvé (${res.statusCode}) - Ressource inexistante`, 'yellow');
          resolve(false);
        } else {
          log(`❌ ${name}: Erreur (${res.statusCode})`, 'red');
          reject(new Error(`Status ${res.statusCode}`));
        }
      });
    });
    
    req.on('error', (error) => {
      log(`❌ ${name}: Erreur réseau`, 'red');
      reject(error);
    });
    
    if (method === 'POST') {
      const body = method === 'POST' && path.includes('location/update') 
        ? JSON.stringify({ latitude: -4.3276, longitude: 15.3136, timestamp: new Date().toISOString() })
        : method === 'POST' && path.includes('location/online')
        ? JSON.stringify({ online: true })
        : '{}';
      req.write(body);
    }
    
    req.end();
  });
}

// Fonction principale
async function runTests() {
  log('🧪 Tests de Connexion End-to-End', 'cyan');
  log('=' .repeat(50), 'cyan');
  
  // Récupérer le token depuis les arguments ou l'environnement
  const token = process.argv[2] || process.env.DRIVER_TOKEN;
  
  if (!token) {
    log('\n⚠️  Aucun token fourni', 'yellow');
    log('   Usage: node test-connections.js <token>', 'yellow');
    log('   Ou: DRIVER_TOKEN=<token> node test-connections.js', 'yellow');
    log('   Les tests nécessitant un token seront ignorés\n', 'yellow');
  }
  
  try {
    // Test 1: Santé du serveur
    await testServerHealth();
    
    // Test 2: WebSocket
    try {
      await testWebSocketConnection(token);
    } catch (error) {
      log(`⚠️  Test WebSocket échoué: ${error.message}`, 'yellow');
    }
    
    // Test 3: Routes API
    await testAPIRoutes(token);
    
    log('\n✅ Tests terminés', 'green');
    log('=' .repeat(50), 'cyan');
    
  } catch (error) {
    log(`\n❌ Erreur lors des tests: ${error.message}`, 'red');
    process.exit(1);
  }
}

// Exécuter les tests
runTests();

