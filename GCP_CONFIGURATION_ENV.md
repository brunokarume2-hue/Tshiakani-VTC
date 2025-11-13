# ☁️ Configuration des Variables d'Environnement GCP

## 📋 Variables Requises

### GCP Configuration

```bash
# Projet GCP
export GCP_PROJECT_ID="tshiakani-vtc"
export GCP_REGION="us-central1"
export GCP_ZONE="us-central1-a"

# Compte de facturation (format: XXXXXX-XXXXXX-XXXXXX)
export GCP_BILLING_ACCOUNT_ID="YOUR_BILLING_ACCOUNT_ID"

# Service Account
export GCP_SERVICE_ACCOUNT="tshiakani-vtc-backend@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
```

### Google Maps Platform

```bash
# Clé API Google Maps
export GOOGLE_MAPS_API_KEY="YOUR_GOOGLE_MAPS_API_KEY"
```

### Cloud SQL (PostgreSQL)

```bash
# Instance Cloud SQL
export CLOUD_SQL_INSTANCE_NAME="tshiakani-vtc-db"
export CLOUD_SQL_DATABASE_NAME="TshiakaniVTC"
export CLOUD_SQL_USER="postgres"
export CLOUD_SQL_PASSWORD="CHANGE_ME"
export CLOUD_SQL_CONNECTION_NAME="${GCP_PROJECT_ID}:${GCP_REGION}:${CLOUD_SQL_INSTANCE_NAME}"
```

### Memorystore (Redis)

```bash
# Instance Redis
export REDIS_INSTANCE_NAME="tshiakani-vtc-redis"
export REDIS_HOST="CHANGE_ME"
export REDIS_PORT="6379"
```

### Cloud Run

```bash
# Service Cloud Run
export CLOUD_RUN_SERVICE_NAME="tshiakani-vtc-backend"
export CLOUD_RUN_REGION="${GCP_REGION}"
```

---

## 🔧 Configuration

### 1. Créer le fichier .env.gcp

```bash
# Créer le fichier
cat > .env.gcp << 'EOF'
# GCP Configuration
GCP_PROJECT_ID=tshiakani-vtc
GCP_REGION=us-central1
GCP_ZONE=us-central1-a
GCP_BILLING_ACCOUNT_ID=YOUR_BILLING_ACCOUNT_ID
GCP_SERVICE_ACCOUNT=tshiakani-vtc-backend@${GCP_PROJECT_ID}.iam.gserviceaccount.com

# Google Maps Platform
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY

# Cloud SQL
CLOUD_SQL_INSTANCE_NAME=tshiakani-vtc-db
CLOUD_SQL_DATABASE_NAME=TshiakaniVTC
CLOUD_SQL_USER=postgres
CLOUD_SQL_PASSWORD=CHANGE_ME
CLOUD_SQL_CONNECTION_NAME=${GCP_PROJECT_ID}:${GCP_REGION}:${CLOUD_SQL_INSTANCE_NAME}

# Memorystore (Redis)
REDIS_INSTANCE_NAME=tshiakani-vtc-redis
REDIS_HOST=CHANGE_ME
REDIS_PORT=6379

# Cloud Run
CLOUD_RUN_SERVICE_NAME=tshiakani-vtc-backend
CLOUD_RUN_REGION=${GCP_REGION}
EOF
```

### 2. Charger les variables

```bash
# Charger les variables
source .env.gcp

# Vérifier
echo $GCP_PROJECT_ID
echo $GOOGLE_MAPS_API_KEY
```

### 3. Sécuriser le fichier

```bash
# Retirer les permissions pour les autres utilisateurs
chmod 600 .env.gcp

# Ajouter à .gitignore
echo ".env.gcp" >> .gitignore
```

---

## 🔐 Utilisation avec Secret Manager

Pour plus de sécurité, stockez les secrets dans Secret Manager :

```bash
# Créer les secrets
gcloud secrets create jwt-secret --data-file=- <<< "your-jwt-secret"
gcloud secrets create db-password --data-file=- <<< "your-db-password"
gcloud secrets create admin-api-key --data-file=- <<< "your-admin-api-key"
gcloud secrets create google-maps-api-key --data-file=- <<< "your-google-maps-api-key"

# Accorder l'accès au compte de service
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:${GCP_SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

---

## 📝 Notes

- Ne jamais commiter le fichier `.env.gcp` dans Git
- Utiliser Secret Manager pour les secrets en production
- Les variables seront définies automatiquement après la création des ressources GCP

