#!/usr/bin/env node

/**
 * Script de vérification de la configuration Cloud Storage
 * Vérifie que tout est correctement configuré avant le déploiement
 */

require('dotenv').config();
const { Storage } = require('@google-cloud/storage');

async function verifyStorageConfig() {
  console.log('🔍 Vérification de la configuration Cloud Storage...\n');

  // Vérifier les variables d'environnement
  const projectId = process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
  const bucketName = process.env.GCS_BUCKET_NAME || 'tshiakani-vtc-documents';
  const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  console.log('📋 Variables d\'environnement:');
  console.log(`   GCP_PROJECT_ID: ${projectId || '❌ NON DÉFINI'}`);
  console.log(`   GCS_BUCKET_NAME: ${bucketName}`);
  console.log(`   GOOGLE_APPLICATION_CREDENTIALS: ${credentialsPath || '❌ NON DÉFINI (utilise les credentials par défaut)'}`);
  console.log(`   NODE_ENV: ${process.env.NODE_ENV || 'development'}\n`);

  // Vérifier que le projectId est défini
  if (!projectId) {
    console.error('❌ ERREUR: GCP_PROJECT_ID ou GOOGLE_CLOUD_PROJECT doit être défini');
    process.exit(1);
  }

  // Vérifier les credentials
  if (credentialsPath) {
    const fs = require('fs');
    if (!fs.existsSync(credentialsPath)) {
      console.error(`❌ ERREUR: Le fichier de credentials n'existe pas: ${credentialsPath}`);
      process.exit(1);
    }
    console.log(`✅ Fichier de credentials trouvé: ${credentialsPath}`);
  } else {
    console.log('⚠️  Aucun fichier de credentials spécifié. En production sur Cloud Run, les credentials sont automatiques.');
  }

  // Essayer d'initialiser Cloud Storage
  try {
    const storageConfig = {};
    if (projectId) {
      storageConfig.projectId = projectId;
    }
    if (credentialsPath) {
      storageConfig.keyFilename = credentialsPath;
    }

    const storage = credentialsPath || process.env.NODE_ENV === 'production'
      ? new Storage(storageConfig)
      : new Storage();

    console.log('✅ Cloud Storage initialisé avec succès\n');

    // Vérifier que le bucket existe
    console.log(`🔍 Vérification du bucket: ${bucketName}...`);
    const bucket = storage.bucket(bucketName);
    const [exists] = await bucket.exists();

    if (exists) {
      console.log(`✅ Le bucket ${bucketName} existe\n`);
    } else {
      console.log(`⚠️  Le bucket ${bucketName} n'existe pas`);
      console.log(`   Vous pouvez le créer avec: gsutil mb -p ${projectId} -l us-central1 gs://${bucketName}\n`);
    }

    // Vérifier les permissions
    try {
      const [permissions] = await bucket.iam.getPolicy();
      console.log('✅ Permissions vérifiées\n');
    } catch (error) {
      console.error(`❌ Erreur lors de la vérification des permissions: ${error.message}\n`);
    }

    console.log('✅ Configuration Cloud Storage vérifiée avec succès!');
    process.exit(0);
  } catch (error) {
    console.error('❌ ERREUR lors de l\'initialisation de Cloud Storage:');
    console.error(`   ${error.message}\n`);
    
    if (error.code === 'ENOENT') {
      console.error('   Vérifiez que le fichier de credentials existe et est accessible.');
    } else if (error.code === '403') {
      console.error('   Vérifiez que vous avez les permissions nécessaires sur le projet GCP.');
    } else if (error.message.includes('Could not load the default credentials')) {
      console.error('   Configurez GOOGLE_APPLICATION_CREDENTIALS ou déployez sur Cloud Run.');
    }
    
    process.exit(1);
  }
}

verifyStorageConfig();

