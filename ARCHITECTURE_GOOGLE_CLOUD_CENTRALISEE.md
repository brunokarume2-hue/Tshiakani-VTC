# 🏗️ Architecture Google Cloud Centralisée - Tshiakani VTC

Guide complet pour mettre en place l'architecture Google Cloud centralisée pour le projet Tshiakani VTC.

## 📋 Vue d'ensemble

Cette architecture centralise tous les services sur Google Cloud Platform pour une gestion simplifiée, une scalabilité optimale et une sécurité renforcée.

```
┌─────────────────────────────────────────────────────────────────┐
│              Architecture Centralisée Google Cloud               │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  iOS Client App  │  │  iOS Driver App  │  │  Dashboard Admin │
│   (Firebase)     │  │   (Firebase)     │  │ (Firebase Hosting)│
└────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Firebase Auth       │
                    │   (Authentification)  │
                    └───────────┬───────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Backend API         │
                    │   (Cloud Run)         │
                    └───────────┬───────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
┌────────▼─────────┐  ┌────────▼─────────┐  ┌────────▼─────────┐
│  Cloud SQL       │  │  Cloud Storage   │  │  Firebase FCM    │
│  (PostgreSQL)    │  │  (Fichiers)      │  │  (Notifications) │
└──────────────────┘  └──────────────────┘  └──────────────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │   Pub/Sub             │
                    │   (Events Temps Réel) │
                    └───────────┬───────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
┌────────▼─────────┐  ┌────────▼─────────┐  ┌────────▼─────────┐
│  Cloud Build     │  │  Cloud Monitoring│  │  IAM + Secrets   │
│  + GitHub Actions│  │  + Logging       │  │  Manager         │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 📦 Modules de l'Architecture

### 1. ✅ Backend API → Cloud Run

**Statut:** ✅ **Déjà configuré**

**Produit Google:** Cloud Run  
**Rôle:** Héberge ton backend Node.js/NestJS en conteneur

**Ce qui existe:**
- ✅ `backend/Dockerfile` - Image Docker configurée
- ✅ `backend/cloudbuild.yaml` - Configuration Cloud Build
- ✅ `backend/scripts/deploy-cloud-run.sh` - Script de déploiement
- ✅ Backend Node.js/Express fonctionnel

**Actions à effectuer:**
1. Vérifier que Cloud Run est déployé
2. Configurer les variables d'environnement dans Cloud Run
3. Configurer les secrets dans Secret Manager

**Commandes:**
```bash
cd backend
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080
```

---

### 2. ✅ Base de données → Cloud SQL (PostgreSQL)

**Statut:** ✅ **Déjà configuré**

**Produit Google:** Cloud SQL (PostgreSQL)  
**Rôle:** Stocke chauffeurs, courses, documents, gains

**Ce qui existe:**
- ✅ Configuration PostgreSQL dans `backend/config/database.js`
- ✅ Support PostGIS pour géolocalisation
- ✅ Migrations SQL prêtes
- ✅ Entités TypeORM configurées

**Actions à effectuer:**
1. Créer l'instance Cloud SQL PostgreSQL
2. Configurer la connexion depuis Cloud Run
3. Exécuter les migrations SQL

**Commandes:**
```bash
# Créer l'instance Cloud SQL
gcloud sql instances create tshiakani-vtc-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=VOTRE_MOT_DE_PASSE

# Créer la base de données
gcloud sql databases create tshiakani_vtc \
  --instance=tshiakani-vtc-db

# Créer un utilisateur
gcloud sql users create tshiakani_user \
  --instance=tshiakani-vtc-db \
  --password=VOTRE_MOT_DE_PASSE

