#!/usr/bin/env node

/**
 * Script pour créer un compte de test dans la base de données PostgreSQL
 * Utilise TypeORM pour se connecter à la base de données
 * 
 * Usage: node scripts/create-test-account.js
 */

require('dotenv').config();
const AppDataSource = require('../config/database');
const User = require('../entities/User');

async function createTestAccount() {
    try {
        console.log('📱 Création du compte de test Tshiakani VTC\n');
        
        // Initialiser la connexion à la base de données
        if (!AppDataSource.isInitialized) {
            console.log('🔌 Connexion à la base de données...');
            await AppDataSource.initialize();
            console.log('✅ Connecté à la base de données\n');
        }
        
        const userRepository = AppDataSource.getRepository(User);
        
        // Vérifier si le compte de test existe déjà
        const existingUser = await userRepository.findOne({
            where: { phoneNumber: '900000000' }
        });
        
        if (existingUser) {
            console.log('⚠️  Le compte de test existe déjà');
            console.log(`   ID: ${existingUser.id}`);
            console.log(`   Nom: ${existingUser.name}`);
            console.log(`   Numéro: ${existingUser.phoneNumber}`);
            console.log(`   Rôle: ${existingUser.role}`);
            console.log('\n✅ Compte de test disponible\n');
            
            // Afficher les informations
            console.log('📋 Informations du compte de test:');
            console.log('   📱 Numéro: +243900000000');
            console.log('   👤 Nom: Compte Test');
            console.log('   🎭 Rôle: client');
            console.log('   ✅ Vérifié: true\n');
            
            await AppDataSource.destroy();
            return;
        }
        
        // Créer le compte de test
        console.log('📝 Création du compte de test...');
        
        const testUser = userRepository.create({
            name: 'Compte Test',
            phoneNumber: '900000000',
            role: 'client',
            isVerified: true
        });
        
        const savedUser = await userRepository.save(testUser);
        
        console.log('✅ Compte de test créé avec succès !\n');
        console.log('📋 Informations du compte de test:');
        console.log(`   ID: ${savedUser.id}`);
        console.log('   📱 Numéro: +243900000000');
        console.log('   👤 Nom: Compte Test');
        console.log('   🎭 Rôle: client');
        console.log('   ✅ Vérifié: true');
        console.log(`   📅 Créé le: ${savedUser.createdAt}\n`);
        console.log('🚀 Vous pouvez maintenant utiliser le bouton "Connexion rapide" dans l\'application\n');
        
        // Fermer la connexion
        await AppDataSource.destroy();
        
    } catch (error) {
        console.error('❌ Erreur lors de la création du compte de test:');
        console.error(`   ${error.message}\n`);
        
        if (error.code === 'ECONNREFUSED') {
            console.error('💡 Vérifiez que:');
            console.error('   - PostgreSQL est démarré');
            console.error('   - Les variables d\'environnement sont correctes dans .env');
            console.error('   - La base de données existe');
        } else if (error.code === '23505') {
            console.error('💡 Le compte de test existe déjà dans la base de données');
        } else {
            console.error('💡 Vérifiez:');
            console.error('   - Que PostgreSQL est installé et démarré');
            console.error('   - Que la base de données existe');
            console.error('   - Que les migrations ont été exécutées');
            console.error('   - Que les variables d\'environnement sont correctes');
        }
        
        if (AppDataSource.isInitialized) {
            await AppDataSource.destroy();
        }
        
        process.exit(1);
    }
}

// Exécuter le script
createTestAccount();

