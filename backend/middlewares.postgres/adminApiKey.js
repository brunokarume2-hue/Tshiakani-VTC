// Middleware de sécurité pour les routes admin
// Vérifie la présence et la validité de X-ADMIN-API-KEY dans les headers

const adminApiKeyAuth = (req, res, next) => {
  try {
    // Récupérer la clé API depuis les headers
    const apiKey = req.header('X-ADMIN-API-KEY');
    
    // Récupérer la clé API attendue depuis les variables d'environnement
    const expectedApiKey = process.env.ADMIN_API_KEY;
    
    // Vérifier que la clé API est configurée
    if (!expectedApiKey) {
      console.error('⚠️ ADMIN_API_KEY non configurée dans les variables d\'environnement');
      return res.status(500).json({ 
        error: 'Configuration serveur manquante',
        message: 'La clé API admin n\'est pas configurée'
      });
    }
    
    // Vérifier que la clé API est présente dans la requête
    if (!apiKey) {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Clé API admin manquante. Veuillez inclure X-ADMIN-API-KEY dans les headers.'
      });
    }
    
    // Vérifier que la clé API est correcte
    if (apiKey !== expectedApiKey) {
      return res.status(403).json({ 
        error: 'Accès refusé',
        message: 'Clé API admin invalide'
      });
    }
    
    // Clé API valide, continuer
    next();
  } catch (error) {
    console.error('Erreur middleware adminApiKeyAuth:', error);
    res.status(500).json({ 
      error: 'Erreur serveur',
      message: 'Erreur lors de la vérification de la clé API'
    });
  }
};

module.exports = { adminApiKeyAuth };

