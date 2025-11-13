// Script pour ajouter la colonne 'name' à la table 'users'
// Usage: node scripts/add-name-column.js

require('dotenv').config();
const AppDataSource = require('../config/database');

async function addNameColumn() {
  try {
    console.log('🔍 Connexion à la base de données...');
    await AppDataSource.initialize();
    console.log('✅ Connecté à PostgreSQL');
    
    console.log('🔧 Ajout de la colonne "name"...');
    await AppDataSource.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255)');
    console.log('✅ Colonne "name" ajoutée avec succès');
    
    // Vérifier
    const result = await AppDataSource.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'name'
    `);
    
    if (result.length > 0) {
      console.log('✅ Vérification: Colonne "name" existe');
      console.log(`   Type: ${result[0].data_type}`);
    } else {
      console.log('⚠️  Colonne "name" non trouvée après ajout');
    }
    
    await AppDataSource.destroy();
    console.log('✅ Connexion fermée');
    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.code === '42701') {
      console.log('✅ La colonne existe déjà');
      process.exit(0);
    } else {
      process.exit(1);
    }
  }
}

addNameColumn();

