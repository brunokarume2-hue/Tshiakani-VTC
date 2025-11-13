#!/bin/bash

# 🗄️ Script d'Initialisation de la Base de Données (Alternative sans psql)
# Utilise gcloud sql connect pour exécuter les migrations

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
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
INSTANCE_NAME="${CLOUD_SQL_INSTANCE_NAME:-tshiakani-vtc-db}"
DATABASE_NAME="${CLOUD_SQL_DATABASE_NAME:-TshiakaniVTC}"
DB_USER="${CLOUD_SQL_USER:-postgres}"

log_info "Initialisation de la base de données (méthode alternative)"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $INSTANCE_NAME"
log_info "  Database Name: $DATABASE_NAME"
log_info "  DB User: $DB_USER"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Vérifier que l'instance existe
if ! gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_error "L'instance $INSTANCE_NAME n'existe pas"
    exit 1
fi

# Vérifier que la base de données existe
if ! gcloud sql databases describe "$DATABASE_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_error "La base de données $DATABASE_NAME n'existe pas"
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

log_info "Exécution des migrations SQL..."

# Créer un fichier SQL temporaire avec les commandes
SQL_FILE=$(mktemp)
cat > "$SQL_FILE" << 'SQL_EOF'
-- Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Vérifier PostGIS
SELECT PostGIS_version();
SQL_EOF

# Exécuter via gcloud sql connect (méthode interactive)
log_info "Méthode 1 : Utilisation de gcloud sql connect"
log_warning "Cette méthode nécessite une connexion interactive"
log_info "Exécutez manuellement :"
echo ""
echo "gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME --project=$PROJECT_ID"
echo ""
echo "Puis exécutez les commandes SQL suivantes :"
echo ""
cat "$SQL_FILE"
echo ""

# Alternative : Utiliser un conteneur Docker PostgreSQL
log_info "Méthode 2 : Utilisation d'un conteneur Docker PostgreSQL"
if command -v docker &> /dev/null && docker ps > /dev/null 2>&1; then
    log_info "Docker est disponible, tentative d'exécution via conteneur..."
    
    # Obtenir l'IP publique de l'instance
    INSTANCE_IP=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(ipAddresses[0].ipAddress)" 2>/dev/null)
    
    if [ -n "$INSTANCE_IP" ]; then
        log_info "IP de l'instance: $INSTANCE_IP"
        log_info "Exécution des migrations via Docker..."
        
        # Exécuter les migrations via Docker
        docker run --rm -i postgres:14 psql -h "$INSTANCE_IP" -U "$DB_USER" -d "$DATABASE_NAME" < "$SQL_FILE" 2>&1 || {
            log_warning "Échec de l'exécution via Docker"
            log_info "Vérifiez que l'IP publique est autorisée dans les autorisations Cloud SQL"
        }
    else
        log_warning "Impossible de récupérer l'IP de l'instance"
    fi
else
    log_warning "Docker n'est pas disponible"
fi

# Nettoyer
rm -f "$SQL_FILE"

log_info "Méthode 3 : Utiliser Cloud SQL Proxy"
log_info "1. Télécharger Cloud SQL Proxy :"
echo "   curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.darwin.arm64"
echo "   chmod +x cloud-sql-proxy"
echo ""
log_info "2. Démarrer le proxy (dans un terminal séparé) :"
echo "   ./cloud-sql-proxy $PROJECT_ID:$REGION:$INSTANCE_NAME"
echo ""
log_info "3. Se connecter avec psql (dans un autre terminal) :"
echo "   psql -h 127.0.0.1 -U $DB_USER -d $DATABASE_NAME"
echo ""
log_info "4. Exécuter les migrations :"
echo "   \\i backend/migrations/001_init_postgis_cloud_sql.sql"

log_success "Instructions fournies pour l'initialisation de la base de données"

