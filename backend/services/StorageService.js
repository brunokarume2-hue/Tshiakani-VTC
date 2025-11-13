/**
 * Service pour gérer le stockage de fichiers sur Google Cloud Storage
 * Utilisé pour stocker les documents: permis de conduire, cartes grises, assurances
 */

const { Storage } = require('@google-cloud/storage');
const path = require('path');

// Initialiser Cloud Storage
let storage = null;
let bucket = null;
let isStorageEnabled = false;

/**
 * Initialise Cloud Storage de manière sécurisée
 */
function initializeStorage() {
  // Si déjà initialisé avec succès, ne pas réessayer
  if (isStorageEnabled && bucket !== null) {
    return;
  }
  
  // Si on a déjà essayé et échoué en production, ne pas réessayer indéfiniment
  if (storage === null && process.env.NODE_ENV === 'production' && !process.env.GOOGLE_APPLICATION_CREDENTIALS && !process.env.GCP_PROJECT_ID) {
    return;
  }

  try {
    // Configuration pour Cloud Run (utilise les credentials par défaut)
    // Ou utiliser un fichier de credentials pour le développement local
    const storageConfig = {};

    // Ajouter le projectId si disponible
    const projectId = process.env.GCP_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT;
    if (projectId) {
      storageConfig.projectId = projectId;
    }

    // Si on a un fichier de credentials (développement local)
    if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
      storageConfig.keyFilename = process.env.GOOGLE_APPLICATION_CREDENTIALS;
    }

    // En production sur Cloud Run, on peut initialiser sans config explicite
    // Les credentials sont automatiquement disponibles via le service account
    if (Object.keys(storageConfig).length === 0 && process.env.NODE_ENV === 'production') {
      // En production, on essaie d'initialiser sans config (utilise les credentials par défaut)
      storage = new Storage();
    } else if (Object.keys(storageConfig).length > 0) {
      storage = new Storage(storageConfig);
    } else {
      // En développement local sans credentials, on ne peut pas initialiser
      console.warn('⚠️ Cloud Storage non configuré. Les uploads de fichiers ne fonctionneront pas.');
      console.warn('   Pour activer Cloud Storage, configurez GOOGLE_APPLICATION_CREDENTIALS ou déployez sur Cloud Run.');
      return;
    }

    const bucketName = process.env.GCS_BUCKET_NAME || 'tshiakani-vtc-documents';
    bucket = storage.bucket(bucketName);
    isStorageEnabled = true;
    
    console.log(`✅ Cloud Storage initialisé avec le bucket: ${bucketName}`);
  } catch (error) {
    console.error('❌ Erreur initialisation Cloud Storage:', error.message);
    // En développement local, on peut continuer sans Cloud Storage
    if (process.env.NODE_ENV === 'production') {
      console.error('⚠️ En production, Cloud Storage est requis. Vérifiez la configuration.');
      // Ne pas throw pour éviter de planter le serveur, mais marquer comme non disponible
      isStorageEnabled = false;
    } else {
      console.warn('⚠️ Cloud Storage non disponible en développement. Mode dégradé activé.');
      isStorageEnabled = false;
    }
  }
}

// Initialiser au chargement du module
initializeStorage();

