#!/bin/bash

# 📊 Script de Création de Tableau de Bord Cloud Monitoring
# Crée un tableau de bord pour visualiser les métriques critiques

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
DASHBOARD_NAME="Tshiakani VTC - Monitoring"

log_info "Création du tableau de bord Cloud Monitoring"
log_info "  Project ID: $PROJECT_ID"
log_info "  Service Name: $SERVICE_NAME"
log_info "  Dashboard Name: $DASHBOARD_NAME"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Créer le fichier de configuration du tableau de bord
DASHBOARD_FILE="/tmp/dashboard-config.json"

cat > "$DASHBOARD_FILE" << EOF
{
  "displayName": "${DASHBOARD_NAME}",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "xPos": 0,
        "yPos": 0,
        "widget": {
          "title": "Latence API Cloud Run",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/request_latencies\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "ms",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 6,
        "yPos": 0,
        "widget": {
          "title": "Taux d'Erreurs HTTP",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/request_count\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_RATE",
                      "groupByFields": ["metric.label.response_code_class"]
                    }
                  }
                },
                "plotType": "STACKED_AREA"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "req/s",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 0,
        "yPos": 4,
        "widget": {
          "title": "Utilisation Mémoire Cloud Run",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/container/memory/utilizations\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "%",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 6,
        "yPos": 4,
        "widget": {
          "title": "Utilisation CPU Cloud Run",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "%",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 0,
        "yPos": 8,
        "widget": {
          "title": "Utilisation Mémoire Cloud SQL",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${PROJECT_ID}:${CLOUD_SQL_INSTANCE}\" AND metric.type = \"cloudsql.googleapis.com/database/memory/utilization\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "%",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 6,
        "yPos": 8,
        "widget": {
          "title": "Utilisation CPU Cloud SQL",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloudsql_database\" AND resource.labels.database_id = \"${PROJECT_ID}:${CLOUD_SQL_INSTANCE}\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "%",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 0,
        "yPos": 12,
        "widget": {
          "title": "Erreurs de Paiement",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"custom.googleapis.com/errors/count\" AND metric.labels.error_type = \"payment_error\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_RATE"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "erreurs/s",
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "xPos": 6,
        "yPos": 12,
        "widget": {
          "title": "Erreurs de Matching",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${SERVICE_NAME}\" AND metric.type = \"custom.googleapis.com/errors/count\" AND metric.labels.error_type = \"matching_error\"",
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "perSeriesAligner": "ALIGN_RATE"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "erreurs/s",
              "scale": "LINEAR"
            }
          }
        }
      }
    ]
  }
}
EOF

log_info "Fichier de configuration du tableau de bord créé: $DASHBOARD_FILE"
log_warning "Note: La création de tableau de bord via gcloud CLI nécessite l'API Monitoring"
log_info "Vous pouvez créer le tableau de bord manuellement via la console:"
log_info "  https://console.cloud.google.com/monitoring/dashboards"
echo ""
log_info "Ou utiliser l'API REST pour créer le tableau de bord:"
log_info "  gcloud monitoring dashboards create --config-from-file=$DASHBOARD_FILE"
echo ""

# Nettoyer
rm -f "$DASHBOARD_FILE"

log_success "✅ Configuration du tableau de bord créée!"
log_info "Pour créer le tableau de bord, utilisez la console GCP ou l'API REST"

