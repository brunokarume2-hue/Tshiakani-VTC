# 🎯 Guide des Actions Suivantes

Guide complet pour les prochaines étapes de votre projet Tshiakani VTC.

## 📋 Vue d'Ensemble

1. ✅ **Tester les endpoints API** - Vérifier que tout fonctionne
2. ✅ **Connecter l'application iOS** - Configurer l'app mobile
3. ✅ **Connecter le dashboard admin** - Configurer le dashboard React
4. ⚠️ **Configurer Cloud Storage** - Stockage de fichiers (optionnel)
5. ⚠️ **Déployer sur Cloud Run** - Mise en production (quand prêt)

---

## 1️⃣ Tester les Endpoints API

### Objectif
Vérifier que tous les endpoints API fonctionnent correctement.

### Étapes

#### 1.1 Health Check
```bash
curl http://localhost:3000/health
```

**Réponse attendue:**
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "..."
}
```

#### 1.2 Test d'Authentification

**Créer un utilisateur:**
```bash
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "name": "Test User"
  }'
```

**Réponse attendue:**
```json
{
  "success": true,
  "message": "Code OTP envoyé",
  "userId": 1
}
```

#### 1.3 Test des Routes Driver

**Obtenir les courses disponibles:**
```bash
# Nécessite un token d'authentification
curl -X GET http://localhost:3000/api/driver/rides/available \
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 1.4 Test des Routes Client

**Créer une course:**
```bash
curl -X POST http://localhost:3000/api/rides/create \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "pickupAddress": "Kinshasa, RDC",
    "dropoffAddress": "Aéroport de N'djili",
    "pickupLatitude": -4.3276,
    "pickupLongitude": 15.3136,
    "dropoffLatitude": -4.3858,
    "dropoffLongitude": 15.4444
  }'
```

### Script de Test Complet

Créez un fichier `backend/scripts/test-api.sh`:

```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🧪 Test des endpoints API..."
echo ""

# Health check
echo "1. Health Check..."
curl -s $BASE_URL/health | jq .
echo ""

# Test d'authentification
echo "2. Test d'authentification..."
curl -s -X POST $BASE_URL/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000000", "name": "Test User"}' | jq .
echo ""

echo "✅ Tests terminés"
```

---

## 2️⃣ Connecter l'Application iOS

### Objectif
Configurer l'application iOS pour se connecter au backend.

### Étapes

#### 2.1 Configurer l'URL de l'API

**Fichier:** `Tshiakani VTC/Services/APIService.swift`

```swift
class APIService {
    // Pour le développement local
    #if DEBUG
    private let baseURL = "http://localhost:3000/api"
    #else
    // Pour la production (Cloud Run)
    private let baseURL = "https://tshiakani-vtc-api-xxxxx.run.app/api"
    #endif
    
    // ... reste du code
}
```

#### 2.2 Configurer pour iOS Simulator

**Problème:** L'iPhone Simulator ne peut pas accéder à `localhost` directement.

**Solution:** Utiliser l'adresse IP de votre machine.

```swift
// Obtenir l'adresse IP locale
#if targetEnvironment(simulator)
private let baseURL = "http://192.168.1.X:3000/api"  // Remplacez X par votre IP
#else
private let baseURL = "http://localhost:3000/api"
#endif
```

**Trouver votre adresse IP:**
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1
```

#### 2.3 Configurer CORS dans le Backend

**Fichier:** `backend/server.postgres.js`

```javascript
app.use(cors({
  origin: [
    "http://localhost:3001",
    "http://localhost:5173",
    "http://192.168.1.X:3000",  // Adresse IP de votre machine
    "capacitor://localhost",     // Pour Capacitor
    "ionic://localhost"          // Pour Ionic
  ],
  credentials: true
}));
```

#### 2.4 Tester la Connexion depuis l'App iOS

**Créer une fonction de test:**
```swift
func testConnection() async {
    do {
        let url = URL(string: "\(baseURL)/../health")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(HealthResponse.self, from: data)
        print("✅ Connexion réussie: \(response.status)")
    } catch {
        print("❌ Erreur de connexion: \(error)")
    }
}
```

### Checklist iOS

- [ ] URL de l'API configurée
- [ ] CORS configuré dans le backend
- [ ] Test de connexion réussi
- [ ] Authentification fonctionnelle
- [ ] Création de course testée
- [ ] WebSocket fonctionnel

---

## 3️⃣ Connecter le Dashboard Admin

### Objectif
Configurer le dashboard React pour se connecter au backend.

### Étapes

#### 3.1 Configurer l'URL de l'API

**Fichier:** `admin-dashboard/src/services/api.js`

```javascript
// Pour le développement local
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

// Pour la production
// const API_URL = 'https://tshiakani-vtc-api-xxxxx.run.app/api';

export default API_URL;
```

#### 3.2 Configurer les Variables d'Environnement

**Fichier:** `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_ADMIN_API_KEY=votre_admin_api_key
```

#### 3.3 Démarrer le Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

#### 3.4 Tester la Connexion

**Ouvrir:** `http://localhost:5173`

