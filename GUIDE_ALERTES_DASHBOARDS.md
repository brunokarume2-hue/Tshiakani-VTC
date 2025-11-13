# 📊 Guide Rapide - Alertes et Tableaux de Bord

## 🚀 Création Rapide via Console GCP

### 📈 Créer les Alertes (5 minutes)

1. **Aller sur Cloud Monitoring - Alertes** :
   - https://console.cloud.google.com/monitoring/alerting?project=tshiakani-vtc-477711

2. **Créer une politique d'alerte** :
   - Cliquer sur "Créer une politique"
   - **Nom** : "Latence API élevée"
   - **Métrique** : `run.googleapis.com/request_latencies`
   - **Filtre** : `resource.service_name="tshiakani-vtc-backend"`
   - **Seuil** : > 2000ms
   - **Durée** : 5 minutes
   - **Notification** : Ajouter votre email

3. **Répéter pour les autres alertes** :
   - Taux d'erreur > 5%
   - Utilisation CPU > 80%
   - Utilisation mémoire > 80%

---

### 📊 Créer les Tableaux de Bord (10 minutes)

1. **Aller sur Cloud Monitoring - Tableaux de Bord** :
   - https://console.cloud.google.com/monitoring/dashboards?project=tshiakani-vtc-477711

2. **Créer un tableau de bord** :
   - Cliquer sur "Créer un tableau de bord"
   - **Nom** : "Tshiakani VTC - Vue d'Ensemble"

3. **Ajouter des widgets** :
   - **Widget 1** : Graphique de latence
     - Métrique : `run.googleapis.com/request_latencies`
     - Type : Line chart
   - **Widget 2** : Taux de requêtes
     - Métrique : `run.googleapis.com/request_count`
     - Type : Line chart
   - **Widget 3** : Taux d'erreur
     - Métrique : `run.googleapis.com/request_count` (filtrer sur status_code >= 400)
     - Type : Line chart
   - **Widget 4** : Utilisation CPU
     - Métrique : `run.googleapis.com/container/cpu/utilizations`
     - Type : Gauge

---

## ✅ Résumé

**Temps estimé** : 15 minutes pour créer les alertes et tableaux de bord de base.

**Avantages** :
- Interface graphique intuitive
- Prévisualisation en temps réel
- Configuration facile des seuils

---

**Date de création** : 2025-01-15  
**Statut** : Guide rapide pour finaliser le monitoring

