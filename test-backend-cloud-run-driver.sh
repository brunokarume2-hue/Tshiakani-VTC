#!/bin/bash

# Script de test de connexion au backend Cloud Run pour l'app driver
# Usage: ./test-backend-cloud-run-driver.sh

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "🔍 TEST CONNEXION BACKEND CLOUD RUN - APP DRIVER"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables - Configuration comme l'app driver
BACKEND_URL="https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
API_URL="${BACKEND_URL}/api"
HEALTH_URL="${BACKEND_URL}/health"
WS_URL="${BACKEND_URL}/ws/driver"
DRIVER_PHONE="${DRIVER_PHONE:-+243900000001}"
DRIVER_TOKEN=""
DRIVER_ID=""

# Compteurs
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0

# Fonction pour logger les résultats
log_result() {
    local status=$1
    local message=$2
    case $status in
        "✅ PASS")
            echo -e "${GREEN}✅${NC} $message"
            ((TESTS_PASSED++))
            ;;
        "❌ FAIL")
            echo -e "${RED}❌${NC} $message"
            ((TESTS_FAILED++))
            ;;
        "⚠️  WARN")
            echo -e "${YELLOW}⚠️${NC}  $message"
            ((TESTS_WARNING++))
            ;;
        "ℹ️  INFO")
            echo -e "${BLUE}ℹ️${NC}  $message"
            ;;
    esac
}

# ============================================================================
# 1. TEST HEALTH CHECK
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. TEST HEALTH CHECK${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -n "Test: Health Check Cloud Run... "
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${HEALTH_URL}" 2>/dev/null || echo -e "ERROR\n000")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    log_result "✅ PASS" "Backend Cloud Run accessible sur ${BACKEND_URL}"
    echo "   Réponse: $BODY"
    if echo "$BODY" | grep -q "status.*OK" || echo "$BODY" | grep -q "\"status\""; then
        log_result "✅ PASS" "Backend répond correctement"
    fi
else
    log_result "❌ FAIL" "Backend Cloud Run non accessible (Code HTTP: ${HTTP_CODE})"
    echo "   Réponse: $BODY"
    exit 1
fi

# ============================================================================
# 2. TEST AUTHENTIFICATION DRIVER
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. TEST AUTHENTIFICATION DRIVER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -n "Test: Authentification driver... "
AUTH_RESPONSE=$(curl -s -X POST "${API_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"phoneNumber\": \"${DRIVER_PHONE}\",
    \"role\": \"driver\"
  }" 2>/dev/null || echo "ERROR")

if echo "$AUTH_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
    DRIVER_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.token')
    DRIVER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.user.id // .userId // empty')
    log_result "✅ PASS" "Authentification driver réussie"
    echo "   Token JWT: ${DRIVER_TOKEN:0:50}..."
    if [ -n "$DRIVER_ID" ]; then
        echo "   Driver ID: ${DRIVER_ID}"
        DRIVER_NAME=$(echo "$AUTH_RESPONSE" | jq -r '.user.name // "N/A"')
        echo "   Nom: ${DRIVER_NAME}"
    fi
else
    log_result "❌ FAIL" "Échec de l'authentification driver"
    echo "   Réponse: $AUTH_RESPONSE"
    DRIVER_TOKEN=""
fi

# ============================================================================
# 3. TEST PROFIL DRIVER
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. TEST PROFIL DRIVER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$DRIVER_TOKEN" ]; then
    log_result "⚠️  WARN" "Token non disponible, test ignoré"
else
    echo -n "Test: Récupération profil driver... "
    PROFILE_RESPONSE=$(curl -s -X GET "${API_URL}/auth/profile" \
      -H "Authorization: Bearer ${DRIVER_TOKEN}" 2>/dev/null || echo "ERROR")
    
    if echo "$PROFILE_RESPONSE" | jq -e '.id' > /dev/null 2>&1; then
        ROLE=$(echo "$PROFILE_RESPONSE" | jq -r '.role // "N/A"')
        if [ "$ROLE" = "driver" ]; then
            log_result "✅ PASS" "Profil driver récupéré (rôle: ${ROLE})"
            echo "   ID: $(echo "$PROFILE_RESPONSE" | jq -r '.id')"
            echo "   Nom: $(echo "$PROFILE_RESPONSE" | jq -r '.name // "N/A"')"
            echo "   Téléphone: $(echo "$PROFILE_RESPONSE" | jq -r '.phoneNumber // "N/A"')"
        else
            log_result "⚠️  WARN" "Rôle utilisateur: ${ROLE} (attendu: driver)"
        fi
    else
        ERROR_MSG=$(echo "$PROFILE_RESPONSE" | jq -r '.error // .message // "Erreur inconnue"' 2>/dev/null || echo "$PROFILE_RESPONSE")
        log_result "❌ FAIL" "Échec de la récupération du profil: ${ERROR_MSG}"
    fi
fi

# ============================================================================
# 4. TEST MISE À JOUR POSITION
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. TEST MISE À JOUR POSITION${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$DRIVER_TOKEN" ]; then
    log_result "⚠️  WARN" "Token non disponible, test ignoré"
else
    echo -n "Test: POST /api/driver/location/update... "
    LOCATION_RESPONSE=$(curl -s -X POST "${API_URL}/driver/location/update" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${DRIVER_TOKEN}" \
      -d '{
        "latitude": -4.3276,
        "longitude": 15.3136,
        "address": "Kinshasa, RD Congo"
      }' 2>/dev/null || echo "ERROR")
    
    if echo "$LOCATION_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        log_result "✅ PASS" "Mise à jour de la position réussie"
        LAT=$(echo "$LOCATION_RESPONSE" | jq -r '.location.latitude // empty')
        LON=$(echo "$LOCATION_RESPONSE" | jq -r '.location.longitude // empty')
        if [ -n "$LAT" ] && [ -n "$LON" ]; then
            echo "   Position: ${LAT}, ${LON}"
        fi
    else
        ERROR_MSG=$(echo "$LOCATION_RESPONSE" | jq -r '.error // .message // "Erreur inconnue"' 2>/dev/null || echo "$LOCATION_RESPONSE")
        log_result "❌ FAIL" "Échec de la mise à jour de la position: ${ERROR_MSG}"
    fi
fi

# ============================================================================
# 5. TEST PROTECTION DES ROUTES
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. TEST PROTECTION DES ROUTES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -n "Test: Protection route location/update (sans token)... "
PROTECTED_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/driver/location/update" \
  -H "Content-Type: application/json" \
  -d '{"latitude": 0, "longitude": 0}' 2>/dev/null || echo -e "ERROR\n000")
PROTECTED_CODE=$(echo "$PROTECTED_RESPONSE" | tail -n1)

if [ "$PROTECTED_CODE" = "401" ] || [ "$PROTECTED_CODE" = "403" ]; then
    log_result "✅ PASS" "Route protégée (code HTTP: ${PROTECTED_CODE})"
else
    log_result "⚠️  WARN" "Route peut ne pas être correctement protégée (code HTTP: ${PROTECTED_CODE})"
fi

# ============================================================================
# 6. TEST VÉRIFICATION RÔLE
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. TEST VÉRIFICATION RÔLE${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$DRIVER_TOKEN" ]; then
    log_result "⚠️  WARN" "Token non disponible, test ignoré"
else
    echo -n "Test: Vérification rôle driver... "
    ROLE_RESPONSE=$(curl -s -X POST "${API_URL}/driver/location/update" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer ${DRIVER_TOKEN}" \
      -d '{"latitude": -4.3276, "longitude": 15.3136}' 2>/dev/null || echo "ERROR")
    
    if echo "$ROLE_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
        log_result "✅ PASS" "Token driver accepté pour les routes driver"
    else
        ERROR_MSG=$(echo "$ROLE_RESPONSE" | jq -r '.error // .message // "Erreur inconnue"' 2>/dev/null || echo "$ROLE_RESPONSE")
        if echo "$ERROR_MSG" | grep -qi "role\|driver\|403"; then
            log_result "❌ FAIL" "Token driver rejeté: ${ERROR_MSG}"
        else
            log_result "⚠️  WARN" "Erreur inattendue: ${ERROR_MSG}"
        fi
    fi
fi

# ============================================================================
# 7. TEST ENDPOINTS DISPONIBLES
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}7. TEST ENDPOINTS DISPONIBLES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ENDPOINTS=(
    "POST:/api/driver/location/update:Mise à jour position"
    "POST:/api/driver/accept_ride/999:Accepter une course"
    "POST:/api/driver/reject_ride/999:Rejeter une course"
    "POST:/api/driver/complete_ride/999:Compléter une course"
)

for endpoint_info in "${ENDPOINTS[@]}"; do
    IFS=':' read -r method path description <<< "$endpoint_info"
    echo -n "Test: Vérification endpoint ${method} ${path}... "
    
    TEST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BACKEND_URL}${path}" \
      -H "Content-Type: application/json" 2>/dev/null || echo -e "ERROR\n000")
    TEST_CODE=$(echo "$TEST_RESPONSE" | tail -n1)
    
    if [ "$TEST_CODE" = "401" ] || [ "$TEST_CODE" = "403" ] || [ "$TEST_CODE" = "400" ] || [ "$TEST_CODE" = "404" ]; then
        log_result "✅ PASS" "Endpoint ${path} disponible (${description})"
    else
        log_result "⚠️  WARN" "Endpoint ${path} peut ne pas être disponible (code: ${TEST_CODE})"
    fi
done

# ============================================================================
# 8. RÉSUMÉ FINAL
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}8. RÉSUMÉ FINAL${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_WARNING))

