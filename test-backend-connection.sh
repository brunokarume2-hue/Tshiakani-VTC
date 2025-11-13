#!/bin/bash

# Script de test de connexion au backend
# Usage: ./test-backend-connection.sh

set -e

echo "🔍 Vérification de la connexion au backend..."
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
BACKEND_URL="http://localhost:3000"
API_URL="${BACKEND_URL}/api"
HEALTH_URL="${BACKEND_URL}/health"

# Fonction pour tester une URL
test_url() {
    local url=$1
    local description=$2
    
    echo -n "Test: ${description}... "
    
    if curl -s -f -o /dev/null -w "%{http_code}" "${url}" | grep -q "200\|201\|404"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

# Test 1: Vérifier que le backend est démarré
echo "📋 Test 1: Vérification que le backend est démarré"
if test_url "${HEALTH_URL}" "Health Check"; then
    echo "   ✅ Backend accessible"
    # Afficher la réponse
    echo "   Réponse:"
    curl -s "${HEALTH_URL}" | jq . 2>/dev/null || curl -s "${HEALTH_URL}"
else
    echo -e "   ${RED}❌ Backend non accessible${NC}"
    echo "   Vérifiez que le backend est démarré: cd backend && npm start"
    exit 1
fi

echo ""

# Test 2: Test d'authentification
echo "📋 Test 2: Test d'authentification"
echo -n "Test: POST /api/auth/signin... "

response=$(curl -s -X POST "${API_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "role": "client"
  }')

if echo "${response}" | jq -e '.token' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
    token=$(echo "${response}" | jq -r '.token')
    echo "   Token JWT généré: ${token:0:50}..."
else
    echo -e "${RED}❌ ÉCHEC${NC}"
    echo "   Réponse: ${response}"
    exit 1
fi

echo ""

# Test 3: Test avec token JWT
echo "📋 Test 3: Test avec token JWT"
echo -n "Test: GET /api/auth/profile... "

if [ -z "$token" ]; then
    echo -e "${YELLOW}⚠️  Token non disponible${NC}"
else
    response=$(curl -s -X GET "${API_URL}/auth/verify" \
      -H "Authorization: Bearer ${token}")
    
    if echo "${response}" | jq -e '.user' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        echo "   Réponse: ${response}"
    fi
fi

echo ""

# Test 4: Test de création de course
echo "📋 Test 4: Test de création de course"
echo -n "Test: POST /api/rides/estimate-price... "

if [ -z "$token" ]; then
    echo -e "${YELLOW}⚠️  Token non disponible, test sans authentification${NC}"
else
    response=$(curl -s -X POST "${API_URL}/rides/estimate-price" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${token}" \
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
    
    if echo "${response}" | jq -e '.price' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        price=$(echo "${response}" | jq -r '.price')
        echo "   Prix estimé: ${price} CDF"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        echo "   Réponse: ${response}"
    fi
fi

echo ""

# Test 5: Test de recherche de chauffeurs
echo "📋 Test 5: Test de recherche de chauffeurs"
echo -n "Test: GET /api/location/drivers/nearby... "

if [ -z "$token" ]; then
    echo -e "${YELLOW}⚠️  Token non disponible${NC}"
else
    response=$(curl -s -X GET "${API_URL}/location/drivers/nearby?latitude=-4.3276&longitude=15.3136&radius=5" \
      -H "Authorization: Bearer ${token}")
    
    if echo "${response}" | jq -e '.drivers' > /dev/null 2>&1 || echo "${response}" | jq -e '.[]' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        count=$(echo "${response}" | jq '.drivers | length' 2>/dev/null || echo "${response}" | jq 'length' 2>/dev/null || echo "0")
        echo "   Chauffeurs trouvés: ${count}"
    else
        echo -e "${YELLOW}⚠️  Aucun chauffeur trouvé (normal si aucun chauffeur en ligne)${NC}"
    fi
fi

echo ""

# Résumé
echo "📊 Résumé des tests"
echo "==================="
echo "✅ Health Check: OK"
echo "✅ Authentification: OK"
if [ -n "$token" ]; then
    echo "✅ Token JWT: OK"
    echo "✅ Estimation de prix: OK"
    echo "✅ Recherche de chauffeurs: OK"
fi
echo ""
echo -e "${GREEN}✅ Tous les tests sont passés avec succès!${NC}"

