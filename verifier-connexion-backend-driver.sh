#!/bin/bash

# Script de vérification complète de la connexion au backend et de l'app driver
# Usage: ./verifier-connexion-backend-driver.sh

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "🔍 VÉRIFICATION CONNEXION BACKEND ET APP DRIVER"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
BACKEND_URL="${BACKEND_URL:-http://localhost:3000}"
API_URL="${BACKEND_URL}/api"
HEALTH_URL="${BACKEND_URL}/health"
REPORT_FILE="rapport-verification-backend-driver-$(date +%Y%m%d-%H%M%S).txt"
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
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$status] $message" >> "$REPORT_FILE"
    
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

# Initialiser le rapport
echo "Rapport de vérification backend et app driver - $(date)" > "$REPORT_FILE"
echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================================================
# 1. VÉRIFICATION DU BACKEND (HEALTH CHECK)
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. VÉRIFICATION DU BACKEND${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 1.1: Health Check
echo -n "Test: Health Check... "
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${HEALTH_URL}" 2>/dev/null || echo "ERROR")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    log_result "✅ PASS" "Backend accessible sur ${BACKEND_URL}"
    echo "   Réponse: $BODY"
    # Vérifier la connexion à la base de données
    if echo "$BODY" | grep -q "connected"; then
        log_result "✅ PASS" "Base de données connectée"
    else
        log_result "⚠️  WARN" "Base de données non connectée ou statut inconnu"
    fi
else
    log_result "❌ FAIL" "Backend non accessible sur ${BACKEND_URL} (Code HTTP: ${HTTP_CODE})"
    log_result "ℹ️  INFO" "Démarrez le backend: cd backend && npm start"
    echo ""
    echo -e "${RED}❌ Impossible de continuer sans backend accessible${NC}"
    exit 1
fi

# ============================================================================
# 2. AUTHENTIFICATION DRIVER
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. AUTHENTIFICATION DRIVER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 2.1: Authentification driver
echo -n "Test: Authentification driver... "
DRIVER_PHONE="${DRIVER_PHONE:-+243900000001}"
AUTH_RESPONSE=$(curl -s -X POST "${API_URL}/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{
    \"phoneNumber\": \"${DRIVER_PHONE}\",
    \"role\": \"driver\"
  }" 2>/dev/null || echo "ERROR")

if echo "$AUTH_RESPONSE" | jq -e '.token' > /dev/null 2>&1; then
    DRIVER_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.token')
    DRIVER_ID=$(echo "$AUTH_RESPONSE" | jq -r '.user.id // empty')
    log_result "✅ PASS" "Authentification driver réussie"
    echo "   Token JWT: ${DRIVER_TOKEN:0:50}..."
    if [ -n "$DRIVER_ID" ]; then
        echo "   Driver ID: ${DRIVER_ID}"
    fi
else
    log_result "❌ FAIL" "Échec de l'authentification driver"
    echo "   Réponse: $AUTH_RESPONSE"
    log_result "ℹ️  INFO" "Vérifiez que le backend est démarré et que la base de données est configurée"
    DRIVER_TOKEN=""
fi

# Test 2.2: Vérification du profil driver
if [ -n "$DRIVER_TOKEN" ]; then
    echo -n "Test: Vérification profil driver... "
    PROFILE_RESPONSE=$(curl -s -X GET "${API_URL}/auth/profile" \
      -H "Authorization: Bearer ${DRIVER_TOKEN}" 2>/dev/null || echo "ERROR")
    
    if echo "$PROFILE_RESPONSE" | jq -e '.role' > /dev/null 2>&1; then
        ROLE=$(echo "$PROFILE_RESPONSE" | jq -r '.role')
        if [ "$ROLE" = "driver" ]; then
            log_result "✅ PASS" "Profil driver vérifié (rôle: ${ROLE})"
        else
            log_result "⚠️  WARN" "Rôle utilisateur: ${ROLE} (attendu: driver)"
        fi
    else
        log_result "⚠️  WARN" "Impossible de récupérer le profil driver"
    fi
fi

# ============================================================================
# 3. ROUTES DRIVER (API REST)
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. ROUTES DRIVER (API REST)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$DRIVER_TOKEN" ]; then
    log_result "⚠️  WARN" "Impossible de tester les routes driver sans authentification"
else
    # Test 3.1: Mise à jour de la position
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
    
    # Test 3.2: Vérification de l'endpoint (sans authentification pour tester l'erreur)
    echo -n "Test: Protection de l'endpoint (sans token)... "
    PROTECTED_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/driver/location/update" \
      -H "Content-Type: application/json" \
      -d '{"latitude": 0, "longitude": 0}' 2>/dev/null || echo "ERROR")
    PROTECTED_CODE=$(echo "$PROTECTED_RESPONSE" | tail -n1)
    
    if [ "$PROTECTED_CODE" = "401" ] || [ "$PROTECTED_CODE" = "403" ]; then
        log_result "✅ PASS" "Endpoint protégé (code HTTP: ${PROTECTED_CODE})"
    else
        log_result "⚠️  WARN" "Endpoint peut ne pas être correctement protégé (code HTTP: ${PROTECTED_CODE})"
    fi
fi

# ============================================================================
# 4. VÉRIFICATION DES ROUTES DISPONIBLES
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. VÉRIFICATION DES ROUTES DRIVER DISPONIBLES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Liste des routes driver à vérifier
DRIVER_ROUTES=(
    "POST:/api/driver/location/update:Mise à jour position"
    "POST:/api/driver/accept_ride/:rideId:Accepter une course"
    "POST:/api/driver/reject_ride/:rideId:Rejeter une course"
    "POST:/api/driver/complete_ride/:rideId:Compléter une course"
)

for route_info in "${DRIVER_ROUTES[@]}"; do
    IFS=':' read -r method path description <<< "$route_info"
    echo -n "Test: Vérification route ${method} ${path}... "
    
    # Tester avec une requête OPTIONS ou GET pour vérifier si la route existe
    # Pour les routes POST, on vérifie juste que l'endpoint répond (même avec une erreur 401/403)
    TEST_PATH=$(echo "$path" | sed 's/:rideId/999/g')
    TEST_RESPONSE=$(curl -s -w "\n%{http_code}" -X OPTIONS "${BACKEND_URL}${TEST_PATH}" \
      -H "Content-Type: application/json" 2>/dev/null || echo -e "ERROR\n000")
    TEST_CODE=$(echo "$TEST_RESPONSE" | tail -n1)
    
    if [ "$TEST_CODE" != "000" ] && [ "$TEST_CODE" != "404" ]; then
        log_result "✅ PASS" "Route ${method} ${path} disponible (${description})"
    else
        # Essayer avec POST pour vérifier l'authentification
        if [ "$method" = "POST" ]; then
            POST_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BACKEND_URL}${TEST_PATH}" \
              -H "Content-Type: application/json" 2>/dev/null || echo -e "ERROR\n000")
            POST_CODE=$(echo "$POST_RESPONSE" | tail -n1)
            
            if [ "$POST_CODE" = "401" ] || [ "$POST_CODE" = "403" ] || [ "$POST_CODE" = "400" ]; then
                log_result "✅ PASS" "Route ${method} ${path} disponible (${description})"
            else
                log_result "⚠️  WARN" "Route ${method} ${path} peut ne pas être disponible (code: ${POST_CODE})"
            fi
        else
            log_result "⚠️  WARN" "Route ${method} ${path} peut ne pas être disponible"
        fi
    fi
