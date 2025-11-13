# 📊 Guide d'Intégration du Monitoring

## 🎯 Vue d'Ensemble

Ce guide décrit comment le monitoring Cloud Logging et Cloud Monitoring est intégré dans le backend.

---

## 🔧 Services de Monitoring

### 1. Cloud Logging Service

**Fichier**: `backend/utils/cloud-logging.js`

**Fonctionnalités**:
- Envoi de logs structurés à Cloud Logging
- Support des erreurs de paiement et de matching
- Logs HTTP avec métadonnées
- Initialisation automatique en production sur GCP

**Utilisation**:

```javascript
const { getCloudLoggingService } = require('./utils/cloud-logging');
const cloudLogging = getCloudLoggingService();

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

### 2. Cloud Monitoring Service

**Fichier**: `backend/utils/cloud-monitoring.js`

**Fonctionnalités**:
- Envoi de métriques personnalisées à Cloud Monitoring
- Métriques de performance (latence, requêtes)
- Métriques de paiement et de matching
- Initialisation automatique en production sur GCP

**Utilisation**:

```javascript
const { getCloudMonitoringService } = require('./utils/cloud-monitoring');
const cloudMonitoring = getCloudMonitoringService();

// Enregistrer la latence de l'API
await cloudMonitoring.recordApiLatency('/api/rides/create', 150, 200);

// Enregistrer une erreur
await cloudMonitoring.recordError('payment_error', error.message);

// Enregistrer un événement de paiement
await cloudMonitoring.recordPaymentEvent('success', 1500, 'CDF');

// Enregistrer un événement de matching
await cloudMonitoring.recordMatchingEvent('success', 1, 85.5);
```

---

## 🛠️ Middleware de Monitoring

**Fichier**: `backend/middlewares.postgres/monitoring.js`

**Fonctionnalités**:
- Enregistrement automatique des métriques pour chaque requête HTTP
- Enregistrement de la latence, mémoire, statut HTTP
- Intégration avec Cloud Logging et Cloud Monitoring

**Utilisation**:

```javascript
// Dans server.postgres.js
const { monitoringMiddleware } = require('./middlewares.postgres/monitoring');
app.use(monitoringMiddleware);
```

---

## 🔄 Intégration dans les Services

### BackendAgentPrincipal

Le service `BackendAgentPrincipal` enregistre automatiquement :
- **Métriques de course** - Création, distance, prix
- **Métriques de matching** - Succès, échec, score
- **Erreurs** - Erreurs de paiement, matching, création

### PaymentService

Le service `PaymentService` enregistre automatiquement :
- **Métriques de paiement** - Succès, échec, remboursement
- **Erreurs de paiement** - Détails complets dans Cloud Logging

### DriverMatchingService

Le service `DriverMatchingService` enregistre automatiquement :
- **Métriques de matching** - Nombre de conducteurs, score
- **Erreurs de matching** - Détails complets dans Cloud Logging

---

## 🚨 Gestion des Erreurs

### ErrorHandler

Le `errorHandler` centralisé enregistre automatiquement toutes les erreurs :
- **Erreurs de paiement** - Détectées par mot-clé ou code d'erreur
- **Erreurs de matching** - Détectées par mot-clé ou code d'erreur
- **Autres erreurs** - Enregistrées avec détails complets

**Fichier**: `backend/utils/errors.js`

---

## 📊 Métriques Enregistrées

### Métriques API

- **Latence** - `custom.googleapis.com/api/latency`
- **Requêtes** - `custom.googleapis.com/api/requests`

### Métriques d'Erreurs

- **Nombre d'erreurs** - `custom.googleapis.com/errors/count`
  - Labels: `error_type`, `error_message`

### Métriques de Paiement

- **Nombre de paiements** - `custom.googleapis.com/payments/count`
- **Montant des paiements** - `custom.googleapis.com/payments/amount`
  - Labels: `event_type`, `currency`

### Métriques de Matching

- **Nombre de matchings** - `custom.googleapis.com/matching/count`
- **Nombre de conducteurs** - `custom.googleapis.com/matching/driver_count`
- **Score de matching** - `custom.googleapis.com/matching/score`
  - Labels: `event_type`

### Métriques de Courses

- **Nombre de courses** - `custom.googleapis.com/rides/count`
- **Distance des courses** - `custom.googleapis.com/rides/distance`
- **Prix des courses** - `custom.googleapis.com/rides/price`
  - Labels: `event_type`

---

## 🔍 Consultation des Métriques

### Via Console GCP

```
https://console.cloud.google.com/monitoring
```

### Via gcloud CLI

```bash
# Voir les métriques de latence
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc

# Voir les métriques d'erreurs
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/errors/count"' \
  --project=tshiakani-vtc
```

---

## 🚨 Alertes

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

---

## 📝 Configuration

### Variables d'Environnement

```bash
# Cloud Logging
GCP_PROJECT_ID=tshiakani-vtc
CLOUD_LOGGING_LOG_NAME=tshiakani-vtc-backend

# Cloud Monitoring (automatique si GCP_PROJECT_ID est défini)
GCP_REGION=us-central1
```

### Permissions IAM

Le service account Cloud Run doit avoir les permissions :
- `roles/logging.logWriter` - Pour Cloud Logging
- `roles/monitoring.metricWriter` - Pour Cloud Monitoring

---

## ✅ Checklist

- [x] Service Cloud Logging créé
- [x] Service Cloud Monitoring créé
- [x] Middleware de monitoring créé
- [x] Intégration dans les services
- [x] Gestion des erreurs intégrée
- [x] Scripts de configuration créés
- [x] Documentation créée
- [ ] APIs activées (à faire manuellement)
- [ ] Permissions IAM configurées (à faire manuellement)
- [ ] Alertes créées (à faire manuellement)
- [ ] Tableaux de bord configurés (à faire manuellement)

---

## 🚀 Utilisation

### Configuration

```bash
# 1. Configurer le monitoring
./scripts/gcp-setup-monitoring.sh

# 2. Créer les alertes
./scripts/gcp-create-alerts.sh
```

### Vérification

```bash
# Voir les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" --limit 10

# Voir les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc
```

---

## 📚 Documentation

- **Guide complet**: `GCP_SETUP_ETAPE5.md`
- **Guide tableau de bord**: `GCP_MONITORING_DASHBOARD.md`
- **Service Cloud Logging**: `backend/utils/cloud-logging.js`
- **Service Cloud Monitoring**: `backend/utils/cloud-monitoring.js`
- **Middleware de monitoring**: `backend/middlewares.postgres/monitoring.js`

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

