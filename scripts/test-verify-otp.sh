#!/bin/bash

# 🧪 Script de Test : Vérification d'OTP
# Usage: ./scripts/test-verify-otp.sh [PHONE_NUMBER] [OTP_CODE]

set -e

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKEND_URL="${BACKEND_URL:-https://tshiakani-vtc-backend-418102154417.us-central1.run.app}"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧪 Test de Vérification d'OTP${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Récupérer les paramètres
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${YELLOW}Usage: $0 [PHONE_NUMBER] [OTP_CODE]${NC}"
    echo ""
    echo -e "${BLUE}Exemple:${NC}"
    echo "  $0 +243847305825 123456"
    echo ""
    read -p "Numéro de téléphone (ex: +243847305825): " PHONE_NUMBER
    read -p "Code OTP (6 chiffres): " OTP_CODE
else
    PHONE_NUMBER="$1"
    OTP_CODE="$2"
fi

if [ -z "$PHONE_NUMBER" ] || [ -z "$OTP_CODE" ]; then
    echo -e "${RED}❌ Numéro de téléphone et code OTP requis${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Paramètres :${NC}"
echo "  Numéro : $PHONE_NUMBER"
echo "  Code OTP : $OTP_CODE"
echo ""

echo -e "${BLUE}🔄 Vérification du code OTP...${NC}"
echo ""

VERIFY_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"${PHONE_NUMBER}\", \"code\": \"${OTP_CODE}\"}")

echo -e "${BLUE}📥 Réponse de l'API :${NC}"
echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VERIFY_RESPONSE"
echo ""

if echo "$VERIFY_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ ✅ Code OTP vérifié avec succès !${NC}"
    echo ""
    echo -e "${GREEN}🎉 Le système d'authentification OTP fonctionne parfaitement !${NC}"
    echo ""
    echo -e "${BLUE}📋 Résumé :${NC}"
    echo -e "  ${GREEN}✅${NC} Envoi d'OTP via Twilio : Fonctionnel"
    echo -e "  ${GREEN}✅${NC} Stockage dans Redis : Fonctionnel"
    echo -e "  ${GREEN}✅${NC} Vérification d'OTP : Fonctionnel"
    echo ""
    echo -e "${GREEN}🚀 Le système est prêt pour la production !${NC}"
elif echo "$VERIFY_RESPONSE" | grep -q "invalide\|expiré\|invalid\|expired"; then
    echo -e "${RED}⚠️  Code OTP invalide ou expiré${NC}"
    echo ""
    echo -e "${YELLOW}💡 Vérifiez :${NC}"
    echo "  1. Que le code est correct (6 chiffres)"
    echo "  2. Que le code n'a pas expiré (10 minutes)"
    echo "  3. Que vous n'avez pas dépassé 5 tentatives"
    echo "  4. Que le numéro de téléphone correspond"
elif echo "$VERIFY_RESPONSE" | grep -q "error"; then
    ERROR_MSG=$(echo "$VERIFY_RESPONSE" | grep -o '"error":"[^"]*"' | head -1)
    echo -e "${RED}❌ Erreur :${NC}"
    echo "$ERROR_MSG"
else
    echo -e "${YELLOW}📝 Vérifiez la réponse ci-dessus${NC}"
fi

