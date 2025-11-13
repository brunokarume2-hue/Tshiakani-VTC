#!/bin/bash

# Script pour préparer le déploiement du dashboard
# Usage: ./preparer-deploiement-dashboard.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Préparation du déploiement du dashboard...${NC}"
echo ""

# Variables
BACKEND_URL="https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
DASHBOARD_DIR="admin-dashboard"
ENV_PRODUCTION_FILE="${DASHBOARD_DIR}/.env.production"

# Vérifier que le backend est accessible
echo -e "${BLUE}🔍 Vérification du backend...${NC}"
if curl -s -f -o /dev/null "${BACKEND_URL}/health"; then
    echo -e "${GREEN}✅ Backend accessible sur ${BACKEND_URL}${NC}"
else
    echo -e "${RED}❌ Backend non accessible sur ${BACKEND_URL}${NC}"
    exit 1
fi

# Créer le fichier .env.production
echo -e "${BLUE}📝 Création du fichier .env.production...${NC}"

if [ -f "$ENV_PRODUCTION_FILE" ]; then
    echo -e "${YELLOW}⚠️  Le fichier .env.production existe déjà.${NC}"
    read -p "Voulez-vous le remplacer ? (o/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
        echo -e "${YELLOW}❌ Opération annulée.${NC}"
        exit 0
    fi
fi

# Demander la clé API Admin
echo -e "${YELLOW}🔑 Entrez la clé API Admin (ou appuyez sur Entrée pour laisser vide) :${NC}"
read -r ADMIN_API_KEY

# Créer le fichier .env.production
cat > "$ENV_PRODUCTION_FILE" << EOF
# Configuration pour la production
# Généré automatiquement le $(date)

# URL de l'API backend (Cloud Run)
VITE_API_URL=${BACKEND_URL}/api

# Clé API Admin (doit correspondre à ADMIN_API_KEY dans le backend)
VITE_ADMIN_API_KEY=${ADMIN_API_KEY:-votre_cle_api_admin}

# URL du serveur WebSocket (optionnel, pour les mises à jour en temps réel)
VITE_SOCKET_URL=${BACKEND_URL}
EOF

echo -e "${GREEN}✅ Fichier .env.production créé${NC}"
echo ""

# Afficher le contenu du fichier
echo -e "${BLUE}📄 Contenu du fichier .env.production :${NC}"
cat "$ENV_PRODUCTION_FILE"
echo ""

# Vérifier les dépendances
echo -e "${BLUE}📦 Vérification des dépendances...${NC}"
if [ ! -d "${DASHBOARD_DIR}/node_modules" ]; then
    echo -e "${YELLOW}⚠️  Les dépendances ne sont pas installées.${NC}"
    read -p "Voulez-vous les installer maintenant ? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        cd "$DASHBOARD_DIR"
        npm install
        cd ..
        echo -e "${GREEN}✅ Dépendances installées${NC}"
    fi
else
    echo -e "${GREEN}✅ Dépendances déjà installées${NC}"
fi

echo ""
echo -e "${GREEN}✅ Préparation terminée !${NC}"
echo ""
echo -e "${BLUE}📋 Prochaines étapes :${NC}"
echo "1. Vérifiez que la clé API Admin est correcte dans .env.production"
echo "2. Builder le dashboard : cd admin-dashboard && npm run build"
echo "3. Déployer sur Firebase : firebase deploy --only hosting"
echo ""
echo -e "${YELLOW}💡 Astuce :${NC}"
echo "   Assurez-vous que CORS est configuré dans le backend pour autoriser :"
echo "   - https://tshiakani-vtc.firebaseapp.com"
echo "   - https://tshiakani-vtc.web.app"

