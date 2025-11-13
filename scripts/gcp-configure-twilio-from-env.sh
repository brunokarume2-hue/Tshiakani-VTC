#!/bin/bash

# Script pour configurer Twilio depuis un fichier .env
# Usage: 
#   1. Copier twilio-config.env.example en twilio-config.env
#   2. Remplir vos identifiants dans twilio-config.env
#   3. Exécuter: ./scripts/gcp-configure-twilio-from-env.sh

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
CONFIG_FILE="scripts/twilio-config.env"

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration Twilio depuis fichier .env${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier que le fichier existe
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "${RED}❌ Fichier de configuration non trouvé: ${CONFIG_FILE}${NC}"
  echo ""
  echo "Pour créer le fichier :"
  echo "  1. Copier: cp scripts/twilio-config.env.example scripts/twilio-config.env"
  echo "  2. Remplir vos identifiants Twilio dans scripts/twilio-config.env"
  echo "  3. Relancer ce script"
  exit 1
fi

# Charger les variables d'environnement
source "$CONFIG_FILE"

# Vérifier que les variables sont définies
if [ -z "$TWILIO_ACCOUNT_SID" ] || [ "$TWILIO_ACCOUNT_SID" = "VOTRE_ACCOUNT_SID_ICI" ]; then
  echo -e "${RED}❌ TWILIO_ACCOUNT_SID non configuré dans ${CONFIG_FILE}${NC}"
  exit 1
fi

if [ -z "$TWILIO_AUTH_TOKEN" ] || [ "$TWILIO_AUTH_TOKEN" = "VOTRE_AUTH_TOKEN_ICI" ]; then
  echo -e "${RED}❌ TWILIO_AUTH_TOKEN non configuré dans ${CONFIG_FILE}${NC}"
  exit 1
fi

if [ -z "$TWILIO_PHONE_NUMBER" ] || [ "$TWILIO_PHONE_NUMBER" = "+VOTRE_NUMERO_ICI" ]; then
  echo -e "${RED}❌ TWILIO_PHONE_NUMBER non configuré dans ${CONFIG_FILE}${NC}"
  exit 1
fi

# WhatsApp From (par défaut si non défini)
TWILIO_WHATSAPP_FROM="${TWILIO_WHATSAPP_FROM:-whatsapp:+14155238886}"

# Afficher la configuration
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

