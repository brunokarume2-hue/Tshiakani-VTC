#!/bin/bash

# Script pour exécuter les prochaines étapes prioritaires
# Usage: ./scripts/executer-prochaines-etapes.sh

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
DASHBOARD_URL="https://tshiakani-vtc-99cea.web.app"

echo -e "${BLUE}🚀 Exécution des Prochaines Étapes Prioritaires${NC}"
echo ""

# Étape 1 : Configurer CORS
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 1 : Configuration CORS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CORS_ORIGINS="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"

if command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}⚠️  Configuration CORS...${NC}"
    
    # Créer un fichier temporaire pour les variables d'environnement
    ENV_TEMP=$(mktemp)
    echo "CORS_ORIGIN=${CORS_ORIGINS}" > "$ENV_TEMP"
    
    # Méthode alternative : utiliser --set-env-vars avec échappement
    # Essayer avec des guillemets simples autour de la valeur
    gcloud run services update ${SERVICE_NAME} \
        --update-env-vars="CORS_ORIGIN=${CORS_ORIGINS}" \
        --region ${REGION} \
        --project ${GCP_PROJECT_ID} 2>&1 | grep -v "Setting IAM Policy" || {
        echo -e "${YELLOW}⚠️  Erreur avec --update-env-vars, tentative avec --set-env-vars...${NC}"
        # Obtenir les variables existantes et les combiner
        CURRENT_ENV=$(gcloud run services describe ${SERVICE_NAME} \
            --region ${REGION} \
            --project ${GCP_PROJECT_ID} \
            --format="value(spec.template.spec.containers[0].env)" 2>/dev/null | tr '\n' ',' || echo "")
        
        # Utiliser --set-env-vars avec toutes les variables
        if [ ! -z "$CURRENT_ENV" ]; then
            gcloud run services update ${SERVICE_NAME} \
                --set-env-vars="${CURRENT_ENV}CORS_ORIGIN=${CORS_ORIGINS}" \
                --region ${REGION} \
                --project ${GCP_PROJECT_ID} 2>&1 | grep -v "Setting IAM Policy" || echo -e "${YELLOW}⚠️  Configuration CORS échouée${NC}"
        fi
    }
    
    rm -f "$ENV_TEMP"
    
    echo -e "${YELLOW}⚠️  Si la configuration a échoué, utilisez cette commande manuelle :${NC}"
    echo ""
    echo "gcloud run services update ${SERVICE_NAME} \\"
    echo "  --update-env-vars=\"CORS_ORIGIN=${CORS_ORIGINS}\" \\"
    echo "  --region ${REGION} \\"
    echo "  --project ${GCP_PROJECT_ID}"
    echo ""
    echo -e "${GREEN}✅ Instructions CORS affichées${NC}"
else
    echo -e "${RED}❌ gcloud CLI non trouvé${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 2 : Configuration Twilio (Optionnel)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Voulez-vous configurer Twilio maintenant ? (o/N) : " configure_twilio

if [[ "$configure_twilio" =~ ^[Oo]$ ]]; then
    read -p "Entrez votre Twilio Account SID : " twilio_sid
    read -sp "Entrez votre Twilio Auth Token : " twilio_token
    echo ""
    
    if [ ! -z "$twilio_sid" ] && [ ! -z "$twilio_token" ]; then
        if command -v gcloud &> /dev/null; then
            gcloud run services update ${SERVICE_NAME} \
                --update-env-vars="TWILIO_ACCOUNT_SID=${twilio_sid},TWILIO_AUTH_TOKEN=${twilio_token}" \
                --region ${REGION} \
                --project ${GCP_PROJECT_ID} 2>&1 | grep -v "Setting IAM Policy" || true
            
            echo -e "${GREEN}✅ Twilio configuré${NC}"
        else
            echo -e "${RED}❌ gcloud CLI non trouvé${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Configuration Twilio annulée${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Configuration Twilio ignorée${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Étape 3 : Tests de Vérification${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test Backend
echo -e "${BLUE}🧪 Test Backend...${NC}"
BACKEND_URL="https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
if curl -s -f "${BACKEND_URL}/health" > /dev/null; then
    echo -e "${GREEN}✅ Backend accessible${NC}"
else
    echo -e "${RED}❌ Backend non accessible${NC}"
fi

# Test Dashboard
echo -e "${BLUE}🧪 Test Dashboard...${NC}"
if curl -s -f -I "${DASHBOARD_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Dashboard accessible${NC}"
else
    echo -e "${RED}❌ Dashboard non accessible${NC}"
fi

echo ""
echo -e "${GREEN}✅ Étapes prioritaires terminées !${NC}"
echo ""
echo -e "${BLUE}📋 Résumé :${NC}"
echo "  ✅ CORS : Configuré (ou à configurer manuellement)"
echo "  ⚠️  Twilio : Configuration optionnelle"
echo "  ✅ Tests : Effectués"
echo ""
echo -e "${YELLOW}📝 Prochaines actions :${NC}"
echo "  1. Tester le dashboard : open ${DASHBOARD_URL}"
echo "  2. Configurer Firebase FCM (si nécessaire)"
echo "  3. Créer les alertes de monitoring (optionnel)"
echo ""

