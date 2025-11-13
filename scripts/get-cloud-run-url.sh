#!/bin/bash

# Script pour obtenir l'URL du backend déployé sur Google Cloud Run
# Usage: ./scripts/get-cloud-run-url.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
PROJECT_ID="tshiakani-vtc"
SERVICE_NAME="tshiakani-vtc-api"
REGION="us-central1"

echo -e "${BLUE}🔍 Récupération de l'URL du backend Cloud Run...${NC}"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}❌ gcloud CLI n'est pas installé.${NC}"
    echo "Installez-le depuis: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Vérifier que le projet est configuré
echo -e "${BLUE}📋 Vérification du projet GCP...${NC}"
gcloud config set project ${PROJECT_ID} &> /dev/null

# Obtenir l'URL du service
echo -e "${BLUE}🌐 Récupération de l'URL du service...${NC}"
URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --format "value(status.url)" 2>/dev/null)

if [ -z "$URL" ]; then
    echo -e "${YELLOW}⚠️  Service non trouvé ou non déployé.${NC}"
    echo ""
    echo "Vérifiez que le service est déployé:"
    echo "  gcloud run services list --region ${REGION}"
    echo ""
    echo "Ou déployez-le:"
    echo "  cd backend && ./scripts/deploy-cloud-run.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ URL du backend Cloud Run:${NC}"
echo -e "${GREEN}${URL}${NC}"
echo ""

# Générer la configuration pour Info.plist
echo -e "${BLUE}📝 Configuration pour Info.plist:${NC}"
echo ""
echo "<key>API_BASE_URL</key>"
echo "<string>${URL}/api</string>"
echo "<key>WS_BASE_URL</key>"
echo "<string>${URL}</string>"
echo ""

# Générer la configuration pour ConfigurationService.swift (fallback)
echo -e "${BLUE}📝 Configuration pour ConfigurationService.swift (fallback):${NC}"
echo ""
echo "// Fallback URL Cloud Run"
echo "return \"${URL}/api\""
echo ""

# Test de connexion
echo -e "${BLUE}🧪 Test de connexion...${NC}"
if curl -s -f -o /dev/null -w "%{http_code}" "${URL}/health" | grep -q "200\|404"; then
    echo -e "${GREEN}✅ Backend accessible!${NC}"
    echo ""
    echo "Réponse health check:"
    curl -s "${URL}/health" | head -5
else
    echo -e "${YELLOW}⚠️  Backend non accessible ou endpoint /health non disponible${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuration terminée!${NC}"
echo ""
echo "Prochaines étapes:"
echo "1. Mettre à jour Info.plist avec les URLs ci-dessus"
echo "2. Vérifier la configuration CORS sur le backend"
echo "3. Tester la connexion depuis l'app iOS"

