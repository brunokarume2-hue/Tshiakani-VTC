#!/bin/bash

# Script de vérification et démarrage des serveurs
# Usage: ./verifier-et-demarrer.sh

set -e

echo "🔍 Vérification de l'environnement"
echo "==================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifier PostgreSQL
echo -n "Vérification de PostgreSQL... "
if command -v psql &> /dev/null; then
    echo -e "${GREEN}✅ Installé${NC}"
    PSQL_VERSION=$(psql --version 2>/dev/null | head -1)
    echo "   Version: $PSQL_VERSION"
    
    # Vérifier si PostgreSQL est démarré
    if lsof -i:5432 > /dev/null 2>&1; then
        echo -e "   Statut: ${GREEN}✅ Démarré${NC}"
    else
        echo -e "   Statut: ${YELLOW}⚠️  Non démarré${NC}"
        echo "   Démarrage de PostgreSQL..."
        if command -v brew &> /dev/null; then
            brew services start postgresql@14 2>/dev/null || brew services start postgresql 2>/dev/null || echo "   ${YELLOW}Impossible de démarrer automatiquement${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Non installé${NC}"
    echo ""
    echo "Pour installer PostgreSQL :"
    echo "  ./installer-postgresql.sh"
    echo ""
    exit 1
fi

echo ""

# Vérifier Node.js
echo -n "Vérification de Node.js... "
if command -v node &> /dev/null; then
    echo -e "${GREEN}✅ Installé${NC}"
    NODE_VERSION=$(node --version)
    echo "   Version: $NODE_VERSION"
else
    echo -e "${RED}❌ Non installé${NC}"
    exit 1
fi

echo ""

# Vérifier les fichiers .env
echo "Vérification des fichiers de configuration..."
if [ -f "backend/.env" ]; then
    echo -e "   Backend: ${GREEN}✅ .env existe${NC}"
else
    echo -e "   Backend: ${YELLOW}⚠️  .env manquant${NC}"
fi

if [ -f "admin-dashboard/.env" ]; then
    echo -e "   Dashboard: ${GREEN}✅ .env existe${NC}"
else
    echo -e "   Dashboard: ${YELLOW}⚠️  .env manquant${NC}"
fi

echo ""

# Vérifier les dépendances
echo "Vérification des dépendances..."
if [ -d "backend/node_modules" ]; then
    echo -e "   Backend: ${GREEN}✅ Dépendances installées${NC}"
else
    echo -e "   Backend: ${YELLOW}⚠️  Dépendances manquantes${NC}"
    echo "   Installation des dépendances backend..."
    cd backend && npm install && cd ..
fi

if [ -d "admin-dashboard/node_modules" ]; then
    echo -e "   Dashboard: ${GREEN}✅ Dépendances installées${NC}"
else
    echo -e "   Dashboard: ${YELLOW}⚠️  Dépendances manquantes${NC}"
    echo "   Installation des dépendances dashboard..."
    cd admin-dashboard && npm install && cd ..
fi

echo ""

# Vérifier la base de données
echo "Vérification de la base de données..."
if command -v psql &> /dev/null; then
    DB_NAME=$(grep DB_NAME backend/.env 2>/dev/null | cut -d '=' -f2 | tr -d ' ' || echo "TshiakaniVTC")
    if psql -U postgres -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "   Base de données: ${GREEN}✅ Accessible${NC}"
        
        # Vérifier PostGIS
        if psql -U postgres -d "$DB_NAME" -c "SELECT PostGIS_version();" > /dev/null 2>&1; then
            echo -e "   PostGIS: ${GREEN}✅ Activé${NC}"
        else
            echo -e "   PostGIS: ${YELLOW}⚠️  Non activé${NC}"
            echo "   Activation de PostGIS..."
            psql -U postgres -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null || echo "   ${YELLOW}Impossible d'activer PostGIS automatiquement${NC}"
        fi
    else
        echo -e "   Base de données: ${YELLOW}⚠️  Non accessible ou n'existe pas${NC}"
        echo "   Exécutez: ./SCRIPT_SETUP_BDD.sh"
    fi
fi

echo ""
echo -e "${BLUE}🚀 Démarrage des serveurs...${NC}"
echo ""

# Démarrer les serveurs
./demarrer-serveurs.sh

