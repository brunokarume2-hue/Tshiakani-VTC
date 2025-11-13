#!/bin/bash

# Script pour ouvrir la console GCP directement sur la page de configuration CORS
# Usage: ./scripts/ouvrir-console-cors.sh

# Couleurs
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="tshiakani-vtc-477711"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"

CONSOLE_URL="https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}?project=${GCP_PROJECT_ID}"

echo -e "${BLUE}🌐 Ouverture de la Console GCP pour Configuration CORS${NC}"
echo ""
echo -e "${GREEN}🔗 URL :${NC}"
echo "$CONSOLE_URL"
echo ""

# Ouvrir dans le navigateur
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "$CONSOLE_URL"
    echo -e "${GREEN}✅ Console GCP ouverte dans votre navigateur${NC}"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "$CONSOLE_URL" 2>/dev/null || echo "Ouvrez manuellement : $CONSOLE_URL"
else
    echo "Ouvrez manuellement : $CONSOLE_URL"
fi

echo ""
echo -e "${BLUE}📋 Instructions Rapides :${NC}"
echo "  1. Cliquez sur 'MODIFIER ET DÉPLOYER UNE NOUVELLE RÉVISION'"
echo "  2. Onglet 'Variables d'environnement'"
echo "  3. Ajoutez CORS_ORIGIN avec la valeur depuis VALEUR_CORS.txt"
echo "  4. Cliquez sur 'DÉPLOYER'"
echo ""
echo -e "${GREEN}📝 Valeur CORS_ORIGIN :${NC}"
cat "VALEUR_CORS.txt" 2>/dev/null || echo "https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"
echo ""

