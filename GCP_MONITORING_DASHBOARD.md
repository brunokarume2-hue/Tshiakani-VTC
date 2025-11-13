# 📊 Guide de Création de Tableau de Bord Cloud Monitoring

## 🎯 Objectif

Créer un tableau de bord pour visualiser les métriques critiques de l'application Tshiakani VTC.

---

## 📋 Métriques à Afficher

### 1. Latence de l'API Cloud Run

- **Métrique**: `run.googleapis.com/request_latencies`
- **Type**: Ligne
- **Unité**: ms
- **Agrégation**: Moyenne sur 60 secondes

### 2. Taux d'Erreurs HTTP

- **Métrique**: `run.googleapis.com/request_count`
- **Type**: Stacked Area
- **Unité**: req/s
- **Groupement**: Par code de statut HTTP (2xx, 3xx, 4xx, 5xx)

### 3. Utilisation Mémoire Cloud Run

- **Métrique**: `run.googleapis.com/container/memory/utilizations`
- **Type**: Ligne
- **Unité**: %
- **Agrégation**: Moyenne sur 60 secondes

### 4. Utilisation CPU Cloud Run

- **Métrique**: `run.googleapis.com/container/cpu/utilizations`
- **Type**: Ligne
- **Unité**: %
- **Agrégation**: Moyenne sur 60 secondes

### 5. Utilisation Mémoire Cloud SQL

- **Métrique**: `cloudsql.googleapis.com/database/memory/utilization`
- **Type**: Ligne
- **Unité**: %
- **Agrégation**: Moyenne sur 60 secondes

### 6. Utilisation CPU Cloud SQL

- **Métrique**: `cloudsql.googleapis.com/database/cpu/utilization`
- **Type**: Ligne
- **Unité**: %
- **Agrégation**: Moyenne sur 60 secondes

### 7. Erreurs de Paiement

- **Métrique**: `custom.googleapis.com/errors/count`
- **Label**: `error_type=payment_error`
- **Type**: Ligne
- **Unité**: erreurs/s
- **Agrégation**: Taux sur 60 secondes

### 8. Erreurs de Matching

- **Métrique**: `custom.googleapis.com/errors/count`
- **Label**: `error_type=matching_error`
- **Type**: Ligne
- **Unité**: erreurs/s
- **Agrégation**: Taux sur 60 secondes

---

## 🚀 Création du Tableau de Bord

### Option 1: Via Console GCP (Recommandé)

1. **Accéder à Cloud Monitoring**
   ```
   https://console.cloud.google.com/monitoring/dashboards
   ```

2. **Créer un nouveau tableau de bord**
   - Cliquer sur "CREATE DASHBOARD"
   - Nommer le tableau de bord: "Tshiakani VTC - Monitoring"

3. **Ajouter les widgets**
   - Pour chaque métrique, cliquer sur "ADD CHART"
   - Sélectionner la métrique et configurer l'affichage

### Option 2: Via Script

```bash
# Le script génère la configuration JSON
./scripts/gcp-create-dashboard.sh

# Puis créer le tableau de bord via l'API REST
# (voir documentation GCP pour les détails)
```

---

## 📊 Configuration des Widgets

### Widget 1: Latence API

```json
{
  "title": "Latence API Cloud Run",
  "xyChart": {
    "dataSets": [{
      "timeSeriesQuery": {
        "timeSeriesFilter": {
          "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"tshiakani-vtc-backend\" AND metric.type = \"run.googleapis.com/request_latencies\"",
          "aggregation": {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_MEAN"
          }
        }
      },
      "plotType": "LINE"
    }],
    "yAxis": {
      "label": "ms",
      "scale": "LINEAR"
    }
  }
}
```

### Widget 2: Taux d'Erreurs HTTP

```json
{
  "title": "Taux d'Erreurs HTTP",
  "xyChart": {
    "dataSets": [{
      "timeSeriesQuery": {
        "timeSeriesFilter": {
          "filter": "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"tshiakani-vtc-backend\" AND metric.type = \"run.googleapis.com/request_count\"",
          "aggregation": {
            "alignmentPeriod": "60s",
            "perSeriesAligner": "ALIGN_RATE",
            "groupByFields": ["metric.label.response_code_class"]
          }
        }
      },
      "plotType": "STACKED_AREA"
    }],
    "yAxis": {
      "label": "req/s",
      "scale": "LINEAR"
    }
  }
}
```

---

## 🔍 Filtres de Métriques

### Cloud Run

```
resource.type = "cloud_run_revision"
AND resource.labels.service_name = "tshiakani-vtc-backend"
AND metric.type = "run.googleapis.com/request_latencies"
```

### Cloud SQL

```
resource.type = "cloudsql_database"
AND resource.labels.database_id = "tshiakani-vtc:us-central1:tshiakani-vtc-db"
AND metric.type = "cloudsql.googleapis.com/database/memory/utilization"
```

### Métriques Personnalisées

```
resource.type = "cloud_run_revision"
AND resource.labels.service_name = "tshiakani-vtc-backend"
AND metric.type = "custom.googleapis.com/errors/count"
AND metric.labels.error_type = "payment_error"
```

---

## 📈 Métriques Personnalisées Disponibles

### Erreurs

- `custom.googleapis.com/errors/count` - Nombre d'erreurs
  - Labels: `error_type`, `error_message`

### Paiements

- `custom.googleapis.com/payments/count` - Nombre de paiements
- `custom.googleapis.com/payments/amount` - Montant des paiements
  - Labels: `event_type`, `currency`

### Matching

- `custom.googleapis.com/matching/count` - Nombre de matchings
- `custom.googleapis.com/matching/driver_count` - Nombre de conducteurs
- `custom.googleapis.com/matching/score` - Score de matching
  - Labels: `event_type`

### Courses

- `custom.googleapis.com/rides/count` - Nombre de courses
- `custom.googleapis.com/rides/distance` - Distance des courses
- `custom.googleapis.com/rides/price` - Prix des courses
  - Labels: `event_type`

### API

- `custom.googleapis.com/api/latency` - Latence de l'API
- `custom.googleapis.com/api/requests` - Nombre de requêtes
  - Labels: `endpoint`, `status_code`

---

## 🚨 Alertes Associées

Les alertes suivantes sont associées au tableau de bord :

1. **Latence API élevée** - > 2000ms
2. **Utilisation mémoire Cloud Run élevée** - > 80%
3. **Utilisation CPU Cloud Run élevée** - > 80%
4. **Utilisation mémoire Cloud SQL élevée** - > 80%
5. **Utilisation CPU Cloud SQL élevée** - > 80%
6. **Taux d'erreurs HTTP 5xx élevé** - > 5%
7. **Taux d'erreurs de paiement élevé** - > 10 erreurs
8. **Taux d'erreurs de matching élevé** - > 10 erreurs

---

## 📚 Documentation

- **Console GCP**: https://console.cloud.google.com/monitoring/dashboards
- **Documentation**: https://cloud.google.com/monitoring/dashboards
- **API REST**: https://cloud.google.com/monitoring/api/ref_v3/rest/v1/projects.dashboards

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

