#!/bin/bash

# Script de test pour l'OTP avec Redis
# Teste l'envoi, la vérification et le stockage dans Redis

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKEND_URL="${BACKEND_URL:-https://tshiakani-vtc-backend-418102154417.us-central1.run.app}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
REDIS_INSTANCE="${REDIS_INSTANCE:-tshiakani-redis}"
REDIS_REGION="${REDIS_REGION:-us-central1}"

# Numéro de téléphone de test
TEST_PHONE="${1:-243820098808}"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🧪 Test OTP avec Redis${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Backend URL: ${BACKEND_URL}"
echo "  Numéro de test: +${TEST_PHONE}"
echo "  Redis Instance: ${REDIS_INSTANCE}"
echo ""

# Étape 1 : Test de l'envoi d'OTP
echo -e "${BLUE}📋 Étape 1 : Test de l'envoi d'OTP${NC}"
echo ""

SEND_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/send-otp" \
  -H "Content-Type: application/json" \
  -d "{
    \"phoneNumber\": \"+${TEST_PHONE}\",
    \"channel\": \"sms\"
  }")

if echo "$SEND_RESPONSE" | grep -q "success\|message\|sent"; then
  echo -e "${GREEN}✅ OTP envoyé avec succès${NC}"
  echo "  Réponse: $SEND_RESPONSE"
else
  echo -e "${RED}❌ Erreur lors de l'envoi d'OTP${NC}"
  echo "  Réponse: $SEND_RESPONSE"
  exit 1
fi

echo ""
echo -e "${YELLOW}⏳ Attente de 3 secondes pour que l'OTP soit stocké dans Redis...${NC}"
sleep 3

# Étape 2 : Vérifier que l'OTP est stocké dans Redis
echo ""
echo -e "${BLUE}📋 Étape 2 : Vérification du stockage dans Redis${NC}"
echo ""

# Obtenir l'adresse IP de Redis
REDIS_HOST=$(gcloud redis instances describe "${REDIS_INSTANCE}" \
  --region="${REDIS_REGION}" \
  --project="${GCP_PROJECT_ID}" \
  --format="value(host)" 2>/dev/null || echo "")

if [ -z "$REDIS_HOST" ]; then
  echo -e "${YELLOW}⚠️  Impossible de récupérer l'adresse Redis automatiquement${NC}"
  echo "  Vérifiez manuellement dans Google Cloud Console"
  echo "  Ou utilisez: gcloud redis instances describe ${REDIS_INSTANCE} --region=${REDIS_REGION}"
else
  echo -e "${GREEN}✅ Redis Host trouvé: ${REDIS_HOST}${NC}"
  echo ""
  echo -e "${BLUE}🔍 Vérification de la clé OTP dans Redis...${NC}"
  echo ""
  
  # Note: Pour accéder à Redis, vous devez être dans le même VPC ou utiliser un tunnel
  echo -e "${YELLOW}⚠️  Pour vérifier directement dans Redis, vous devez:${NC}"
  echo "  1. Être connecté au VPC de Redis"
  echo "  2. Ou utiliser un tunnel VPN"
  echo "  3. Ou utiliser gcloud redis connect"
  echo ""
  echo "  Commande pour se connecter:"
  echo "  gcloud redis instances describe ${REDIS_INSTANCE} --region=${REDIS_REGION} --project=${GCP_PROJECT_ID}"
  echo ""
fi

# Étape 3 : Test de la vérification d'OTP
echo -e "${BLUE}📋 Étape 3 : Test de la vérification d'OTP${NC}"
echo ""
echo -e "${YELLOW}⚠️  Pour tester la vérification, vous devez:${NC}"
echo "  1. Récupérer le code OTP depuis Redis ou les logs"
echo "  2. Ou utiliser un code de test si disponible"
echo ""
read -p "Entrez le code OTP reçu (ou appuyez sur Entrée pour passer): " OTP_CODE

if [ ! -z "$OTP_CODE" ]; then
  echo ""
  echo -e "${BLUE}🔄 Vérification de l'OTP...${NC}"
  
  VERIFY_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{
      \"phoneNumber\": \"+${TEST_PHONE}\",
      \"code\": \"${OTP_CODE}\"
    }")
  
  if echo "$VERIFY_RESPONSE" | grep -q "valid\|success\|token"; then
    echo -e "${GREEN}✅ OTP vérifié avec succès${NC}"
    echo "  Réponse: $VERIFY_RESPONSE"
  else
    echo -e "${RED}❌ Erreur lors de la vérification d'OTP${NC}"
    echo "  Réponse: $VERIFY_RESPONSE"
  fi
else
  echo -e "${YELLOW}⚠️  Test de vérification ignoré${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📊 Résumé des Tests${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📝 Pour vérifier manuellement dans Redis:${NC}"
echo ""
echo "1. Se connecter à Redis:"
echo "   gcloud redis instances describe ${REDIS_INSTANCE} --region=${REDIS_REGION}"
echo ""
echo "2. Vérifier la clé OTP:"
echo "   redis-cli -h ${REDIS_HOST} GET \"otp:${TEST_PHONE}\""
echo "   ou"
echo "   redis-cli -h ${REDIS_HOST} HGETALL \"otp:${TEST_PHONE}\""
echo ""
echo "3. Vérifier les logs Cloud Run:"
echo "   gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend\" --limit 50 --project=${GCP_PROJECT_ID}"
echo ""

