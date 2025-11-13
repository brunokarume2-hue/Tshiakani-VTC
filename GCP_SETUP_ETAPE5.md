# 📊 Étape 5 : Monitoring et Observabilité

## 🎯 Objectif

Configurer le monitoring et l'observabilité pour l'application Tshiakani VTC sur GCP avec Cloud Logging et Cloud Monitoring.

---

## 📋 Prérequis

1. ✅ Étape 1 complétée (Projet GCP créé, APIs activées)
2. ✅ Étape 4 complétée (Backend déployé sur Cloud Run)
3. ✅ Cloud Run service déployé
4. ✅ gcloud CLI installé et configuré

---

## 🚨 1. Cloud Logging

### Configuration

Cloud Logging collecte automatiquement les logs de Cloud Run, mais nous configurons des logs structurés pour les erreurs critiques.

### Logs Structurés

Le backend envoie des logs structurés pour :
- **Erreurs de paiement** - Échecs de paiement Stripe
- **Erreurs de matching** - Échecs de matching de conducteurs
- **Requêtes HTTP** - Toutes les requêtes avec métadonnées
- **Performance** - Métriques de performance

### Configuration Automatique

```bash
# Configurer Cloud Logging
./scripts/gcp-setup-monitoring.sh
```

### Configuration Manuelle

```bash
# Activer l'API Cloud Logging
gcloud services enable logging.googleapis.com --project=tshiakani-vtc

# Accorder les permissions
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"
```

### Variables d'Environnement

```bash
# Cloud Logging
GCP_PROJECT_ID=tshiakani-vtc
CLOUD_LOGGING_LOG_NAME=tshiakani-vtc-backend
```

---

## 📈 2. Cloud Monitoring

### Métriques Critiques

#### Latence de l'API Cloud Run

- **Métrique**: `run.googleapis.com/request_latencies`
- **Alerte**: Latence > 2000ms pendant 5 minutes
- **Action**: Notification email/SMS

#### Utilisation Mémoire Cloud Run

- **Métrique**: `run.googleapis.com/container/memory/utilizations`
- **Alerte**: Utilisation > 80% pendant 5 minutes
- **Action**: Notification et scaling

#### Utilisation CPU Cloud Run

- **Métrique**: `run.googleapis.com/container/cpu/utilizations`
- **Alerte**: Utilisation > 80% pendant 5 minutes
- **Action**: Notification et scaling

#### Utilisation Mémoire Cloud SQL

- **Métrique**: `cloudsql.googleapis.com/database/memory/utilization`
- **Alerte**: Utilisation > 80% pendant 5 minutes
- **Action**: Notification

#### Utilisation CPU Cloud SQL

- **Métrique**: `cloudsql.googleapis.com/database/cpu/utilization`
- **Alerte**: Utilisation > 80% pendant 5 minutes
- **Action**: Notification

### Métriques Personnalisées

#### Erreurs de Paiement

- **Métrique**: `custom.googleapis.com/errors/count`
- **Label**: `error_type=payment_error`
- **Alerte**: > 10 erreurs en 5 minutes

#### Erreurs de Matching

- **Métrique**: `custom.googleapis.com/errors/count`
- **Label**: `error_type=matching_error`
- **Alerte**: > 10 erreurs en 5 minutes

#### Latence API Personnalisée

- **Métrique**: `custom.googleapis.com/api/latency`
- **Label**: `endpoint`, `status_code`
- **Alerte**: Latence > 2000ms

---

## 🔧 Configuration

### Option 1: Configuration Automatique (Recommandé)

```bash
# 1. Configurer le monitoring
./scripts/gcp-setup-monitoring.sh

# 2. Créer les alertes
./scripts/gcp-create-alerts.sh
```

### Option 2: Configuration Manuelle

#### Activer les APIs

```bash
# Activer Cloud Monitoring API
gcloud services enable monitoring.googleapis.com --project=tshiakani-vtc

# Activer Cloud Logging API
gcloud services enable logging.googleapis.com --project=tshiakani-vtc
```

#### Configurer les Permissions IAM

