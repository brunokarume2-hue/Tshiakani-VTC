#!/bin/bash

# Script pour configurer Twilio API dans Cloud Run
# Twilio offre $15.50 de crédit gratuit à l'inscription !

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

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration Twilio API (Plan Gratuit : \$15.50)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier les arguments
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo -e "${YELLOW}⚠️  Credentials Twilio requis${NC}"
  echo ""
  echo "Pour obtenir vos credentials Twilio (GRATUIT) :"
  echo "  1. Aller sur : https://www.twilio.com/try-twilio"
  echo "  2. Créer un compte (gratuit, \$15.50 offert)"
  echo "  3. Obtenir dans le Dashboard :"
  echo "     - Account SID"
  echo "     - Auth Token"
  echo "     - Numéro de téléphone Twilio (gratuit pour les tests)"
  echo ""
  echo "Usage:"
  echo "  $0 [ACCOUNT_SID] [AUTH_TOKEN] [PHONE_NUMBER]"
  echo ""
  echo "Exemple:"
  echo "  $0 AC1234567890 abcdef123456 +1234567890"
  echo ""
  
  # Demander les valeurs
  read -p "Entrez votre Twilio Account SID: " TWILIO_ACCOUNT_SID
  read -p "Entrez votre Twilio Auth Token: " TWILIO_AUTH_TOKEN
  read -p "Entrez votre numéro Twilio (ex: +1234567890): " TWILIO_PHONE_NUMBER
  
  if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ] || [ -z "$TWILIO_PHONE_NUMBER" ]; then
    echo -e "${RED}❌ Erreur: Tous les champs sont requis${NC}"
    exit 1
  fi
else
  TWILIO_ACCOUNT_SID="$1"
  TWILIO_AUTH_TOKEN="$2"
  TWILIO_PHONE_NUMBER="$3"
fi

# WhatsApp From (numéro de test Twilio)
TWILIO_WHATSAPP_FROM="${4:-whatsapp:+14155238886}"

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
  echo "  ✅ TWILIO_ACCOUNT_SID"
  echo "  ✅ TWILIO_AUTH_TOKEN"
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
