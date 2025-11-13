#!/bin/bash

# 🔍 Script de Vérification du Déploiement Cloud Run

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
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${CLOUD_RUN_SERVICE_NAME:-tshiakani-vtc-backend}"

log_info "Vérification du déploiement Cloud Run"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Service Name: $SERVICE_NAME"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# 1. Vérifier que le service existe
log_info "1. Vérification du service Cloud Run..."
if gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" &> /dev/null; then
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(status.url)")
    SERVICE_STATUS=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(status.conditions[0].status)")
    log_success "Service existe: $SERVICE_NAME"
    log_info "  URL: $SERVICE_URL"
    log_info "  Status: $SERVICE_STATUS"
else
    log_error "Service n'existe pas: $SERVICE_NAME"
    exit 1
fi

# 2. Vérifier les variables d'environnement
log_info "2. Vérification des variables d'environnement..."
ENV_VARS=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].env)")

REQUIRED_VARS=(
    "NODE_ENV"
    "PORT"
    "INSTANCE_CONNECTION_NAME"
    "DB_USER"
    "DB_PASSWORD"
    "DB_NAME"
    "JWT_SECRET"
    "ADMIN_API_KEY"
    "GOOGLE_MAPS_API_KEY"
    "CORS_ORIGIN"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if echo "$ENV_VARS" | grep -q "$var"; then
        log_success "Variable configurée: $var"
    else
        log_warning "Variable manquante: $var"
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    log_warning "Variables manquantes: ${MISSING_VARS[*]}"
    log_info "Utilisez: ./scripts/gcp-set-cloud-run-env.sh"
else
    log_success "Toutes les variables requises sont configurées"
fi

# 3. Vérifier la connexion Cloud SQL
log_info "3. Vérification de la connexion Cloud SQL..."
CLOUD_SQL_INSTANCES=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].env[?(@.name=='INSTANCE_CONNECTION_NAME')].value)")

if [ -n "$CLOUD_SQL_INSTANCES" ]; then
    log_success "Connexion Cloud SQL configurée: $CLOUD_SQL_INSTANCES"
    
    # Vérifier que la connexion est ajoutée
    CLOUD_SQL_CONNECTION=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].env[?(@.name=='INSTANCE_CONNECTION_NAME')].value)")
    if [ -n "$CLOUD_SQL_CONNECTION" ]; then
        log_success "Cloud SQL instance ajoutée au service"
    else
        log_warning "Cloud SQL instance non ajoutée au service"
        log_info "Utilisez: gcloud run services update $SERVICE_NAME --region $REGION --add-cloudsql-instances $CLOUD_SQL_INSTANCES"
    fi
else
    log_warning "Connexion Cloud SQL non configurée"
fi

# 4. Vérifier la connexion Redis
log_info "4. Vérification de la connexion Redis..."
REDIS_HOST=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].env[?(@.name=='REDIS_HOST')].value)")

if [ -n "$REDIS_HOST" ]; then
    log_success "Redis configuré: $REDIS_HOST"
    
    # Vérifier le VPC Connector
    VPC_CONNECTOR=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].env[?(@.name=='VPC_CONNECTOR')].value)")
    if [ -n "$VPC_CONNECTOR" ]; then
        log_success "VPC Connector configuré: $VPC_CONNECTOR"
    else
        log_warning "VPC Connector non configuré (nécessaire pour Redis)"
        log_info "Utilisez: gcloud run services update $SERVICE_NAME --region $REGION --vpc-connector redis-connector"
    fi
else
    log_warning "Redis non configuré (optionnel)"
fi

# 5. Vérifier les permissions IAM
log_info "5. Vérification des permissions IAM..."
SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.serviceAccountName)")

if [ -z "$SERVICE_ACCOUNT" ]; then
    SERVICE_ACCOUNT="${PROJECT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"
fi

log_info "Service Account: $SERVICE_ACCOUNT"

# Vérifier les permissions Cloud SQL
CLOUD_SQL_PERMISSION=$(gcloud projects get-iam-policy "$PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}" \
    --format "value(bindings.role)" | grep -q "roles/cloudsql.client" && echo "OK" || echo "MISSING")

if [ "$CLOUD_SQL_PERMISSION" = "OK" ]; then
    log_success "Permission Cloud SQL accordée"
else
    log_warning "Permission Cloud SQL manquante"
    log_info "Utilisez: gcloud projects add-iam-policy-binding $PROJECT_ID --member=\"serviceAccount:${SERVICE_ACCOUNT}\" --role=\"roles/cloudsql.client\""
fi

# Vérifier les permissions Redis
REDIS_PERMISSION=$(gcloud projects get-iam-policy "$PROJECT_ID" \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:${SERVICE_ACCOUNT}" \
    --format "value(bindings.role)" | grep -q "roles/redis.editor" && echo "OK" || echo "MISSING")

if [ "$REDIS_PERMISSION" = "OK" ]; then
    log_success "Permission Redis accordée"
else
    log_warning "Permission Redis manquante (optionnel)"
fi

# 6. Tester le health check
log_info "6. Test du health check..."
if [ -n "$SERVICE_URL" ]; then
    HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" || echo "000")
    
    if [ "$HEALTH_RESPONSE" = "200" ]; then
        log_success "Health check réussi (HTTP $HEALTH_RESPONSE)"
        
        # Afficher la réponse du health check
        HEALTH_BODY=$(curl -s "$SERVICE_URL/health")
        log_info "Réponse: $HEALTH_BODY"
    else
        log_error "Health check échoué (HTTP $HEALTH_RESPONSE)"
        log_info "URL: $SERVICE_URL/health"
    fi
else
    log_warning "URL du service non disponible"
fi

# 7. Vérifier les ressources
log_info "7. Vérification des ressources..."
MEMORY=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].resources.limits.memory)")
CPU=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.containers[0].resources.limits.cpu)")
TIMEOUT=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT_ID" --format "value(spec.template.spec.timeoutSeconds)")

log_info "  Memory: ${MEMORY:-Non défini}"
log_info "  CPU: ${CPU:-Non défini}"
log_info "  Timeout: ${TIMEOUT:-Non défini} secondes"

# Résumé
echo ""
log_info "Résumé de la vérification:"
echo "  Service: $SERVICE_NAME"
echo "  URL: $SERVICE_URL"
echo "  Status: $SERVICE_STATUS"
echo "  Variables manquantes: ${#MISSING_VARS[@]}"
echo "  Health check: $([ "$HEALTH_RESPONSE" = "200" ] && echo "OK" || echo "FAILED")"

if [ ${#MISSING_VARS[@]} -eq 0 ] && [ "$HEALTH_RESPONSE" = "200" ]; then
    echo ""
    log_success "✅ Déploiement Cloud Run vérifié avec succès!"
else
    echo ""
    log_warning "⚠️  Certaines vérifications ont échoué"
    exit 1
fi

echo ""