```bash
# Service account du service Cloud Run
SERVICE_ACCOUNT="tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com"

# Permissions Cloud Logging
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/logging.logWriter"

# Permissions Cloud Monitoring
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/monitoring.metricWriter"
```

---

## 🚨 3. Alertes

### Alertes Configurées

1. **Latence API élevée** - > 2000ms pendant 5 minutes
2. **Utilisation mémoire Cloud Run élevée** - > 80% pendant 5 minutes
3. **Utilisation CPU Cloud Run élevée** - > 80% pendant 5 minutes
4. **Utilisation mémoire Cloud SQL élevée** - > 80% pendant 5 minutes
5. **Utilisation CPU Cloud SQL élevée** - > 80% pendant 5 minutes
6. **Taux d'erreurs HTTP 5xx élevé** - > 5% pendant 5 minutes
7. **Taux d'erreurs de paiement élevé** - > 10 erreurs en 5 minutes
8. **Taux d'erreurs de matching élevé** - > 10 erreurs en 5 minutes

### Création des Alertes

```bash
# Créer toutes les alertes
./scripts/gcp-create-alerts.sh
```

### Configuration des Notifications

Les alertes peuvent être configurées pour envoyer des notifications via :
- **Email** - Notifications par email
- **SMS** - Notifications par SMS
- **Pub/Sub** - Intégration avec d'autres services
- **Webhook** - Intégration avec Slack, Discord, etc.

---

## 📊 4. Tableaux de Bord

### Tableau de Bord Principal

Créer un tableau de bord pour visualiser :
- **Latence de l'API** - Graphique de la latence au fil du temps
- **Taux d'erreurs** - Graphique des erreurs par type
- **Utilisation des ressources** - CPU, mémoire, réseau
- **Métriques de paiement** - Taux de succès, montants
- **Métriques de matching** - Taux de succès, nombre de conducteurs

### Création du Tableau de Bord

```bash
# Créer un tableau de bord (via console GCP)
# https://console.cloud.google.com/monitoring/dashboards
```

### Métriques à Afficher

1. **Latence API** - `run.googleapis.com/request_latencies`
2. **Taux d'erreurs** - `run.googleapis.com/request_count` (5xx)
3. **Utilisation mémoire** - `run.googleapis.com/container/memory/utilizations`
4. **Utilisation CPU** - `run.googleapis.com/container/cpu/utilizations`
5. **Erreurs de paiement** - `custom.googleapis.com/errors/count` (payment_error)
6. **Erreurs de matching** - `custom.googleapis.com/errors/count` (matching_error)

---

## 🔍 5. Consultation des Logs

### Voir les Logs en Temps Réel

```bash
# Logs en temps réel
gcloud logging tail "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend"

# Logs d'erreurs uniquement
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND severity>=ERROR" --limit 50

# Logs de paiement
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND jsonPayload.payment.rideId:*" --limit 50

# Logs de matching
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND jsonPayload.ride.rideId:*" --limit 50
```

### Filtres de Logs

```bash
# Erreurs de paiement
severity>=ERROR AND jsonPayload.payment.rideId:*

# Erreurs de matching
severity>=ERROR AND jsonPayload.ride.rideId:*

# Requêtes lentes (> 1 seconde)
jsonPayload.httpRequest.latency>"1s"

# Erreurs HTTP 5xx
jsonPayload.httpRequest.status>=500
```

---

## 📈 6. Consultation des Métriques

### Via Console GCP

```
https://console.cloud.google.com/monitoring
```

### Via gcloud CLI

```bash
# Voir les métriques de latence
gcloud monitoring time-series list \
  --filter='metric.type="run.googleapis.com/request_latencies"' \
  --project=tshiakani-vtc

# Voir les métriques d'erreurs
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/errors/count"' \
  --project=tshiakani-vtc
```

---

## 🔧 7. Intégration dans le Backend

### Service Cloud Logging

