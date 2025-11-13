# Guide de Déploiement en Production

## Prérequis

1. **Compte Google Cloud Platform** (pour Cloud Run)
2. **PostgreSQL avec PostGIS** (Cloud SQL ou instance gérée)
3. **Redis** (Memorystore ou instance gérée)
4. **Variables d'environnement** configurées
5. **Docker** (optionnel, pour containerisation)

## Étape 1 : Préparer l'Environnement de Production

### 1.1 Variables d'Environnement

Créer un fichier `.env.production` :

```bash
# Base de données
DB_HOST=your-db-host
DB_PORT=5432
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_NAME=tshiakani_vtc

# JWT
JWT_SECRET=your-super-secret-jwt-key-min-32-characters
JWT_EXPIRES_IN=7d

# Redis
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

# Node.js
NODE_ENV=production
PORT=3000

# CORS
CORS_ORIGIN=https://your-domain.com,https://your-ios-app.com

# Twilio (pour OTP)
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number

# Firebase (pour notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Stripe (pour paiements)
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key

# Google Cloud Storage (pour fichiers)
GCS_BUCKET_NAME=your-gcs-bucket-name
GCS_PROJECT_ID=your-gcs-project-id

# Monitoring (optionnel)
GCP_PROJECT_ID=your-gcp-project-id
GOOGLE_CLOUD_PROJECT=your-gcp-project-id
```

### 1.2 Configuration de la Base de Données

#### Créer la Base de Données

```sql
CREATE DATABASE tshiakani_vtc;
\c tshiakani_vtc
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

#### Exécuter les Migrations

```bash
# Migration initiale
psql -U postgres -d tshiakani_vtc -f migrations/001_init_postgis.sql

# Migration des nouvelles fonctionnalités
psql -U postgres -d tshiakani_vtc -f migrations/006_create_new_features_tables.sql
```

### 1.3 Configuration Redis

Assurez-vous que Redis est configuré et accessible depuis votre environnement de production.

## Étape 2 : Désactiver la Synchronisation TypeORM

### 2.1 Modifier `backend/config/database.js`

```javascript
const AppDataSource = new DataSource({
  ...dbConfig,
  synchronize: false, // DÉSACTIVER en production
  logging: ['error', 'warn'], // Seulement erreurs et warnings en production
  // ...
});
```

### 2.2 Utiliser les Migrations

En production, utilisez les migrations SQL au lieu de `synchronize: true`.

## Étape 3 : Déploiement sur Google Cloud Run

### 3.1 Créer un Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copier les fichiers de configuration
COPY package*.json ./
COPY .env.production .env

# Installer les dépendances
RUN npm ci --only=production

# Copier le code source
COPY . .

# Exposer le port
EXPOSE 3000

# Démarrer l'application
CMD ["node", "server.postgres.js"]
```

### 3.2 Créer un fichier `.dockerignore`

```
node_modules
.env
.env.local
.env.development
logs
*.log
.git
.gitignore
README.md
```

### 3.3 Build et Push vers Google Container Registry

```bash
# Build l'image Docker
docker build -t gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend .

# Push vers Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend
```

### 3.4 Déployer sur Cloud Run

```bash
# Déployer sur Cloud Run
gcloud run deploy tshiakani-vtc-backend \
  --image gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production \
  --set-env-vars DB_HOST=your-db-host \
  --set-env-vars DB_USER=your-db-user \
  --set-env-vars DB_PASSWORD=your-db-password \
  --set-env-vars DB_NAME=tshiakani_vtc \
  --set-env-vars JWT_SECRET=your-jwt-secret \
  --set-env-vars REDIS_HOST=your-redis-host \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10
```

### 3.5 Configurer Cloud SQL

```bash
# Connecter Cloud Run à Cloud SQL
gcloud run services update tshiakani-vtc-backend \
  --add-cloudsql-instances YOUR_INSTANCE_CONNECTION_NAME \
  --region us-central1
```

## Étape 4 : Configuration de l'Application iOS

### 4.1 Mettre à jour l'URL de l'API

Dans `Tshiakani VTC/Services/ConfigurationService.swift` :

```swift
var apiBaseURL: String {
  #if DEBUG
  // URL de développement
  return "http://localhost:3000"
  #else
  // URL de production
  return "https://your-cloud-run-url.run.app"
  #endif
}
```

### 4.2 Mettre à jour les Variables d'Environnement

Dans `Info.plist` ou via les variables d'environnement Xcode :

```xml
<key>API_BASE_URL</key>
<string>https://your-cloud-run-url.run.app</string>
```

## Étape 5 : Tests de Production

### 5.1 Test de Santé

```bash
curl https://your-cloud-run-url.run.app/health
```

### 5.2 Test d'Authentification

```bash
curl -X POST https://your-cloud-run-url.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000001","role":"client"}'
```

### 5.3 Test des Endpoints Protégés

