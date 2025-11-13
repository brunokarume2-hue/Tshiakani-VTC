#!/bin/bash

# 🔍 Script de Vérification de la Base de Données Cloud SQL

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

log_info "Vérification de la base de données Cloud SQL"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $INSTANCE_NAME"
log_info "  Database Name: $DATABASE_NAME"
echo ""

# 1. Vérifier que l'instance existe
log_info "1. Vérification de l'instance..."
if gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    INSTANCE_STATUS=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(state)")
    log_success "Instance existe: $INSTANCE_NAME (État: $INSTANCE_STATUS)"
else
    log_error "Instance n'existe pas: $INSTANCE_NAME"
    exit 1
fi

# 2. Vérifier que la base de données existe
log_info "2. Vérification de la base de données..."
if gcloud sql databases describe "$DATABASE_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_success "Base de données existe: $DATABASE_NAME"
else
    log_error "Base de données n'existe pas: $DATABASE_NAME"
    exit 1
fi

# 3. Vérifier que l'utilisateur existe
log_info "3. Vérification de l'utilisateur..."
if gcloud sql users describe "$DB_USER" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_success "Utilisateur existe: $DB_USER"
else
    log_error "Utilisateur n'existe pas: $DB_USER"
    exit 1
fi

# 4. Vérifier PostGIS (si psql est disponible)
if command -v psql &> /dev/null; then
    if [ -z "$DB_PASSWORD" ]; then
        read -sp "Entrez le mot de passe pour l'utilisateur $DB_USER: " DB_PASSWORD
        echo ""
    fi
    
    if [ -n "$DB_PASSWORD" ]; then
        INSTANCE_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(ipAddresses[0].ipAddress)" 2>/dev/null)
        
        if [ -n "$INSTANCE_IP" ]; then
            export PGPASSWORD="$DB_PASSWORD"
            
            # Vérifier PostGIS
            log_info "4. Vérification de PostGIS..."
            POSTGIS_VERSION=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT PostGIS_version();" 2>/dev/null | xargs)
            if [ -n "$POSTGIS_VERSION" ]; then
                log_success "PostGIS activé: $POSTGIS_VERSION"
            else
                log_error "PostGIS n'est pas activé"
            fi
            
            # Vérifier les tables
            log_info "5. Vérification des tables..."
            TABLES=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null | xargs)
            
            REQUIRED_TABLES=("users" "rides" "notifications" "sos_reports" "price_configurations")
            ALL_TABLES_EXIST=true
            
            for table in "${REQUIRED_TABLES[@]}"; do
                if echo "$TABLES" | grep -q "$table"; then
                    log_success "Table existe: $table"
                else
                    log_error "Table manquante: $table"
                    ALL_TABLES_EXIST=false
                fi
            done
            
            # Vérifier les index
            log_info "6. Vérification des index..."
            INDEX_COUNT=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public';" 2>/dev/null | xargs)
            if [ -n "$INDEX_COUNT" ]; then
                log_success "Nombre d'index: $INDEX_COUNT"
            else
                log_warning "Aucun index trouvé"
            fi
            
            # Vérifier les fonctions
            log_info "7. Vérification des fonctions..."
            FUNCTIONS=$(psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" -t -c "SELECT routine_name FROM information_schema.routines WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';" 2>/dev/null | xargs)
            
            if echo "$FUNCTIONS" | grep -q "calculate_distance"; then
                log_success "Fonction existe: calculate_distance"
            else
                log_warning "Fonction manquante: calculate_distance"
            fi
            
            if echo "$FUNCTIONS" | grep -q "find_nearby_drivers"; then
                log_success "Fonction existe: find_nearby_drivers"
            else
                log_warning "Fonction manquante: find_nearby_drivers"
            fi
            
            # Résumé
            echo ""
            if [ "$ALL_TABLES_EXIST" = true ] && [ -n "$POSTGIS_VERSION" ]; then
                log_success "✅ Base de données configurée correctement!"
            else
                log_warning "⚠️  Certaines vérifications ont échoué"
                exit 1
            fi
        else
            log_warning "Impossible de récupérer l'IP de l'instance"
        fi
    else
        log_warning "Mot de passe non fourni, certaines vérifications sont ignorées"
    fi
else
    log_warning "psql n'est pas installé, certaines vérifications sont ignorées"
fi

# Obtenir le nom de connexion
CONNECTION_NAME=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(connectionName)" 2>/dev/null)

echo ""
log_info "Informations de connexion:"
echo "  Connection Name: $CONNECTION_NAME"
echo "  Database: $DATABASE_NAME"
echo "  User: $DB_USER"
echo ""

