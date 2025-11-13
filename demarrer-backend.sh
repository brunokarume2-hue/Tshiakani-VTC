#!/bin/bash

# Script de démarrage du backend Tshiakani VTC
# Usage: ./demarrer-backend.sh

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "🚀 DÉMARRAGE DU BACKEND TSHIAKANI VTC"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
BACKEND_DIR="./backend"
ENV_FILE="${BACKEND_DIR}/.env"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Répertoire backend non trouvé${NC}"
    echo "Assurez-vous d'exécuter ce script depuis la racine du projet"
    exit 1
fi

# Vérifier que le fichier .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  Fichier .env non trouvé${NC}"
    echo "Création du fichier .env depuis ENV.example..."
    if [ -f "${BACKEND_DIR}/ENV.example" ]; then
        cp "${BACKEND_DIR}/ENV.example" "$ENV_FILE"
        echo -e "${YELLOW}⚠️  Veuillez configurer le fichier .env avant de continuer${NC}"
        echo "Fichier créé: ${ENV_FILE}"
        exit 1
    else
        echo -e "${RED}❌ Fichier ENV.example non trouvé${NC}"
        exit 1
    fi
fi

# Vérifier que node_modules existe
if [ ! -d "${BACKEND_DIR}/node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules non trouvé${NC}"
    echo "Installation des dépendances..."
    cd "$BACKEND_DIR"
    npm install
    cd ..
fi

# Vérifier si le port 3000 est déjà utilisé
if lsof -ti:3000 > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Le port 3000 est déjà utilisé${NC}"
    echo "Arrêt du processus existant..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Vérifier PostgreSQL (optionnel - le backend affichera une erreur si nécessaire)
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Vérification des prérequis...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Vérifier Node.js
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js installé: ${NODE_VERSION}${NC}"
else
    echo -e "${RED}❌ Node.js non installé${NC}"
    exit 1
fi

# Vérifier npm
if command -v npm > /dev/null 2>&1; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm installé: ${NPM_VERSION}${NC}"
else
    echo -e "${RED}❌ npm non installé${NC}"
    exit 1
fi

# Afficher les informations de configuration
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Configuration${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Lire le port depuis .env
PORT=$(grep "^PORT=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "3000")
echo -e "${BLUE}Port: ${PORT}${NC}"

# Lire la configuration de la base de données
DB_HOST=$(grep "^DB_HOST=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "localhost")
DB_PORT=$(grep "^DB_PORT=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "5432")
DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"' | tr -d "'" || echo "tshiakani_vtc")
echo -e "${BLUE}Base de données: ${DB_NAME}@${DB_HOST}:${DB_PORT}${NC}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Démarrage du serveur...${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Démarrer le serveur
cd "$BACKEND_DIR"

# Vérifier si nodemon est disponible
if command -v nodemon > /dev/null 2>&1 || [ -f "./node_modules/.bin/nodemon" ]; then
    echo -e "${GREEN}✅ Démarrage en mode développement (nodemon)${NC}"
    echo ""
    npm run dev
else
    echo -e "${YELLOW}⚠️  nodemon non trouvé, démarrage en mode production${NC}"
    echo ""
    npm start
fi
