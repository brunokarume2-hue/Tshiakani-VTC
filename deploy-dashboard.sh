#!/bin/bash

# Script de déploiement du dashboard sur Firebase Hosting
# Usage: ./deploy-dashboard.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Déploiement du Dashboard sur Firebase Hosting...${NC}"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Erreur: firebase.json non trouvé${NC}"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Vérifier que Node.js 20 est utilisé
echo -e "${BLUE}📋 Vérification de Node.js...${NC}"
if command -v nvm &> /dev/null; then
    echo -e "${YELLOW}ℹ️  nvm détecté${NC}"
    NODE_VERSION=$(node --version 2>/dev/null || echo "none")
    if [[ ! "$NODE_VERSION" =~ ^v20\. ]]; then
        echo -e "${YELLOW}⚠️  Node.js 20 n'est pas actif. Tentative de basculement...${NC}"
        if nvm use 20 2>/dev/null; then
            echo -e "${GREEN}✅ Node.js 20 activé${NC}"
        else
            echo -e "${YELLOW}⚠️  Node.js 20 non trouvé. Installation...${NC}"
            nvm install 20
            nvm use 20
            echo -e "${GREEN}✅ Node.js 20 installé et activé${NC}"
        fi
    else
        echo -e "${GREEN}✅ Node.js 20 est actif${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  nvm non trouvé. Vérification de la version Node.js...${NC}"
    NODE_VERSION=$(node --version 2>/dev/null || echo "none")
    if [[ "$NODE_VERSION" =~ ^v(18|20|22)\. ]]; then
        echo -e "${GREEN}✅ Node.js $NODE_VERSION est compatible${NC}"
    else
        echo -e "${RED}❌ Node.js $NODE_VERSION n'est pas compatible avec Firebase CLI${NC}"
        echo -e "${YELLOW}ℹ️  Firebase CLI nécessite Node.js 18, 20 ou 22${NC}"
        echo -e "${YELLOW}ℹ️  Installez nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash${NC}"
        exit 1
    fi
fi

# Vérifier que Firebase CLI est installé
echo -e "${BLUE}📋 Vérification de Firebase CLI...${NC}"
if ! command -v firebase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Firebase CLI non trouvé. Installation...${NC}"
    npm install -g firebase-tools
    echo -e "${GREEN}✅ Firebase CLI installé${NC}"
else
    FIREBASE_VERSION=$(firebase --version)
    echo -e "${GREEN}✅ Firebase CLI installé (version $FIREBASE_VERSION)${NC}"
fi

# Vérifier que l'utilisateur est connecté
echo -e "${BLUE}📋 Vérification de la connexion Firebase...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vous n'êtes pas connecté à Firebase${NC}"
    echo -e "${BLUE}🔐 Connexion à Firebase...${NC}"
    firebase login
else
    echo -e "${GREEN}✅ Connecté à Firebase${NC}"
fi

# Vérifier que le projet est sélectionné
echo -e "${BLUE}📋 Vérification du projet Firebase...${NC}"
CURRENT_PROJECT=$(firebase use 2>/dev/null | grep "Using project" | awk '{print $3}' || echo "")
if [ -z "$CURRENT_PROJECT" ] || [ "$CURRENT_PROJECT" != "tshiakani-vtc-99cea" ]; then
    echo -e "${YELLOW}⚠️  Projet Firebase non sélectionné. Sélection de tshiakani-vtc-99cea...${NC}"
    firebase use tshiakani-vtc-99cea || {
        echo -e "${RED}❌ Erreur: Impossible de sélectionner le projet tshiakani-vtc-99cea${NC}"
        echo -e "${YELLOW}ℹ️  Liste des projets disponibles:${NC}"
        firebase projects:list
        exit 1
    }
    echo -e "${GREEN}✅ Projet tshiakani-vtc-99cea sélectionné${NC}"
else
    echo -e "${GREEN}✅ Projet $CURRENT_PROJECT sélectionné${NC}"
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

# Déployer
echo -e "${BLUE}🚀 Déploiement sur Firebase Hosting...${NC}"
firebase deploy --only hosting

echo ""
echo -e "${GREEN}✅ Déploiement terminé!${NC}"
echo ""
echo -e "${GREEN}🌐 URLs du dashboard:${NC}"
echo -e "   - https://tshiakani-vtc-99cea.web.app"
echo -e "   - https://tshiakani-vtc-99cea.firebaseapp.com"
echo ""
echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo "   1. Vérifier l'accessibilité: curl -I https://tshiakani-vtc-99cea.web.app"
echo "   2. Ouvrir dans le navigateur: open https://tshiakani-vtc-99cea.web.app"
echo "   3. Vérifier la connexion au backend dans la console (F12)"
echo "   4. Tester les fonctionnalités du dashboard"