# Activer l'extension PostGIS
gcloud sql connect tshiakani-vtc-db --user=tshiakani_user --database=tshiakani_vtc
# Puis exécuter: CREATE EXTENSION IF NOT EXISTS postgis;
```

---

### 3. ✅ Authentification → Firebase Auth

**Statut:** ✅ **Partiellement configuré**

**Produit Google:** Firebase Auth  
**Rôle:** Gère login, tokens, sécurité, OTP

**Ce qui existe:**
- ✅ Firebase Admin SDK installé dans le backend
- ✅ Service Firebase dans l'app iOS (`FirebaseService.swift`)
- ✅ Configuration Firebase dans `FIREBASE_SETUP.md`

**Actions à effectuer:**
1. ✅ Créer le projet Firebase (déjà fait)
2. ✅ Configurer Firebase Auth avec Phone (déjà fait)
3. Configurer Firebase Auth dans le backend pour valider les tokens
4. Migrer l'authentification actuelle vers Firebase Auth

**Configuration Backend:**
```javascript
// backend/config/firebase.js
const admin = require('firebase-admin');

// Initialiser Firebase Admin
if (admin.apps.length === 0) {
  const serviceAccount = require('./firebase-service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

// Middleware pour valider les tokens Firebase
async function verifyFirebaseToken(req, res, next) {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'Token manquant' });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Token invalide' });
  }
}

module.exports = { admin, verifyFirebaseToken };
```

---

### 4. ❌ Stockage fichiers → Cloud Storage

**Statut:** ❌ **À implémenter**

**Produit Google:** Cloud Storage  
**Rôle:** Stocke permis, carte grise, assurance

**Actions à effectuer:**
1. Créer un bucket Cloud Storage
2. Configurer les permissions IAM
3. Implémenter l'upload de fichiers dans le backend
4. Créer les routes API pour l'upload

**Création du bucket:**
```bash
# Créer le bucket
gsutil mb -p tshiakani-vtc -l us-central1 gs://tshiakani-vtc-documents

# Configurer les permissions CORS
gsutil cors set backend/config/cors.json gs://tshiakani-vtc-documents
```

**Configuration CORS (`backend/config/cors.json`):**
```json
[
  {
    "origin": ["https://tshiakani-vtc.firebaseapp.com", "https://tshiakani-vtc.web.app"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "responseHeader": ["Content-Type", "Authorization"],
    "maxAgeSeconds": 3600
  }
]
```

**Installation du package:**
```bash
cd backend
npm install @google-cloud/storage
```

**Implémentation Backend (`backend/services/StorageService.js`):**
```javascript
const { Storage } = require('@google-cloud/storage');
const path = require('path');

const storage = new Storage({
  projectId: process.env.GCP_PROJECT_ID,
  keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS
});

const bucket = storage.bucket(process.env.GCS_BUCKET_NAME || 'tshiakani-vtc-documents');

class StorageService {
  /**
   * Upload un fichier vers Cloud Storage
   * @param {Buffer} fileBuffer - Buffer du fichier
   * @param {string} fileName - Nom du fichier
   * @param {string} folder - Dossier de destination (ex: 'permis', 'cartes-grises', 'assurances')
   * @returns {Promise<string>} URL publique du fichier
   */
  static async uploadFile(fileBuffer, fileName, folder = 'documents') {
    const filePath = `${folder}/${Date.now()}-${fileName}`;
    const file = bucket.file(filePath);

    await file.save(fileBuffer, {
      metadata: {
        contentType: this.getContentType(fileName)
      }
    });

    // Rendre le fichier public (optionnel)
    await file.makePublic();

    return `https://storage.googleapis.com/${bucket.name}/${filePath}`;
  }

  /**
   * Supprimer un fichier
   * @param {string} filePath - Chemin du fichier dans le bucket
   */
  static async deleteFile(filePath) {
    await bucket.file(filePath).delete();
  }

  /**
   * Obtenir le type MIME d'un fichier
   */
  static getContentType(fileName) {
    const ext = path.extname(fileName).toLowerCase();
    const types = {
      '.pdf': 'application/pdf',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp'
    };
    return types[ext] || 'application/octet-stream';
  }
}

module.exports = StorageService;
```

**Route API (`backend/routes.postgres/documents.js`):**
```javascript
const express = require('express');
const router = express.Router();
const multer = require('multer');
const StorageService = require('../services/StorageService');
const { authenticate } = require('../middlewares.postgres/auth');

const upload = multer({ storage: multer.memoryStorage() });

// Upload d'un document
router.post('/upload', authenticate, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier fourni' });
    }

    const { folder } = req.body; // 'permis', 'carte-grise', 'assurance'
    const fileName = req.file.originalname;
    const fileBuffer = req.file.buffer;

    const fileUrl = await StorageService.uploadFile(fileBuffer, fileName, folder);

    // Sauvegarder l'URL dans la base de données
    // TODO: Mettre à jour la table users avec l'URL du document

    res.json({ url: fileUrl, message: 'Fichier uploadé avec succès' });
  } catch (error) {
    console.error('Erreur upload:', error);
    res.status(500).json({ error: 'Erreur lors de l\'upload' });
  }
});

