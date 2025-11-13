#!/bin/bash

# Script pour créer un compte de test dans la base de données PostgreSQL
# Usage: ./create-test-account.sh

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Création du compte de test Tshiakani VTC${NC}"
echo ""

# Charger les variables d'environnement depuis .env si disponible
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Variables par défaut
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_NAME=${DB_NAME:-tshiakani_vtc}
DB_PASSWORD=${DB_PASSWORD:-}

# Demander le mot de passe si non défini
if [ -z "$DB_PASSWORD" ]; then
    echo -e "${YELLOW}⚠️  Mot de passe PostgreSQL non défini dans .env${NC}"
    echo -e "${YELLOW}   Entrez le mot de passe pour l'utilisateur '$DB_USER':${NC}"
    read -s DB_PASSWORD
    echo ""
fi

# Exporter le mot de passe pour psql
export PGPASSWORD=$DB_PASSWORD

echo -e "${BLUE}🔌 Connexion à la base de données...${NC}"
echo -e "   Host: $DB_HOST"
echo -e "   Port: $DB_PORT"
echo -e "   Database: $DB_NAME"
echo -e "   User: $DB_USER"
echo ""

# Exécuter la migration SQL
echo -e "${BLUE}📝 Exécution de la migration...${NC}"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f migrations/003_create_test_account.sql

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Compte de test créé avec succès !${NC}"
    echo ""
    echo -e "${GREEN}📋 Informations du compte de test:${NC}"
    echo -e "   📱 Numéro: ${BLUE}+243900000000${NC}"
    echo -e "   👤 Nom: ${BLUE}Compte Test${NC}"
    echo -e "   🎭 Rôle: ${BLUE}client${NC}"
    echo ""
    echo -e "${GREEN}🚀 Vous pouvez maintenant utiliser le bouton 'Connexion rapide' dans l'application${NC}"
else
    echo ""
    echo -e "${RED}❌ Erreur lors de la création du compte de test${NC}"
    echo -e "${YELLOW}   Vérifiez:${NC}"
    echo -e "   - Que PostgreSQL est démarré"
    echo -e "   - Que la base de données '$DB_NAME' existe"
    echo -e "   - Que les migrations initiales ont été exécutées"
    echo -e "   - Que le mot de passe est correct"
    exit 1
fi

# Nettoyer
unset PGPASSWORD

