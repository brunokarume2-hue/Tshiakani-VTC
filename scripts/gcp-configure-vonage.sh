#!/bin/bash

# Script pour configurer Vonage API dans Cloud Run
# Usage: ./scripts/gcp-configure-vonage.sh [VONAGE_API_KEY] [VONAGE_PHONE_NUMBER]

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
VONAGE_API_SECRET="7BFjTqkirVbRIDEj" # Secret fourni par l'utilisateur

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔧 Configuration Vonage API pour OTP${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier les arguments
if [ -z "$1" ]; then
  echo -e "${YELLOW}⚠️  Aucune clé API Vonage fournie${NC}"
  echo ""
  echo "Usage:"
  echo "  $0 [VONAGE_API_KEY] [VONAGE_PHONE_NUMBER]"
  echo ""
  echo "Ou définir les variables d'environnement :"
  echo "  export VONAGE_API_KEY='VOTRE_CLE_API'"
  echo "  export VONAGE_PHONE_NUMBER='+1234567890'"
  echo "  $0"
  echo ""
  
  # Demander les valeurs
  read -p "Entrez la clé API Vonage (API Key): " VONAGE_API_KEY
  read -p "Entrez le numéro de téléphone Vonage (ex: +1234567890): " VONAGE_PHONE_NUMBER
  
  if [ -z "$VONAGE_API_KEY" ] || [ -z "$VONAGE_PHONE_NUMBER" ]; then
    echo -e "${RED}❌ Erreur: Clé API et numéro de téléphone requis${NC}"
    exit 1
  fi
else
  VONAGE_API_KEY="$1"
  VONAGE_PHONE_NUMBER="${2:-}"
  
  if [ -z "$VONAGE_PHONE_NUMBER" ]; then
    read -p "Entrez le numéro de téléphone Vonage (ex: +1234567890): " VONAGE_PHONE_NUMBER
    if [ -z "$VONAGE_PHONE_NUMBER" ]; then
      echo -e "${RED}❌ Erreur: Numéro de téléphone requis${NC}"
      exit 1
    fi
  fi
fi

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
  echo -e "${RED}❌ Erreur: gcloud CLI n'est pas installé${NC}"
  exit 1
fi

# Afficher la configuration
echo -e "${BLUE}📋 Configuration:${NC}"
echo "  Projet GCP: ${GCP_PROJECT_ID}"
echo "  Service: ${SERVICE_NAME}"
echo "  Région: ${REGION}"
echo "  Clé API Vonage: ${VONAGE_API_KEY}"
echo "  Secret API Vonage: ${VONAGE_API_SECRET:0:10}..."
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
gcloud run services update ${SERVICE_NAME} \
  --region ${REGION} \
  --project ${GCP_PROJECT_ID} \
  --update-env-vars="VONAGE_API_KEY=${VONAGE_API_KEY},VONAGE_API_SECRET=${VONAGE_API_SECRET},VONAGE_PHONE_NUMBER=${VONAGE_PHONE_NUMBER}" \
  --quiet

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Variables d'environnement Vonage configurées avec succès!${NC}"
  echo ""
  echo -e "${BLUE}📝 Variables configurées:${NC}"
  echo "  ✅ VONAGE_API_KEY"
  echo "  ✅ VONAGE_API_SECRET"
  echo "  ✅ VONAGE_PHONE_NUMBER"
  echo ""
  echo -e "${BLUE}🧪 Pour tester l'envoi d'OTP:${NC}"
  echo "  ./scripts/test-otp-redis.sh 243820098808"
  echo ""
  echo -e "${GREEN}✅ Configuration terminée!${NC}"
else
  echo -e "${RED}❌ Erreur lors de la configuration${NC}"
  exit 1
fi

