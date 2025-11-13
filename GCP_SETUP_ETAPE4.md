# 🚀 Étape 4 : Déploiement du Backend sur Cloud Run

## 🎯 Objectif

Déployer le backend Node.js/Express sur Google Cloud Run avec connexion à Cloud SQL et Memorystore (Redis).

---

## 📋 Prérequis

1. ✅ Étape 1 complétée (Projet GCP créé, APIs activées)
2. ✅ Étape 2 complétée (Cloud SQL configuré)
3. ✅ Étape 3 complétée (Memorystore Redis configuré)
4. ✅ Docker installé
5. ✅ gcloud CLI installé et configuré
6. ✅ Code backend prêt

---

## 🛠️ Structure du Backend

### Endpoints Principaux

- `POST /api/v1/auth/login` - Authentification
- `POST /api/v1/ride/request` - Requête de course
- `POST /api/v1/driver/location` - Mise à jour position conducteur (utilise Redis)
- `GET /health` - Health check

### Technologies

- **Node.js 18** (LTS)
- **Express.js** - Framework web
- **PostgreSQL + PostGIS** - Base de données
- **Redis (Memorystore)** - Cache temps réel
- **Socket.io** - Communication temps réel
- **TypeORM** - ORM
- **JWT** - Authentification
- **Firebase Admin SDK** - Notifications push
- **Stripe** - Paiements
- **Google Maps Platform** - Géolocalisation

---

## 🐳 Conteneurisation avec Docker

### Dockerfile

Le Dockerfile est optimisé pour Cloud Run :

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
USER nodejs
EXPOSE 8080
CMD ["node", "server.postgres.js"]
```

### .dockerignore

Exclut les fichiers non nécessaires :
- `node_modules`
- `.env`
- `*.log`
- Documentation
- Tests

---

## 🚀 Déploiement sur Cloud Run

### Option 1: Déploiement Automatique (Recommandé)

```bash
# 1. Déployer le backend
./scripts/gcp-deploy-backend.sh

# 2. Configurer les variables d'environnement
./scripts/gcp-set-cloud-run-env.sh
```

### Option 2: Déploiement Manuel

#### 1. Construire l'Image Docker

```bash
cd backend
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .
```

#### 2. Authentifier Docker

```bash
gcloud auth configure-docker
```

#### 3. Push de l'Image

```bash
docker push gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest
```

#### 4. Déployer sur Cloud Run

```bash
gcloud run deploy tshiakani-vtc-backend \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --concurrency 80
```

---

## 🔧 Configuration des Variables d'Environnement

### Variables Obligatoires

```bash
# Environnement
NODE_ENV=production
PORT=8080

# Base de données Cloud SQL
INSTANCE_CONNECTION_NAME=tshiakani-vtc:us-central1:tshiakani-vtc-db
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=tshiakani_vtc
DB_HOST=/cloudsql/tshiakani-vtc:us-central1:tshiakani-vtc-db

# Sécurité
JWT_SECRET=your_jwt_secret_min_64_characters
ADMIN_API_KEY=your_admin_api_key

# CORS
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### Variables Optionnelles

```bash
# Redis (Memorystore)
REDIS_HOST=10.0.0.3
REDIS_PORT=6379
REDIS_PASSWORD=

# Stripe
STRIPE_SECRET_KEY=sk_live_...

# Firebase
FIREBASE_PROJECT_ID=tshiakani-vtc
FIREBASE_SERVICE_ACCOUNT_PATH=/secrets/firebase-service-account.json

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Configuration via Script

```bash
./scripts/gcp-set-cloud-run-env.sh
```

### Configuration Manuelle

```bash
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --update-env-vars NODE_ENV=production,PORT=8080,DB_USER=postgres,...
```

---

## 🔐 Permissions IAM

### Service Account Cloud Run

Cloud Run utilise un service account pour accéder aux autres services GCP.

#### Permissions Requises

1. **Cloud SQL Client** - Pour se connecter à Cloud SQL
2. **Redis Editor** - Pour accéder à Memorystore
3. **Cloud Storage** - Pour accéder aux fichiers (si nécessaire)

#### Configuration Automatique

Le script `gcp-set-cloud-run-env.sh` configure automatiquement les permissions.

#### Configuration Manuelle

```bash
# Service account du service Cloud Run
SERVICE_ACCOUNT="tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com"

# Accorder les permissions Cloud SQL
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/cloudsql.client"