// Supprimer un document
router.delete('/:filePath', authenticate, async (req, res) => {
  try {
    await StorageService.deleteFile(req.params.filePath);
    res.json({ message: 'Fichier supprimé avec succès' });
  } catch (error) {
    console.error('Erreur suppression:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression' });
  }
});

module.exports = router;
```

**Ajouter la route dans `server.postgres.js`:**
```javascript
app.use('/api/documents', require('./routes.postgres/documents'));
```

---

### 5. ✅ Dashboard Admin → Firebase Hosting ou Cloud Run

**Statut:** ✅ **Déjà configuré**

**Produit Google:** Firebase Hosting ou Cloud Run  
**Rôle:** Héberge ton dashboard web

**Ce qui existe:**
- ✅ Dashboard React.js dans `admin-dashboard/`
- ✅ Configuration Firebase Hosting dans `firebase.json`
- ✅ Scripts de déploiement

**Actions à effectuer:**
1. Build du dashboard
2. Déploiement sur Firebase Hosting

**Commandes:**
```bash
cd admin-dashboard
npm install
npm run build
firebase deploy --only hosting
```

---

### 6. ✅ Notifications push → Firebase Cloud Messaging (FCM)

**Statut:** ✅ **Déjà implémenté**

**Produit Google:** Firebase Cloud Messaging (FCM)  
**Rôle:** Envoie des alertes aux apps Driver/Client

**Ce qui existe:**
- ✅ Firebase Admin SDK installé
- ✅ Service de notifications dans `backend/utils/notifications.js`
- ✅ Tokens FCM stockés dans la table `users`
- ✅ Notifications envoyées lors des événements de course

**Actions à effectuer:**
1. ✅ Vérifier que Firebase Admin SDK est configuré
2. ✅ Vérifier que les tokens FCM sont enregistrés
3. Tester l'envoi de notifications

**Configuration:**
Le service de notifications est déjà fonctionnel. Il suffit de vérifier que:
- Le fichier `firebase-service-account.json` existe
- Les tokens FCM sont enregistrés dans la base de données
- Les notifications sont envoyées lors des événements

---

### 7. ❌ Realtime events → Pub/Sub ou Firebase Realtime DB

**Statut:** ⚠️ **Partiellement implémenté (Socket.io actuellement)**

**Produit Google:** Pub/Sub ou Firebase Realtime DB  
**Rôle:** Gère les événements comme SOS, disponibilité

**Situation actuelle:**
- ✅ Socket.io implémenté pour les événements temps réel
- ❌ Pub/Sub non utilisé
- ❌ Firebase Realtime DB non utilisé

**Options:**
1. **Garder Socket.io** (recommandé pour l'instant) - Déjà fonctionnel
2. **Migrer vers Pub/Sub** - Pour une architecture plus scalable
3. **Utiliser Firebase Realtime DB** - Pour une intégration Firebase complète

**Recommandation:** Garder Socket.io pour l'instant car il est déjà fonctionnel. Migrer vers Pub/Sub plus tard si nécessaire.

**Si migration vers Pub/Sub:**
```bash
# Installer le package
npm install @google-cloud/pubsub