```bash
# Obtenir un token
TOKEN=$(curl -s -X POST https://your-cloud-run-url.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000001","role":"client"}' | jq -r '.token')

# Tester un endpoint protégé
curl -X GET https://your-cloud-run-url.run.app/api/support/faq \
  -H "Authorization: Bearer $TOKEN"
```

## Étape 6 : Monitoring et Logs

### 6.1 Cloud Logging

Les logs sont automatiquement envoyés à Cloud Logging si `GCP_PROJECT_ID` est configuré.

### 6.2 Cloud Monitoring

Les métriques sont automatiquement envoyées à Cloud Monitoring si `GCP_PROJECT_ID` est configuré.

### 6.3 Alertes

Configurer des alertes pour :
- Erreurs 5xx
- Temps de réponse élevé
- Taux d'erreur élevé
- Utilisation de la mémoire/CPU

## Étape 7 : Sécurité

### 7.1 Secrets

Utiliser Google Secret Manager pour stocker les secrets :

```bash
# Créer un secret
echo -n "your-jwt-secret" | gcloud secrets create jwt-secret --data-file=-

# Accéder au secret dans Cloud Run
gcloud run services update tshiakani-vtc-backend \
  --set-secrets JWT_SECRET=jwt-secret:latest \
  --region us-central1
```

### 7.2 CORS

Configurer CORS pour autoriser uniquement les origines autorisées :

```javascript
const corsOrigins = process.env.CORS_ORIGIN 
  ? process.env.CORS_ORIGIN.split(',')
  : [];
```

### 7.3 Rate Limiting

Le rate limiting est déjà configuré dans `server.postgres.js` :

```javascript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // 100 requêtes par fenêtre
});
```

### 7.4 Helmet

Helmet est déjà configuré pour sécuriser les headers HTTP.

## Étape 8 : Backup et Récupération

### 8.1 Backup de la Base de Données

```bash
# Backup quotidien
pg_dump -U postgres -d tshiakani_vtc > backup_$(date +%Y%m%d).sql

# Restauration
psql -U postgres -d tshiakani_vtc < backup_20241113.sql
```

### 8.2 Backup Cloud SQL

Configurer des backups automatiques dans Cloud SQL :
- Fréquence : Quotidienne
- Rétention : 7 jours
- Point-in-time recovery : Activé

## Étape 9 : Scaling

### 9.1 Cloud Run Auto-scaling

Cloud Run scale automatiquement selon la charge :
- Min instances : 1
- Max instances : 10
- CPU : 1
- Memory : 512Mi

### 9.2 Database Connection Pooling

Le pooling de connexions est déjà configuré dans `database.js` :

```javascript
extra: {
  max: 20, // Nombre max de connexions
  connectionTimeoutMillis: 2000,
  idleTimeoutMillis: 30000
}
```

## Étape 10 : Checklist de Déploiement

### Pré-déploiement
- [ ] Variables d'environnement configurées
- [ ] Base de données créée et migrée
- [ ] Redis configuré
- [ ] Secrets stockés dans Secret Manager
- [ ] CORS configuré
- [ ] Rate limiting configuré
- [ ] Monitoring configuré

### Déploiement
- [ ] Dockerfile créé
- [ ] Image Docker buildée
- [ ] Image pushée vers GCR
- [ ] Service déployé sur Cloud Run
- [ ] Cloud SQL connecté
- [ ] Health check fonctionne
- [ ] Authentification fonctionne

### Post-déploiement
- [ ] Tests de production effectués
- [ ] Monitoring vérifié
- [ ] Logs vérifiés
- [ ] Alertes configurées
- [ ] Backup configuré
- [ ] Documentation mise à jour

## 📝 Notes

- Utiliser des secrets pour toutes les informations sensibles
- Configurer des backups automatiques
- Monitorer les performances et les erreurs
- Configurer des alertes pour les problèmes critiques
- Tester régulièrement les sauvegardes
- Documenter les procédures de récupération

## 🚀 Commandes Utiles

### Déploiement
```bash
# Build et push
docker build -t gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend .
docker push gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend

# Déployer
gcloud run deploy tshiakani-vtc-backend \
  --image gcr.io/YOUR_PROJECT_ID/tshiakani-vtc-backend \
  --platform managed \
  --region us-central1
```

### Logs
```bash
# Voir les logs
gcloud run logs read tshiakani-vtc-backend --region us-central1

# Suivre les logs en temps réel
gcloud run logs tail tshiakani-vtc-backend --region us-central1
```

### Monitoring
```bash
# Voir les métriques
gcloud monitoring dashboards list

# Voir les alertes
gcloud alpha monitoring policies list
```

## ✅ Conclusion

Le backend est prêt pour le déploiement en production. Suivez les étapes ci-dessus pour déployer sur Google Cloud Run ou votre plateforme préférée.