```javascript
// Dans backend/utils/cloud-logging.js
const { getCloudLoggingService } = require('./utils/cloud-logging');

// Enregistrer une erreur de paiement
await cloudLogging.logPaymentError({
  rideId: 123,
  amount: 1500,
  currency: 'CDF',
  method: 'stripe'
}, error);

// Enregistrer une erreur de matching
await cloudLogging.logMatchingError({
  rideId: 123,
  clientId: 456,
  pickupLocation: { latitude: -4.3276, longitude: 15.3136 },
  dropoffLocation: { latitude: -4.3286, longitude: 15.3146 }
}, error);
```

### Service Cloud Monitoring

```javascript
// Dans backend/utils/cloud-monitoring.js
const { getCloudMonitoringService } = require('./utils/cloud-monitoring');

// Enregistrer la latence de l'API
await cloudMonitoring.recordApiLatency('/api/rides/create', 150, 200);

// Enregistrer une erreur de paiement
await cloudMonitoring.recordPaymentEvent('failure', 1500, 'CDF');
await cloudMonitoring.recordError('payment_error', error.message);

// Enregistrer une erreur de matching
await cloudMonitoring.recordMatchingEvent('failure', 0, 0);
await cloudMonitoring.recordError('matching_error', error.message);
```

### Middleware de Monitoring

```javascript
// Dans backend/middlewares.postgres/monitoring.js
const { monitoringMiddleware } = require('./middlewares.postgres/monitoring');

// Ajouter le middleware
app.use(monitoringMiddleware);
```

---

## 📊 8. Métriques Personnalisées

### Types de Métriques

1. **API Latency** - `custom.googleapis.com/api/latency`
2. **API Requests** - `custom.googleapis.com/api/requests`
3. **Errors Count** - `custom.googleapis.com/errors/count`
4. **Payments Count** - `custom.googleapis.com/payments/count`
5. **Payments Amount** - `custom.googleapis.com/payments/amount`
6. **Matching Count** - `custom.googleapis.com/matching/count`
7. **Matching Driver Count** - `custom.googleapis.com/matching/driver_count`
8. **Matching Score** - `custom.googleapis.com/matching/score`
9. **Rides Count** - `custom.googleapis.com/rides/count`
10. **Rides Distance** - `custom.googleapis.com/rides/distance`
11. **Rides Price** - `custom.googleapis.com/rides/price`

### Labels

- **service** - Nom du service (tshiakani-vtc-backend)
- **environment** - Environnement (production, development)
- **endpoint** - Endpoint de l'API
- **status_code** - Code de statut HTTP
- **error_type** - Type d'erreur (payment_error, matching_error, etc.)
- **event_type** - Type d'événement (success, failure, etc.)

---

## 🚨 9. Dépannage

### Erreur: "Permission denied"

```bash
# Vérifier les permissions IAM
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com"
```

### Erreur: "API not enabled"

```bash
# Activer les APIs
gcloud services enable logging.googleapis.com --project=tshiakani-vtc
gcloud services enable monitoring.googleapis.com --project=tshiakani-vtc
```

### Erreur: "No metrics found"

```bash
# Vérifier que les métriques sont envoyées
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc
```

---

## 📚 Ressources Utiles

- **Documentation Cloud Logging**: https://cloud.google.com/logging/docs
- **Documentation Cloud Monitoring**: https://cloud.google.com/monitoring/docs
- **Guide des alertes**: https://cloud.google.com/monitoring/alerts
- **Guide des tableaux de bord**: https://cloud.google.com/monitoring/dashboards

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée :

1. **Tableaux de bord**: Créer des tableaux de bord personnalisés
2. **Notifications**: Configurer les notifications d'alertes
3. **Optimisation**: Analyser les métriques pour optimiser les performances
4. **Tests**: Tester les alertes et les notifications

---

## ✅ Checklist

- [ ] APIs Cloud Logging et Cloud Monitoring activées
- [ ] Permissions IAM configurées
- [ ] Service Cloud Logging intégré dans le backend
- [ ] Service Cloud Monitoring intégré dans le backend
- [ ] Middleware de monitoring configuré
- [ ] Alertes créées
- [ ] Tableaux de bord configurés
- [ ] Logs testés
- [ ] Métriques testées
- [ ] Alertes testées

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

