// Script pour créer un utilisateur admin par défaut
require('dotenv').config();
const AppDataSource = require('../config/database');
const User = require('../entities/User');

async function createDefaultAdmin() {
  try {
    // Initialiser la connexion à la base de données
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
      console.log('✅ Connexion à la base de données établie');
      
      // Synchroniser le schéma si nécessaire (créer les tables)
      if (process.env.NODE_ENV === 'development' || process.env.DB_SYNC === 'true') {
        console.log('🔄 Synchronisation du schéma de base de données...');
        await AppDataSource.synchronize();
        console.log('✅ Schéma synchronisé');
      }
    }

    const userRepository = AppDataSource.getRepository(User);
    
    // Numéro de téléphone par défaut pour l'admin
    const defaultPhoneNumber = '243900000000';
    
    // Vérifier si un admin existe déjà
    const existingAdmin = await userRepository.findOne({
      where: {
        phoneNumber: defaultPhoneNumber,
        role: 'admin'
      }
    });

    if (existingAdmin) {
      console.log('✅ Un admin existe déjà avec le numéro:', defaultPhoneNumber);
      console.log('   Nom:', existingAdmin.name);
      console.log('   ID:', existingAdmin.id);
      return;
    }

    // Créer l'admin par défaut
    const admin = userRepository.create({
      name: 'Admin',
      phoneNumber: defaultPhoneNumber,
      role: 'admin',
      isVerified: true
    });

    await userRepository.save(admin);
    
    console.log('✅ Admin par défaut créé avec succès!');
    console.log('   Nom:', admin.name);
    console.log('   Numéro:', admin.phoneNumber);
    console.log('   ID:', admin.id);
    console.log('');
    console.log('🔐 Identifiants de connexion:');
    console.log('   Numéro de téléphone:', `+${defaultPhoneNumber}`);
    console.log('   Mot de passe: (laissez vide)');
    
  } catch (error) {
    console.error('❌ Erreur lors de la création de l\'admin:', error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

// Exécuter le script
createDefaultAdmin();

