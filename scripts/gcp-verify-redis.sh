#!/bin/bash

# 🔍 Script de Vérification de Memorystore (Redis)

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
REDIS_INSTANCE_NAME="${REDIS_INSTANCE_NAME:-tshiakani-vtc-redis}"
REGION="${GCP_REGION:-us-central1}"

log_info "Vérification de l'instance Memorystore (Redis)"
log_info "  Project ID: $PROJECT_ID"
log_info "  Instance Name: $REDIS_INSTANCE_NAME"
log_info "  Region: $REGION"
echo ""

# 1. Vérifier que l'instance existe
log_info "1. Vérification de l'instance..."
if gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" &> /dev/null; then
    INSTANCE_STATE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(state)")
    log_success "Instance existe: $REDIS_INSTANCE_NAME (État: $INSTANCE_STATE)"
else
    log_error "Instance n'existe pas: $REDIS_INSTANCE_NAME"
    exit 1
fi

# 2. Vérifier l'état de l'instance
log_info "2. Vérification de l'état..."
INSTANCE_STATE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(state)")

if [ "$INSTANCE_STATE" = "READY" ]; then
    log_success "Instance prête: $INSTANCE_STATE"
else
    log_warning "Instance non prête: $INSTANCE_STATE"
fi

# 3. Récupérer les informations de connexion
log_info "3. Informations de connexion..."
REDIS_HOST=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(host)" 2>/dev/null)
REDIS_PORT=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(port)" 2>/dev/null)
MEMORY_SIZE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(memorySizeGb)" 2>/dev/null)
REDIS_VERSION=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(redisVersion)" 2>/dev/null)

if [ -n "$REDIS_HOST" ]; then
    log_success "Host: $REDIS_HOST"
    log_success "Port: ${REDIS_PORT:-6379}"
    log_success "Memory: ${MEMORY_SIZE} GB"
    log_success "Version: $REDIS_VERSION"
else
    log_error "Impossible de récupérer les informations de connexion"
    exit 1
fi

# 4. Tester la connexion (si redis-cli est disponible)
if command -v redis-cli &> /dev/null; then
    log_info "4. Test de connexion..."
    if [ -n "$REDIS_HOST" ]; then
        # Note: La connexion directe depuis une machine locale peut échouer
        # car Memorystore utilise un réseau privé (VPC)
        log_warning "redis-cli disponible mais connexion peut échouer (réseau privé VPC)"
        log_info "Pour tester, connectez-vous depuis une instance Cloud Run ou Compute Engine"
    fi
else
    log_warning "redis-cli n'est pas installé"
    log_info "Installation: brew install redis"
fi

# 5. Vérifier les métriques
log_info "5. Métriques de l'instance..."
MEMORY_USAGE=$(gcloud redis instances describe "$REDIS_INSTANCE_NAME" --region="$REGION" --project="$PROJECT_ID" --format="value(memorySizeGb)" 2>/dev/null)

if [ -n "$MEMORY_USAGE" ]; then
    log_success "Mémoire configurée: ${MEMORY_USAGE} GB"
else
    log_warning "Impossible de récupérer les métriques"
fi

# Résumé
echo ""
log_info "Résumé de la vérification:"
echo "  Instance: $REDIS_INSTANCE_NAME"
echo "  État: $INSTANCE_STATE"
echo "  Host: $REDIS_HOST"
echo "  Port: ${REDIS_PORT:-6379}"
echo "  Memory: ${MEMORY_SIZE} GB"
echo "  Version: $REDIS_VERSION"

if [ "$INSTANCE_STATE" = "READY" ] && [ -n "$REDIS_HOST" ]; then
    echo ""
    log_success "✅ Instance Memorystore (Redis) configurée correctement!"
    echo ""
    log_info "Variables d'environnement:"
    echo "  export REDIS_HOST=\"$REDIS_HOST\""
    echo "  export REDIS_PORT=\"${REDIS_PORT:-6379}\""
    echo "  export REDIS_PASSWORD=\"\"  # Vide pour Memorystore"
    echo ""
    log_warning "⚠️  Note: Memorystore utilise un réseau privé (VPC)"
    log_info "   Seules les ressources dans le même VPC peuvent se connecter"
    log_info "   Pour tester, déployez le backend sur Cloud Run (même VPC)"
else
    echo ""
    log_warning "⚠️  Certaines vérifications ont échoué"
    exit 1
fi

