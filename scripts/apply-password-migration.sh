#!/bin/bash

# Script pour appliquer la migration password et créer le compte admin
# Usage: ./scripts/apply-password-migration.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
INSTANCE_NAME="tshiakani-vtc-db"
DATABASE_NAME="TshiakaniVTC"
DB_USER="postgres"
REGION="us-central1"

echo -e "${BLUE}🔐 Application de la migration password et création du compte admin${NC}"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé${NC}"
    exit 1
fi

# Vérifier que le projet est configuré
echo -e "${BLUE}📋 Vérification du projet GCP...${NC}"
gcloud config set project ${PROJECT_ID} > /dev/null 2>&1
echo -e "${GREEN}✅ Projet configuré: ${PROJECT_ID}${NC}"

# Appliquer la migration SQL
echo ""
echo -e "${BLUE}📝 Application de la migration SQL (004_add_password_column.sql)...${NC}"

MIGRATION_FILE="backend/migrations/004_add_password_column.sql"

if [ ! -f "$MIGRATION_FILE" ]; then
    echo -e "${RED}❌ Fichier de migration non trouvé: ${MIGRATION_FILE}${NC}"
    exit 1
fi

# Méthode 1: Utiliser gcloud sql connect (interactif)
echo -e "${YELLOW}⚠️  Méthode interactive:${NC}"
echo "   Exécutez manuellement:"
echo "   gcloud sql connect ${INSTANCE_NAME} --user=${DB_USER} --database=${DATABASE_NAME} --project=${PROJECT_ID}"
echo "   Puis copiez-collez le contenu de ${MIGRATION_FILE}"
echo ""

# Méthode 2: Utiliser Docker pour exécuter psql
echo -e "${BLUE}🔄 Tentative avec Docker...${NC}"

# Obtenir l'IP publique de l'instance
INSTANCE_IP=$(gcloud sql instances describe ${INSTANCE_NAME} --project=${PROJECT_ID} --format="value(ipAddresses[0].ipAddress)" 2>/dev/null || echo "")

if [ -z "$INSTANCE_IP" ]; then
    echo -e "${YELLOW}⚠️  Impossible d'obtenir l'IP de l'instance${NC}"
    echo -e "${YELLOW}   Utilisez la méthode interactive ci-dessus${NC}"
else
    echo -e "${GREEN}✅ IP de l'instance: ${INSTANCE_IP}${NC}"
    
    # Demander le mot de passe
    read -sp "Entrez le mot de passe PostgreSQL: " DB_PASSWORD
    echo ""
    
    # Exécuter la migration avec Docker
    if docker run --rm -i \
        -e PGPASSWORD="${DB_PASSWORD}" \
        postgres:15 \
        psql -h "${INSTANCE_IP}" -U "${DB_USER}" -d "${DATABASE_NAME}" \
        < "${MIGRATION_FILE}" 2>/dev/null; then
        echo -e "${GREEN}✅ Migration SQL appliquée avec succès${NC}"
    else
        echo -e "${YELLOW}⚠️  Échec de la migration via Docker${NC}"
        echo -e "${YELLOW}   Utilisez la méthode interactive ci-dessus${NC}"
    fi
fi

# Créer le compte admin
echo ""
echo -e "${BLUE}👤 Création du compte admin...${NC}"

cd backend

if [ ! -f "scripts/create-admin.js" ]; then
    echo -e "${RED}❌ Script create-admin.js non trouvé${NC}"
    exit 1
fi

if node scripts/create-admin.js; then
    echo -e "${GREEN}✅ Compte admin créé/mis à jour avec succès${NC}"
else
    echo -e "${RED}❌ Erreur lors de la création du compte admin${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}✅ Migration et création du compte admin terminées !${NC}"
echo ""
echo -e "${BLUE}📝 Prochaines étapes :${NC}"
echo "  1. Redéployer le backend: ./scripts/gcp-deploy-backend.sh"
echo "  2. Redéployer le dashboard: ./deploy-dashboard.sh"
echo ""