done

# ============================================================================
# 5. VÉRIFICATION DE LA CONFIGURATION iOS
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. VÉRIFICATION DE LA CONFIGURATION iOS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier ConfigurationService.swift
CONFIG_FILE="Tshiakani VTC/Services/ConfigurationService.swift"
if [ -f "$CONFIG_FILE" ]; then
    log_result "✅ PASS" "Fichier ConfigurationService.swift trouvé"
    
    # Vérifier les URLs
    if grep -q "localhost:3000" "$CONFIG_FILE"; then
        log_result "✅ PASS" "URL backend DEBUG configurée (localhost:3000)"
    fi
    
    if grep -q "tshiakani-driver-backend" "$CONFIG_FILE" || grep -q "api.tshiakani-vtc.com" "$CONFIG_FILE"; then
        log_result "✅ PASS" "URL backend PRODUCTION configurée"
    fi
    
    if grep -q "/ws/driver" "$CONFIG_FILE"; then
        log_result "✅ PASS" "Namespace WebSocket driver configuré (/ws/driver)"
    else
        log_result "⚠️  WARN" "Namespace WebSocket driver non trouvé"
    fi
    
    # Vérifier les endpoints driver
    if grep -q "driver" "$CONFIG_FILE" -i; then
        log_result "✅ PASS" "Configuration driver présente"
    fi
else
    log_result "❌ FAIL" "Fichier ConfigurationService.swift non trouvé"
fi

