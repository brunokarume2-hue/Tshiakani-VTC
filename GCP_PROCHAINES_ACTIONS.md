# 🚀 Prochaines Actions - Déploiement Backend VTC sur GCP

## 📋 Vue d'Ensemble

Ce document liste les prochaines actions concrètes à effectuer pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP), étape par étape.

---

## 🎯 Actions Immédiates (À faire maintenant)

### ✅ Vérification Préalable

Avant de commencer, vérifiez que vous avez :

- [ ] Un compte Google Cloud Platform avec facturation activée
- [ ] Google Cloud SDK (gcloud) installé et configuré
- [ ] Docker installé (pour le build des images)
- [ ] Accès au projet GCP avec les permissions nécessaires
- [ ] Clés API Google Maps créées (si disponible)

```bash
# Vérifier l'installation de gcloud
gcloud --version

# Vérifier la configuration
gcloud config list

# Vérifier le projet actif
gcloud config get-value project
```

---

## 🗄️ Action 1 : Créer et Configurer Cloud SQL

### Étape 1.1 : Créer l'Instance Cloud SQL

```bash
# Exécuter le script de création
./scripts/gcp-create-cloud-sql.sh

# Vérifier que l'instance est créée
gcloud sql instances describe tshiakani-vtc-db \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Instance Cloud SQL créée avec succès
- [ ] Version PostgreSQL 14+ installée
- [ ] Instance accessible depuis votre machine locale (pour tests)

### Étape 1.2 : Initialiser la Base de Données

```bash
# Exécuter le script d'initialisation
./scripts/gcp-init-database.sh

# Vérifier les tables créées
gcloud sql connect tshiakani-vtc-db \
  --user=postgres \
  --database=tshiakani_vtc
```

**Commandes SQL de vérification** :
```sql
-- Vérifier les tables
\dt

-- Vérifier la table users
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users';

-- Vérifier l'extension PostGIS
SELECT PostGIS_version();
```

**Vérifications** :
- [ ] Tables `users`, `rides` créées
- [ ] Extension PostGIS activée
- [ ] Index créés

### Étape 1.3 : Tester les Inscriptions

```bash
# Tester l'inscription d'un utilisateur
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "name": "Test User",
    "role": "client"
  }'

# Vérifier dans la base de données
gcloud sql connect tshiakani-vtc-db \
  --user=postgres \
  --database=tshiakani_vtc \
  --command="SELECT * FROM users WHERE phone_number = '+243900000001';"
```

**Vérifications** :
- [ ] Inscription utilisateur réussie
- [ ] Données correctement enregistrées
- [ ] Rôles correctement assignés

---

## 🔴 Action 2 : Créer et Configurer Memorystore (Redis)

### Étape 2.1 : Créer l'Instance Memorystore

```bash
# Exécuter le script de création
./scripts/gcp-create-redis.sh

# Vérifier que l'instance est créée
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Instance Memorystore créée avec succès
- [ ] Version Redis 6+ installée
- [ ] Instance accessible depuis Cloud Run (VPC Connector)

### Étape 2.2 : Tester la Connexion Redis

```bash
# Tester la connexion depuis le backend local
# (assurez-vous que le backend est démarré)
curl http://localhost:3000/health

# Vérifier le statut Redis dans la réponse
# La réponse doit inclure : "redis": {"status": "connected"}
```

**Vérifications** :
- [ ] Connexion Redis réussie
- [ ] Health check retourne `redis.status: "connected"`
- [ ] Pas d'erreurs de connexion dans les logs

### Étape 2.3 : Tester l'Écriture (HSET) - Mise à Jour de Position

```bash
# Simuler une mise à jour de position depuis l'application Chauffeur
curl -X POST http://localhost:3000/api/driver/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <driver_token>" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3363,
    "status": "available"
  }'
```

**Vérifications** :
- [ ] Position mise à jour avec succès (code 200)
- [ ] Données correctement enregistrées dans Redis
- [ ] Clé `driver:<driver_id>` créée
- [ ] Hash contient : `lat`, `lon`, `status`, `last_update`

