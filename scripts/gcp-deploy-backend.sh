#!/bin/bash

# 🚀 Script de Déploiement du Backend sur Cloud Run
# Déploie le backend Tshiakani VTC sur Google Cloud Run

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
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"
BACKEND_DIR="${BACKEND_DIR:-backend}"

log_info "Configuration du déploiement:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Service Name: $SERVICE_NAME"
log_info "  Image Name: $IMAGE_NAME"
log_info "  Backend Directory: $BACKEND_DIR"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

# Vérifier que le projet existe
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_error "Le projet $PROJECT_ID n'existe pas"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Vérifier que les APIs nécessaires sont activées
log_info "Vérification des APIs..."
REQUIRED_APIS=(
    "run.googleapis.com"
    "cloudbuild.googleapis.com"
    "containerregistry.googleapis.com"
    "sqladmin.googleapis.com"
    "redis.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if ! gcloud services list --enabled --project="$PROJECT_ID" --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        log_info "Activation de l'API: $api"
        gcloud services enable "$api" --project="$PROJECT_ID"
        log_success "API activée: $api"
    fi
done

# Aller dans le répertoire backend
cd "$BACKEND_DIR" || {
    log_error "Répertoire backend non trouvé: $BACKEND_DIR"
    exit 1
}

# Vérifier que Dockerfile existe
if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile non trouvé dans $BACKEND_DIR"
    exit 1
fi

# Construire l'image Docker
log_info "Construction de l'image Docker..."
log_warning "Cette opération peut prendre plusieurs minutes..."

docker build --platform=linux/amd64 -t "$IMAGE_NAME:latest" .

if [ $? -ne 0 ]; then
    log_error "Échec de la construction de l'image Docker"
    exit 1
fi

log_success "Image Docker construite avec succès"

# Authentifier Docker pour Google Container Registry
log_info "Authentification Docker pour GCR..."
gcloud auth configure-docker --quiet

# Push de l'image vers Google Container Registry
log_info "Envoi de l'image vers Google Container Registry..."
docker push "$IMAGE_NAME:latest"

if [ $? -ne 0 ]; then
    log_error "Échec de l'envoi de l'image"
    exit 1
fi

log_success "Image envoyée vers GCR avec succès"

# Revenir au répertoire racine
cd ..

# Demander les variables d'environnement
log_info "Configuration des variables d'environnement..."
log_warning "Les variables d'environnement doivent être configurées manuellement"
log_info "Utilisez le script gcp-set-cloud-run-env.sh pour configurer les variables"

# Déployer sur Cloud Run
log_info "Déploiement sur Cloud Run..."
log_warning "Assurez-vous que les variables d'environnement sont configurées"

gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE_NAME:latest" \
    --platform managed \
    --region "$REGION" \
    --allow-unauthenticated \
    --port 8080 \
    --memory 2Gi \
    --cpu 2 \
    --timeout 300 \
    --max-instances 10 \
    --min-instances 0 \
    --concurrency 80 \
    --project "$PROJECT_ID"

if [ $? -ne 0 ]; then
    log_error "Échec du déploiement sur Cloud Run"
    exit 1
fi

# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
    --region "$REGION" \
    --project "$PROJECT_ID" \
    --format "value(status.url)")

log_success "✅ Backend déployé avec succès sur Cloud Run!"
echo ""
log_info "URL du service: $SERVICE_URL"
echo ""
log_warning "⚠️  N'oubliez pas de configurer les variables d'environnement:"
log_info "   Utilisez: ./scripts/gcp-set-cloud-run-env.sh"
echo ""
log_info "Prochaines étapes:"
echo "  1. Configurer les variables d'environnement"
echo "  2. Configurer les permissions IAM"
echo "  3. Tester le service: curl $SERVICE_URL/health"
echo ""

