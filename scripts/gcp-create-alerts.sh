#!/bin/bash

# 🚨 Script de Création d'Alertes Cloud Monitoring
# Crée les alertes pour les métriques critiques

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
CLOUD_SQL_INSTANCE="${CLOUD_SQL_INSTANCE_NAME:-tshiakani-vtc-db}"

log_info "Création des alertes Cloud Monitoring"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Service Name: $SERVICE_NAME"
log_info "  Cloud SQL Instance: $CLOUD_SQL_INSTANCE"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Fonction pour créer une alerte
create_alert() {
    local alert_name=$1
    local display_name=$2
    local metric_type=$3
    local threshold=$4
    local filter=$5

    log_info "Création de l'alerte: $display_name"

    # Vérifier si l'alerte existe déjà
    if gcloud alpha monitoring policies list --project="$PROJECT_ID" --filter="displayName:${display_name}" --format="value(name)" | grep -q "policies"; then
        log_warning "Alerte existe déjà: $display_name"
        return
    fi

    # Créer le fichier de politique d'alerte
    local policy_file="/tmp/alert-${alert_name}.yaml"
    cat > "$policy_file" << EOF
displayName: "${display_name}"
conditions:
  - displayName: "${display_name}"
    conditionThreshold:
      filter: "${filter}"
      comparison: COMPARISON_GT
      thresholdValue: ${threshold}
      duration: 300s
      aggregations:
        - alignmentPeriod: 60s
          perSeriesAligner: ALIGN_MEAN
combiner: OR
notificationChannels: []
EOF

    # Créer la politique d'alerte
    gcloud alpha monitoring policies create --project="$PROJECT_ID" --policy-from-file="$policy_file"

    if [ $? -eq 0 ]; then
        log_success "Alerte créée: $display_name"
    else
        log_error "Échec de la création de l'alerte: $display_name"
    fi

    # Nettoyer
    rm -f "$policy_file"
}

# 1. Alerte pour la latence de l'API Cloud Run
log_info "1. Création de l'alerte pour la latence de l'API..."
create_alert \
    "api-latency-high" \
    "Latence API élevée (> 2000ms)" \
    "run.googleapis.com/request_latencies" \
    2000 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/request_latencies\""

# 2. Alerte pour l'utilisation de la mémoire Cloud Run
log_info "2. Création de l'alerte pour l'utilisation de la mémoire..."
create_alert \
    "cloud-run-memory-high" \
    "Utilisation mémoire Cloud Run élevée (> 80%)" \
    "run.googleapis.com/container/memory/utilizations" \
    0.8 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/container/memory/utilizations\""

# 3. Alerte pour l'utilisation du CPU Cloud Run
log_info "3. Création de l'alerte pour l'utilisation du CPU..."
create_alert \
    "cloud-run-cpu-high" \
    "Utilisation CPU Cloud Run élevée (> 80%)" \
    "run.googleapis.com/container/cpu/utilizations" \
    0.8 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""

# 4. Alerte pour l'utilisation de la mémoire Cloud SQL
log_info "4. Création de l'alerte pour l'utilisation de la mémoire Cloud SQL..."
create_alert \
    "cloud-sql-memory-high" \
    "Utilisation mémoire Cloud SQL élevée (> 80%)" \
    "cloudsql.googleapis.com/database/memory/utilization" \
    0.8 \
    "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${PROJECT_ID}:${CLOUD_SQL_INSTANCE}\" AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\""

# 5. Alerte pour l'utilisation du CPU Cloud SQL
log_info "5. Création de l'alerte pour l'utilisation du CPU Cloud SQL..."
create_alert \
    "cloud-sql-cpu-high" \
    "Utilisation CPU Cloud SQL élevée (> 80%)" \
    "cloudsql.googleapis.com/database/cpu/utilization" \
    0.8 \
    "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${PROJECT_ID}:${CLOUD_SQL_INSTANCE}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""

# 6. Alerte pour les erreurs HTTP 5xx
log_info "6. Création de l'alerte pour les erreurs HTTP 5xx..."
create_alert \
    "http-5xx-errors" \
    "Taux d'erreurs HTTP 5xx élevé (> 5%)" \
    "run.googleapis.com/request_count" \
    0.05 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""

# 7. Alerte pour les erreurs de paiement (métrique personnalisée)
log_info "7. Création de l'alerte pour les erreurs de paiement..."
create_alert \
    "payment-errors" \
    "Taux d'erreurs de paiement élevé (> 10)" \
    "custom.googleapis.com/errors/count" \
    10 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"custom.googleapis.com/errors/count\" AND metric.labels.error_type = \"payment_error\""

# 8. Alerte pour les erreurs de matching (métrique personnalisée)
log_info "8. Création de l'alerte pour les erreurs de matching..."
create_alert \
    "matching-errors" \
    "Taux d'erreurs de matching élevé (> 10)" \
    "custom.googleapis.com/errors/count" \
    10 \
    "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"custom.googleapis.com/errors/count\" AND metric.labels.error_type = \"matching_error\""

# Résumé
echo ""
log_success "✅ Alertes créées avec succès!"
echo ""
log_info "Alertes configurées:"
echo "  1. Latence API élevée (> 2000ms)"
echo "  2. Utilisation mémoire Cloud Run élevée (> 80%)"
echo "  3. Utilisation CPU Cloud Run élevée (> 80%)"
echo "  4. Utilisation mémoire Cloud SQL élevée (> 80%)"
echo "  5. Utilisation CPU Cloud SQL élevée (> 80%)"
echo "  6. Taux d'erreurs HTTP 5xx élevé (> 5%)"
echo "  7. Taux d'erreurs de paiement élevé (> 10)"
echo "  8. Taux d'erreurs de matching élevé (> 10)"
echo ""
log_info "Voir les alertes: https://console.cloud.google.com/monitoring/alerting"
echo ""

