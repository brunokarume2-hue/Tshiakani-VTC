#!/usr/bin/env node

/**
 * Script de test pour vérifier la connexion à la base de données PostgreSQL
 * Usage: node test-database-connection.js
 */

require('dotenv').config();
const { DataSource } = require('typeorm');
const AppDataSource = require('./config/database');

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

async function testDatabaseConnection() {
  log('\n═══════════════════════════════════════════════════════════════', 'cyan');
  log('🔍 VÉRIFICATION DE LA CONNEXION À LA BASE DE DONNÉES', 'cyan');
  log('═══════════════════════════════════════════════════════════════', 'cyan');
  log('');

  // Afficher la configuration (sans le mot de passe)
  log('📋 Configuration de la connexion:', 'blue');
  log(`   Host: ${process.env.DB_HOST || 'localhost'}`, 'blue');
  log(`   Port: ${process.env.DB_PORT || 5432}`, 'blue');
  log(`   User: ${process.env.DB_USER || 'postgres'}`, 'blue');
  log(`   Database: ${process.env.DB_NAME || 'tshiakani_vtc'}`, 'blue');
  log(`   Password: ${process.env.DB_PASSWORD ? '***' : 'NON CONFIGURÉ'}`, 'blue');
  log('');

  try {
    // Test 1: Initialiser la connexion
    log('📡 Test 1: Initialisation de la connexion...', 'cyan');
    await AppDataSource.initialize();
    log('✅ Connexion à PostgreSQL réussie', 'green');
    log('');

    // Test 2: Vérifier PostGIS
    log('🗺️  Test 2: Vérification de PostGIS...', 'cyan');
    try {
      const result = await AppDataSource.query("SELECT PostGIS_version();");
      if (result && result.length > 0) {
        const version = result[0].postgis_version;
        log(`✅ PostGIS est activé (version: ${version})`, 'green');
      } else {
        log('⚠️  PostGIS n\'est pas activé', 'yellow');
      }
    } catch (error) {
      log('❌ Erreur lors de la vérification de PostGIS', 'red');
      log(`   ${error.message}`, 'red');
    }
    log('');

    // Test 3: Vérifier les tables
    log('📊 Test 3: Vérification des tables...', 'cyan');
    try {
      const tables = await AppDataSource.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        ORDER BY table_name;
      `);
      
      if (tables && tables.length > 0) {
        log(`✅ ${tables.length} table(s) trouvée(s):`, 'green');
        tables.forEach(table => {
          log(`   - ${table.table_name}`, 'blue');
        });
      } else {
        log('⚠️  Aucune table trouvée dans la base de données', 'yellow');
      }
    } catch (error) {
      log('❌ Erreur lors de la vérification des tables', 'red');
      log(`   ${error.message}`, 'red');
    }
    log('');

    // Test 4: Vérifier les entités TypeORM
    log('🔍 Test 4: Vérification des entités TypeORM...', 'cyan');
    try {
      const entityMetadata = AppDataSource.entityMetadatas;
      if (entityMetadata && entityMetadata.length > 0) {
        log(`✅ ${entityMetadata.length} entité(s) configurée(s):`, 'green');
        entityMetadata.forEach(entity => {
          log(`   - ${entity.name}`, 'blue');
        });
      } else {
        log('⚠️  Aucune entité configurée', 'yellow');
      }
    } catch (error) {
      log('❌ Erreur lors de la vérification des entités', 'red');
      log(`   ${error.message}`, 'red');
    }
    log('');

    // Test 5: Test de requête simple
    log('🧪 Test 5: Test de requête simple...', 'cyan');
    try {
      const result = await AppDataSource.query('SELECT NOW() as current_time, version() as postgres_version;');
      if (result && result.length > 0) {
        log('✅ Requête réussie', 'green');
        log(`   Heure actuelle: ${result[0].current_time}`, 'blue');
        log(`   Version PostgreSQL: ${result[0].postgres_version.split(',')[0]}`, 'blue');
      }
    } catch (error) {
      log('❌ Erreur lors de la requête de test', 'red');
      log(`   ${error.message}`, 'red');
    }
    log('');

    // Test 6: Vérifier les tables spécifiques
    log('📋 Test 6: Vérification des tables spécifiques...', 'cyan');
    const requiredTables = ['user', 'ride', 'notification', 'sos_report', 'price_configuration'];
    
    for (const tableName of requiredTables) {
      try {
        const result = await AppDataSource.query(`
          SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = $1
          );
        `, [tableName]);
        
        if (result && result.length > 0 && result[0].exists) {
          // Compter les lignes
          const countResult = await AppDataSource.query(`SELECT COUNT(*) as count FROM ${tableName};`);
          const count = countResult[0].count;
          log(`✅ Table '${tableName}' existe (${count} ligne(s))`, 'green');
        } else {
          log(`⚠️  Table '${tableName}' n'existe pas`, 'yellow');
        }
      } catch (error) {
        log(`❌ Erreur lors de la vérification de la table '${tableName}'`, 'red');
        log(`   ${error.message}`, 'red');
      }
    }
    log('');

    // Test 7: Vérifier les extensions PostGIS
    log('🗺️  Test 7: Vérification des extensions PostGIS...', 'cyan');
    try {
      const extensions = await AppDataSource.query(`
        SELECT extname, extversion 
        FROM pg_extension 
        WHERE extname LIKE 'postgis%';
      `);
      
      if (extensions && extensions.length > 0) {
        log(`✅ ${extensions.length} extension(s) PostGIS installée(s):`, 'green');
        extensions.forEach(ext => {
          log(`   - ${ext.extname} (version: ${ext.extversion})`, 'blue');
        });
      } else {
        log('⚠️  Aucune extension PostGIS trouvée', 'yellow');
      }
    } catch (error) {
      log('❌ Erreur lors de la vérification des extensions', 'red');
      log(`   ${error.message}`, 'red');
    }
    log('');

    // Résumé
    log('═══════════════════════════════════════════════════════════════', 'cyan');
    log('✅ Tous les tests de connexion à la base de données sont terminés', 'green');
    log('═══════════════════════════════════════════════════════════════', 'cyan');
    log('');

  } catch (error) {
    log('═══════════════════════════════════════════════════════════════', 'red');
    log('❌ ERREUR DE CONNEXION À LA BASE DE DONNÉES', 'red');
    log('═══════════════════════════════════════════════════════════════', 'red');
    log('');
    log(`Message d'erreur: ${error.message}`, 'red');
    log('');
    log('🔧 Vérifications à faire:', 'yellow');
    log('   1. PostgreSQL est-il en cours d\'exécution?', 'yellow');
    log('   2. Les variables d\'environnement sont-elles correctement configurées?', 'yellow');
    log('   3. Le mot de passe de la base de données est-il correct?', 'yellow');
    log('   4. La base de données existe-t-elle?', 'yellow');
    log('   5. L\'utilisateur a-t-il les permissions nécessaires?', 'yellow');
    log('');
    process.exit(1);
  } finally {
    // Fermer la connexion
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
      log('🔌 Connexion fermée', 'blue');
    }
  }
}

// Exécuter les tests
testDatabaseConnection().catch(error => {
  log(`\n❌ Erreur fatale: ${error.message}`, 'red');
  process.exit(1);
});

