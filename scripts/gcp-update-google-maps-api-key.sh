#!/bin/bash

# Script pour mettre à jour la clé API Google Maps dans Cloud Run
# Usage: ./scripts/gcp-update-google-maps-api-key.sh [NOUVELLE_CLE_API]

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"

echo -e "${BLUE}🔧 Mise à jour de la clé API Google Maps${NC}"
echo ""

# Vérifier si une nouvelle clé est fournie en argument
if [ -z "$1" ]; then
  echo -e "${YELLOW}⚠️  Aucune clé API fournie${NC}"
  echo ""
  echo "Usage:"
  echo "  $0 [NOUVELLE_CLE_API]"
  echo ""
  echo "Ou définir la variable d'environnement :"
  echo "  export GOOGLE_MAPS_API_KEY='VOTRE_CLE_API'"
  echo "  $0"
  echo ""
  
  # Demander la clé API
  read -p "Entrez la nouvelle clé API Google Maps: " NEW_API_KEY
  
  if [ -z "$NEW_API_KEY" ]; then
    echo -e "${RED}❌ Erreur: Clé API requise${NC}"
    exit 1
  fi
else
  NEW_API_KEY="$1"
fi

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
  echo -e "${RED}❌ Erreur: gcloud CLI n'est pas installé${NC}"
  exit 1
fi

# Vérifier que le projet est configuré
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Projet GCP: ${GCP_PROJECT_ID}"
echo "  Service: ${SERVICE_NAME}"
echo "  Région: ${REGION}"
echo "  Clé API: ${NEW_API_KEY:0:20}..."
echo ""

# Confirmer
read -p "Continuer avec la mise à jour? (o/N): " confirm
if [[ ! $confirm =~ ^[OoYy]$ ]]; then
  echo -e "${YELLOW}⚠️  Opération annulée${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}🔄 Mise à jour de la variable d'environnement...${NC}"

# Mettre à jour la variable d'environnement
gcloud run services update ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${GCP_PROJECT_ID} \
  --update-env-vars="GOOGLE_MAPS_API_KEY=${NEW_API_KEY}" \
  --quiet

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Clé API Google Maps mise à jour avec succès!${NC}"
  echo ""
  echo -e "${BLUE}🧪 Test de l'API...${NC}"
  
  # Tester l'API
  sleep 3
  
  TEST_RESPONSE=$(curl -s -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
    -H "Content-Type: application/json" \
    -H "X-Goog-Api-Key: ${NEW_API_KEY}" \
    -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters" \
    -d '{
      "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3136}}},
      "destination": {"location": {"latLng": {"latitude": -4.3297, "longitude": 15.3150}}},
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE"
    }' 2>&1)
  
  if echo "$TEST_RESPONSE" | grep -q "distanceMeters"; then
    echo -e "${GREEN}✅ Test réussi! L'API Google Maps fonctionne correctement.${NC}"
  elif echo "$TEST_RESPONSE" | grep -q "error"; then
    echo -e "${YELLOW}⚠️  L'API retourne une erreur:${NC}"
    echo "$TEST_RESPONSE" | grep -o '"message":"[^"]*"' | head -1
    echo ""
    echo -e "${YELLOW}💡 Vérifiez la configuration de la clé API dans Google Cloud Console${NC}"
  else
    echo -e "${YELLOW}⚠️  Réponse inattendue de l'API${NC}"
    echo "$TEST_RESPONSE" | head -5
  fi
  
  echo ""
  echo -e "${BLUE}📝 Prochaines étapes:${NC}"
  echo "  1. Vérifier les logs Cloud Run pour confirmer que l'API fonctionne"
  echo "  2. Tester la création d'une course depuis l'application"
  echo "  3. Vérifier que le prix et l'ETA sont calculés correctement"
  
else
  echo -e "${RED}❌ Erreur lors de la mise à jour${NC}"
  exit 1
fi

