#!/bin/bash

# 🗄️ Script d'Initialisation de la Base de Données Cloud SQL
# Active PostGIS et applique les migrations

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuration par défaut
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
INSTANCE_NAME="${CLOUD_SQL_INSTANCE_NAME:-tshiakani-vtc-db}"
DATABASE_NAME="${CLOUD_SQL_DATABASE_NAME:-TshiakaniVTC}"
DB_USER="${CLOUD_SQL_USER:-postgres}"

log_info "Configuration:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $INSTANCE_NAME"
log_info "  Database Name: $DATABASE_NAME"
log_info "  DB User: $DB_USER"

# Vérifier que l'instance existe
if ! gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_error "L'instance $INSTANCE_NAME n'existe pas"
    log_info "Créez d'abord l'instance: ./scripts/gcp-create-cloud-sql.sh"
    exit 1
fi

# Vérifier que la base de données existe
if ! gcloud sql databases describe "$DATABASE_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_error "La base de données $DATABASE_NAME n'existe pas"
    log_info "Créez d'abord la base de données: ./scripts/gcp-create-cloud-sql.sh"
    exit 1
fi

# Obtenir le mot de passe
if [ -z "$DB_PASSWORD" ]; then
    log_warning "DB_PASSWORD n'est pas défini."
    read -sp "Entrez le mot de passe pour l'utilisateur $DB_USER: " DB_PASSWORD
    echo ""
    if [ -z "$DB_PASSWORD" ]; then
        log_error "Le mot de passe est requis"
        exit 1
    fi
fi

# Obtenir l'IP de l'instance
INSTANCE_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(ipAddresses[0].ipAddress)" 2>/dev/null)

if [ -z "$INSTANCE_IP" ]; then
    log_error "Impossible de récupérer l'IP de l'instance"
    exit 1
fi

log_info "IP de l'instance: $INSTANCE_IP"

# Vérifier que psql est installé
if ! command -v psql &> /dev/null; then
    log_error "psql n'est pas installé"
    log_info "Installation sur macOS: brew install postgresql"
    exit 1
fi

# Créer un fichier temporaire avec les commandes SQL
SQL_FILE=$(mktemp)
cat > "$SQL_FILE" << 'EOF'
-- Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Vérifier PostGIS
SELECT PostGIS_version();
EOF

log_info "Activation de PostGIS..."
export PGPASSWORD="$DB_PASSWORD"

if psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -f "$SQL_FILE" 2>&1; then
    log_success "PostGIS activé avec succès"
else
    log_error "Échec de l'activation de PostGIS"
    rm -f "$SQL_FILE"
    exit 1
fi

rm -f "$SQL_FILE"

# Vérifier PostGIS
log_info "Vérification de PostGIS..."
POSTGIS_VERSION=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT PostGIS_version();" 2>/dev/null | xargs)

if [ -n "$POSTGIS_VERSION" ]; then
    log_success "PostGIS version: $POSTGIS_VERSION"
else
    log_error "PostGIS n'est pas disponible"
    exit 1
fi

# Vérifier les extensions
log_info "Extensions installées:"
psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -c "\dx" 2>&1

echo ""
log_success "✅ Base de données initialisée avec succès!"
echo ""
log_info "Prochaines étapes:"
echo "  1. Appliquer les migrations: ./scripts/gcp-apply-migrations.sh"
echo ""

