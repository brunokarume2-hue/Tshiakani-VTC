#!/bin/bash

# 🚀 Script de Configuration VPC Connector pour Cloud Run
# Permet l'accès à Memorystore Redis depuis Cloud Run

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Configuration
GCP_PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
REGION="${REGION:-us-central1}"
SERVICE_NAME="tshiakani-vtc-backend"
CONNECTOR_NAME="tshiakani-vpc-connector"
CONNECTOR_RANGE="10.8.0.0/28"
BACKEND_URL="https://tshiakani-vtc-backend-418102154417.us-central1.run.app"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration VPC Connector pour Cloud Run${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

# Vérifier que l'utilisateur est connecté
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    log_error "Vous n'êtes pas connecté à gcloud"
    log_info "Connectez-vous avec: gcloud auth login"
    exit 1
fi

# Définir le projet
log_info "Configuration du projet: ${GCP_PROJECT_ID}"
gcloud config set project ${GCP_PROJECT_ID} --quiet

# Activer l'API Serverless VPC Access
log_info "Activation de l'API Serverless VPC Access..."
if gcloud services enable vpcaccess.googleapis.com --project=${GCP_PROJECT_ID} 2>&1 | grep -q "already enabled"; then
    log_success "API déjà activée"
else
    log_success "API activée"
fi

echo ""

# Étape 1 : Vérifier si le VPC connector existe déjà
log_info "Vérification du VPC connector existant..."
EXISTING_CONNECTOR=$(gcloud compute networks vpc-access connectors describe ${CONNECTOR_NAME} \
  --region=${REGION} \
  --project=${GCP_PROJECT_ID} \
  --format="value(name)" 2>/dev/null || echo "")

if [ -n "$EXISTING_CONNECTOR" ]; then
    log_success "VPC connector existe déjà: ${CONNECTOR_NAME}"
    CONNECTOR_STATUS=$(gcloud compute networks vpc-access connectors describe ${CONNECTOR_NAME} \
      --region=${REGION} \
      --project=${GCP_PROJECT_ID} \
      --format="value(state)" 2>/dev/null || echo "UNKNOWN")
    
    if [ "$CONNECTOR_STATUS" = "READY" ]; then
        log_success "VPC connector est prêt"
    else
        log_warning "VPC connector existe mais n'est pas prêt (statut: ${CONNECTOR_STATUS})"
        log_info "Attente de la disponibilité..."
        gcloud compute networks vpc-access connectors wait ${CONNECTOR_NAME} \
          --region=${REGION} \
          --project=${GCP_PROJECT_ID} \
          --timeout=600
        log_success "VPC connector est maintenant prêt"
    fi
else
    # Créer le VPC connector
    log_info "Création du VPC connector: ${CONNECTOR_NAME}"
    log_warning "Cette opération peut prendre 5-10 minutes..."
    
    gcloud compute networks vpc-access connectors create ${CONNECTOR_NAME} \
      --region=${REGION} \
      --project=${GCP_PROJECT_ID} \
      --network=default \
      --range=${CONNECTOR_RANGE} \
      --min-instances=2 \
      --max-instances=3 \
      --machine-type=e2-micro
    
    if [ $? -eq 0 ]; then
        log_success "VPC connector créé avec succès"
        log_info "Attente de la disponibilité..."
        gcloud compute networks vpc-access connectors wait ${CONNECTOR_NAME} \
          --region=${REGION} \
          --project=${GCP_PROJECT_ID} \
          --timeout=600
        log_success "VPC connector est maintenant prêt"
    else
        log_error "Échec de la création du VPC connector"
        exit 1
    fi
fi

echo ""

# Étape 2 : Configurer Cloud Run pour utiliser le VPC connector
log_info "Configuration de Cloud Run pour utiliser le VPC connector..."

# Vérifier si Cloud Run utilise déjà le VPC connector
CURRENT_VPC=$(gcloud run services describe ${SERVICE_NAME} \
  --region=${REGION} \
  --project=${GCP_PROJECT_ID} \
  --format="get(spec.template.metadata.annotations.'run.googleapis.com/vpc-access-connector')" 2>/dev/null || echo "")

if [ "$CURRENT_VPC" = "${CONNECTOR_NAME}" ]; then
    log_success "Cloud Run utilise déjà le VPC connector"
else
    log_info "Mise à jour de Cloud Run..."
    gcloud run services update ${SERVICE_NAME} \
      --region=${REGION} \
      --project=${GCP_PROJECT_ID} \
      --vpc-connector=${CONNECTOR_NAME} \
      --vpc-egress=all-traffic \
      --quiet
    
    if [ $? -eq 0 ]; then
        log_success "Cloud Run configuré pour utiliser le VPC connector"
        log_warning "Attente de 30 secondes pour que les changements prennent effet..."
        sleep 30
    else
        log_error "Échec de la configuration de Cloud Run"
        exit 1
    fi
fi

echo ""

# Étape 3 : Vérifier la connexion Redis
log_info "Vérification de la connexion Redis..."
sleep 5

HEALTH_RESPONSE=$(curl -s ${BACKEND_URL}/health 2>/dev/null || echo "")
if [ -z "$HEALTH_RESPONSE" ]; then
    log_warning "Impossible de vérifier le health check"
else
    REDIS_STATUS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('redis', {}).get('status', 'unknown'))" 2>/dev/null || echo "unknown")
    
    if [ "$REDIS_STATUS" = "connected" ]; then
        log_success "Redis est connecté !"
    elif [ "$REDIS_STATUS" = "not_configured" ]; then
        log_warning "Redis n'est pas encore configuré"
        log_info "Redéployez le backend pour activer Redis"
    else
        log_warning "Statut Redis: ${REDIS_STATUS}"
    fi
fi

echo ""

# Étape 4 : Résumé
log_success "Configuration VPC connector terminée !"
echo ""
log_info "📋 Résumé :"
echo "  ✅ VPC connector: ${CONNECTOR_NAME}"
echo "  ✅ Cloud Run configuré pour utiliser le VPC connector"
echo "  ✅ Redis devrait maintenant être accessible"
echo ""
log_info "🧪 Prochaines étapes :"
echo "  1. Redéployer le backend (si nécessaire):"
echo "     ./scripts/gcp-deploy-backend.sh"
echo ""
echo "  2. Tester l'envoi d'OTP :"
echo "     curl -X POST ${BACKEND_URL}/api/auth/send-otp \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"phoneNumber\": \"+243847305825\", \"channel\": \"sms\"}'"
echo ""
echo "  3. Tester la vérification d'OTP :"
echo "     curl -X POST ${BACKEND_URL}/api/auth/verify-otp \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"phoneNumber\": \"+243847305825\", \"code\": \"CODE_RECU\", \"role\": \"client\"}'"
echo ""

