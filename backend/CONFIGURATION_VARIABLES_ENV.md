# 📝 Configuration des Variables d'Environnement

Ce document décrit toutes les variables d'environnement nécessaires pour le déploiement sur Firebase/GCP.

## 🔧 Fichier de configuration

Copiez le fichier `ENV.example` vers `.env` et remplissez les valeurs:

```bash
cd backend
cp ENV.example .env
```

## 📋 Variables d'environnement

### Environnement

- `NODE_ENV`: Environnement d'exécution (`production`, `development`)
- `PORT`: Port d'écoute du serveur (par défaut: `3000`)

### Base de données PostgreSQL

#### Option 1: URL de connexion complète (Recommandé pour GCP Cloud SQL)

```env
DATABASE_URL=postgresql://username:password@host:5432/database_name
```

Pour Cloud SQL avec Unix socket:
```env
DATABASE_URL=postgresql://user:password@/database?host=/cloudsql/project:region:instance
```

#### Option 2: Variables individuelles

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_NAME=tshiakani_vtc
```

#### Connection Pooling (Optionnel)

```env
DB_POOL_MAX=20
DB_POOL_CONNECTION_TIMEOUT=2000
DB_POOL_IDLE_TIMEOUT=30000
DB_STATEMENT_TIMEOUT=30000
```

### Sécurité

#### JWT Secret

Générer une clé forte (minimum 64 caractères):

```bash
openssl rand -hex 32
```

```env
JWT_SECRET=your_jwt_secret_here_min_64_characters_long
```

#### Clé API Admin

```env
ADMIN_API_KEY=your_admin_api_key_here
```

### CORS

URLs autorisées (séparées par des virgules):

```env
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app
```

Pour le développement local:
```env
CORS_ORIGIN=http://localhost:5173,http://localhost:3001
```

### Rate Limiting

```env
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Firebase Admin SDK

#### Option 1: Fichier de service account (Recommandé)

Télécharger depuis Firebase Console > Project Settings > Service Accounts

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

#### Option 2: Variables d'environnement

```env
FIREBASE_PROJECT_ID=tshiakani-vtc
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tshiakani-vtc.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
```

### Stripe (Paiements)

```env
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_CURRENCY=CDF
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

### Google Cloud Platform (GCP)

```env
GCP_PROJECT_ID=tshiakani-vtc
GCP_INSTANCE_CONNECTION_NAME=tshiakani-vtc:region:instance-name
GCP_STORAGE_BUCKET=tshiakani-vtc-uploads
```

### Google Maps API

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### Logging

```env
LOG_LEVEL=info
LOG_FORMAT=json
```

### Monitoring (Optionnel)

#### Sentry

```env
SENTRY_DSN=your_sentry_dsn_here
```

### WebSocket (Socket.io)

```env
WS_CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app
```

## 🔒 Sécurité sur GCP

### Utiliser Secret Manager

Pour la production sur GCP, utilisez Secret Manager au lieu de variables d'environnement en texte clair:

```bash
# Créer un secret
echo -n "your-secret-value" | gcloud secrets create secret-name --data-file=-

# Accéder au secret dans Cloud Run
gcloud run deploy service-name \
  --set-secrets "SECRET_NAME=secret-name:latest"
```

### Secrets recommandés

- `jwt-secret`: Clé JWT
- `admin-api-key`: Clé API admin
- `stripe-secret-key`: Clé secrète Stripe
- `database-password`: Mot de passe de la base de données
- `firebase-private-key`: Clé privée Firebase (si utilisé)

## 📝 Configuration pour Cloud Run

Lors du déploiement sur Cloud Run, utilisez `--set-secrets`:

```bash
gcloud run deploy tshiakani-vtc-api \
  --set-secrets "JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest"
```

## 📝 Configuration pour App Engine

Dans `app.yaml`, définissez les variables d'environnement:

```yaml
env_variables:
  NODE_ENV: production
  PORT: 8080
```

Pour les secrets, utilisez Secret Manager avec `secret_env_vars`:

```yaml
secret_env_vars:
  - name: JWT_SECRET
    secret: jwt-secret
    version: latest
```

## ✅ Vérification

Après configuration, vérifiez que:

1. Toutes les variables obligatoires sont définies
2. Les valeurs sont correctes
3. Les secrets sont stockés de manière sécurisée
4. Le fichier `.env` n'est pas commité dans Git (vérifiez `.gitignore`)

## 🆘 Dépannage

### Erreur "Variable not defined"

Vérifiez que toutes les variables obligatoires sont définies dans `.env` ou dans les secrets GCP.

### Erreur de connexion à la base de données

Vérifiez que:
- Les identifiants sont corrects
- La base de données est accessible
- Le format de `DATABASE_URL` est correct

### Erreur d'authentification Firebase

Vérifiez que:
- Le fichier `firebase-service-account.json` existe
- Les permissions sont correctes
- Le projet Firebase est correctement configuré