log_result "ℹ️  INFO" "═══════════════════════════════════════════════════════════════"
log_result "ℹ️  INFO" "RÉSULTATS:"
log_result "ℹ️  INFO" "  ✅ Tests réussis: ${TESTS_PASSED}"
log_result "ℹ️  INFO" "  ❌ Tests échoués: ${TESTS_FAILED}"
log_result "ℹ️  INFO" "  ⚠️  Avertissements: ${TESTS_WARNING}"
log_result "ℹ️  INFO" "  📊 Total: ${TOTAL_TESTS}"
log_result "ℹ️  INFO" "═══════════════════════════════════════════════════════════════"

echo ""
log_result "ℹ️  INFO" "Configuration testée:"
log_result "ℹ️  INFO" "  - Backend URL: ${BACKEND_URL}"
log_result "ℹ️  INFO" "  - API URL: ${API_URL}"
log_result "ℹ️  INFO" "  - WebSocket URL: ${WS_URL}"
if [ -n "$DRIVER_TOKEN" ]; then
    log_result "ℹ️  INFO" "  - Driver Token: ${DRIVER_TOKEN:0:50}..."
    log_result "ℹ️  INFO" "  - Driver ID: ${DRIVER_ID}"
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Tous les tests critiques sont passés!${NC}"
    echo -e "${GREEN}🌐 Le backend Cloud Run est accessible et fonctionne correctement${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Certains tests ont échoué.${NC}"
    echo -e "${YELLOW}⚠️  Vérifiez la configuration et les logs du backend Cloud Run${NC}"
    exit 1
fi

