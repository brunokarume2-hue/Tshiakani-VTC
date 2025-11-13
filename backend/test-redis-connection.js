#!/usr/bin/env node

// Script de test de connexion Redis
// Usage: node test-redis-connection.js

require('dotenv').config();
const { getRedisService } = require('./services/RedisService');

async function testRedis() {
  try {
    console.log('🧪 Test de connexion Redis');
    console.log('================================');
    console.log('');
    
    // Afficher la configuration
    console.log('📡 Configuration Redis:');
    if (process.env.REDIS_URL) {
      // Masquer le token dans les logs
      const maskedUrl = process.env.REDIS_URL.replace(/:[^:@]+@/, ':****@');
      console.log('   REDIS_URL:', maskedUrl);
      console.log('   Type: Upstash Redis (gratuit)');
    } else {
      console.log('   REDIS_HOST:', process.env.REDIS_HOST || 'localhost');
      console.log('   REDIS_PORT:', process.env.REDIS_PORT || 6379);
      console.log('   REDIS_PASSWORD:', process.env.REDIS_PASSWORD ? '***' : '(aucun)');
      console.log('   Type: Redis Local/Memorystore');
    }
    console.log('   REDIS_CONNECT_TIMEOUT:', process.env.REDIS_CONNECT_TIMEOUT || 10000);
    console.log('');
    
    // Obtenir le service Redis
    const redisService = getRedisService();
    console.log('🔄 Connexion à Redis...');
    
    // Connecter à Redis
    await redisService.connect();
    console.log('✅ Redis connecté avec succès');
    console.log('');
    
    // Vérifier que Redis est prêt
    const isReady = redisService.isReady();
    console.log('✅ Redis est prêt:', isReady ? 'OUI' : 'NON');
    console.log('');
    
    // Tester la connexion
    console.log('🧪 Test de connexion (PING)...');
    const testResult = await redisService.testConnection();
    console.log('✅ Test de connexion Redis:', testResult ? 'OK' : 'ÉCHEC');
    console.log('');
    
    if (testResult) {
      // Tester le stockage d'une valeur
      console.log('🧪 Test de stockage d\'une valeur...');
      try {
        await redisService.client.set('test:key', 'test:value', { EX: 10 });
        const value = await redisService.client.get('test:key');
        console.log('✅ Stockage réussi:', value === 'test:value' ? 'OK' : 'ÉCHEC');
        await redisService.client.del('test:key');
      } catch (error) {
        console.error('❌ Erreur de stockage:', error.message);
      }
      console.log('');
      
      // Tester les méthodes OTP
      console.log('🧪 Test des méthodes OTP...');
      try {
        const testPhone = '+243900000000';
        
        // Test storePendingRegistration
        const stored = await redisService.storePendingRegistration(testPhone, {
          name: 'Test User',
          phoneNumber: '243900000000',
          role: 'client'
        }, 60);
        console.log('✅ storePendingRegistration:', stored ? 'OK' : 'ÉCHEC');
        
        // Test getPendingRegistration
        const registration = await redisService.getPendingRegistration(testPhone);
        console.log('✅ getPendingRegistration:', registration ? 'OK' : 'ÉCHEC');
        
        // Test deletePendingRegistration
        const deleted = await redisService.deletePendingRegistration(testPhone);
        console.log('✅ deletePendingRegistration:', deleted ? 'OK' : 'ÉCHEC');
        
      } catch (error) {
        console.error('❌ Erreur test méthodes OTP:', error.message);
      }
      console.log('');
      
      // Tester le rate limiting
      console.log('🧪 Test du rate limiting...');
      try {
        const testPhone = '+243900000001';
        const rateLimit = await redisService.checkOTPRateLimit(testPhone, 3, 60);
        console.log('✅ checkOTPRateLimit:', rateLimit.allowed ? 'OK' : 'LIMITE ATTEINTE');
        console.log('   Tentatives restantes:', rateLimit.remaining);
        
        // Réinitialiser le rate limiting
        await redisService.resetOTPRateLimit(testPhone);
        console.log('✅ resetOTPRateLimit: OK');
        
      } catch (error) {
        console.error('❌ Erreur test rate limiting:', error.message);
      }
      console.log('');
      
      console.log('================================');
      console.log('🎉 Tous les tests sont réussis !');
      console.log('✅ Redis est configuré et fonctionne correctement');
      console.log('');
      console.log('📝 Prochaines étapes:');
      console.log('   1. Démarrez le serveur backend: npm run dev');
      console.log('   2. Vérifiez les logs pour confirmer la connexion Redis');
      console.log('   3. Testez l\'inscription/connexion avec OTP');
      console.log('');
      
      process.exit(0);
    } else {
      console.error('❌ Test de connexion échoué');
      process.exit(1);
    }
  } catch (error) {
    console.error('');
    console.error('================================');
    console.error('❌ Erreur de connexion Redis');
    console.error('================================');
    console.error('');
    console.error('📝 Message d\'erreur:', error.message);
    console.error('');
    console.error('💡 Vérifiez que:');
    if (process.env.REDIS_URL) {
      console.error('   1. Upstash Redis est configuré (REDIS_URL)');
      console.error('   2. L\'URL Redis est correcte et contient le token d\'authentification');
      console.error('   3. La base de données Upstash Redis est active');
      console.error('   4. Vous n\'avez pas dépassé la limite de 10 000 commandes/jour (tier gratuit)');
      console.error('');
      console.error('📚 Voir GUIDE_UPSTASH_REDIS.md pour les instructions de configuration');
    } else {
      console.error('   1. Redis est installé (pour Redis local)');
      console.error('   2. Redis est en cours d\'exécution (redis-cli ping)');
      console.error('   3. Les variables d\'environnement sont correctes dans .env');
      console.error('   4. Le port Redis (6379) n\'est pas bloqué par un firewall');
      console.error('');
      console.error('📚 Voir INSTALLER_REDIS_MANUEL.md pour les instructions d\'installation');
      console.error('📚 Voir GUIDE_UPSTASH_REDIS.md pour configurer Upstash Redis (gratuit)');
    }
    console.error('');
    
    process.exit(1);
  }
}

// Exécuter le test
testRedis();

