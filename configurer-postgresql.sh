#!/bin/bash

# Script pour configurer PostgreSQL après installation
# Usage: ./configurer-postgresql.sh

set -e

echo "🔧 Configuration de PostgreSQL"
echo "=============================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Vérifier si psql est accessible
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  psql non trouvé dans le PATH${NC}"
    echo ""
    echo "Ajout de Postgres.app au PATH..."
    
    # Ajouter Postgres.app au PATH
    if [ -d "/Applications/Postgres.app" ]; then
        export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
        echo 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
        echo -e "${GREEN}✅ Postgres.app ajouté au PATH${NC}"
        echo "Redémarrez votre terminal ou exécutez: source ~/.zshrc"
    else
        echo -e "${RED}❌ Postgres.app non trouvé dans /Applications${NC}"
        echo "Veuillez installer Postgres.app depuis : https://postgresapp.com/"
        exit 1
    fi
fi

# Vérifier la connexion
echo ""
echo "Test de connexion à PostgreSQL..."
if psql -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connexion réussie${NC}"
    DB_USER=$(whoami)
elif psql -U postgres -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connexion réussie (utilisateur postgres)${NC}"
    DB_USER="postgres"
else
    echo -e "${YELLOW}⚠️  Impossible de se connecter automatiquement${NC}"
    echo "Veuillez vous assurer que PostgreSQL est démarré"
    echo ""
    read -p "Nom d'utilisateur PostgreSQL [$(whoami)]: " DB_USER
    DB_USER=${DB_USER:-$(whoami)}
    
    read -sp "Mot de passe PostgreSQL (si nécessaire): " DB_PASSWORD
    echo ""
    export PGPASSWORD="$DB_PASSWORD"
fi

echo ""
echo "Vérification de la base de données..."

# Vérifier si la base existe
DB_NAME="TshiakaniVTC"
if psql -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME';" | grep -q 1; then
    echo -e "${GREEN}✅ La base de données '$DB_NAME' existe déjà${NC}"
else
    echo "Création de la base de données '$DB_NAME'..."
    if psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;" 2>/dev/null; then
        echo -e "${GREEN}✅ Base de données créée${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la création${NC}"
        exit 1
    fi
fi

echo ""
echo "Configuration de PostGIS..."

# Activer PostGIS
if psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null; then
    echo -e "${GREEN}✅ PostGIS activé${NC}"
else
    echo -e "${YELLOW}⚠️  PostGIS non disponible${NC}"
    echo "PostGIS doit être installé séparément"
    echo "Pour Postgres.app : PostGIS est généralement inclus"
fi

# Activer uuid-ossp
if psql -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";" 2>/dev/null; then
    echo -e "${GREEN}✅ Extension uuid-ossp activée${NC}"
fi

echo ""
echo "Vérification finale..."

# Vérifier PostGIS
if psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT PostGIS_version();" > /dev/null 2>&1; then
    POSTGIS_VERSION=$(psql -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT PostGIS_version();")
    echo -e "${GREEN}✅ PostGIS version: $POSTGIS_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  PostGIS non disponible${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuration terminée !${NC}"
echo ""
echo "📝 Mettez à jour backend/.env avec :"
echo "   DB_USER=$DB_USER"
echo "   DB_NAME=$DB_NAME"
echo "   DB_PASSWORD=(si vous avez configuré un mot de passe)"
echo ""
echo "🚀 Vous pouvez maintenant démarrer les serveurs :"
echo "   ./demarrer-serveurs.sh"

