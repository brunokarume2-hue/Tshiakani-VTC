#!/bin/bash

# Script pour vérifier directement les OTP dans Redis
# Nécessite d'être connecté au VPC ou d'utiliser un tunnel

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
REDIS_INSTANCE="${REDIS_INSTANCE:-tshiakani-redis}"
REDIS_REGION="${REDIS_REGION:-us-central1}"

# Numéro de téléphone à vérifier
PHONE_NUMBER="${1}"

if [ -z "$PHONE_NUMBER" ]; then
  echo -e "${RED}❌ Erreur: Numéro de téléphone requis${NC}"
  echo ""
  echo "Usage: $0 [PHONE_NUMBER]"
  echo "Exemple: $0 243820098808"
  exit 1
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🔍 Vérification OTP dans Redis${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Obtenir les informations Redis
echo -e "${BLUE}📋 Récupération des informations Redis...${NC}"
echo ""

REDIS_INFO=$(gcloud redis instances describe "${REDIS_INSTANCE}" \
  --region="${REDIS_REGION}" \
  --project="${GCP_PROJECT_ID}" \
  --format="yaml(host,port,authorizedNetwork)" 2>&1)

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Erreur lors de la récupération des informations Redis${NC}"
  echo "$REDIS_INFO"
  exit 1
fi

REDIS_HOST=$(echo "$REDIS_INFO" | grep "^host:" | awk '{print $2}')
REDIS_PORT=$(echo "$REDIS_INFO" | grep "^port:" | awk '{print $2}')

echo -e "${GREEN}✅ Informations Redis:${NC}"
echo "  Host: ${REDIS_HOST}"
echo "  Port: ${REDIS_PORT}"
echo ""

# Clé OTP dans Redis
OTP_KEY="otp:${PHONE_NUMBER}"

echo -e "${BLUE}🔍 Recherche de la clé OTP: ${OTP_KEY}${NC}"
echo ""

# Vérifier si redis-cli est disponible
if command -v redis-cli &> /dev/null; then
  echo -e "${BLUE}🔄 Tentative de connexion à Redis...${NC}"
  echo ""
  
  # Essayer de se connecter (nécessite d'être dans le VPC)
  REDIS_DATA=$(redis-cli -h "${REDIS_HOST}" -p "${REDIS_PORT}" HGETALL "${OTP_KEY}" 2>&1)
  
  if [ $? -eq 0 ] && [ ! -z "$REDIS_DATA" ]; then
    echo -e "${GREEN}✅ Données OTP trouvées dans Redis:${NC}"
    echo ""
    echo "$REDIS_DATA" | while read line; do
      if [ ! -z "$line" ]; then
        echo "  $line"
      fi
    done
  else
    echo -e "${YELLOW}⚠️  Impossible de se connecter à Redis directement${NC}"
    echo ""
    echo -e "${BLUE}💡 Solutions alternatives:${NC}"
    echo ""
    echo "1. Utiliser un tunnel VPN vers le VPC"
    echo "2. Utiliser Cloud Shell (dans le même projet)"
    echo "3. Vérifier les logs Cloud Run pour voir les opérations Redis"
    echo ""
    echo "Commande pour les logs:"
    echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND jsonPayload.message=~'OTP'\" --limit 20 --project=${GCP_PROJECT_ID}"
  fi
else
  echo -e "${YELLOW}⚠️  redis-cli n'est pas installé${NC}"
  echo ""
  echo -e "${BLUE}💡 Pour vérifier les OTP dans Redis:${NC}"
  echo ""
  echo "1. Installer redis-cli:"
  echo "   brew install redis  # macOS"
  echo "   ou"
  echo "   apt-get install redis-tools  # Linux"
  echo ""
  echo "2. Se connecter au VPC (tunnel VPN ou Cloud Shell)"
  echo ""
  echo "3. Utiliser redis-cli:"
  echo "   redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} HGETALL \"${OTP_KEY}\""
  echo ""
fi

echo ""
echo -e "${BLUE}📝 Vérification via les logs Cloud Run:${NC}"
echo ""
echo "Pour voir les opérations OTP dans les logs:"
echo "gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND (jsonPayload.message=~'OTP' OR jsonPayload.phoneNumber='${PHONE_NUMBER}')\" --limit 50 --project=${GCP_PROJECT_ID} --format=json"
echo ""

