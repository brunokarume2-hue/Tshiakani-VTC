#!/bin/bash

# 🗄️ Script d'Application des Migrations Cloud SQL
# Applique les migrations SQL à la base de données

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
MIGRATIONS_DIR="${MIGRATIONS_DIR:-backend/migrations}"

log_info "Configuration:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $INSTANCE_NAME"
log_info "  Database Name: $DATABASE_NAME"
log_info "  DB User: $DB_USER"
log_info "  Migrations Dir: $MIGRATIONS_DIR"

# Vérifier que l'instance existe
if ! gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_error "L'instance $INSTANCE_NAME n'existe pas"
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

# Vérifier que le répertoire des migrations existe
if [ ! -d "$MIGRATIONS_DIR" ]; then
    log_error "Le répertoire des migrations n'existe pas: $MIGRATIONS_DIR"
    exit 1
fi

export PGPASSWORD="$DB_PASSWORD"

# Liste des migrations à appliquer (dans l'ordre)
MIGRATIONS=(
    "001_init_postgis_cloud_sql.sql"
    "002_create_price_configurations.sql"
    "003_optimize_indexes.sql"
)

# Appliquer les migrations
log_info "Application des migrations..."
for migration in "${MIGRATIONS[@]}"; do
    MIGRATION_FILE="$MIGRATIONS_DIR/$migration"
    
    if [ ! -f "$MIGRATION_FILE" ]; then
        log_warning "Migration non trouvée: $MIGRATION_FILE"
        continue
    fi
    
    log_info "Application de: $migration"
    
    if psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -f "$MIGRATION_FILE" 2>&1; then
        log_success "Migration appliquée: $migration"
    else
        log_error "Échec de l'application de la migration: $migration"
        exit 1
    fi
done

# Vérifier les tables créées
log_info "Vérification des tables..."
TABLES=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null | xargs)

if [ -n "$TABLES" ]; then
    log_success "Tables créées:"
    echo "$TABLES" | tr ' ' '\n' | while read table; do
        echo "  - $table"
    done
else
    log_warning "Aucune table trouvée"
fi

# Vérifier les index
log_info "Vérification des index..."
INDEX_COUNT=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';" 2>/dev/null | xargs)

if [ -n "$INDEX_COUNT" ]; then
    log_success "Nombre d'index: $INDEX_COUNT"
fi

echo ""
log_success "✅ Migrations appliquées avec succès!"
echo ""
log_info "Pour vérifier la base de données:"
echo "  gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME"
echo "  \\dt  -- Lister les tables"
echo "  \\di  -- Lister les index"
echo ""

