#!/bin/bash

# Script rapide pour configurer Twilio avec Account SID déjà fourni
# Usage: ./scripts/gcp-configure-twilio-quick.sh [AUTH_TOKEN] [PHONE_NUMBER]

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
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"
TWILIO_ACCOUNT_SID="TWILIO_ACCOUNT_SID" # Account SID fourni
TWILIO_WHATSAPP_FROM="whatsapp:+14155238886" # Numéro WhatsApp de test Twilio

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration Rapide Twilio${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier les arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo -e "${YELLOW}⚠️  Auth Token et numéro de téléphone requis${NC}"
  echo ""
  echo "Account SID déjà configuré : ${TWILIO_ACCOUNT_SID:0:10}..."
  echo ""
  echo "Usage:"
  echo "  $0 [AUTH_TOKEN] [PHONE_NUMBER]"
  echo ""
  echo "Exemple:"
  echo "  $0 abc123def456 +1234567890"
  echo ""
  
  # Demander les valeurs
  read -p "Entrez votre Twilio Auth Token: " TWILIO_AUTH_TOKEN
  read -p "Entrez votre numéro Twilio (ex: +1234567890): " TWILIO_PHONE_NUMBER
  
  if [ -z "$TWILIO_AUTH_TOKEN" ] || [ -z "$TWILIO_PHONE_NUMBER" ]; then
    echo -e "${RED}❌ Erreur: Auth Token et numéro de téléphone requis${NC}"
    exit 1
  fi
else
  TWILIO_AUTH_TOKEN="$1"
  TWILIO_PHONE_NUMBER="$2"
fi

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
  echo -e "${RED}❌ Erreur: gcloud CLI n'est pas installé${NC}"
  exit 1
fi

# Afficher la configuration
echo ""
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Projet GCP: ${GCP_PROJECT_ID}"
echo "  Service: ${SERVICE_NAME}"
echo "  Région: ${REGION}"
echo "  Account SID: ${TWILIO_ACCOUNT_SID:0:10}..."
echo "  Auth Token: ${TWILIO_AUTH_TOKEN:0:10}..."
echo "  Numéro SMS: ${TWILIO_PHONE_NUMBER}"
echo "  WhatsApp From: ${TWILIO_WHATSAPP_FROM}"
echo ""

# Confirmer
read -p "Continuer avec la configuration? (o/N): " confirm
if [[ ! $confirm =~ ^[OoYy]$ ]]; then
  echo -e "${YELLOW}⚠️  Opération annulée${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}🔄 Configuration des variables d'environnement dans Cloud Run...${NC}"

# Mettre à jour les variables d'environnement
gcloud run services update ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${GCP_PROJECT_ID} \
  --update-env-vars="TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID},TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN},TWILIO_PHONE_NUMBER=${TWILIO_PHONE_NUMBER},TWILIO_WHATSAPP_FROM=${TWILIO_WHATSAPP_FROM}" \
  --quiet

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Variables d'environnement Twilio configurées avec succès!${NC}"
  echo ""
  echo -e "${BLUE}📝 Variables configurées:${NC}"
  echo "  ✅ TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID:0:10}..."
  echo "  ✅ TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN:0:10}..."
  echo "  ✅ TWILIO_PHONE_NUMBER=${TWILIO_PHONE_NUMBER}"
  echo "  ✅ TWILIO_WHATSAPP_FROM=${TWILIO_WHATSAPP_FROM}"
  echo ""
  echo -e "${GREEN}💰 Plan Gratuit Twilio :${NC}"
  echo "  • \$15.50 de crédit offert"
  echo "  • ~2000 SMS gratuits"
  echo "  • ~3000 messages WhatsApp gratuits"
  echo ""
  echo -e "${YELLOW}⚠️  Important: Redéployez le backend pour activer Twilio${NC}"
  echo ""
  echo -e "${BLUE}🧪 Pour tester après redéploiement:${NC}"
  echo "  ./scripts/test-otp-redis.sh 243820098808"
  echo ""
  echo -e "${GREEN}✅ Configuration terminée!${NC}"
else
  echo -e "${RED}❌ Erreur lors de la configuration${NC}"
  exit 1
fi

