#!/bin/bash

# Script rapide pour configurer Vonage avec les credentials fournis
# Usage: ./scripts/gcp-configure-vonage-quick.sh [VONAGE_PHONE_NUMBER]

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
VONAGE_API_KEY="85ba4b36" # Clé API fournie
VONAGE_API_SECRET="7BFjTqkirVbRIDEj" # Secret fourni
VONAGE_WHATSAPP_FROM="+14157386102" # Numéro WhatsApp de test Vonage (sandbox)

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration Rapide Vonage API${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier le numéro de téléphone
VONAGE_PHONE_NUMBER="${1}"

if [ -z "$VONAGE_PHONE_NUMBER" ]; then
  echo -e "${YELLOW}⚠️  Numéro de téléphone Vonage requis${NC}"
  echo ""
  echo "Pour obtenir un numéro Vonage :"
  echo "  1. Aller sur : https://dashboard.nexmo.com/getting-started/numbers"
  echo "  2. Acheter un numéro virtuel"
  echo "  3. Utiliser ce numéro ici"
  echo ""
  read -p "Entrez le numéro de téléphone Vonage (ex: +1234567890) ou appuyez sur Entrée pour configurer plus tard: " VONAGE_PHONE_NUMBER
  
  if [ -z "$VONAGE_PHONE_NUMBER" ]; then
    echo -e "${YELLOW}⚠️  Configuration annulée. Vous pouvez configurer le numéro plus tard.${NC}"
    echo ""
    echo "Pour configurer plus tard :"
    echo "  ./scripts/gcp-configure-vonage-quick.sh +VOTRE_NUMERO"
    exit 0
  fi
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
echo "  Clé API Vonage: ${VONAGE_API_KEY}"
echo "  Secret API: ${VONAGE_API_SECRET:0:10}..."
echo "  Numéro Vonage: ${VONAGE_PHONE_NUMBER}"
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
# Note: On utilise --update-env-vars pour ajouter/ mettre à jour sans écraser les autres variables
gcloud run services update ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${GCP_PROJECT_ID} \
  --update-env-vars="VONAGE_API_KEY=${VONAGE_API_KEY},VONAGE_API_SECRET=${VONAGE_API_SECRET},VONAGE_PHONE_NUMBER=${VONAGE_PHONE_NUMBER},VONAGE_WHATSAPP_FROM=${VONAGE_WHATSAPP_FROM}" \
  --quiet

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Variables d'environnement Vonage configurées avec succès!${NC}"
  echo ""
  echo -e "${BLUE}📝 Variables configurées:${NC}"
  echo "  ✅ VONAGE_API_KEY=${VONAGE_API_KEY}"
  echo "  ✅ VONAGE_API_SECRET=${VONAGE_API_SECRET:0:10}..."
  echo "  ✅ VONAGE_PHONE_NUMBER=${VONAGE_PHONE_NUMBER}"
  echo "  ✅ VONAGE_WHATSAPP_FROM=${VONAGE_WHATSAPP_FROM} (sandbox)"
  echo ""
  echo -e "${YELLOW}⚠️  Important: Redéployez le backend pour activer Vonage${NC}"
  echo ""
  echo -e "${BLUE}🧪 Pour tester après redéploiement:${NC}"
  echo "  ./scripts/test-otp-redis.sh 243820098808"
  echo ""
  echo -e "${GREEN}✅ Configuration terminée!${NC}"
else
  echo -e "${RED}❌ Erreur lors de la configuration${NC}"
  exit 1
fi

