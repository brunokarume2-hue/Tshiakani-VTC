/**
 * Script pour créer ou mettre à jour le compte admin
 * Usage: node scripts/create-admin.js
 */

require('dotenv').config();
const AppDataSource = require('../config/database');
const User = require('../entities/User');
const bcrypt = require('bcryptjs');

async function createAdmin() {
  try {
    console.log('🔄 Connexion à la base de données...');
    await AppDataSource.initialize();
    console.log('✅ Connexion à la base de données réussie');

    const phoneNumber = '243820098808';
    const password = 'Nyota9090';
    const hashedPassword = await bcrypt.hash(password, 10);

    console.log(`\n🔍 Recherche du compte admin avec le numéro: +${phoneNumber}...`);
    
    // Utiliser une requête SQL directe pour éviter les problèmes de mapping TypeORM
    // Ne pas sélectionner password dans le SELECT initial (colonne peut ne pas exister dans certaines versions)
    const existingAdmin = await AppDataSource.query(
      `SELECT id, name, phone_number, role, is_verified
       FROM users 
       WHERE phone_number = $1 AND role = $2 
       LIMIT 1`,
      [phoneNumber, 'admin']
    );

    let adminId;
    let admin;

    if (existingAdmin && existingAdmin.length > 0) {
      adminId = existingAdmin[0].id;
      console.log('📝 Compte admin existant trouvé, mise à jour...');
      
      // Mettre à jour le compte existant
      await AppDataSource.query(
        `UPDATE users 
         SET name = $1, password = $2, is_verified = $3, updated_at = NOW()
         WHERE id = $4`,
        ['Admin', hashedPassword, true, adminId]
      );
      
      admin = {
        id: adminId,
        name: 'Admin',
        phoneNumber: phoneNumber,
        role: 'admin',
        isVerified: true
      };
      console.log('✅ Compte admin mis à jour avec succès');
    } else {
      console.log('📝 Création d\'un nouveau compte admin...');
      
      // Créer un nouveau compte admin
      const result = await AppDataSource.query(
        `INSERT INTO users (name, phone_number, role, is_verified, password, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
         RETURNING id, name, phone_number, role, is_verified`,
        ['Admin', phoneNumber, 'admin', true, hashedPassword]
      );
      
      admin = {
        id: result[0].id,
        name: result[0].name,
        phoneNumber: result[0].phone_number,
        role: result[0].role,
        isVerified: result[0].is_verified
      };
      console.log('✅ Compte admin créé avec succès');
    }

    console.log('\n📋 Informations du compte admin :');
    console.log(`   ID: ${admin.id}`);
    console.log(`   Nom: ${admin.name}`);
    console.log(`   Numéro: +${admin.phoneNumber}`);
    console.log(`   Rôle: ${admin.role}`);
    console.log(`   Vérifié: ${admin.isVerified ? 'Oui' : 'Non'}`);
    console.log(`   Mot de passe: ${password} (hashé dans la base)`);
    console.log('\n✅ Opération terminée avec succès !');

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

createAdmin();