### Étape 2.4 : Tester la Lecture (HGETALL) - Récupération de Position

```bash
# Tester la récupération de la position d'un conducteur
curl -X GET http://localhost:3000/api/driver/location \
  -H "Authorization: Bearer <driver_token>"

# Tester la recherche de conducteurs disponibles
curl -X GET "http://localhost:3000/api/location/nearby-drivers?lat=-4.3276&lon=15.3363&radius=5000" \
  -H "Authorization: Bearer <client_token>"
```

**Vérifications** :
- [ ] Position récupérée avec succès
- [ ] Données correctes (latitude, longitude, statut)
- [ ] Recherche de conducteurs disponibles fonctionnelle
- [ ] Résultats filtrés par rayon (5 km)

---

## 🚀 Action 3 : Déployer le Backend sur Cloud Run

### Étape 3.1 : Build l'Image Docker

```bash
# Aller dans le répertoire backend
cd backend

# Build l'image Docker
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .

# Tester l'image localement
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:password@host:5432/database \
  -e REDIS_HOST=localhost \
  -e REDIS_PORT=6379 \
  gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest
```

**Vérifications** :
- [ ] Image Docker buildée avec succès
- [ ] Image testée localement
- [ ] Application démarre correctement
- [ ] Health check fonctionnel

### Étape 3.2 : Déployer sur Cloud Run

```bash
# Revenir à la racine du projet
cd ..

# Exécuter le script de déploiement
./scripts/gcp-deploy-backend.sh

# Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

**Vérifications** :
- [ ] Service Cloud Run créé avec succès
- [ ] Image poussée vers Artifact Registry
- [ ] Service accessible via URL HTTPS
- [ ] Health check retourne 200

### Étape 3.3 : Configurer les Variables d'Environnement

```bash
# Exécuter le script de configuration
./scripts/gcp-set-cloud-run-env.sh

# Vérifier les variables
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

**Vérifications** :
- [ ] `DATABASE_URL` configurée (connexion Cloud SQL)
- [ ] `REDIS_HOST` et `REDIS_PORT` configurés
- [ ] `JWT_SECRET` configurée
- [ ] `GOOGLE_MAPS_API_KEY` configurée
- [ ] `FIREBASE_PROJECT_ID` configurée

### Étape 3.4 : Tester les Endpoints API

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.url)")

# Tester le health check
curl $SERVICE_URL/health

# Tester l'authentification
curl -X POST $SERVICE_URL/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "code": "123456"
  }'
```

**Vérifications** :
- [ ] Health check fonctionnel
- [ ] Authentification fonctionnelle
- [ ] Tous les endpoints API fonctionnels
- [ ] Latence acceptable (< 500ms p95)

---

## 🗺️ Action 4 : Configurer Google Maps et FCM

### Étape 4.1 : Activer les APIs Google Maps

```bash
# Activer les APIs Google Maps
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# Vérifier l'activation
gcloud services list --enabled \
  --filter="name:routes OR name:places OR name:geocoding"
```

**Vérifications** :
- [ ] Routes API activée
- [ ] Places API activée
- [ ] Geocoding API activée

### Étape 4.2 : Configurer la Clé API Google Maps

```bash
# Créer une clé API (via la console GCP ou gcloud)
# Note: La création de clé API via gcloud nécessite gcloud alpha

# Stocker la clé dans Secret Manager
echo -n "YOUR_GOOGLE_MAPS_API_KEY" | \
  gcloud secrets create google-maps-api-key \
  --data-file=-

# Donner accès au service account Cloud Run
gcloud secrets add-iam-policy-binding google-maps-api-key \
  --member="serviceAccount:tshiakani-vtc-backend@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

**Vérifications** :
- [ ] Clé API créée
- [ ] Clé API stockée dans Secret Manager
- [ ] Service account Cloud Run a accès à la clé
- [ ] Clé API configurée dans les variables d'environnement Cloud Run

