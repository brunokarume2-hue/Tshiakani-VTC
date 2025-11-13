#!/bin/bash

# Script de vérification de l'état du déploiement
# Usage: bash scripts/check-status.sh

set -e

echo "🔍 Vérification de l'état du déploiement - Tshiakani VTC"
echo "============================================================"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
REGION="us-central1"
SERVICE_NAME="tshiakani-driver-backend"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

section() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Vérifier la facturation
section "Vérification de la facturation..."
BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "true" ]; then
    info "Facturation activée"
    BILLING_ACCOUNT=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingAccountName)" 2>/dev/null || echo "")
    if [ ! -z "$BILLING_ACCOUNT" ]; then
        echo "   Compte: $BILLING_ACCOUNT"
    fi
else
    error "Facturation non activée"
    echo "   → Aller sur https://console.cloud.google.com"
    echo "   → Facturation > Gérer les comptes de facturation"
    echo "   → Lier un compte de facturation"
fi

echo ""

# Vérifier les APIs
section "Vérification des APIs..."
APIS=(
    "cloudbuild.googleapis.com"
    "run.googleapis.com"
    "artifactregistry.googleapis.com"
    "containerregistry.googleapis.com"
)

ENABLED_APIS=$(gcloud services list --enabled --project=${PROJECT_ID} --format="value(name)" 2>/dev/null || echo "")

ALL_APIS_ENABLED=true
for API in "${APIS[@]}"; do
    if echo "$ENABLED_APIS" | grep -q "$API"; then
        info "$API est activé"
    else
        error "$API n'est pas activé"
        ALL_APIS_ENABLED=false
    fi
done

if [ "$ALL_APIS_ENABLED" = "false" ]; then
    echo ""
    echo "   Pour activer les APIs:"
    echo "   gcloud services enable ${APIS[@]} --project=${PROJECT_ID}"
fi

echo ""

# Vérifier la configuration Redis
section "Vérification de la configuration Redis..."
if [ -f "scripts/deploy-cloud-run.sh" ]; then
    if grep -q "REDIS_URL=" scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_URL=""' scripts/deploy-cloud-run.sh; then
        REDIS_URL=$(grep "REDIS_URL=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$REDIS_URL" ] && [ "$REDIS_URL" != "" ]; then
            info "Upstash Redis configuré (gratuit)"
            echo "   REDIS_URL: $(echo $REDIS_URL | sed 's/:[^:@]*@/:****@/')"
        else
            warn "REDIS_URL vide"
        fi
    elif grep -q "REDIS_HOST=" scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_HOST=""' scripts/deploy-cloud-run.sh; then
        REDIS_HOST=$(grep "REDIS_HOST=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$REDIS_HOST" ] && [ "$REDIS_HOST" != "" ]; then
            info "Redis Memorystore configuré (payant)"
            echo "   REDIS_HOST: $REDIS_HOST"
        else
            warn "REDIS_HOST vide"
        fi
    else
        warn "Redis non configuré (mode dégradé)"
        echo "   → Configurer Upstash Redis (gratuit) dans scripts/deploy-cloud-run.sh"
    fi
else
    error "Fichier deploy-cloud-run.sh non trouvé"
fi

echo ""

# Vérifier la configuration Twilio
section "Vérification de la configuration Twilio..."
if [ -f "scripts/deploy-cloud-run.sh" ]; then
    if grep -q "TWILIO_ACCOUNT_SID=" scripts/deploy-cloud-run.sh && ! grep -q 'TWILIO_ACCOUNT_SID=""' scripts/deploy-cloud-run.sh; then
        TWILIO_SID=$(grep "TWILIO_ACCOUNT_SID=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$TWILIO_SID" ] && [ "$TWILIO_SID" != "" ]; then
            info "Twilio configuré"
        else
            warn "Twilio non configuré"
        fi
    else
        warn "Twilio non configuré"
    fi
else
    error "Fichier deploy-cloud-run.sh non trouvé"
fi

echo ""

# Vérifier le service Cloud Run
section "Vérification du service Cloud Run..."
if gcloud run services describe ${SERVICE_NAME} --region=${REGION} --project=${PROJECT_ID} &>/dev/null; then
    info "Service Cloud Run existe"
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --project=${PROJECT_ID} --format="value(status.url)" 2>/dev/null || echo "")
    if [ ! -z "$SERVICE_URL" ]; then
        info "URL du service: $SERVICE_URL"
        echo ""
        echo "🧪 Test de la route de santé..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/health" 2>/dev/null || echo "000")
        if [ "$HTTP_CODE" = "200" ]; then
            info "Service accessible (HTTP 200)"
        elif [ "$HTTP_CODE" = "404" ]; then
            warn "Service accessible mais route /health non trouvée (HTTP 404)"
        else
            warn "Service peut prendre quelques minutes pour être accessible (HTTP $HTTP_CODE)"
        fi
    fi
else
    warn "Service Cloud Run n'existe pas encore"
    echo "   → Exécuter: bash scripts/setup-and-deploy.sh"
fi

echo ""
echo "============================================================"
info "Vérification terminée !"
echo "============================================================"
echo ""

