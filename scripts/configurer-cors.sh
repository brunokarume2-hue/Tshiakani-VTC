#!/bin/bash

# Script pour configurer CORS dans Cloud Run
# Utilise un fichier YAML pour éviter les problèmes d'échappement

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

echo -e "${BLUE}🌐 Configuration CORS dans Cloud Run${NC}"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé${NC}"
    exit 1
fi

# Obtenir les variables d'environnement actuelles
echo -e "${BLUE}📋 Récupération des variables d'environnement actuelles...${NC}"
CURRENT_ENV=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --project ${GCP_PROJECT_ID} \
    --format="value(spec.template.spec.containers[0].env)" 2>/dev/null)

# Créer un fichier temporaire pour les variables d'environnement
ENV_FILE=$(mktemp)

# URLs autorisées pour CORS
CORS_ORIGINS="https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"

echo -e "${BLUE}📝 Création du fichier de configuration...${NC}"

# Écrire les variables d'environnement dans le fichier
cat > "$ENV_FILE" << EOF
CORS_ORIGIN=${CORS_ORIGINS}
EOF

# Méthode 1 : Utiliser --env-vars-file (si supporté)
echo -e "${YELLOW}⚠️  Tentative de configuration avec fichier...${NC}"

# Méthode 2 : Utiliser --set-env-vars avec chaque variable individuellement
echo -e "${YELLOW}⚠️  Configuration CORS...${NC}"

# Utiliser la méthode avec échappement correct
gcloud run services update ${SERVICE_NAME} \
    --update-env-vars CORS_ORIGIN="${CORS_ORIGINS}" \
    --region ${REGION} \
    --project ${GCP_PROJECT_ID} 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CORS configuré avec succès${NC}"
else
    echo -e "${YELLOW}⚠️  Erreur lors de la configuration automatique${NC}"
    echo ""
    echo -e "${BLUE}📝 Commande manuelle à exécuter :${NC}"
    echo ""
    echo "gcloud run services update ${SERVICE_NAME} \\"
    echo "  --update-env-vars CORS_ORIGIN=\"${CORS_ORIGINS}\" \\"
    echo "  --region ${REGION} \\"
    echo "  --project ${GCP_PROJECT_ID}"
    echo ""
fi

# Nettoyer
rm -f "$ENV_FILE"

echo ""
echo -e "${GREEN}✅ Script terminé${NC}"