### Étape 4.3 : Tester le Calcul d'Itinéraire

```bash
# Tester le calcul d'itinéraire
curl -X POST $SERVICE_URL/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3363,
      "address": "Avenue de la Justice, Kinshasa"
    },
    "dropoffLocation": {
      "latitude": -4.3376,
      "longitude": 15.3463,
      "address": "Avenue du Port, Kinshasa"
    }
  }'
```

**Vérifications** :
- [ ] Itinéraire calculé avec succès
- [ ] Distance calculée correctement (en km)
- [ ] Durée calculée correctement (en minutes)
- [ ] Prise en compte du trafic (TRAFFIC_AWARE)

### Étape 4.4 : Tester la Tarification Dynamique

```bash
# Vérifier la tarification dans la réponse de création de course
curl -X POST $SERVICE_URL/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }' | jq '.estimatedPrice'
```

**Vérifications** :
- [ ] Prix calculé avec la formule : Base + (Distance × Prix/km) + (Temps × Multiplicateur)
- [ ] Multiplicateurs appliqués (heure de pointe, nuit, week-end)
- [ ] Surge pricing appliqué (si applicable)
- [ ] Prix en CDF (Franc congolais)

---

## 📊 Action 5 : Configurer le Monitoring

### Étape 5.1 : Configurer Cloud Logging

```bash
# Exécuter le script de configuration
./scripts/gcp-setup-monitoring.sh

# Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=10 \
  --format=json
```

**Vérifications** :
- [ ] Logs envoyés à Cloud Logging
- [ ] Logs structurés (JSON)
- [ ] Niveaux de log corrects (ERROR, WARN, INFO, DEBUG)

### Étape 5.2 : Configurer Cloud Monitoring

```bash
# Vérifier les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc \
  --limit=10
```

**Vérifications** :
- [ ] Métriques enregistrées dans Cloud Monitoring
- [ ] Métriques de latence API visibles
- [ ] Métriques d'erreurs visibles
- [ ] Métriques de paiement visibles

### Étape 5.3 : Créer les Alertes

```bash
# Exécuter le script de création des alertes
./scripts/gcp-create-alerts.sh

# Vérifier les alertes
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Alerte de latence API créée (> 2000ms)
- [ ] Alerte de taux d'erreurs créée (> 5%)
- [ ] Alerte d'utilisation mémoire Cloud Run créée (> 80%)
- [ ] Alerte d'utilisation CPU Cloud Run créée (> 80%)
- [ ] Alerte d'erreurs de paiement créée (> 10 erreurs)
- [ ] Alerte d'erreurs de matching créée (> 10 erreurs)

### Étape 5.4 : Tester les Alertes

```bash
# Simuler une erreur de paiement
curl -X POST $SERVICE_URL/api/payment/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "rideId": "invalid-ride-id",
    "amount": 1000,
    "paymentToken": "invalid-token"
  }'

# Attendre quelques secondes et vérifier que l'alerte est déclenchée
sleep 60

# Vérifier les alertes actives
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc \
  --filter="displayName:Erreurs de paiement"
```

**Vérifications** :
- [ ] Erreur enregistrée dans Cloud Logging
- [ ] Métrique d'erreur de paiement enregistrée
- [ ] Alerte déclenchée (si seuil dépassé)
- [ ] Notification envoyée (email, SMS, webhook)

### Étape 5.5 : Créer les Tableaux de Bord

```bash
# Exécuter le script de création des tableaux de bord
./scripts/gcp-create-dashboard.sh

# Vérifier les tableaux de bord
gcloud monitoring dashboards list \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Tableau de bord principal créé
- [ ] Métriques de latence API visibles
- [ ] Métriques d'erreurs visibles
- [ ] Métriques de paiement visibles
- [ ] Métriques de matching visibles

---

## 🎯 Checklist Globale

### Étape 1 : Base de Données
- [ ] Instance Cloud SQL créée
- [ ] Tables Users/Drivers/Rides créées
- [ ] Index créés
- [ ] Inscriptions fonctionnelles
- [ ] Requêtes géospatiales performantes