# Créer un topic
gcloud pubsub topics create ride-events
gcloud pubsub topics create sos-events
gcloud pubsub topics create driver-availability
```

---

### 8. ⚠️ CI/CD → Cloud Build + GitHub Actions

**Statut:** ⚠️ **Cloud Build configuré, GitHub Actions à ajouter**

**Produit Google:** Cloud Build + GitHub Actions  
**Rôle:** Automatise les déploiements backend

**Ce qui existe:**
- ✅ `backend/cloudbuild.yaml` - Configuration Cloud Build
- ❌ GitHub Actions non configuré

**Actions à effectuer:**
1. Configurer un trigger Cloud Build sur GitHub
2. Créer un workflow GitHub Actions
3. Configurer les secrets GitHub

**Configuration Cloud Build Trigger:**
```bash
# Créer un trigger Cloud Build
gcloud builds triggers create github \
  --repo-name=tshiakani-vtc \
  --repo-owner=VOTRE_USERNAME \
  --branch-pattern="^main$" \
  --build-config=backend/cloudbuild.yaml
```

**Workflow GitHub Actions (`.github/workflows/deploy.yml`):**
```yaml
name: Deploy to Cloud Run

on:
  push:
    branches:
      - main
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - id: 'auth'
        uses: 'google-github-actions/auth@v1'
        with:
          credentials_json: '${{ secrets.GCP_SA_KEY }}'
      
      - name: 'Set up Cloud SDK'
        uses: 'google-github-actions/setup-gcloud@v1'
      
      - name: 'Build and Deploy'
        run: |
          cd backend
          gcloud builds submit --config cloudbuild.yaml
```

**Secrets GitHub à configurer:**
- `GCP_SA_KEY`: Clé de service account JSON
- `GCP_PROJECT_ID`: ID du projet GCP

---

### 9. ❌ Monitoring → Cloud Monitoring + Logging

**Statut:** ❌ **À configurer**

**Produit Google:** Cloud Monitoring + Logging  
**Rôle:** Surveille /health, erreurs, performances

**Actions à effectuer:**
1. Activer Cloud Monitoring
2. Configurer des alertes
3. Configurer des dashboards
4. Configurer les logs structurés

**Activation:**
```bash
# Activer les APIs
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