# Accorder les permissions Redis
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/redis.editor"
```

---

## 🔌 Connexion à Cloud SQL

### Socket Unix (Recommandé)

Cloud Run se connecte à Cloud SQL via un socket Unix :

```javascript
// Dans config/database.js
const isCloudSQL = process.env.INSTANCE_CONNECTION_NAME;
if (isCloudSQL) {
  dbConfig.host = `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`;
}
```

### Configuration Cloud Run

```bash
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --add-cloudsql-instances tshiakani-vtc:us-central1:tshiakani-vtc-db
```

---

## 🔴 Connexion à Memorystore (Redis)

### Réseau Privé (VPC)

Memorystore utilise un réseau privé (VPC). Cloud Run doit être dans le même VPC.

#### Configuration

1. **Créer un VPC Connector** (si nécessaire)
2. **Configurer Cloud Run pour utiliser le VPC**
3. **Configurer les variables d'environnement Redis**

```bash
# Variables d'environnement
REDIS_HOST=10.0.0.3  # IP privée de l'instance Redis
REDIS_PORT=6379
REDIS_PASSWORD=  # Vide pour Memorystore
```

#### VPC Connector

```bash
# Créer un VPC Connector
gcloud compute networks vpc-access connectors create redis-connector \
  --region=us-central1 \
  --subnet=default \
  --subnet-project=tshiakani-vtc \
  --min-instances=2 \
  --max-instances=3

# Configurer Cloud Run pour utiliser le VPC Connector
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --vpc-connector redis-connector \
  --vpc-egress all-traffic
```

---

## 📊 Configuration Cloud Run

### Ressources

- **Memory**: 2 GiB (recommandé)
- **CPU**: 2 vCPU (recommandé)
- **Timeout**: 300 secondes (5 minutes)
- **Concurrency**: 80 requêtes par instance
- **Min Instances**: 0 (scale to zero)
- **Max Instances**: 10

### Commandes

```bash
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --max-instances 10 \
  --min-instances 0 \
  --concurrency 80
```

---

## 🧪 Tests Post-Déploiement

### 1. Health Check

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region us-central1 \
  --format "value(status.url)")

# Tester le health check
curl $SERVICE_URL/health
```

### Réponse Attendue

```json
{
  "status": "OK",
  "timestamp": "2025-01-15T10:30:00Z",
  "uptime": 3600,
  "database": {
    "status": "connected"
  },
  "redis": {
    "status": "connected"
  }
}
```

### 2. Test d'Authentification

```bash
# Test de connexion
curl -X POST $SERVICE_URL/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "code": "123456"
  }'
```

### 3. Test de Création de Course

```bash
# Test de création de course
curl -X POST $SERVICE_URL/api/rides/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136
    },
    "dropoffLocation": {
      "latitude": -4.3286,
      "longitude": 15.3146
    }
  }'
```

---

## 📝 Logs et Monitoring

### Voir les Logs

```bash
# Logs en temps réel
gcloud run services logs tail tshiakani-vtc-backend \
  --region us-central1

# Logs récents
gcloud run services logs read tshiakani-vtc-backend \
  --region us-central1 \
  --limit 50
```

### Monitoring

- **Cloud Run Metrics** - Métriques de performance
- **Cloud Logging** - Logs structurés
- **Error Reporting** - Rapports d'erreurs
- **Trace** - Traçage des requêtes

---

## 🔍 Dépannage

### Erreur: "Connection refused to Cloud SQL"

```bash
# Vérifier la connexion Cloud SQL
gcloud run services describe tshiakani-vtc-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"

# Vérifier les permissions IAM
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com"
```

### Erreur: "Connection refused to Redis"

```bash
# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list \
  --region us-central1

# Vérifier les variables d'environnement Redis
gcloud run services describe tshiakani-vtc-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"
```

### Erreur: "Out of memory"

```bash
# Augmenter la mémoire
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --memory 4Gi
```

### Erreur: "Timeout"

```bash
# Augmenter le timeout
gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --timeout 600
```

---

## 📚 Ressources Utiles

- **Documentation Cloud Run**: https://cloud.google.com/run/docs
- **Documentation Cloud SQL**: https://cloud.google.com/sql/docs
- **Documentation Memorystore**: https://cloud.google.com/memorystore/docs/redis
- **Documentation Docker**: https://docs.docker.com

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée :

1. **Étape 5**: Configuration du Dashboard Admin
2. **Étape 6**: Déploiement des Applications iOS
3. **Test**: Tests end-to-end de l'application

---

## ✅ Checklist

- [ ] Dockerfile créé
- [ ] .dockerignore créé
- [ ] Image Docker construite
- [ ] Image poussée vers GCR
- [ ] Service Cloud Run créé
- [ ] Variables d'environnement configurées
- [ ] Connexion Cloud SQL configurée
- [ ] Connexion Redis configurée
- [ ] Permissions IAM configurées
- [ ] Health check fonctionne
- [ ] Tests post-déploiement réussis
- [ ] Logs configurés
- [ ] Monitoring configuré

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

