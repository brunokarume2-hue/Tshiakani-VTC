#!/bin/bash

# 🔧 Script de Configuration des Variables d'Environnement pour Cloud Run

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration par défaut
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${CLOUD_RUN_SERVICE_NAME:-tshiakani-vtc-backend}"

log_info "Configuration des variables d'environnement pour Cloud Run"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Service Name: $SERVICE_NAME"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Récupérer les informations nécessaires
log_info "Récupération des informations de configuration..."

# Récupérer l'instance Cloud SQL
CLOUD_SQL_INSTANCE=$(gcloud sql instances list --project="$PROJECT_ID" --format="value(name)" | head -n 1)
if [ -z "$CLOUD_SQL_INSTANCE" ]; then
    log_error "Aucune instance Cloud SQL trouvée"
    exit 1
fi

INSTANCE_CONNECTION_NAME="${PROJECT_ID}:${REGION}:${CLOUD_SQL_INSTANCE}"
log_info "Instance Cloud SQL: $CLOUD_SQL_INSTANCE"
log_info "Connection Name: $INSTANCE_CONNECTION_NAME"

# Récupérer l'instance Redis
REDIS_INSTANCE=$(gcloud redis instances list --project="$PROJECT_ID" --region="$REGION" --format="value(name)" | head -n 1)
if [ -z "$REDIS_INSTANCE" ]; then
    log_warning "Aucune instance Redis trouvée"
    REDIS_HOST=""
else
    REDIS_HOST=$(gcloud redis instances describe "$REDIS_INSTANCE" --region="$REGION" --project="$PROJECT_ID" --format="value(host)" 2>/dev/null)
    log_info "Instance Redis: $REDIS_INSTANCE"
    log_info "Redis Host: $REDIS_HOST"
fi

# Demander les valeurs manuelles
echo ""
log_info "Valeurs à configurer manuellement:"
echo ""

read -p "DB_USER (utilisateur PostgreSQL) [postgres]: " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "DB_PASSWORD (mot de passe PostgreSQL): " DB_PASSWORD
echo ""

read -p "DB_NAME (nom de la base de données) [tshiakani_vtc]: " DB_NAME
DB_NAME=${DB_NAME:-tshiakani_vtc}

read -p "JWT_SECRET (clé secrète JWT, minimum 64 caractères): " JWT_SECRET

read -p "ADMIN_API_KEY (clé API Admin): " ADMIN_API_KEY

read -p "GOOGLE_MAPS_API_KEY (clé API Google Maps): " GOOGLE_MAPS_API_KEY

read -p "CORS_ORIGIN (URLs autorisées, séparées par des virgules): " CORS_ORIGIN

read -p "STRIPE_SECRET_KEY (clé secrète Stripe, optionnel): " STRIPE_SECRET_KEY

read -p "FIREBASE_PROJECT_ID (ID du projet Firebase, optionnel): " FIREBASE_PROJECT_ID

# Préparer les variables d'environnement
ENV_VARS=(
    "NODE_ENV=production"
    "PORT=8080"
    "INSTANCE_CONNECTION_NAME=$INSTANCE_CONNECTION_NAME"
    "DB_USER=$DB_USER"
    "DB_PASSWORD=$DB_PASSWORD"
    "DB_NAME=$DB_NAME"
    "DB_HOST=/cloudsql/$INSTANCE_CONNECTION_NAME"
    "JWT_SECRET=$JWT_SECRET"
    "ADMIN_API_KEY=$ADMIN_API_KEY"
    "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY"
    "CORS_ORIGIN=$CORS_ORIGIN"
)

# Ajouter Redis si disponible
if [ -n "$REDIS_HOST" ]; then
    ENV_VARS+=("REDIS_HOST=$REDIS_HOST")
    ENV_VARS+=("REDIS_PORT=6379")
    ENV_VARS+=("REDIS_PASSWORD=")
fi

# Ajouter Stripe si fourni
if [ -n "$STRIPE_SECRET_KEY" ]; then
    ENV_VARS+=("STRIPE_SECRET_KEY=$STRIPE_SECRET_KEY")
fi

# Ajouter Firebase si fourni
if [ -n "$FIREBASE_PROJECT_ID" ]; then
    ENV_VARS+=("FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID")
fi

# Construire la commande
ENV_VARS_STRING=$(IFS=','; echo "${ENV_VARS[*]}")

# Définir les variables d'environnement
log_info "Configuration des variables d'environnement sur Cloud Run..."
gcloud run services update "$SERVICE_NAME" \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --update-env-vars "$ENV_VARS_STRING"

if [ $? -eq 0 ]; then
    log_success "✅ Variables d'environnement configurées avec succès!"
else
    log_error "Échec de la configuration des variables d'environnement"
    exit 1
fi

# Configurer la connexion Cloud SQL
log_info "Configuration de la connexion Cloud SQL..."
gcloud run services update "$SERVICE_NAME" \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --add-cloudsql-instances "$INSTANCE_CONNECTION_NAME"

if [ $? -eq 0 ]; then
    log_success "✅ Connexion Cloud SQL configurée avec succès!"
else
    log_warning "⚠️  La connexion Cloud SQL pourrait déjà être configurée"
fi

# Configurer les permissions IAM
log_info "Configuration des permissions IAM..."

# Service account du service Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --format "value(spec.template.spec.serviceAccountName)")

if [ -z "$SERVICE_ACCOUNT" ]; then
    # Utiliser le service account par défaut
    SERVICE_ACCOUNT="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
fi

log_info "Service Account: $SERVICE_ACCOUNT"

# Accorder les permissions Cloud SQL
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudsql.client" \
    --quiet

log_success "✅ Permissions Cloud SQL accordées"

# Accorder les permissions Redis (si disponible)
if [ -n "$REDIS_INSTANCE" ]; then
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${SERVICE_ACCOUNT}" \
        --role="roles/redis.editor" \
        --quiet
    
    log_success "✅ Permissions Redis accordées"
fi

echo ""
log_success "✅ Configuration terminée avec succès!"
echo ""
log_info "Variables d'environnement configurées:"
for var in "${ENV_VARS[@]}"; do
    echo "  - $var"
done
echo ""
log_info "Prochaines étapes:"
echo "  1. Tester le service: curl \$(gcloud run services describe $SERVICE_NAME --region $REGION --format 'value(status.url)')/health"
echo "  2. Vérifier les logs: gcloud run services logs read $SERVICE_NAME --region $REGION"
echo ""