**Configuration des alertes:**
1. Aller dans [Cloud Console > Monitoring > Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Créer des alertes pour:
   - Temps de réponse de l'API
   - Taux d'erreur HTTP
   - Utilisation de la CPU
   - Utilisation de la mémoire
   - Erreurs de base de données

**Endpoint de santé:**
Le endpoint `/health` existe déjà dans `server.postgres.js`. Il faut s'assurer qu'il renvoie les bonnes informations:

```javascript
app.get('/health', async (req, res) => {
  try {
    // Vérifier la connexion à la base de données
    await AppDataSource.query('SELECT 1');
    
    res.json({ 
      status: 'OK', 
      database: 'connected',
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'ERROR', 
      database: 'disconnected',
      error: error.message 
    });
  }
});
```

**Logs structurés:**
```javascript
// Utiliser Winston pour les logs structurés
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Dans les routes
logger.info('Ride created', { rideId, clientId, driverId });
logger.error('Database error', { error: error.message });
```

---

### 10. ⚠️ Sécurité → IAM + Secrets Manager

**Statut:** ⚠️ **Partiellement configuré**

**Produit Google:** IAM + Secrets Manager  
**Rôle:** Gère les accès, clés API, tokens sensibles

**Ce qui existe:**
- ⚠️ Secrets Manager mentionné dans la documentation
- ❌ Secrets non encore migrés vers Secret Manager

**Actions à effectuer:**
1. Créer les secrets dans Secret Manager
2. Configurer IAM pour les services
3. Migrer les variables d'environnement vers Secret Manager
4. Configurer les permissions d'accès

**Création des secrets:**
```bash
# JWT Secret
echo -n "votre-jwt-secret" | gcloud secrets create jwt-secret --data-file=-

# Admin API Key
echo -n "votre-admin-api-key" | gcloud secrets create admin-api-key --data-file=-

# Database Password
echo -n "votre-database-password" | gcloud secrets create database-password --data-file=-

# Stripe Secret Key
echo -n "votre-stripe-secret-key" | gcloud secrets create stripe-secret-key --data-file=-
```

**Configuration IAM:**
```bash
# Donner l'accès à Cloud Run pour lire les secrets
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

**Utilisation dans Cloud Run:**
```bash
gcloud run deploy tshiakani-vtc-api \
  --update-secrets="JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest,DB_PASSWORD=database-password:latest"
```

---

## 📋 Checklist de Mise en Place

### Phase 1: Infrastructure de Base ✅
- [x] Backend API sur Cloud Run
- [x] Base de données Cloud SQL PostgreSQL
- [x] Firebase Auth configuré
- [x] Dashboard sur Firebase Hosting
- [x] Notifications FCM implémentées

### Phase 2: Stockage et Fichiers ❌
- [ ] Cloud Storage bucket créé
- [ ] Routes API pour l'upload de fichiers
- [ ] Service StorageService implémenté
- [ ] Permissions IAM configurées
- [ ] CORS configuré

### Phase 3: CI/CD ⚠️
- [x] Cloud Build configuré
- [ ] GitHub Actions workflow créé
- [ ] Trigger Cloud Build configuré
- [ ] Secrets GitHub configurés

### Phase 4: Monitoring ❌
- [ ] Cloud Monitoring activé
- [ ] Alertes configurées
- [ ] Dashboards créés
- [ ] Logs structurés implémentés

### Phase 5: Sécurité ⚠️
- [ ] Secrets Manager configuré
- [ ] Secrets migrés vers Secret Manager
- [ ] IAM configuré
- [ ] Permissions d'accès configurées

---

## 🚀 Plan d'Implémentation

### Semaine 1: Stockage et Fichiers
1. Créer le bucket Cloud Storage
2. Implémenter StorageService
3. Créer les routes API pour l'upload
4. Tester l'upload de fichiers

### Semaine 2: CI/CD
1. Configurer GitHub Actions
2. Configurer Cloud Build Trigger
3. Tester le déploiement automatique
4. Documenter le processus

### Semaine 3: Monitoring
1. Activer Cloud Monitoring
2. Configurer les alertes
3. Créer les dashboards
4. Implémenter les logs structurés

### Semaine 4: Sécurité
1. Migrer les secrets vers Secret Manager
2. Configurer IAM
3. Tester les permissions
4. Documenter la sécurité

---

## 📚 Ressources

- [Documentation Cloud Run](https://cloud.google.com/run/docs)
- [Documentation Cloud SQL](https://cloud.google.com/sql/docs)
- [Documentation Cloud Storage](https://cloud.google.com/storage/docs)
- [Documentation Firebase Auth](https://firebase.google.com/docs/auth)
- [Documentation FCM](https://firebase.google.com/docs/cloud-messaging)
- [Documentation Cloud Build](https://cloud.google.com/build/docs)
- [Documentation Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Documentation Secret Manager](https://cloud.google.com/secret-manager/docs)

---

## ✅ Résumé

Cette architecture centralise tous les services sur Google Cloud Platform pour une gestion simplifiée et une scalabilité optimale. Les modules principaux sont déjà en place, il reste à implémenter:

1. **Cloud Storage** pour le stockage de fichiers
2. **GitHub Actions** pour le CI/CD
3. **Cloud Monitoring** pour le monitoring
4. **Secret Manager** pour la sécurité

Une fois ces modules implémentés, l'architecture sera complète et prête pour la production.

---

**Date de création:** Novembre 2025  
**Version:** 1.0.0

