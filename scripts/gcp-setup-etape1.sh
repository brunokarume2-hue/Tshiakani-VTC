#!/bin/bash

# ☁️ Script d'Initialisation GCP - Étape 1
# Configuration de base pour Tshiakani VTC

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
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

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé. Veuillez l'installer d'abord."
    echo "Installation: brew install google-cloud-sdk"
    exit 1
fi

log_success "gcloud CLI trouvé"

# Configuration par défaut
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
REGION="${GCP_REGION:-us-central1}"
PROJECT_NAME="Tshiakani VTC"

log_info "Configuration:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Project Name: $PROJECT_NAME"

# Demander le compte de facturation si non défini
if [ -z "$BILLING_ACCOUNT_ID" ]; then
    log_warning "BILLING_ACCOUNT_ID n'est pas défini."
    echo "Liste des comptes de facturation disponibles:"
    gcloud billing accounts list
    echo ""
    read -p "Entrez l'ID du compte de facturation: " BILLING_ACCOUNT_ID
fi

# 1. Se connecter à GCP
log_info "Étape 1/7: Vérification de la connexion GCP..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_warning "Vous n'êtes pas connecté. Veuillez vous connecter:"
    gcloud auth login
fi
log_success "Connecté à GCP"

# 2. Créer le projet GCP
log_info "Étape 2/7: Création du projet GCP..."
if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_warning "Le projet $PROJECT_ID existe déjà."
    read -p "Voulez-vous continuer avec ce projet? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Opération annulée."
        exit 1
    fi
else
    log_info "Création du projet $PROJECT_ID..."
    gcloud projects create "$PROJECT_ID" \
        --name="$PROJECT_NAME" \
        --labels=environment=production,team=backend,app=tshiakani-vtc
    log_success "Projet $PROJECT_ID créé"
fi

# Définir le projet actif
gcloud config set project "$PROJECT_ID"
log_success "Projet $PROJECT_ID défini comme actif"

# 3. Lier le compte de facturation
log_info "Étape 3/7: Liaison du compte de facturation..."
if gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" | grep -q "billingAccounts/$BILLING_ACCOUNT_ID"; then
    log_success "Le compte de facturation est déjà lié"
else
    log_info "Liaison du compte de facturation $BILLING_ACCOUNT_ID..."
    if gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"; then
        log_success "Compte de facturation lié avec succès"
    else
        log_error "Échec de la liaison du compte de facturation"
        exit 1
    fi
fi

# 4. Activer les APIs de base
log_info "Étape 4/7: Activation des APIs de base..."
APIS=(
    "cloudresourcemanager.googleapis.com"
    "compute.googleapis.com"
    "iam.googleapis.com"
)

for api in "${APIS[@]}"; do
    log_info "Activation de $api..."
    gcloud services enable "$api" --project="$PROJECT_ID" || log_warning "Échec activation $api"
done
log_success "APIs de base activées"

# 5. Activer Cloud Run API
log_info "Étape 5/7: Activation de Cloud Run API..."
gcloud services enable run.googleapis.com --project="$PROJECT_ID"
log_success "Cloud Run API activée"

# 6. Activer Cloud SQL API
log_info "Étape 6/7: Activation de Cloud SQL API..."
gcloud services enable sqladmin.googleapis.com --project="$PROJECT_ID"
gcloud services enable sql-component.googleapis.com --project="$PROJECT_ID"
log_success "Cloud SQL API activée"

# 7. Activer Memorystore (Redis) API
log_info "Étape 7/7: Activation de Memorystore (Redis) API..."
gcloud services enable redis.googleapis.com --project="$PROJECT_ID"
log_success "Memorystore (Redis) API activée"

# 8. Activer Google Maps Platform APIs
log_info "Activation des APIs Google Maps Platform..."
MAPS_APIS=(
    "routes.googleapis.com"
    "places.googleapis.com"
    "geocoding-backend.googleapis.com"
    "maps-backend.googleapis.com"
)

for api in "${MAPS_APIS[@]}"; do
    log_info "Activation de $api..."
    gcloud services enable "$api" --project="$PROJECT_ID" || log_warning "Échec activation $api"
done
log_success "Google Maps Platform APIs activées"

# 9. Activer les APIs supplémentaires
log_info "Activation des APIs supplémentaires..."
EXTRA_APIS=(
    "containerregistry.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "logging.googleapis.com"
    "monitoring.googleapis.com"
)

for api in "${EXTRA_APIS[@]}"; do
    log_info "Activation de $api..."
    gcloud services enable "$api" --project="$PROJECT_ID" || log_warning "Échec activation $api"
done
log_success "APIs supplémentaires activées"

# 10. Créer le compte de service
log_info "Création du compte de service..."
SERVICE_ACCOUNT_NAME="tshiakani-vtc-backend"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" &> /dev/null; then
    log_warning "Le compte de service $SERVICE_ACCOUNT_EMAIL existe déjà"
else
    gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --display-name="Tshiakani VTC Backend Service Account" \
        --description="Service account pour le backend Cloud Run" \
        --project="$PROJECT_ID"
    log_success "Compte de service créé: $SERVICE_ACCOUNT_EMAIL"
fi

# 11. Accorder les permissions IAM
log_info "Configuration des permissions IAM..."

# Cloud SQL Client
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/cloudsql.client" \
    --condition=None 2>/dev/null || log_warning "Permission Cloud SQL déjà accordée"

# Redis Editor
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/redis.editor" \
    --condition=None 2>/dev/null || log_warning "Permission Redis déjà accordée"

# Secret Manager
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
    --role="roles/secretmanager.secretAccessor" \
    --condition=None 2>/dev/null || log_warning "Permission Secret Manager déjà accordée"

log_success "Permissions IAM configurées"

# 12. Vérification finale
log_info "Vérification finale..."
echo ""

# Vérifier le projet
if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_success "Projet $PROJECT_ID existe"
else
    log_error "Projet $PROJECT_ID n'existe pas"
    exit 1
fi

# Vérifier la facturation
BILLING_STATUS=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null)
if [ -n "$BILLING_ACCOUNT_ID" ] && echo "$BILLING_STATUS" | grep -q "billingAccounts/$BILLING_ACCOUNT_ID"; then
    log_success "Facturation activée"
else
    log_warning "Facturation non vérifiée"
fi

# Vérifier les APIs activées
log_info "APIs activées:"
gcloud services list --enabled --project="$PROJECT_ID" --filter="name:run.googleapis.com OR name:sqladmin.googleapis.com OR name:redis.googleapis.com OR name:routes.googleapis.com OR name:places.googleapis.com" --format="table(name,title)"

echo ""
log_success "✅ Configuration GCP terminée avec succès!"
echo ""
log_info "Prochaines étapes:"
echo "  1. Créer une clé API Google Maps: https://console.cloud.google.com/apis/credentials"
echo "  2. Configurer Cloud SQL (PostgreSQL + PostGIS)"
echo "  3. Configurer Memorystore (Redis)"
echo "  4. Déployer le backend sur Cloud Run"
echo ""
log_info "Variables d'environnement à sauvegarder:"
echo "  export GCP_PROJECT_ID=\"$PROJECT_ID\""
echo "  export GCP_REGION=\"$REGION\""
echo "  export GCP_SERVICE_ACCOUNT=\"$SERVICE_ACCOUNT_EMAIL\""
echo "  export BILLING_ACCOUNT_ID=\"$BILLING_ACCOUNT_ID\""
echo ""

