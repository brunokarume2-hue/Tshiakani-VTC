#!/bin/bash

# Script de test de connexion au backend
# Usage: ./test-connexion-backend.sh

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL du backend
BACKEND_URL="https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
API_URL="${BACKEND_URL}/api"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Test de Connexion Frontend ↔ Backend - Tshiakani VTC${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Test 1: Health Check
echo -e "${YELLOW}1. Test Health Check...${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${BACKEND_URL}/health")
HEALTH_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
HEALTH_BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HEALTH_CODE" -eq 200 ]; then
    print_result 0 "Health Check: Backend accessible (HTTP $HEALTH_CODE)"
    echo -e "${BLUE}   Réponse:${NC} $(echo "$HEALTH_BODY" | jq -r '.status // "N/A"' 2>/dev/null || echo "OK")"
else
    print_result 1 "Health Check: Échec (HTTP $HEALTH_CODE)"
fi
echo ""

# Test 2: Authentification
echo -e "${YELLOW}2. Test Authentification...${NC}"
AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/signin" \
    -H "Content-Type: application/json" \
    -d '{"phoneNumber":"+243900000000","role":"client"}')
AUTH_CODE=$(echo "$AUTH_RESPONSE" | tail -n1)
AUTH_BODY=$(echo "$AUTH_RESPONSE" | sed '$d')

if [ "$AUTH_CODE" -eq 200 ]; then
    print_result 0 "Authentification: Succès (HTTP $AUTH_CODE)"
    TOKEN=$(echo "$AUTH_BODY" | jq -r '.token // "N/A"' 2>/dev/null || echo "N/A")
    if [ "$TOKEN" != "N/A" ] && [ "$TOKEN" != "null" ]; then
        echo -e "${GREEN}   Token JWT généré: ${TOKEN:0:50}...${NC}"
    fi
else
    print_result 1 "Authentification: Échec (HTTP $AUTH_CODE)"
    echo -e "${RED}   Erreur: $(echo "$AUTH_BODY" | jq -r '.error // .message // "N/A"' 2>/dev/null || echo "N/A")${NC}"
fi
echo ""

# Test 3: CORS
echo -e "${YELLOW}3. Test CORS...${NC}"
CORS_RESPONSE=$(curl -s -w "\n%{http_code}" -X OPTIONS "${API_URL}/auth/signin" \
    -H "Origin: http://localhost:3001" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type")
CORS_CODE=$(echo "$CORS_RESPONSE" | tail -n1)

if [ "$CORS_CODE" -eq 204 ] || [ "$CORS_CODE" -eq 200 ]; then
    print_result 0 "CORS: Configuré correctement (HTTP $CORS_CODE)"
else
    print_result 1 "CORS: Problème potentiel (HTTP $CORS_CODE)"
fi
echo ""

# Test 4: Endpoint Admin (avec clé API)
echo -e "${YELLOW}4. Test Endpoint Admin...${NC}"
ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
ADMIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/admin/stats" \
    -H "X-ADMIN-API-KEY: ${ADMIN_API_KEY}")
ADMIN_CODE=$(echo "$ADMIN_RESPONSE" | tail -n1)
ADMIN_BODY=$(echo "$ADMIN_RESPONSE" | sed '$d')

if [ "$ADMIN_CODE" -eq 200 ]; then
    print_result 0 "Endpoint Admin: Accessible (HTTP $ADMIN_CODE)"
else
    print_result 1 "Endpoint Admin: Échec (HTTP $ADMIN_CODE)"
    echo -e "${RED}   Erreur: $(echo "$ADMIN_BODY" | jq -r '.error // .message // "N/A"' 2>/dev/null || echo "N/A")${NC}"
fi
echo ""

# Résumé
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Résumé${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Backend URL: ${GREEN}${BACKEND_URL}${NC}"
echo -e "API URL: ${GREEN}${API_URL}${NC}"
echo ""
echo -e "${GREEN}✅ Tests terminés${NC}"
echo ""

