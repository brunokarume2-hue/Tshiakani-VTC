#!/bin/bash

# Script de vérification complète des connexions
# Backend, App Driver, Base de données PostgreSQL
# Usage: ./verifier-connexions.sh

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "🔍 VÉRIFICATION DES CONNEXIONS - TSHIAKANI VTC"
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
BACKEND_DIR="./backend"
ENV_FILE="${BACKEND_DIR}/.env"
BACKEND_URL="http://localhost:3000"
API_URL="${BACKEND_URL}/api"
REPORT_FILE="rapport-verification-connexions-$(date +%Y%m%d-%H%M%S).txt"

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
echo "Rapport de vérification des connexions - $(date)" > "$REPORT_FILE"
echo "═══════════════════════════════════════════════════════════════" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# ============================================================================
# 1. VÉRIFICATION DU FICHIER .env
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}1. VÉRIFICATION DE LA CONFIGURATION (.env)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$ENV_FILE" ]; then
    log_result "✅ PASS" "Fichier .env trouvé dans ${BACKEND_DIR}/"
    
    # Vérifier les variables essentielles en lisant le fichier
    if grep -q "DB_HOST\|DATABASE_URL" "$ENV_FILE" 2>/dev/null; then
        log_result "✅ PASS" "Configuration de la base de données présente"
    else
        log_result "❌ FAIL" "Configuration de la base de données manquante (DB_HOST ou DATABASE_URL)"
    fi
    
    if grep -q "DB_PASSWORD\|DATABASE_URL" "$ENV_FILE" 2>/dev/null; then
        if grep -q "DB_PASSWORD=.*[^your_password_here]" "$ENV_FILE" 2>/dev/null || grep -q "DATABASE_URL=postgresql://" "$ENV_FILE" 2>/dev/null; then
            log_result "✅ PASS" "Mot de passe de la base de données configuré"
        else
            log_result "⚠️  WARN" "Mot de passe de la base de données semble être la valeur par défaut"
        fi
    else
        log_result "⚠️  WARN" "Mot de passe de la base de données non configuré"
    fi
    
    if grep -q "JWT_SECRET=" "$ENV_FILE" 2>/dev/null; then
        if grep -q "JWT_SECRET=.*[^your_jwt_secret_here]" "$ENV_FILE" 2>/dev/null; then
            log_result "✅ PASS" "JWT_SECRET configuré"
        else
            log_result "⚠️  WARN" "JWT_SECRET semble être la valeur par défaut"
        fi
    else
        log_result "❌ FAIL" "JWT_SECRET manquant"
    fi
    
    PORT_LINE=$(grep "^PORT=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 || echo "")
    if [ -n "$PORT_LINE" ]; then
        log_result "ℹ️  INFO" "Port du serveur: ${PORT_LINE}"
    else
        log_result "ℹ️  INFO" "Port du serveur: 3000 (par défaut)"
    fi
else
    log_result "❌ FAIL" "Fichier .env non trouvé dans ${BACKEND_DIR}/"
    log_result "ℹ️  INFO" "Créez le fichier .env à partir de ENV.example: cd backend && cp ENV.example .env"
fi

# ============================================================================
# 2. VÉRIFICATION DE POSTGRESQL
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}2. VÉRIFICATION DE POSTGRESQL${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si PostgreSQL est installé
if command -v psql &> /dev/null; then
    log_result "✅ PASS" "PostgreSQL est installé (psql trouvé)"
    
    # Vérifier si PostgreSQL est en cours d'exécution
    if pg_isready -h localhost -p 5432 &> /dev/null; then
        log_result "✅ PASS" "PostgreSQL est en cours d'exécution sur localhost:5432"
        
        # Tester la connexion avec les variables d'environnement
        if [ -f "$ENV_FILE" ]; then
            # Lire les variables depuis le fichier .env
            DB_HOST=$(grep "^DB_HOST=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
            DB_PORT=$(grep "^DB_PORT=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "5432")
            DB_USER=$(grep "^DB_USER=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "postgres")
            DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "tshiakani_vtc")
            DB_PASSWORD=$(grep "^DB_PASSWORD=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "")
            
            # Utiliser les valeurs par défaut si vides
            DB_HOST="${DB_HOST:-localhost}"
            DB_PORT="${DB_PORT:-5432}"
            DB_USER="${DB_USER:-postgres}"
            DB_NAME="${DB_NAME:-tshiakani_vtc}"
            
            if [ -n "$DB_PASSWORD" ] && [ "$DB_PASSWORD" != "your_password_here" ]; then
                # Essayer de se connecter
                if PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null 2>&1; then
                    log_result "✅ PASS" "Connexion à la base de données réussie (${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME})"
                    
                    # Vérifier PostGIS
                    POSTGIS_VERSION=$(PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT PostGIS_version();" 2>/dev/null | xargs || echo "")
                    if [ -n "$POSTGIS_VERSION" ] && [ "$POSTGIS_VERSION" != "" ]; then
                        log_result "✅ PASS" "PostGIS est activé (version: ${POSTGIS_VERSION})"
                    else
                        log_result "⚠️  WARN" "PostGIS n'est pas activé ou n'est pas installé"
                    fi
                    
                    # Vérifier les tables principales
                    TABLES=$(PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs || echo "0")
                    if [ -n "$TABLES" ] && [ "$TABLES" -gt 0 ]; then
                        log_result "✅ PASS" "Base de données contient ${TABLES} table(s)"
                    else
                        log_result "⚠️  WARN" "Aucune table trouvée dans la base de données"
                    fi
                else
                    log_result "⚠️  WARN" "Impossible de se connecter à la base de données (vérifiez DB_PASSWORD ou utilisez le script Node.js)"
                fi
            else
                log_result "⚠️  WARN" "Mot de passe non configuré, impossible de tester la connexion PostgreSQL directement"
                log_result "ℹ️  INFO" "Utilisez: cd backend && node test-database-connection.js"
            fi
        else
            log_result "⚠️  WARN" "Fichier .env non trouvé, impossible de tester la connexion"
        fi
    else
        log_result "❌ FAIL" "PostgreSQL n'est pas en cours d'exécution"
        log_result "ℹ️  INFO" "Démarrez PostgreSQL: brew services start postgresql@14 (ou votre version)"
    fi
else
    log_result "❌ FAIL" "PostgreSQL n'est pas installé"
    log_result "ℹ️  INFO" "Installez PostgreSQL: brew install postgresql@14"
fi

# ============================================================================
# 3. VÉRIFICATION DU BACKEND
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}3. VÉRIFICATION DU BACKEND${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si le backend est en cours d'exécution
if curl -s -f -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health" 2>/dev/null | grep -q "200\|404"; then
    log_result "✅ PASS" "Backend accessible sur ${BACKEND_URL}"
    
    # Tester l'endpoint health
    HEALTH_RESPONSE=$(curl -s "${BACKEND_URL}/health" 2>/dev/null || echo "")
    if [ -n "$HEALTH_RESPONSE" ]; then
        log_result "ℹ️  INFO" "Réponse health: ${HEALTH_RESPONSE}"
    fi
else
    log_result "❌ FAIL" "Backend non accessible sur ${BACKEND_URL}"
    log_result "ℹ️  INFO" "Démarrez le backend: cd backend && npm run dev"
fi

# Vérifier les endpoints de l'API
echo ""
log_result "ℹ️  INFO" "Test des endpoints de l'API..."

# Test endpoint auth
if curl -s -f -o /dev/null -w "%{http_code}" "${API_URL}/auth" 2>/dev/null | grep -q "200\|404\|405"; then
    log_result "✅ PASS" "Endpoint /api/auth accessible"
else
    log_result "⚠️  WARN" "Endpoint /api/auth non accessible"
fi

# Test endpoint driver
if curl -s -f -o /dev/null -w "%{http_code}" "${API_URL}/driver" 2>/dev/null | grep -q "200\|404\|401\|403"; then
    log_result "✅ PASS" "Endpoint /api/driver accessible"
else
    log_result "⚠️  WARN" "Endpoint /api/driver non accessible"
fi

# Test endpoint client
if curl -s -f -o /dev/null -w "%{http_code}" "${API_URL}/client" 2>/dev/null | grep -q "200\|404\|401\|403"; then
    log_result "✅ PASS" "Endpoint /api/client accessible"
else
    log_result "⚠️  WARN" "Endpoint /api/client non accessible"
fi

# Test endpoint admin
if curl -s -f -o /dev/null -w "%{http_code}" "${API_URL}/admin" 2>/dev/null | grep -q "200\|404\|401\|403"; then
    log_result "✅ PASS" "Endpoint /api/admin accessible"
else
    log_result "⚠️  WARN" "Endpoint /api/admin non accessible"
fi

# ============================================================================
# 4. VÉRIFICATION DES ROUTES DE L'APP DRIVER
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}4. VÉRIFICATION DES ROUTES DE L'APP DRIVER${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si le fichier de routes driver existe
if [ -f "${BACKEND_DIR}/routes.postgres/driver.js" ]; then
    log_result "✅ PASS" "Fichier routes.postgres/driver.js trouvé"
    
    # Vérifier les routes spécifiques (nécessite authentification, donc on teste juste la présence)
    log_result "ℹ️  INFO" "Routes driver disponibles:"
    log_result "ℹ️  INFO" "  - POST /api/driver/location/update"
    log_result "ℹ️  INFO" "  - POST /api/driver/accept_ride/:rideId"
    log_result "ℹ️  INFO" "  - POST /api/driver/reject_ride/:rideId"
    log_result "ℹ️  INFO" "  - POST /api/driver/complete_ride/:rideId"
else
    log_result "❌ FAIL" "Fichier routes.postgres/driver.js non trouvé"
fi

# ============================================================================
# 5. VÉRIFICATION DES ROUTES DE L'APP CLIENT
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}5. VÉRIFICATION DES ROUTES DE L'APP CLIENT${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si le fichier de routes client existe
if [ -f "${BACKEND_DIR}/routes.postgres/client.js" ]; then
    log_result "✅ PASS" "Fichier routes.postgres/client.js trouvé"
    
    log_result "ℹ️  INFO" "Routes client disponibles:"
    log_result "ℹ️  INFO" "  - GET /api/client/track_driver/:rideId"
else
    log_result "❌ FAIL" "Fichier routes.postgres/client.js non trouvé"
fi

# ============================================================================
# 6. VÉRIFICATION DE LA CONFIGURATION iOS
# ============================================================================
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}6. VÉRIFICATION DE LA CONFIGURATION iOS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier si le fichier ConfigurationService.swift existe
if [ -f "Tshiakani VTC/Services/ConfigurationService.swift" ]; then
    log_result "✅ PASS" "Fichier ConfigurationService.swift trouvé"
    
    # Vérifier les URLs configurées
    if grep -q "localhost:3000" "Tshiakani VTC/Services/ConfigurationService.swift"; then
        log_result "✅ PASS" "URL backend configurée pour le mode DEBUG: http://localhost:3000"
    fi
    
    if grep -q "api.tshiakani-vtc.com" "Tshiakani VTC/Services/ConfigurationService.swift"; then
        log_result "✅ PASS" "URL backend configurée pour le mode PRODUCTION: https://api.tshiakani-vtc.com"
    fi
    
    if grep -q "/ws/driver" "Tshiakani VTC/Services/ConfigurationService.swift"; then
        log_result "✅ PASS" "Namespace WebSocket driver configuré: /ws/driver"
    fi
else
    log_result "⚠️  WARN" "Fichier ConfigurationService.swift non trouvé"
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

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Tous les tests critiques sont passés!${NC}"
    echo -e "${GREEN}📄 Rapport détaillé: ${REPORT_FILE}${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Certains tests ont échoué. Consultez le rapport pour plus de détails.${NC}"
    echo -e "${YELLOW}📄 Rapport détaillé: ${REPORT_FILE}${NC}"
    exit 1
fi

