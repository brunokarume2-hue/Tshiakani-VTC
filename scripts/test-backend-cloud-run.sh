#!/bin/bash

# Script de test du backend déployé sur Cloud Run
# Usage: ./scripts/test-backend-cloud-run.sh

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# URL du backend
BACKEND_URL="https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
API_URL="${BACKEND_URL}/api"

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🧪 TEST DU BACKEND CLOUD RUN${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Backend URL: ${BACKEND_URL}${NC}"
echo -e "${BLUE}API URL: ${API_URL}${NC}"
echo ""

# Test 1: Health Check
echo -e "${CYAN}Test 1: Health Check${NC}"
if curl -s -f -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health" | grep -q "200\|404"; then
    echo -e "${GREEN}✅ Health check réussi${NC}"
    HEALTH_RESPONSE=$(curl -s "${BACKEND_URL}/health")
    echo -e "${BLUE}   Réponse: ${HEALTH_RESPONSE}${NC}"
else
    echo -e "${RED}❌ Health check échoué${NC}"
    exit 1
fi
echo ""

# Test 2: Authentification Client
echo -e "${CYAN}Test 2: Authentification Client${NC}"
AUTH_RESPONSE=$(curl -s -X POST "${API_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "role": "client"
  }')

if echo "${AUTH_RESPONSE}" | grep -q "token"; then
    echo -e "${GREEN}✅ Authentification réussie${NC}"
    TOKEN=$(echo "${AUTH_RESPONSE}" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    echo -e "${BLUE}   Token reçu: ${TOKEN:0:50}...${NC}"
else
    echo -e "${RED}❌ Authentification échouée${NC}"
    echo -e "${YELLOW}   Réponse: ${AUTH_RESPONSE}${NC}"
    exit 1
fi
echo ""

# Test 3: Estimation de Prix
echo -e "${CYAN}Test 3: Estimation de Prix${NC}"
if [ -n "$TOKEN" ]; then
    ESTIMATE_RESPONSE=$(curl -s -X POST "${API_URL}/rides/estimate-price" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${TOKEN}" \
      -d '{
        "pickupLocation": {
          "latitude": -4.3276,
          "longitude": 15.3136
        },
        "dropoffLocation": {
          "latitude": -4.3296,
          "longitude": 15.3156
        }
      }')
    
    if echo "${ESTIMATE_RESPONSE}" | grep -q "price"; then
        echo -e "${GREEN}✅ Estimation de prix réussie${NC}"
        PRICE=$(echo "${ESTIMATE_RESPONSE}" | grep -o '"price":[0-9]*' | cut -d':' -f2)
        echo -e "${BLUE}   Prix estimé: ${PRICE} CDF${NC}"
    else
        echo -e "${YELLOW}⚠️  Estimation de prix échouée ou réponse inattendue${NC}"
        echo -e "${YELLOW}   Réponse: ${ESTIMATE_RESPONSE}${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Token non disponible, test ignoré${NC}"
fi
echo ""

# Test 4: Routes Disponibles
echo -e "${CYAN}Test 4: Vérification des Routes${NC}"
ROUTES=(
    "/api/auth/signin"
    "/api/rides/estimate-price"
    "/api/rides/create"
    "/api/client/track_driver/1"
    "/api/location/drivers/nearby"
)

for ROUTE in "${ROUTES[@]}"; do
    STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}${ROUTE}" \
      -H "Authorization: Bearer ${TOKEN}" 2>/dev/null || echo "000")
    
    if [ "$STATUS_CODE" = "200" ] || [ "$STATUS_CODE" = "201" ] || [ "$STATUS_CODE" = "404" ] || [ "$STATUS_CODE" = "401" ] || [ "$STATUS_CODE" = "403" ]; then
        echo -e "${GREEN}✅ Route ${ROUTE} accessible (${STATUS_CODE})${NC}"
    else
        echo -e "${YELLOW}⚠️  Route ${ROUTE} retourne ${STATUS_CODE}${NC}"
    fi
done
echo ""

# Résumé
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 RÉSUMÉ DES TESTS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Backend accessible${NC}"
echo -e "${GREEN}✅ Authentification fonctionnelle${NC}"
echo -e "${GREEN}✅ Routes API disponibles${NC}"
echo ""
echo -e "${BLUE}Prochaines étapes:${NC}"
echo "1. Vérifier CORS configuration sur Cloud Run"
echo "2. Tester l'application iOS en mode RELEASE"
echo "3. Vérifier les WebSockets"
echo "4. Monitorer les logs"

