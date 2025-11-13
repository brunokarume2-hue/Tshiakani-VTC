#!/bin/bash

# Script de déploiement du dashboard avec npx (sans installation globale)
# Usage: ./deploy-dashboard-npx.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Déploiement du Dashboard sur Firebase Hosting (avec npx)...${NC}"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Erreur: firebase.json non trouvé${NC}"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Vérifier que le dossier dist existe
echo -e "${BLUE}📋 Vérification du build...${NC}"
if [ ! -d "admin-dashboard/dist" ]; then
    echo -e "${YELLOW}⚠️  Dossier dist non trouvé. Build du dashboard...${NC}"
    cd admin-dashboard
    npm install
    npm run build
    cd ..
    echo -e "${GREEN}✅ Dashboard builder${NC}"
else
    echo -e "${GREEN}✅ Dossier dist trouvé${NC}"
fi

# Vérifier que index.html existe
if [ ! -f "admin-dashboard/dist/index.html" ]; then
    echo -e "${RED}❌ Erreur: index.html non trouvé dans admin-dashboard/dist/${NC}"
    exit 1
fi

# Utiliser npx pour exécuter firebase-tools
echo -e "${BLUE}🔧 Utilisation de npx pour exécuter Firebase CLI...${NC}"
echo -e "${YELLOW}ℹ️  Note: La première exécution peut prendre du temps pour télécharger Firebase CLI${NC}"
echo ""

# Vérifier la connexion Firebase
echo -e "${BLUE}📋 Vérification de la connexion Firebase...${NC}"
if ! npx firebase-tools projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vous n'êtes pas connecté à Firebase${NC}"
    echo -e "${BLUE}🔐 Connexion à Firebase...${NC}"
    npx firebase-tools login
else
    echo -e "${GREEN}✅ Connecté à Firebase${NC}"
fi

# Vérifier que le projet est sélectionné
echo -e "${BLUE}📋 Vérification du projet Firebase...${NC}"
CURRENT_PROJECT=$(npx firebase-tools use 2>/dev/null | grep "Using project" | awk '{print $3}' || echo "")
if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" != "tshiakani-vtc" ]; then
    echo -e "${YELLOW}⚠️  Projet Firebase non sélectionné. Sélection de tshiakani-vtc...${NC}"
    npx firebase-tools use tshiakani-vtc || {
        echo -e "${RED}❌ Erreur: Impossible de sélectionner le projet tshiakani-vtc${NC}"
        echo -e "${YELLOW}ℹ️  Liste des projets disponibles:${NC}"
        npx firebase-tools projects:list
        exit 1
    }
    echo -e "${GREEN}✅ Projet tshiakani-vtc sélectionné${NC}"
else
    echo -e "${GREEN}✅ Projet $CURRENT_PROJECT sélectionné${NC}"
fi

# Déployer
echo -e "${BLUE}🚀 Déploiement sur Firebase Hosting...${NC}"
echo -e "${YELLOW}ℹ️  Cela peut prendre quelques minutes...${NC}"
npx firebase-tools deploy --only hosting

echo ""
echo -e "${GREEN}✅ Déploiement terminé!${NC}"
echo ""
echo -e "${GREEN}🌐 URLs du dashboard:${NC}"
echo -e "   - https://tshiakani-vtc.firebaseapp.com"
echo -e "   - https://tshiakani-vtc.web.app"
echo ""
echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo "   1. Vérifier l'accessibilité: curl -I https://tshiakani-vtc.firebaseapp.com"
echo "   2. Ouvrir dans le navigateur: open https://tshiakani-vtc.firebaseapp.com"
echo "   3. Vérifier la connexion au backend dans la console (F12)"
echo "   4. Tester les fonctionnalités du dashboard"