**Tester la connexion:**
- Se connecter avec les identifiants admin
- Vérifier que les données s'affichent
- Tester les fonctionnalités (courses, utilisateurs, etc.)

### Checklist Dashboard

- [ ] URL de l'API configurée
- [ ] Variables d'environnement configurées
- [ ] Dashboard démarre correctement
- [ ] Authentification fonctionnelle
- [ ] Données affichées correctement
- [ ] Fonctionnalités testées

---

## 4️⃣ Configurer Cloud Storage

### Objectif
Configurer Cloud Storage pour le stockage de fichiers (permis, cartes grises, etc.).

### Étapes

#### 4.1 Créer le Bucket

```bash
cd backend
npm run setup:storage
```

**Ou manuellement:**
```bash
gcloud config set project tshiakani-vtc
gsutil mb -p tshiakani-vtc -l us-central1 gs://tshiakani-vtc-documents
gsutil cors set backend/config/cors-storage.json gs://tshiakani-vtc-documents
```

#### 4.2 Configurer les Variables d'Environnement

**Fichier:** `backend/.env`

```env
GCP_PROJECT_ID=tshiakani-vtc
GCS_BUCKET_NAME=tshiakani-vtc-documents
GOOGLE_APPLICATION_CREDENTIALS=./config/gcp-service-account.json
```

#### 4.3 Vérifier la Configuration

```bash
cd backend
npm run verify:storage
```

#### 4.4 Tester l'Upload

```bash
# Créer un fichier de test
echo "Test document" > test.pdf

# Tester l'upload (nécessite un token d'authentification)
curl -X POST http://localhost:3000/api/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.pdf" \
  -F "documentType=permis"
```

### Checklist Cloud Storage

- [ ] Bucket créé
- [ ] CORS configuré
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Upload testé
- [ ] Téléchargement testé

---

## 5️⃣ Déployer sur Cloud Run

### Objectif
Déployer le backend sur Google Cloud Run pour la production.

### Prérequis

- ✅ Compte Google Cloud Platform
- ✅ Projet GCP créé
- ✅ Google Cloud SDK installé
- ✅ Facturation activée

### Étapes

#### 5.1 Préparer le Déploiement

```bash
cd backend

# Vérifier la configuration
npm run check

# Build l'image Docker localement (optionnel)
docker build -t tshiakani-vtc-api .
```

#### 5.2 Déployer sur Cloud Run

```bash
# Build et déployer
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api

# Déployer sur Cloud Run
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production,PORT=8080"
```

#### 5.3 Configurer les Variables d'Environnement

```bash
# Configurer les variables d'environnement
gcloud run services update tshiakani-vtc-api \
  --region us-central1 \
  --set-env-vars "NODE_ENV=production,PORT=8080,GCP_PROJECT_ID=tshiakani-vtc" \
  --update-secrets "JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest"
```

#### 5.4 Vérifier le Déploiement

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(status.url)')

# Tester
curl $SERVICE_URL/health
```

### Checklist Déploiement

- [ ] Image Docker buildée
- [ ] Service déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Secrets configurés (Secret Manager)
- [ ] Health check réussi
- [ ] Logs vérifiés
- [ ] Monitoring configuré

---

## 📊 Résumé des Actions

### Priorité Haute (Maintenant)

1. ✅ **Tester les endpoints API** - Vérifier que tout fonctionne
2. ✅ **Connecter l'application iOS** - Configurer l'app mobile
3. ✅ **Connecter le dashboard admin** - Configurer le dashboard

### Priorité Moyenne (Bientôt)

4. ⚠️ **Configurer Cloud Storage** - Quand vous avez besoin de stocker des fichiers
5. ⚠️ **Déployer sur Cloud Run** - Quand vous êtes prêt pour la production

---

## 🚀 Scripts Utiles

### Test API Complet

```bash
cd backend
./scripts/test-api.sh
```

### Configuration iOS

```bash
# Trouver l'adresse IP
ifconfig | grep "inet " | grep -v 127.0.0.1

# Tester la connexion depuis l'app
# Utiliser l'adresse IP dans APIService.swift
```

### Configuration Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

### Configuration Cloud Storage

```bash
cd backend
npm run setup:storage
npm run verify:storage
```

### Déploiement Cloud Run

```bash
cd backend
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
gcloud run deploy tshiakani-vtc-api --image gcr.io/tshiakani-vtc/tshiakani-vtc-api
```

---

## 📚 Documentation

- **Architecture:** `ARCHITECTURE_GOOGLE_CLOUD_CENTRALISEE.md`
- **API:** Voir les routes dans `backend/routes.postgres/`
- **Déploiement:** `PROCHAINES_ETAPES_FINAL.md`
- **Cloud Storage:** `backend/README_STORAGE.md`

---

**Date:** Novembre 2025  
**Version:** 1.0.0