class StorageService {
  /**
   * Upload un fichier vers Cloud Storage
   * @param {Buffer} fileBuffer - Buffer du fichier
   * @param {string} fileName - Nom du fichier original
   * @param {string} folder - Dossier de destination (ex: 'permis', 'cartes-grises', 'assurances', 'vehicles')
   * @param {number} userId - ID de l'utilisateur propriétaire du fichier
   * @returns {Promise<{url: string, path: string}>} URL publique et chemin du fichier
   */
  static async uploadFile(fileBuffer, fileName, folder = 'documents', userId = null) {
    // Réessayer l'initialisation si nécessaire
    if (!isStorageEnabled && !bucket) {
      initializeStorage();
    }

    if (!bucket || !isStorageEnabled) {
      throw new Error('Cloud Storage n\'est pas configuré. Vérifiez les variables d\'environnement GCP_PROJECT_ID et GCS_BUCKET_NAME.');
    }

    try {
      // Générer un nom de fichier unique
      const timestamp = Date.now();
      const sanitizedName = fileName.replace(/[^a-zA-Z0-9.-]/g, '_');
      const filePath = userId 
        ? `${folder}/${userId}/${timestamp}-${sanitizedName}`
        : `${folder}/${timestamp}-${sanitizedName}`;
      
      const file = bucket.file(filePath);

      // Upload du fichier
      await file.save(fileBuffer, {
        metadata: {
          contentType: this.getContentType(fileName),
          metadata: {
            originalName: fileName,
            uploadedAt: new Date().toISOString(),
            userId: userId?.toString() || null
          }
        },
        public: false // Fichiers privés par défaut (accès via signed URL)
      });

      // Générer une URL signée valide pendant 1 an
      const [signedUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + 365 * 24 * 60 * 60 * 1000 // 1 an
      });

      return {
        url: signedUrl,
        path: filePath,
        publicUrl: `https://storage.googleapis.com/${bucket.name}/${filePath}`,
        bucket: bucket.name
      };
    } catch (error) {
      console.error('Erreur upload fichier:', error);
      throw new Error(`Erreur lors de l'upload: ${error.message}`);
    }
  }

  /**
   * Supprimer un fichier
   * @param {string} filePath - Chemin du fichier dans le bucket
   */
  static async deleteFile(filePath) {
    if (!bucket || !isStorageEnabled) {
      throw new Error('Cloud Storage n\'est pas configuré');
    }

    try {
      await bucket.file(filePath).delete();
      return { success: true, message: 'Fichier supprimé avec succès' };
    } catch (error) {
      console.error('Erreur suppression fichier:', error);
      throw new Error(`Erreur lors de la suppression: ${error.message}`);
    }
  }

  /**
   * Obtenir une URL signée pour un fichier
   * @param {string} filePath - Chemin du fichier
   * @param {number} expiresIn - Durée de validité en millisecondes (défaut: 1 heure)
   * @returns {Promise<string>} URL signée
   */
  static async getSignedUrl(filePath, expiresIn = 60 * 60 * 1000) {
    if (!bucket || !isStorageEnabled) {
      throw new Error('Cloud Storage n\'est pas configuré');
    }

    try {
      const file = bucket.file(filePath);
      const [signedUrl] = await file.getSignedUrl({
        action: 'read',
        expires: Date.now() + expiresIn
      });
      return signedUrl;
    } catch (error) {
      console.error('Erreur génération URL signée:', error);
      throw new Error(`Erreur lors de la génération de l'URL: ${error.message}`);
    }
  }

  /**
   * Vérifier si un fichier existe
   * @param {string} filePath - Chemin du fichier
   * @returns {Promise<boolean>} True si le fichier existe
   */
  static async fileExists(filePath) {
    if (!bucket || !isStorageEnabled) {
      return false;
    }

    try {
      const [exists] = await bucket.file(filePath).exists();
      return exists;
    } catch (error) {
      console.error('Erreur vérification fichier:', error);
      return false;
    }
  }

  /**
   * Obtenir les métadonnées d'un fichier
   * @param {string} filePath - Chemin du fichier
   * @returns {Promise<Object>} Métadonnées du fichier
   */
  static async getFileMetadata(filePath) {
    if (!bucket || !isStorageEnabled) {
      throw new Error('Cloud Storage n\'est pas configuré');
    }

    try {
      const [metadata] = await bucket.file(filePath).getMetadata();
      return metadata;
    } catch (error) {
      console.error('Erreur récupération métadonnées:', error);
      throw new Error(`Erreur lors de la récupération des métadonnées: ${error.message}`);
    }
  }

  /**
   * Obtenir le type MIME d'un fichier
   * @param {string} fileName - Nom du fichier
   * @returns {string} Type MIME
   */
  static getContentType(fileName) {
    const ext = path.extname(fileName).toLowerCase();
    const types = {
      '.pdf': 'application/pdf',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.gif': 'image/gif',
      '.doc': 'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls': 'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    };
    return types[ext] || 'application/octet-stream';
  }

  /**
   * Valider le type de fichier
   * @param {string} fileName - Nom du fichier
   * @param {string[]} allowedTypes - Types de fichiers autorisés (extensions)
   * @returns {boolean} True si le type est autorisé
   */
  static validateFileType(fileName, allowedTypes = ['.pdf', '.jpg', '.jpeg', '.png', '.webp']) {
    const ext = path.extname(fileName).toLowerCase();
    return allowedTypes.includes(ext);
  }

  /**
   * Valider la taille du fichier
   * @param {number} fileSize - Taille du fichier en bytes
   * @param {number} maxSize - Taille maximale en bytes (défaut: 10MB)
   * @returns {boolean} True si la taille est valide
   */
  static validateFileSize(fileSize, maxSize = 10 * 1024 * 1024) {
    return fileSize <= maxSize;
  }
}

module.exports = StorageService;

