#!/bin/bash

# 🔴 Script de Création d'Instance Memorystore (Redis)
# Configuration Redis pour le suivi temps réel des conducteurs

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
REDIS_INSTANCE_NAME="${REDIS_INSTANCE_NAME:-tshiakani-vtc-redis}"
REGION="${GCP_REGION:-us-central1}"
MEMORY_SIZE_GB="${REDIS_MEMORY_SIZE_GB:-1}"  # 1 GB pour dev
TIER="${REDIS_TIER:-BASIC}"  # BASIC pour dev, STANDARD_HA pour prod
REDIS_VERSION="${REDIS_VERSION:-redis_7_0}"

log_info "Configuration:"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $REDIS_INSTANCE_NAME"
log_info "  Region: $REGION"
log_info "  Memory Size: $MEMORY_SIZE_GB GB"
log_info "  Tier: $TIER"
log_info "  Redis Version: $REDIS_VERSION"

# Vérifier que le projet existe
if ! gcloud projects describe "$PROJECT_ID" &> /dev/null; then
    log_error "Le projet $PROJECT_ID n'existe pas"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Vérifier si l'instance existe déjà
log_info "Vérification de l'instance existante..."
if gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" &> /dev/null; then
    log_warning "L'instance $REDIS_INSTANCE_NAME existe déjà."
    read -p "Voulez-vous continuer avec cette instance? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Opération annulée."
        exit 1
    fi
    log_info "Utilisation de l'instance existante"
else
    # Vérifier que Memorystore API est activée
    log_info "Vérification de Memorystore API..."
    if ! gcloud services list --enabled --project="$PROJECT_ID" --filter="name:redis.googleapis.com" --format="value(name)" | grep -q "redis.googleapis.com"; then
        log_info "Activation de Memorystore API..."
        gcloud services enable redis.googleapis.com --project="$PROJECT_ID"
        log_success "Memorystore API activée"
    fi

    # Créer l'instance Redis
    log_info "Création de l'instance Memorystore (Redis)..."
    log_warning "Cette opération peut prendre 5-10 minutes..."
    
    gcloud redis instances create "$REDIS_INSTANCE_NAME" \
        --size=$MEMORY_SIZE_GB \
        --region="$REGION" \
        --tier="$TIER" \
        --redis-version="$REDIS_VERSION" \
        --project="$PROJECT_ID" \
        --quiet
    
    if [ $? -eq 0 ]; then
        log_success "Instance Redis créée: $REDIS_INSTANCE_NAME"
    else
        log_error "Échec de la création de l'instance"
        exit 1
    fi
fi

# Attendre que l'instance soit prête
log_info "Attente de la disponibilité de l'instance..."
while true; do
    INSTANCE_STATE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(state)" 2>/dev/null)
    if [ "$INSTANCE_STATE" = "READY" ]; then
        log_success "Instance prête"
        break
    elif [ "$INSTANCE_STATE" = "CREATING" ] || [ "$INSTANCE_STATE" = "UPDATING" ]; then
        log_info "État de l'instance: $INSTANCE_STATE (attente...)"
        sleep 10
    else
        log_warning "État de l'instance: $INSTANCE_STATE"
        sleep 5
    fi
done

# Obtenir les informations de connexion
log_info "Récupération des informations de connexion..."
REDIS_HOST=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(host)" 2>/dev/null)
REDIS_PORT=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(port)" 2>/dev/null)

if [ -z "$REDIS_HOST" ]; then
    log_error "Impossible de récupérer l'adresse IP de l'instance"
    exit 1
fi

# Afficher les informations de connexion
echo ""
log_success "✅ Instance Memorystore (Redis) configurée avec succès!"
echo ""
log_info "Informations de connexion:"
echo "  Instance Name: $REDIS_INSTANCE_NAME"
echo "  Host: $REDIS_HOST"
echo "  Port: ${REDIS_PORT:-6379}"
echo "  Region: $REGION"
echo "  Memory Size: $MEMORY_SIZE_GB GB"
echo "  Tier: $TIER"
echo ""
log_info "Variables d'environnement à sauvegarder:"
echo "  export REDIS_INSTANCE_NAME=\"$REDIS_INSTANCE_NAME\""
echo "  export REDIS_HOST=\"$REDIS_HOST\""
echo "  export REDIS_PORT=\"${REDIS_PORT:-6379}\""
echo "  export REDIS_PASSWORD=\"\"  # Vide pour Memorystore"
echo ""
log_warning "⚠️  Note: Memorystore utilise un réseau privé (VPC)"
log_info "   Seules les ressources dans le même VPC peuvent se connecter"
echo ""
log_info "Prochaines étapes:"
echo "  1. Configurer le service Redis dans le backend"
echo "  2. Tester la connexion Redis"
echo "  3. Déployer le backend sur Cloud Run (même VPC)"
echo ""