### Étape 2 : Redis
- [ ] Instance Memorystore créée
- [ ] Connexion Redis fonctionnelle
- [ ] Écriture (HSET) fonctionnelle
- [ ] Lecture (HGETALL) fonctionnelle
- [ ] Matching avec Redis fonctionnel

### Étape 3 : Cloud Run
- [ ] Backend déployé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Mise à l'échelle automatique fonctionnelle
- [ ] Endpoints API fonctionnels

### Étape 4 : Google Maps
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Calcul itinéraire fonctionnel
- [ ] Tarification fonctionnelle
- [ ] Notifications FCM fonctionnelles

### Étape 5 : Monitoring
- [ ] Cloud Logging configuré
- [ ] Cloud Monitoring configuré
- [ ] Alertes créées
- [ ] Notifications configurées
- [ ] Tableaux de bord créés

---

## 🚨 Tests Critiques à Effectuer

### Test 1 : Échec Paiement → Alerte
```bash
# Simuler un échec de paiement
curl -X POST $SERVICE_URL/api/payment/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "rideId": "test-ride-id",
    "amount": 1000,
    "paymentToken": "invalid-token"
  }'

# Vérifier que l'alerte est déclenchée dans les secondes qui suivent
```

### Test 2 : Matching avec Redis
```bash
# Mettre à jour la position d'un conducteur
curl -X POST $SERVICE_URL/api/driver/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <driver_token>" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3363,
    "status": "available"
  }'

# Créer une course et vérifier le matching
curl -X POST $SERVICE_URL/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <client_token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }'
```

### Test 3 : Latence Élevée → Alerte
```bash
# Générer du trafic pour augmenter la latence
for i in {1..1000}; do
  curl $SERVICE_URL/health &
done
wait

# Vérifier que l'alerte est déclenchée si la latence dépasse 2000ms
```

---

## 📚 Documentation de Référence

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL (Base de données)
- `GCP_SETUP_ETAPE3.md` - Memorystore (Redis)
- `GCP_SETUP_ETAPE4.md` - Cloud Run (Déploiement)
- `GCP_SETUP_ETAPE5.md` - Monitoring (Observabilité)

### Guides de Déploiement
- `GCP_5_ETAPES_DEPLOIEMENT.md` - Les 5 étapes de déploiement
- `GCP_ACTIONS_CLES_DETAILLEES.md` - Actions clés détaillées
- `GCP_ACTIONS_CLES_RESUME.md` - Résumé des actions clés
- `GCP_DEPLOYMENT_QUICK_START.md` - Démarrage rapide

### Guides Techniques
- `backend/ALGORITHME_MATCHING_TARIFICATION.md` - Algorithme de matching
- `backend/MONITORING_INTEGRATION.md` - Intégration monitoring
- `backend/REDIS_STRUCTURE.md` - Structure Redis
- `backend/DATABASE_SCHEMA.md` - Schéma de base de données

---

## 🎉 Résumé

### Actions Immédiates
1. ✅ Créer et configurer Cloud SQL
2. ✅ Créer et configurer Memorystore (Redis)
3. ✅ Déployer le backend sur Cloud Run
4. ✅ Configurer Google Maps et FCM
5. ✅ Configurer le monitoring

### Tests Critiques
1. ✅ Test d'inscription utilisateur/conducteur
2. ✅ Test de mise à jour de position (Redis)
3. ✅ Test de matching avec Redis
4. ✅ Test de calcul d'itinéraire (Google Maps)
5. ✅ Test de tarification dynamique
6. ✅ Test d'alerte en cas d'échec de paiement

### Prochaines Étapes
- ⏳ Tests end-to-end complets
- ⏳ Optimisations de performance
- ⏳ Déploiement du dashboard admin
- ⏳ Configuration des applications iOS
- ⏳ Lancement en production

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide des prochaines actions pour le déploiement

