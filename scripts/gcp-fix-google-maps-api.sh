#!/bin/bash

# Script interactif pour corriger la clé API Google Maps
# Ce script guide l'utilisateur et teste la clé après modification

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
GCP_PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
CURRENT_KEY="AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Correction de la Clé API Google Maps${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1 : Tester la clé actuelle
echo -e "${BLUE}📋 Étape 1 : Test de la clé API actuelle...${NC}"
echo ""

TEST_RESPONSE=$(curl -s -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: ${CURRENT_KEY}" \
  -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters" \
  -d '{
    "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3136}}},
    "destination": {"location": {"latLng": {"latitude": -4.3297, "longitude": 15.3150}}},
    "travelMode": "DRIVE",
    "routingPreference": "TRAFFIC_AWARE"
  }' 2>&1)

if echo "$TEST_RESPONSE" | grep -q "distanceMeters"; then
  echo -e "${GREEN}✅ La clé API fonctionne déjà !${NC}"
  echo ""
  DISTANCE=$(echo "$TEST_RESPONSE" | grep -o '"distanceMeters":[0-9]*' | cut -d: -f2)
  echo "  Distance testée : ${DISTANCE} mètres"
  echo ""
  echo -e "${GREEN}✅ Aucune action requise.${NC}"
  exit 0
elif echo "$TEST_RESPONSE" | grep -q "API_KEY_IOS_APP_BLOCKED"; then
  echo -e "${RED}❌ La clé API est bloquée pour iOS uniquement${NC}"
  echo ""
else
  echo -e "${YELLOW}⚠️  Erreur inconnue avec la clé API${NC}"
  echo "$TEST_RESPONSE" | head -5
  echo ""
fi

# Étape 2 : Instructions pour modifier dans Google Cloud Console
echo -e "${BLUE}📋 Étape 2 : Instructions pour corriger la clé API${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  INSTRUCTIONS DÉTAILLÉES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}1. Ouvrir Google Cloud Console :${NC}"
echo "   https://console.cloud.google.com/apis/credentials?project=${GCP_PROJECT_ID}"
echo ""
echo -e "${YELLOW}2. Trouver la clé API :${NC}"
echo "   ${CURRENT_KEY}"
echo ""
echo -e "${YELLOW}3. Cliquer sur la clé pour l'éditer${NC}"
echo ""
echo -e "${YELLOW}4. Modifier 'Application restrictions' :${NC}"
echo "   ❌ Actuellement : 'iOS apps'"
echo "   ✅ Changer à : 'None' (ou 'IP addresses' si vous connaissez les IPs Cloud Run)"
echo ""
echo -e "${YELLOW}5. Vérifier 'API restrictions' :${NC}"
echo "   ✅ Doit inclure : 'Routes API'"
echo ""
echo -e "${YELLOW}6. Cliquer sur 'SAVE'${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Étape 3 : Attendre que l'utilisateur modifie la clé
echo -e "${BLUE}📋 Étape 3 : Test après modification${NC}"
echo ""
echo -e "${YELLOW}Après avoir modifié la clé dans Google Cloud Console :${NC}"
echo ""
read -p "Avez-vous modifié la clé API ? (o/N): " confirm

if [[ ! $confirm =~ ^[OoYy]$ ]]; then
  echo -e "${YELLOW}⚠️  Opération annulée. Modifiez la clé et relancez ce script.${NC}"
  exit 0
fi

# Étape 4 : Tester à nouveau
echo ""
echo -e "${BLUE}🔄 Test de la clé API après modification...${NC}"
echo ""

# Attendre quelques secondes pour que les changements soient propagés
echo "⏳ Attente de 5 secondes pour la propagation des changements..."
sleep 5

TEST_RESPONSE=$(curl -s -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: ${CURRENT_KEY}" \
  -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters" \
  -d '{
    "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3136}}},
    "destination": {"location": {"latLng": {"latitude": -4.3297, "longitude": 15.3150}}},
    "travelMode": "DRIVE",
    "routingPreference": "TRAFFIC_AWARE"
  }' 2>&1)

if echo "$TEST_RESPONSE" | grep -q "distanceMeters"; then
  echo -e "${GREEN}✅ SUCCÈS ! La clé API fonctionne maintenant !${NC}"
  echo ""
  DISTANCE=$(echo "$TEST_RESPONSE" | grep -o '"distanceMeters":[0-9]*' | cut -d: -f2)
  DURATION=$(echo "$TEST_RESPONSE" | grep -o '"seconds":[0-9]*' | cut -d: -f2 | head -1)
  echo "  Distance testée : ${DISTANCE} mètres"
  if [ ! -z "$DURATION" ]; then
    echo "  Durée estimée : ${DURATION} secondes"
  fi
  echo ""
  echo -e "${GREEN}✅ La clé API est correctement configurée !${NC}"
  echo ""
  echo -e "${BLUE}📝 Note : La clé est déjà configurée dans Cloud Run.${NC}"
  echo "   Aucune mise à jour nécessaire si vous avez modifié la même clé."
  echo ""
  
  # Proposer de mettre à jour Cloud Run si une nouvelle clé a été créée
  read -p "Avez-vous créé une NOUVELLE clé API (différente) ? (o/N): " new_key
  
  if [[ $new_key =~ ^[OoYy]$ ]]; then
    echo ""
    read -p "Entrez la nouvelle clé API: " NEW_API_KEY
    if [ ! -z "$NEW_API_KEY" ]; then
      echo ""
      echo -e "${BLUE}🔄 Mise à jour de Cloud Run...${NC}"
      gcloud run services update ${SERVICE_NAME} \
        --region ${REGION} \
        --project ${GCP_PROJECT_ID} \
        --update-env-vars="GOOGLE_MAPS_API_KEY=${NEW_API_KEY}" \
        --quiet
      
      if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Cloud Run mis à jour avec la nouvelle clé API !${NC}"
      else
        echo -e "${RED}❌ Erreur lors de la mise à jour de Cloud Run${NC}"
      fi
    fi
  fi
  
else
  echo -e "${RED}❌ La clé API ne fonctionne toujours pas${NC}"
  echo ""
  if echo "$TEST_RESPONSE" | grep -q "API_KEY_IOS_APP_BLOCKED"; then
    echo -e "${YELLOW}⚠️  La clé est toujours bloquée pour iOS uniquement${NC}"
    echo ""
    echo "Vérifiez que :"
    echo "  1. Vous avez bien changé 'Application restrictions' à 'None'"
    echo "  2. Vous avez cliqué sur 'SAVE'"
    echo "  3. Vous avez attendu quelques secondes pour la propagation"
    echo ""
    echo "Réessayez dans quelques instants ou relancez ce script."
  else
    echo "Erreur :"
    echo "$TEST_RESPONSE" | head -10
  fi
  exit 1
fi

echo ""
echo -e "${GREEN}✅ Configuration terminée avec succès !${NC}"

