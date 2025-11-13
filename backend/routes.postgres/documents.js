/**
 * Routes API pour la gestion des documents (upload, téléchargement, suppression)
 * Utilise Google Cloud Storage pour le stockage
 */

const express = require('express');
const router = express.Router();
const multer = require('multer');
const StorageService = require('../services/StorageService');
const { auth: authenticate } = require('../middlewares.postgres/auth');
const AppDataSource = require('../config/database');
const User = require('../entities/User');

// Configuration Multer pour l'upload en mémoire
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB max
  },
  fileFilter: (req, file, cb) => {
    // Valider le type de fichier
    const allowedTypes = ['.pdf', '.jpg', '.jpeg', '.png', '.webp'];
    if (StorageService.validateFileType(file.originalname, allowedTypes)) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé. Types autorisés: PDF, JPG, PNG, WEBP'));
    }
  }
});

/**
 * POST /api/documents/upload
 * Upload un document (permis, carte grise, assurance, etc.)
 */
router.post('/upload', authenticate, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    const { folder, documentType } = req.body; // folder: 'permis', 'carte-grise', 'assurance', 'vehicle'
    const userId = req.user.id;
    const fileName = req.file.originalname;
    const fileBuffer = req.file.buffer;

    // Valider la taille du fichier
    if (!StorageService.validateFileSize(fileBuffer.length)) {
      return res.status(400).json({ error: 'Fichier trop volumineux. Taille maximale: 10MB' });
    }

    // Déterminer le dossier selon le type de document
    let targetFolder = folder || 'documents';
    if (documentType) {
      const folderMap = {
        'permis': 'permis',
        'carte-grise': 'cartes-grises',
        'assurance': 'assurances',
        'vehicle': 'vehicles',
        'identity': 'identites'
      };
      targetFolder = folderMap[documentType] || targetFolder;
    }

    // Upload du fichier
    const fileInfo = await StorageService.uploadFile(
      fileBuffer,
      fileName,
      targetFolder,
      userId
    );

    // Mettre à jour la base de données avec l'URL du document
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: userId } });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Stocker l'URL du document dans driver_info si c'est un driver
    if (user.role === 'driver') {
      if (!user.driverInfo) {
        user.driverInfo = {};
      }
      if (!user.driverInfo.documents) {
        user.driverInfo.documents = {};
      }
      user.driverInfo.documents[documentType || 'other'] = {
        url: fileInfo.url,
        path: fileInfo.path,
        fileName: fileName,
        uploadedAt: new Date().toISOString()
      };
      await userRepository.save(user);
    }

    res.json({
      success: true,
      message: 'Fichier uploadé avec succès',
      file: {
        url: fileInfo.url,
        path: fileInfo.path,
        fileName: fileName,
        size: fileBuffer.length,
        type: documentType || 'other'
      }
    });
  } catch (error) {
    console.error('Erreur upload document:', error);
    
    // Gérer les erreurs spécifiques
    if (error.message && error.message.includes('Cloud Storage n\'est pas configuré')) {
      return res.status(503).json({ 
        error: 'Service de stockage temporairement indisponible',
        message: 'Cloud Storage n\'est pas configuré. Contactez l\'administrateur.'
      });
    }
    
    // Erreur de validation Multer
    if (error instanceof Error && error.message.includes('Type de fichier')) {
      return res.status(400).json({ error: error.message });
    }
    
    res.status(500).json({ 
      error: error.message || 'Erreur lors de l\'upload',
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

/**
 * GET /api/documents/url/:filePath
 * Obtenir une URL signée pour un document
 * DOIT être défini avant /:userId pour éviter les conflits de routes
 */
router.get('/url/:filePath', authenticate, async (req, res) => {
  try {
    const { filePath } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Vérifier que le fichier appartient à l'utilisateur ou que l'utilisateur est admin
    if (!filePath.includes(`/${userId}/`) && userRole !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Générer une URL signée valide pendant 1 heure
    const signedUrl = await StorageService.getSignedUrl(decodeURIComponent(filePath), 60 * 60 * 1000);

    res.json({
      success: true,
      url: signedUrl
    });
  } catch (error) {
    console.error('Erreur génération URL:', error);
    res.status(500).json({ error: error.message || 'Erreur lors de la génération de l\'URL' });
  }
});

/**
 * GET /api/documents/:userId
 * Récupérer les documents d'un utilisateur
 */
router.get('/:userId', authenticate, async (req, res) => {
  try {
    const { userId } = req.params;
    const requestingUserId = req.user.id;
    const requestingUserRole = req.user.role;

    // Vérifier que l'utilisateur peut accéder à ces documents
    if (parseInt(userId) !== requestingUserId && requestingUserRole !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: parseInt(userId) } });

    if (!user) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    // Récupérer les documents depuis driverInfo
    const documents = user.driverInfo?.documents || {};

    res.json({
      success: true,
      documents: documents
    });
  } catch (error) {
    console.error('Erreur récupération documents:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des documents' });
  }
});

/**
 * DELETE /api/documents/:filePath
 * Supprimer un document
 */
router.delete('/:filePath', authenticate, async (req, res) => {
  try {
    const { filePath } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Vérifier que le fichier appartient à l'utilisateur ou que l'utilisateur est admin
    if (!filePath.includes(`/${userId}/`) && userRole !== 'admin') {
      return res.status(403).json({ error: 'Accès refusé' });
    }

    // Supprimer le fichier
    await StorageService.deleteFile(decodeURIComponent(filePath));

    // Mettre à jour la base de données
    const userRepository = AppDataSource.getRepository(User);
    const user = await userRepository.findOne({ where: { id: userId } });

    if (user && user.driverInfo?.documents) {
      // Trouver et supprimer le document dans driverInfo
      for (const [key, doc] of Object.entries(user.driverInfo.documents)) {
        if (doc.path === filePath) {
          delete user.driverInfo.documents[key];
          await userRepository.save(user);
          break;
        }
      }
    }

    res.json({
      success: true,
      message: 'Document supprimé avec succès'
    });
  } catch (error) {
    console.error('Erreur suppression document:', error);
    res.status(500).json({ error: error.message || 'Erreur lors de la suppression' });
  }
});

module.exports = router;

