#!/bin/bash

# Script d'installation PostgreSQL pour Tshiakani VTC
# Usage: ./installer-postgresql.sh

set -e

echo "🐘 Installation de PostgreSQL pour Tshiakani VTC"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
DB_USER="admin"
DB_PASSWORD="Nyota9090_postgres"
DB_NAME="tshiakanivtc"

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour installer via Homebrew
install_via_homebrew() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🍺 Installation via Homebrew"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command_exists brew; then
        echo -e "${RED}❌ Homebrew n'est pas installé${NC}"
        echo "Installation de Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    echo "Installation de PostgreSQL 15..."
    brew install postgresql@15 postgis
    
    # Ajouter au PATH
    if [[ "$(uname -m)" == "arm64" ]]; then
        POSTGRES_PATH="/opt/homebrew/opt/postgresql@15/bin"
    else
        POSTGRES_PATH="/usr/local/opt/postgresql@15/bin"
    fi
    
    if [[ ":$PATH:" != *":$POSTGRES_PATH:"* ]]; then
        echo "export PATH=\"$POSTGRES_PATH:\$PATH\"" >> ~/.zshrc
        export PATH="$POSTGRES_PATH:$PATH"
        echo -e "${GREEN}✅ PostgreSQL ajouté au PATH${NC}"
    fi
    
    echo "Démarrage de PostgreSQL..."
    brew services start postgresql@15
    
    sleep 5
    
    if pg_isready &> /dev/null; then
        echo -e "${GREEN}✅ PostgreSQL démarré${NC}"
    else
        echo -e "${RED}❌ Erreur lors du démarrage de PostgreSQL${NC}"
        return 1
    fi
}

# Fonction pour installer via Docker
install_via_docker() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🐳 Installation via Docker"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command_exists docker; then
        echo -e "${RED}❌ Docker n'est pas installé${NC}"
        echo "Veuillez installer Docker Desktop depuis : https://www.docker.com/products/docker-desktop"
        return 1
    fi
    
    echo "Création du conteneur PostgreSQL avec PostGIS..."
    docker run --name tshiakani-postgres \
        -e POSTGRES_USER=$DB_USER \
        -e POSTGRES_PASSWORD=$DB_PASSWORD \
        -e POSTGRES_DB=$DB_NAME \
        -p 5432:5432 \
        -d postgis/postgis:15-3.4
    
    sleep 5
    
    if docker ps | grep -q tshiakani-postgres; then
        echo -e "${GREEN}✅ Conteneur PostgreSQL démarré${NC}"
    else
        echo -e "${RED}❌ Erreur lors du démarrage du conteneur${NC}"
        return 1
    fi
}

# Fonction pour créer la base de données
create_database() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗄️  Création de la base de données"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Attendre que PostgreSQL soit prêt
    echo "Attente que PostgreSQL soit prêt..."
    for i in {1..30}; do
        if pg_isready &> /dev/null; then
            break
        fi
        sleep 1
    done
    
    if ! pg_isready &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL n'est pas accessible${NC}"
        return 1
    fi
    
    # Créer l'utilisateur (si n'existe pas)
    echo "Création de l'utilisateur $DB_USER..."
    PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || \
    PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d postgres -c "SELECT 1;" &> /dev/null || true
    
    # Donner les permissions
    echo "Configuration des permissions..."
    PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -c "ALTER USER $DB_USER WITH SUPERUSER;" 2>/dev/null || true
    
    # Créer la base de données (si n'existe pas)
    echo "Création de la base de données $DB_NAME..."
    PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || \
    PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true
    
    # Activer PostGIS
    echo "Activation de PostGIS..."
    PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>/dev/null
    PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 2>/dev/null
    
    # Vérifier PostGIS
    echo "Vérification de PostGIS..."
    POSTGIS_VERSION=$(PGPASSWORD=$DB_PASSWORD psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME -t -c "SELECT PostGIS_version();" 2>/dev/null | xargs)
    
    if [ ! -z "$POSTGIS_VERSION" ]; then
        echo -e "${GREEN}✅ PostGIS installé : $POSTGIS_VERSION${NC}"
    else
        echo -e "${YELLOW}⚠️  PostGIS non vérifié${NC}"
    fi
}

# Menu principal
echo "Choisissez la méthode d'installation :"
echo "  1. Homebrew (Recommandé pour macOS)"
echo "  2. Docker (Alternative)"
echo "  3. Quitter"
echo ""
read -p "Votre choix (1-3) : " choice

case $choice in
    1)
        install_via_homebrew
        if [ $? -eq 0 ]; then
            create_database
        fi
        ;;
    2)
        install_via_docker
        if [ $? -eq 0 ]; then
            create_database
        fi
        ;;
    3)
        echo "Installation annulée"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Choix invalide${NC}"
        exit 1
        ;;
esac

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if pg_isready &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL est installé et démarré${NC}"
    echo -e "${GREEN}✅ Base de données $DB_NAME créée${NC}"
    echo -e "${GREEN}✅ Utilisateur $DB_USER créé${NC}"
    echo ""
    echo "Vous pouvez maintenant démarrer le backend :"
    echo "  ./demarrer-backend.sh"
else
    echo -e "${RED}❌ Erreur lors de l'installation${NC}"
    echo "Veuillez consulter les logs ci-dessus pour plus de détails"
fi

echo ""
