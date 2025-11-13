# 📊 Configuration du Monitoring - Complétée

## ✅ Actions Effectuées

**Date** : 2025-01-15  
**Projet** : `tshiakani-vtc-477711`  
**Service** : `tshiakani-vtc-backend`

---

## ✅ Permissions IAM Configurées

- ✅ **Cloud Logging** : `roles/logging.logWriter`
- ✅ **Cloud Monitoring** : `roles/monitoring.metricWriter`
- ✅ **Service Account** : `418102154417-compute@developer.gserviceaccount.com`

---

## 📊 Alertes Cloud Monitoring

### Alertes Recommandées

Les alertes peuvent être créées via la console GCP ou via l'API. Voici les alertes recommandées :

#### 1. Latence API Élevée
- **Métrique** : Latence de réponse Cloud Run
- **Seuil** : > 2000ms pendant 5 minutes
- **Action** : Envoyer une notification

#### 2. Taux d'Erreur Élevé
- **Métrique** : Taux d'erreur HTTP
- **Seuil** : > 5% pendant 5 minutes
- **Action** : Envoyer une notification

#### 3. Utilisation CPU Élevée
- **Métrique** : Utilisation CPU Cloud Run
- **Seuil** : > 80% pendant 10 minutes
- **Action** : Envoyer une notification

#### 4. Utilisation Mémoire Élevée
- **Métrique** : Utilisation mémoire Cloud Run
- **Seuil** : > 80% pendant 10 minutes
- **Action** : Envoyer une notification

#### 5. Erreurs de Base de Données
- **Métrique** : Erreurs de connexion Cloud SQL
- **Seuil** : > 0 erreurs
- **Action** : Envoyer une notification immédiate

#### 6. Erreurs Redis
- **Métrique** : Erreurs de connexion Memorystore
- **Seuil** : > 0 erreurs
- **Action** : Envoyer une notification immédiate

---

## 📈 Tableaux de Bord Cloud Monitoring

### Tableaux de Bord Recommandés

#### 1. Vue d'Ensemble du Service
- Latence API (moyenne, p50, p95, p99)
- Taux de requêtes par seconde
- Taux d'erreur
- Utilisation CPU et mémoire

#### 2. Métriques API
- Requêtes par endpoint
- Latence par endpoint
- Erreurs par type
- Codes de statut HTTP

#### 3. Métriques de Base de Données
- Connexions actives
- Requêtes par seconde
- Temps de réponse des requêtes
- Utilisation CPU et mémoire Cloud SQL

#### 4. Métriques Redis
- Connexions actives
- Opérations par seconde
- Utilisation mémoire
- Taux de hit/miss

#### 5. Métriques Métier
- Nombre de courses créées
- Nombre de courses complétées
- Taux de matching
- Revenus générés

---

## 🔧 Création des Alertes via Console GCP

### Étapes

1. **Aller sur Cloud Monitoring** :
   - https://console.cloud.google.com/monitoring/alerting?project=tshiakani-vtc-477711

2. **Créer une politique d'alerte** :
   - Cliquer sur "Créer une politique"
   - Sélectionner la métrique
   - Configurer le seuil
   - Ajouter des canaux de notification (email, SMS, etc.)

3. **Configurer les canaux de notification** :
   - Aller dans "Canaux de notification"
   - Ajouter votre email
   - Configurer les préférences

---

## 📊 Création des Tableaux de Bord via Console GCP

### Étapes

1. **Aller sur Cloud Monitoring Dashboards** :
   - https://console.cloud.google.com/monitoring/dashboards?project=tshiakani-vtc-477711

2. **Créer un tableau de bord** :
   - Cliquer sur "Créer un tableau de bord"
   - Ajouter des widgets (graphiques, métriques, etc.)
   - Configurer les métriques à afficher

3. **Exemples de widgets** :
   - Graphique de latence
   - Graphique de taux de requêtes
   - Graphique d'utilisation CPU/mémoire
   - Tableau des erreurs

---

## 🧪 Vérification du Monitoring

### Vérifier les Logs

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
export GCP_PROJECT_ID=tshiakani-vtc-477711

# Voir les logs récents
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=50 \
  --project=tshiakani-vtc-477711 \
  --format=json
```

### Vérifier les Métriques

```bash
# Voir les métriques Cloud Run
gcloud monitoring time-series list \
  --filter='metric.type="run.googleapis.com/request_count"' \
  --project=tshiakani-vtc-477711
```

---

## 📝 Commandes Utiles

### Créer une Notification Channel (Email)

```bash
gcloud alpha monitoring channels create \
  --display-name="Email Alerts" \
  --type=email \
  --channel-labels=email_address=your-email@example.com \
  --project=tshiakani-vtc-477711
```

### Lister les Alertes

```bash
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc-477711
```

### Lister les Tableaux de Bord

```bash
gcloud monitoring dashboards list \
  --project=tshiakani-vtc-477711
```

---

## 🔗 Liens Utiles

- **Console Monitoring** : https://console.cloud.google.com/monitoring?project=tshiakani-vtc-477711
- **Alertes** : https://console.cloud.google.com/monitoring/alerting?project=tshiakani-vtc-477711
- **Tableaux de Bord** : https://console.cloud.google.com/monitoring/dashboards?project=tshiakani-vtc-477711
- **Logs** : https://console.cloud.google.com/logs?project=tshiakani-vtc-477711

---

## ✅ Checklist

- [x] Permissions IAM configurées
- [x] Cloud Logging activé
- [x] Cloud Monitoring activé
- [ ] Alertes créées (à faire via console GCP)
- [ ] Tableaux de bord créés (à faire via console GCP)
- [ ] Canaux de notification configurés

---

## 🎯 Prochaines Étapes

1. **Créer les alertes** via la console GCP (plus simple que via CLI)
2. **Créer les tableaux de bord** via la console GCP
3. **Configurer les canaux de notification** (email, SMS, etc.)
4. **Tester les alertes** en générant des conditions d'alerte

---

**Date de configuration** : 2025-01-15  
**Statut** : ✅ Permissions configurées, alertes et dashboards à créer via console GCP

