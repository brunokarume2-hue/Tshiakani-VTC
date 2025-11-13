#!/bin/bash

# Script pour créer/renommer la base de données PostgreSQL
# Usage: ./SCRIPT_SETUP_BDD.sh

set -e

echo "🗄️  Configuration de la base de données PostgreSQL"
echo "=================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Vérifier si PostgreSQL est installé
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠️  PostgreSQL n'est pas installé${NC}"
    echo "Installez PostgreSQL avec: brew install postgresql@14"
    exit 1
fi

echo "Vérification de la connexion PostgreSQL..."
echo ""

# Demander les informations de connexion
read -p "Nom d'utilisateur PostgreSQL [postgres]: " DB_USER
DB_USER=${DB_USER:-postgres}

read -sp "Mot de passe PostgreSQL: " DB_PASSWORD
echo ""

read -p "Hôte PostgreSQL [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -p "Port PostgreSQL [5432]: " DB_PORT
DB_PORT=${DB_PORT:-5432}

echo ""
echo "Vérification de la connexion..."

# Tester la connexion
export PGPASSWORD="$DB_PASSWORD"
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connexion réussie${NC}"
else
    echo -e "${YELLOW}⚠️  Erreur de connexion. Vérifiez vos identifiants.${NC}"
    exit 1
fi

echo ""
echo "Vérification de l'existence de la base de données..."

# Vérifier si wewa_taxi existe
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='wewa_taxi';" | grep -q 1; then
    echo -e "${YELLOW}⚠️  La base de données 'wewa_taxi' existe${NC}"
    read -p "Voulez-vous la renommer en 'tshiakani_vtc'? (o/n): " RENAME
    if [[ "$RENAME" =~ ^[Oo]$ ]]; then
        echo "Renommage de la base de données..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "ALTER DATABASE wewa_taxi RENAME TO tshiakani_vtc;"
        echo -e "${GREEN}✅ Base de données renommée${NC}"
        DB_NAME="tshiakani_vtc"
    else
        read -p "Nom de la nouvelle base de données [tshiakani_vtc]: " DB_NAME
        DB_NAME=${DB_NAME:-tshiakani_vtc}
        echo "Création de la nouvelle base de données..."
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
        echo -e "${GREEN}✅ Base de données créée${NC}"
    fi
else
    echo "La base de données 'wewa_taxi' n'existe pas"
    read -p "Nom de la nouvelle base de données [tshiakani_vtc]: " DB_NAME
    DB_NAME=${DB_NAME:-tshiakani_vtc}
    echo "Création de la nouvelle base de données..."
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✅ Base de données créée${NC}"
fi

echo ""
echo "Activation de PostGIS..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
echo -e "${GREEN}✅ PostGIS activé${NC}"

echo ""
echo "Exécution des migrations..."
if [ -f "backend/migrations/001_init_postgis.sql" ]; then
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f backend/migrations/001_init_postgis.sql
    echo -e "${GREEN}✅ Migrations exécutées${NC}"
else
    echo -e "${YELLOW}⚠️  Fichier de migration non trouvé${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuration de la base de données terminée !${NC}"
echo ""
echo "📝 N'oubliez pas de mettre à jour votre fichier .env:"
echo "   DB_NAME=$DB_NAME"

