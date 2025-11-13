// Script pour appliquer la migration 005 (ajout colonne email)
require('dotenv').config();
const AppDataSource = require('../config/database');

async function applyMigration() {
  try {
    console.log('🔄 Connexion à la base de données...');
    await AppDataSource.initialize();
    console.log('✅ Connexion à la base de données réussie');

    console.log('\n📝 Application de la migration 005: Ajout colonne email...');
    
    // Ajouter la colonne email
    await AppDataSource.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS email VARCHAR(255);
    `);
    console.log('✅ Colonne email ajoutée');

    // Créer l'index unique
    await AppDataSource.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique 
      ON users(email) 
      WHERE email IS NOT NULL;
    `);
    console.log('✅ Index unique créé');

    console.log('\n✅ Migration 005 appliquée avec succès !');
    
    await AppDataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
    process.exit(1);
  }
}

applyMigration();

