#!/bin/bash

# 🔍 Script de Vérification de la Configuration GCP

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

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

# Récupérer le projet actif
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    log_error "Aucun projet GCP actif. Configurez d'abord un projet."
    exit 1
fi

log_info "Vérification du projet: $PROJECT_ID"
echo ""

# 1. Vérifier le projet
log_info "1. Vérification du projet..."
if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_success "Projet $PROJECT_ID existe"
else
    log_error "Projet $PROJECT_ID n'existe pas"
    exit 1
fi

# 2. Vérifier la facturation
log_info "2. Vérification de la facturation..."
BILLING_ACCOUNT=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null)
if [ -n "$BILLING_ACCOUNT" ]; then
    log_success "Facturation activée: $BILLING_ACCOUNT"
else
    log_error "Facturation non activée"
fi

# 3. Vérifier les APIs
log_info "3. Vérification des APIs..."
REQUIRED_APIS=(
    "run.googleapis.com"
    "sqladmin.googleapis.com"
    "redis.googleapis.com"
    "routes.googleapis.com"
    "places.googleapis.com"
    "geocoding-backend.googleapis.com"
)

ALL_APIS_ENABLED=true
for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --project="$PROJECT_ID" --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        log_success "API $api activée"
    else
        log_error "API $api non activée"
        ALL_APIS_ENABLED=false
    fi
done

# 4. Vérifier le compte de service
log_info "4. Vérification du compte de service..."
SERVICE_ACCOUNT="tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT" --project="$PROJECT_ID" &> /dev/null; then
    log_success "Compte de service existe: $SERVICE_ACCOUNT"
else
    log_warning "Compte de service n'existe pas: $SERVICE_ACCOUNT"
fi

# 5. Vérifier les permissions IAM
log_info "5. Vérification des permissions IAM..."
if gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT" --format="value(bindings.role)" | grep -q "roles/cloudsql.client"; then
    log_success "Permission Cloud SQL accordée"
else
    log_warning "Permission Cloud SQL non accordée"
fi

# Résumé
echo ""
log_info "Résumé de la vérification:"
echo "  Projet: $PROJECT_ID"
echo "  Facturation: $([ -n "$BILLING_ACCOUNT" ] && echo "✅ Activée" || echo "❌ Non activée")"
echo "  APIs: $([ "$ALL_APIS_ENABLED" = true ] && echo "✅ Toutes activées" || echo "⚠️  Certaines manquantes")"
echo "  Compte de service: $([ -n "$SERVICE_ACCOUNT" ] && echo "✅ Existe" || echo "⚠️  Non trouvé")"

if [ "$ALL_APIS_ENABLED" = true ] && [ -n "$BILLING_ACCOUNT" ]; then
    echo ""
    log_success "✅ Configuration GCP valide!"
else
    echo ""
    log_warning "⚠️  Certaines vérifications ont échoué. Veuillez corriger les erreurs."
    exit 1
fi

