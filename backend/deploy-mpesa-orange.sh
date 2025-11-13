#!/bin/bash

# Script de déploiement pour les nouvelles méthodes de paiement M-Pesa et Orange Money
# Usage: ./deploy-mpesa-orange.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Déploiement du backend avec support M-Pesa et Orange Money...${NC}"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
SERVICE_NAME="tshiakani-driver-backend"
REGION="us-central1"

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé.${NC}"
    exit 1
fi

# Configurer le projet
echo -e "${BLUE}📋 Configuration du projet: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID}

# Activer les APIs nécessaires
echo -e "${BLUE}📋 Activation des APIs nécessaires...${NC}"
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com --project=${PROJECT_ID} || true

# Déployer depuis le code source
echo -e "${BLUE}📋 Déploiement sur Cloud Run depuis le code source...${NC}"
echo -e "${YELLOW}⏳ Cela peut prendre plusieurs minutes...${NC}"

gcloud run deploy ${SERVICE_NAME} \
  --source . \
  --region ${REGION} \
  --platform managed \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --env-vars-file env-vars.yaml \
  --project ${PROJECT_ID}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Déploiement réussi!${NC}"
    
    # Obtenir l'URL du service
    SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
      --region ${REGION} \
      --format "value(status.url)" \
      --project ${PROJECT_ID} 2>/dev/null || echo "")
    
    if [ ! -z "$SERVICE_URL" ]; then
        echo -e "${GREEN}🌐 URL du service: ${SERVICE_URL}${NC}"
    fi
else
    echo -e "${RED}❌ Erreur lors du déploiement${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Si vous voyez une erreur de facturation:${NC}"
    echo "   1. Activez la facturation sur: https://console.cloud.google.com/billing?project=${PROJECT_ID}"
    echo "   2. Relancez ce script"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Modifications déployées:${NC}"
echo "   - Support M-Pesa (mpesa)"
echo "   - Support Orange Money (orange_money)"
echo "   - Routes client et driver mises à jour"

