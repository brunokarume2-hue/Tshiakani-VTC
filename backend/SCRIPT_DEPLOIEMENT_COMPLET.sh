#!/bin/bash

# Script complet pour redéployer le backend sur Cloud Run
# Usage: ./SCRIPT_DEPLOIEMENT_COMPLET.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Redéploiement du backend sur Cloud Run...${NC}"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
SERVICE_NAME="tshiakani-driver-backend"
REGION="us-central1"
IMAGE_NAME="gcr.io/${PROJECT_ID}/tshiakani-vtc-api"

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé.${NC}"
    echo ""
    echo "Installez-le depuis: https://cloud.google.com/sdk/docs/install"
    echo ""
    echo "Ou utilisez Google Cloud Console pour déployer:"
    echo "1. Allez dans Cloud Build > Triggers"
    echo "2. Créez un nouveau trigger"
    echo "3. Utilisez le fichier cloudbuild.yaml"
    exit 1
fi

# Étape 1: Vérifier la configuration
echo -e "${BLUE}📋 Étape 1: Vérification de la configuration...${NC}"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "server.postgres.js" ]; then
    echo -e "${RED}❌ Erreur: server.postgres.js non trouvé${NC}"
    exit 1
fi

# Vérifier que la route auth existe
if [ ! -f "routes.postgres/auth.js" ]; then
    echo -e "${RED}❌ Erreur: routes.postgres/auth.js non trouvé${NC}"
    exit 1
fi

# Vérifier que la route est montée
if ! grep -q "app.use('/api/auth'" server.postgres.js; then
    echo -e "${RED}❌ Erreur: Route /api/auth non montée dans server.postgres.js${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuration vérifiée${NC}"
echo ""

# Étape 2: Vérifier l'authentification Google Cloud
echo -e "${BLUE}📋 Étape 2: Vérification de l'authentification...${NC}"
gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Vous n'êtes pas connecté à Google Cloud${NC}"
    echo -e "${BLUE}🔐 Connexion à Google Cloud...${NC}"
    gcloud auth login
fi

# Configurer le projet
echo -e "${BLUE}📋 Configuration du projet: ${PROJECT_ID}${NC}"
gcloud config set project ${PROJECT_ID}

echo -e "${GREEN}✅ Authentification vérifiée${NC}"
echo ""

# Étape 3: Builder l'image Docker
echo -e "${BLUE}📋 Étape 3: Build de l'image Docker...${NC}"
echo -e "${YELLOW}⏳ Cela peut prendre plusieurs minutes...${NC}"

gcloud builds submit --tag ${IMAGE_NAME} --timeout=1200s

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image Docker builder avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors du build de l'image Docker${NC}"
    exit 1
fi
echo ""

# Étape 4: Déployer sur Cloud Run
echo -e "${BLUE}📋 Étape 4: Déploiement sur Cloud Run...${NC}"

# Variables d'environnement
JWT_SECRET="ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"
ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"

gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production,PORT=8080,JWT_SECRET=${JWT_SECRET},ADMIN_API_KEY=${ADMIN_API_KEY},CORS_ORIGIN=${CORS_ORIGIN}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Déploiement réussi${NC}"
else
    echo -e "${RED}❌ Erreur lors du déploiement${NC}"
    exit 1
fi
echo ""

# Étape 5: Obtenir l'URL du service
echo -e "${BLUE}📋 Étape 5: Récupération de l'URL du service...${NC}"
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --format "value(status.url)")

echo -e "${GREEN}✅ URL du service: ${SERVICE_URL}${NC}"
echo ""

# Étape 6: Tester la route admin/login
echo -e "${BLUE}📋 Étape 6: Test de la route admin/login...${NC}"
echo -e "${YELLOW}⏳ Attente de 10 secondes pour que le service démarre...${NC}"
sleep 10

TEST_RESPONSE=$(curl -s -X POST ${SERVICE_URL}/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}' || echo "ERROR")

if [[ "$TEST_RESPONSE" == *"token"* ]]; then
    echo -e "${GREEN}✅ Route admin/login fonctionne!${NC}"
    echo -e "${GREEN}📄 Réponse:${NC}"
    echo "$TEST_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TEST_RESPONSE"
else
    echo -e "${YELLOW}⚠️  Route admin/login ne retourne pas de token${NC}"
    echo -e "${YELLOW}📄 Réponse:${NC}"
    echo "$TEST_RESPONSE"
    echo ""
    echo -e "${YELLOW}ℹ️  Vérifiez les logs:${NC}"
    echo "gcloud run services logs read ${SERVICE_NAME} --region ${REGION} --limit=50"
fi
echo ""

# Résumé
echo -e "${GREEN}✅ Déploiement terminé!${NC}"
echo ""
echo -e "${BLUE}📋 Résumé:${NC}"
echo "  - Service: ${SERVICE_NAME}"
echo "  - URL: ${SERVICE_URL}"
echo "  - Région: ${REGION}"
echo ""
echo -e "${BLUE}📝 Prochaines étapes:${NC}"
echo "  1. Vérifier les logs si nécessaire"
echo "  2. Tester la connexion depuis le dashboard"
echo "  3. Vérifier que toutes les routes fonctionnent"
echo ""

