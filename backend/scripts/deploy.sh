#!/bin/bash

# Script de déploiement pour Tshiakani VTC Backend
# Usage: ./scripts/deploy.sh [environment]

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_ID=${GCP_PROJECT_ID:-your-project-id}
REGION=${GCP_REGION:-us-central1}
SERVICE_NAME="tshiakani-vtc-backend"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo -e "${GREEN}🚀 Déploiement de Tshiakani VTC Backend${NC}"
echo -e "Environment: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Project ID: ${YELLOW}${PROJECT_ID}${NC}"
echo -e "Region: ${YELLOW}${REGION}${NC}"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}✗${NC} gcloud CLI n'est pas installé"
    echo "Installez gcloud: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗${NC} Docker n'est pas installé"
    echo "Installez Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Vérifier que le projet est configuré
if [ "$PROJECT_ID" = "your-project-id" ]; then
    echo -e "${RED}✗${NC} GCP_PROJECT_ID n'est pas configuré"
    echo "Exportez GCP_PROJECT_ID ou modifiez le script"
    exit 1
fi

# Build l'image Docker
echo -e "${GREEN}📦 Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:latest .

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Erreur lors du build de l'image Docker"
    exit 1
fi

echo -e "${GREEN}✓${NC} Image Docker buildée avec succès"

# Push l'image vers Google Container Registry
echo -e "${GREEN}📤 Pushing image to GCR...${NC}"
docker push ${IMAGE_NAME}:latest

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Erreur lors du push de l'image"
    exit 1
fi

echo -e "${GREEN}✓${NC} Image pushée avec succès"

# Déployer sur Cloud Run
echo -e "${GREEN}🚀 Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME}:latest \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --timeout 300

if [ $? -ne 0 ]; then
    echo -e "${RED}✗${NC} Erreur lors du déploiement"
    exit 1
fi

echo -e "${GREEN}✓${NC} Déployé avec succès sur Cloud Run"

# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)')

echo ""
echo -e "${GREEN}✅ Déploiement terminé avec succès!${NC}"
echo -e "Service URL: ${YELLOW}${SERVICE_URL}${NC}"
echo ""

# Tester le service
echo -e "${GREEN}🧪 Testing service...${NC}"
HEALTH_RESPONSE=$(curl -s ${SERVICE_URL}/health)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Health check réussi"
    echo "Response: ${HEALTH_RESPONSE}"
else
    echo -e "${YELLOW}⚠${NC} Health check a échoué (le service peut être en cours de démarrage)"
fi

echo ""
echo -e "${GREEN}🎉 Déploiement terminé!${NC}"

