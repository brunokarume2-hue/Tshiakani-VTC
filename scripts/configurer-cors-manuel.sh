#!/bin/bash

# Script pour configurer CORS manuellement avec la bonne syntaxe
# Usage: ./scripts/configurer-cors-manuel.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="tshiakani-vtc-477711"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"

echo -e "${BLUE}🌐 Configuration CORS pour Cloud Run${NC}"
echo ""

# URLs autorisées pour CORS
CORS_ORIGINS="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Récupération des variables d'environnement actuelles...${NC}"

# Récupérer toutes les variables d'environnement actuelles
ENV_VARS=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --project ${GCP_PROJECT_ID} \
    --format="value(spec.template.spec.containers[0].env)" 2>/dev/null)

# Créer un fichier temporaire avec toutes les variables
ENV_FILE=$(mktemp)

# Écrire toutes les variables existantes (sauf CORS_ORIGIN si elle existe)
echo "$ENV_VARS" | while IFS= read -r line; do
    if [[ ! "$line" =~ ^CORS_ORIGIN= ]]; then
        echo "$line" >> "$ENV_FILE"
    fi
done

# Ajouter CORS_ORIGIN
echo "CORS_ORIGIN=${CORS_ORIGINS}" >> "$ENV_FILE"

echo -e "${YELLOW}⚠️  Configuration CORS...${NC}"

# Méthode : Utiliser --set-env-vars avec toutes les variables
# Construire la chaîne de variables
ENV_STRING=""
while IFS= read -r line; do
    if [ ! -z "$line" ]; then
        if [ -z "$ENV_STRING" ]; then
            ENV_STRING="$line"
        else
            ENV_STRING="${ENV_STRING},${line}"
        fi
    fi
done < "$ENV_FILE"

# Afficher la commande à exécuter
echo ""
echo -e "${BLUE}📝 Commande à exécuter :${NC}"
echo ""
echo "gcloud run services update ${SERVICE_NAME} \\"
echo "  --set-env-vars=\"${ENV_STRING}\" \\"
echo "  --region ${REGION} \\"
echo "  --project ${GCP_PROJECT_ID}"
echo ""

read -p "Voulez-vous exécuter cette commande maintenant ? (o/N) : " execute

if [[ "$execute" =~ ^[Oo]$ ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Exécution de la commande...${NC}"
    gcloud run services update ${SERVICE_NAME} \
        --set-env-vars="${ENV_STRING}" \
        --region ${REGION} \
        --project ${GCP_PROJECT_ID} 2>&1 | grep -v "Setting IAM Policy" || {
        echo -e "${RED}❌ Erreur lors de la configuration${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Essayez la méthode alternative :${NC}"
        echo ""
        echo "gcloud run services update ${SERVICE_NAME} \\"
        echo "  --update-env-vars=\"CORS_ORIGIN=${CORS_ORIGINS}\" \\"
        echo "  --region ${REGION} \\"
        echo "  --project ${GCP_PROJECT_ID}"
        exit 1
    }
    
    echo -e "${GREEN}✅ CORS configuré avec succès${NC}"
else
    echo -e "${YELLOW}⚠️  Commande non exécutée. Copiez et exécutez-la manuellement.${NC}"
fi

# Nettoyer
rm -f "$ENV_FILE"

echo ""