# Vérifier Info.plist
INFO_PLIST="Tshiakani VTC/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    log_result "✅ PASS" "Fichier Info.plist trouvé"
    
    if grep -q "API_BASE_URL" "$INFO_PLIST"; then
        API_URL_PLIST=$(grep -A1 "API_BASE_URL" "$INFO_PLIST" | tail -n1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        log_result "ℹ️  INFO" "API_BASE_URL dans Info.plist: ${API_URL_PLIST}"
    fi
    
    if grep -q "WS_BASE_URL" "$INFO_PLIST"; then
        WS_URL_PLIST=$(grep -A1 "WS_BASE_URL" "$INFO_PLIST" | tail -n1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
        log_result "ℹ️  INFO" "WS_BASE_URL dans Info.plist: ${WS_URL_PLIST}"
    fi
else
    log_result "⚠️  WARN" "Fichier Info.plist non trouvé"
fi

# ============================================================================
# 6. VÉRIFICATION DES FICHIERS BACKEND
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. VÉRIFICATION DES FICHIERS BACKEND${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier le fichier de routes driver
DRIVER_ROUTES_FILE="backend/routes.postgres/driver.js"
if [ -f "$DRIVER_ROUTES_FILE" ]; then
    log_result "✅ PASS" "Fichier routes.postgres/driver.js trouvé"
    
    # Vérifier les routes spécifiques
    if grep -q "location/update" "$DRIVER_ROUTES_FILE"; then
        log_result "✅ PASS" "Route location/update présente"
    fi
    
    if grep -q "accept_ride" "$DRIVER_ROUTES_FILE"; then
        log_result "✅ PASS" "Route accept_ride présente"
    fi
    
    if grep -q "reject_ride" "$DRIVER_ROUTES_FILE"; then
        log_result "✅ PASS" "Route reject_ride présente"
    fi
    
    if grep -q "complete_ride" "$DRIVER_ROUTES_FILE"; then
        log_result "✅ PASS" "Route complete_ride présente"
    fi
else
    log_result "❌ FAIL" "Fichier routes.postgres/driver.js non trouvé"
fi

# Vérifier le serveur principal
SERVER_FILE="backend/server.postgres.js"
if [ -f "$SERVER_FILE" ]; then
    log_result "✅ PASS" "Fichier server.postgres.js trouvé"
    
    if grep -q "/api/driver" "$SERVER_FILE"; then
        log_result "✅ PASS" "Route /api/driver enregistrée dans le serveur"
    else
        log_result "❌ FAIL" "Route /api/driver non enregistrée dans le serveur"
    fi
    
    if grep -q "/ws/driver" "$SERVER_FILE"; then
        log_result "✅ PASS" "Namespace WebSocket /ws/driver configuré"
    else
        log_result "⚠️  WARN" "Namespace WebSocket /ws/driver non trouvé"
    fi
else
    log_result "❌ FAIL" "Fichier server.postgres.js non trouvé"
fi

# ============================================================================
# 7. RÉSUMÉ FINAL
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}7. RÉSUMÉ FINAL${NC}"
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

echo "" >> "$REPORT_FILE"
echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
echo "Rapport sauvegardé dans: ${REPORT_FILE}" >> "$REPORT_FILE"

# Résumé des configurations
echo "" >> "$REPORT_FILE"
echo "CONFIGURATIONS DÉTECTÉES:" >> "$REPORT_FILE"
echo "  - Backend URL: ${BACKEND_URL}" >> "$REPORT_FILE"
echo "  - API URL: ${API_URL}" >> "$REPORT_FILE"
if [ -n "$DRIVER_TOKEN" ]; then
    echo "  - Driver Token: ${DRIVER_TOKEN:0:50}..." >> "$REPORT_FILE"
    echo "  - Driver ID: ${DRIVER_ID}" >> "$REPORT_FILE"
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Tous les tests critiques sont passés!${NC}"
    echo -e "${GREEN}📄 Rapport détaillé: ${REPORT_FILE}${NC}"
    echo ""
    echo -e "${CYAN}📋 Prochaines étapes:${NC}"
    echo -e "  1. Vérifier la connexion WebSocket depuis l'app iOS"
    echo -e "  2. Tester l'acceptation de course depuis l'app driver"
    echo -e "  3. Vérifier les notifications en temps réel"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Certains tests ont échoué. Consultez le rapport pour plus de détails.${NC}"
    echo -e "${YELLOW}📄 Rapport détaillé: ${REPORT_FILE}${NC}"
    exit 1
fi

