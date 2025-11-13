#!/bin/bash

# 🗄️ Script de Création d'Instance Cloud SQL
# Configuration PostgreSQL + PostGIS pour Tshiakani VTC

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

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

# Configuration par défaut
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
INSTANCE_NAME="${CLOUD_SQL_INSTANCE_NAME:-tshiakani-vtc-db}"
DATABASE_NAME="${CLOUD_SQL_DATABASE_NAME:-TshiakaniVTC}"
DB_USER="${CLOUD_SQL_USER:-postgres}"
REGION="${GCP_REGION:-us-central1}"
TIER="${DB_TIER:-db-f1-micro}"  # db-f1-micro pour dev, db-n1-standard-1 pour prod

log_info "Configuration:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $INSTANCE_NAME"
log_info "  Database Name: $DATABASE_NAME"
log_info "  DB User: $DB_USER"
log_info "  Region: $REGION"
log_info "  Tier: $TIER"

# Demander le mot de passe si non défini
if [ -z "$DB_PASSWORD" ]; then
    log_warning "DB_PASSWORD n'est pas défini."
    read -sp "Entrez le mot de passe pour l'utilisateur $DB_USER: " DB_PASSWORD
    echo ""
    if [ -z "$DB_PASSWORD" ]; then
        log_error "Le mot de passe est requis"
        exit 1
    fi
fi

# Vérifier que le projet existe
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_error "Le projet $PROJECT_ID n'existe pas"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Vérifier si l'instance existe déjà
log_info "Vérification de l'instance existante..."
if gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_warning "L'instance $INSTANCE_NAME existe déjà."
    read -p "Voulez-vous continuer avec cette instance? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Opération annulée."
        exit 1
    fi
    log_info "Utilisation de l'instance existante"
else
    # Créer l'instance Cloud SQL
    log_info "Création de l'instance Cloud SQL..."
    
    gcloud sql instances create "$INSTANCE_NAME" \
        --database-version=POSTGRES_14 \
        --tier="$TIER" \
        --region="$REGION" \
        --storage-type=SSD \
        --storage-size=20GB \
        --backup \
        --project="$PROJECT_ID" \
        --quiet
    
    if [ $? -eq 0 ]; then
        log_success "Instance Cloud SQL créée: $INSTANCE_NAME"
    else
        log_error "Échec de la création de l'instance"
        exit 1
    fi
fi

# Attendre que l'instance soit prête
log_info "Attente de la disponibilité de l'instance..."
while true; do
    INSTANCE_STATUS=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null)
    if [ "$INSTANCE_STATUS" = "RUNNABLE" ]; then
        log_success "Instance prête"
        break
    elif [ "$INSTANCE_STATUS" = "FAILED" ]; then
        log_error "L'instance a échoué"
        exit 1
    else
        log_info "État de l'instance: $INSTANCE_STATUS (attente...)"
        sleep 5
    fi
done

# Créer l'utilisateur de base de données
log_info "Création de l'utilisateur de base de données..."
if gcloud sql users describe "$DB_USER" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_warning "L'utilisateur $DB_USER existe déjà."
    read -p "Voulez-vous mettre à jour le mot de passe? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gcloud sql users set-password "$DB_USER" \
            --instance="$INSTANCE_NAME" \
            --password="$DB_PASSWORD" \
            --project="$PROJECT_ID" \
            --quiet
        log_success "Mot de passe mis à jour"
    fi
else
    gcloud sql users create "$DB_USER" \
        --instance="$INSTANCE_NAME" \
        --password="$DB_PASSWORD" \
        --project="$PROJECT_ID" \
        --quiet
    
    if [ $? -eq 0 ]; then
        log_success "Utilisateur créé: $DB_USER"
    else
        log_error "Échec de la création de l'utilisateur"
        exit 1
    fi
fi

# Créer la base de données
log_info "Création de la base de données..."
if gcloud sql databases describe "$DATABASE_NAME" --instance="$INSTANCE_NAME" --project="$PROJECT_ID" &> /dev/null; then
    log_warning "La base de données $DATABASE_NAME existe déjà."
else
    gcloud sql databases create "$DATABASE_NAME" \
        --instance="$INSTANCE_NAME" \
        --project="$PROJECT_ID" \
        --quiet
    
    if [ $? -eq 0 ]; then
        log_success "Base de données créée: $DATABASE_NAME"
    else
        log_error "Échec de la création de la base de données"
        exit 1
    fi
fi

# Obtenir le nom de connexion
CONNECTION_NAME=$(gcloud sql instances describe "$INSTANCE_NAME" --project="$PROJECT_ID" --format="value(connectionName)")

# Afficher les informations de connexion
echo ""
log_success "✅ Instance Cloud SQL configurée avec succès!"
echo ""
log_info "Informations de connexion:"
echo "  Instance Name: $INSTANCE_NAME"
echo "  Database Name: $DATABASE_NAME"
echo "  DB User: $DB_USER"
echo "  Connection Name: $CONNECTION_NAME"
echo "  Region: $REGION"
echo ""
log_info "Pour vous connecter:"
echo "  gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME"
echo ""
log_info "Variables d'environnement à sauvegarder:"
echo "  export CLOUD_SQL_INSTANCE_NAME=\"$INSTANCE_NAME\""
echo "  export CLOUD_SQL_DATABASE_NAME=\"$DATABASE_NAME\""
echo "  export CLOUD_SQL_USER=\"$DB_USER\""
echo "  export CLOUD_SQL_PASSWORD=\"$DB_PASSWORD\""
echo "  export CLOUD_SQL_CONNECTION_NAME=\"$CONNECTION_NAME\""
echo ""
log_info "Prochaines étapes:"
echo "  1. Activer PostGIS: ./scripts/gcp-init-database.sh"
echo "  2. Appliquer les migrations: ./scripts/gcp-apply-migrations.sh"
echo ""

