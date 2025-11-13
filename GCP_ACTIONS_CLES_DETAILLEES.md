# 🎯 Détails des Actions Clés - Déploiement Backend VTC sur GCP

## 📋 Vue d'Ensemble

Ce document détaille les actions spécifiques à effectuer pour chaque étape du déploiement, avec des vérifications et des tests à réaliser pour assurer le bon fonctionnement de l'application.

---

## 🗄️ Étape 1 : Le Socle de Données (Cloud SQL)

### 🎯 Objectif Principal
**Assurez-vous que Cloud SQL est provisionné et que les tables Users et Drivers sont prêtes à recevoir les inscriptions.**

### ✅ Actions Clés

#### 1.1 Provisionner Cloud SQL
```bash
# Créer l'instance Cloud SQL (PostgreSQL)
./scripts/gcp-create-cloud-sql.sh

# Vérifier que l'instance est créée
gcloud sql instances describe tshiakani-vtc-db --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Instance Cloud SQL créée avec succès
- [ ] Version PostgreSQL 14+ installée
- [ ] Extension PostGIS activée
- [ ] Instance accessible depuis Cloud Run (VPC Connector ou IP publique)

#### 1.2 Initialiser la Base de Données
```bash
# Initialiser la base de données avec les tables
./scripts/gcp-init-database.sh

# Vérifier les tables créées
gcloud sql connect tshiakani-vtc-db --user=postgres --database=tshiakani_vtc
```

**Commandes SQL de vérification**:
```sql
-- Vérifier les tables
\dt

-- Vérifier la table Users
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'users';

-- Vérifier la table Drivers (via driver_info dans users)
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'users' AND column_name LIKE '%driver%';

-- Vérifier la table Rides
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'rides';

-- Vérifier l'extension PostGIS
SELECT PostGIS_version();
```

**Vérifications**:
- [ ] Table `users` créée avec les colonnes : `id`, `phone_number`, `name`, `role`, `driver_info`, `location`, `created_at`, `updated_at`
- [ ] Table `rides` créée avec les colonnes : `id`, `client_id`, `driver_id`, `pickup_location`, `dropoff_location`, `status`, `estimated_price`, `distance`, `estimated_duration`, `created_at`, `updated_at`
- [ ] Index géospatial créés sur `location` (GIST)
- [ ] Index composite créés (ex: `status`, `created_at`)
- [ ] Extension PostGIS activée

#### 1.3 Tester les Inscriptions
```bash
# Tester l'inscription d'un utilisateur
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "name": "Test User",
    "role": "client"
  }'

# Tester l'inscription d'un conducteur
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000002",
    "name": "Test Driver",
    "role": "driver",
    "driverInfo": {
      "vehicleType": "sedan",
      "licensePlate": "ABC-123",
      "vehicleColor": "white"
    }
  }'
```

**Vérifications**:
- [ ] Inscription utilisateur réussie
- [ ] Inscription conducteur réussie
- [ ] Données correctement enregistrées dans la base de données
- [ ] Localisation géospatiale correctement stockée (pour les conducteurs)
- [ ] Rôles correctement assignés

#### 1.4 Vérifier les Performances
```sql
-- Vérifier les index
SELECT indexname, indexdef FROM pg_indexes 
WHERE tablename IN ('users', 'rides');

-- Tester une requête géospatiale
EXPLAIN ANALYZE
SELECT * FROM users 
WHERE role = 'driver' 
  AND ST_DWithin(
    location,
    ST_SetSRID(ST_MakePoint(15.3363, -4.3276), 4326),
    5000
  );
```

**Vérifications**:
- [ ] Index créés et utilisés dans les requêtes
- [ ] Requêtes géospatiales performantes (< 100ms)
- [ ] Pas d'erreurs dans les logs

---

## 🔴 Étape 2 : L'Épine Dorsale du Temps Réel (Redis)

### 🎯 Objectif Principal
**L'interaction entre votre application Chauffeur et Memorystore doit être la première chose testée, car c'est la source de données pour le matching.**

### ✅ Actions Clés

#### 2.1 Provisionner Memorystore (Redis)
```bash
# Créer l'instance Memorystore
./scripts/gcp-create-redis.sh

# Vérifier que l'instance est créée
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Instance Memorystore créée avec succès
- [ ] Version Redis 6+ installée
- [ ] Instance accessible depuis Cloud Run (VPC Connector)
- [ ] Taille de mémoire suffisante (au moins 1 GB)

#### 2.2 Tester la Connexion Redis
```bash
# Tester la connexion depuis Cloud Run
# (via le backend déployé)
curl https://tshiakani-vtc-backend-xxxxx.run.app/health

# Vérifier le statut Redis dans la réponse
```

**Vérifications**:
- [ ] Connexion Redis réussie depuis Cloud Run
- [ ] Health check retourne `redis.status: "connected"`
- [ ] Pas d'erreurs de connexion dans les logs

#### 2.3 Tester l'Écriture (HSET) - Mise à Jour de Position
```bash
# Simuler une mise à jour de position depuis l'application Chauffeur
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/driver/location \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <driver_token>" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3363,
    "status": "available"
  }'
```

**Vérifications**:
- [ ] Position mise à jour avec succès (code 200)
- [ ] Données correctement enregistrées dans Redis
- [ ] Clé `driver:<driver_id>` créée
- [ ] Hash contient : `lat`, `lon`, `status`, `last_update`
- [ ] TTL configuré (5 minutes)

#### 2.4 Tester la Lecture (HGETALL) - Récupération de Position
```bash
# Tester la récupération de la position d'un conducteur
curl -X GET https://tshiakani-vtc-backend-xxxxx.run.app/api/driver/location \
  -H "Authorization: Bearer <driver_token>"

# Tester la recherche de conducteurs disponibles
curl -X GET "https://tshiakani-vtc-backend-xxxxx.run.app/api/location/nearby-drivers?lat=-4.3276&lon=15.3363&radius=5000" \
  -H "Authorization: Bearer <client_token>"
```

**Vérifications**:
- [ ] Position récupérée avec succès
- [ ] Données correctes (latitude, longitude, statut)
- [ ] Recherche de conducteurs disponibles fonctionnelle
- [ ] Résultats filtrés par rayon (5 km)
- [ ] Performances acceptables (< 100ms)

#### 2.5 Tester la Mise à Jour Continue (2-3 secondes)
```bash
# Script de test de mise à jour continue
for i in {1..10}; do
  curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/driver/location \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <driver_token>" \
    -d "{
      \"latitude\": -4.3276 + ($i * 0.0001),
      \"longitude\": 15.3363 + ($i * 0.0001),
      \"status\": \"available\"
    }"
  sleep 2
done
```

**Vérifications**:
- [ ] Mises à jour réussies toutes les 2-3 secondes
- [ ] Pas de perte de données
- [ ] Performance stable (< 50ms par requête)
- [ ] Pas d'erreurs dans les logs
- [ ] TTL correctement renouvelé

#### 2.6 Tester le Matching avec Redis
```bash
# Créer une course et vérifier le matching
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <client_token>" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3363
    },
    "pickupAddress": "Test Address",
    "dropoffLocation": {
      "latitude": -4.3376,
      "longitude": 15.3463
    },
    "dropoffAddress": "Test Destination"
  }'
```

**Vérifications**:
- [ ] Conducteurs disponibles récupérés depuis Redis
- [ ] Matching réussi (conducteur assigné ou notification envoyée)
- [ ] Distance calculée correctement
- [ ] Performance acceptable (< 500ms)

---

## 🚀 Étape 3 : Le Cœur de la Logique (Cloud Run)

### 🎯 Objectif Principal
**Le déploiement sur Cloud Run est la manière la plus efficace de mettre votre API en ligne, avec une mise à l'échelle automatique gérée par Google.**

### ✅ Actions Clés

#### 3.1 Construire l'Image Docker
```bash
# Build l'image Docker
cd backend
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .

# Tester l'image localement
docker run -p 3000:3000 \
  -e DATABASE_URL=postgresql://user:password@host:5432/database \
  -e REDIS_HOST=localhost \
  -e REDIS_PORT=6379 \
  gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest
```

**Vérifications**:
- [ ] Image Docker buildée avec succès
- [ ] Image testée localement
- [ ] Application démarre correctement
- [ ] Health check fonctionnel

#### 3.2 Déployer sur Cloud Run
```bash
# Déployer sur Cloud Run
./scripts/gcp-deploy-backend.sh

# Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

**Vérifications**:
- [ ] Service Cloud Run créé avec succès
- [ ] Image poussée vers Artifact Registry
- [ ] Service accessible via URL HTTPS
- [ ] Health check retourne 200
- [ ] Variables d'environnement configurées

#### 3.3 Configurer les Variables d'Environnement
```bash
# Configurer les variables d'environnement
./scripts/gcp-set-cloud-run-env.sh

# Vérifier les variables
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

**Vérifications**:
- [ ] `DATABASE_URL` configurée (connexion Cloud SQL)
- [ ] `REDIS_HOST` et `REDIS_PORT` configurés
- [ ] `JWT_SECRET` configurée
- [ ] `GOOGLE_MAPS_API_KEY` configurée
- [ ] `FIREBASE_PROJECT_ID` configurée
- [ ] `STRIPE_SECRET_KEY` configurée (si applicable)

#### 3.4 Configurer les Permissions IAM
```bash
# Vérifier les permissions du service account
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc-backend@tshiakani-vtc.iam.gserviceaccount.com"
```

**Vérifications**:
- [ ] Service account Cloud Run a les permissions :
  - `roles/cloudsql.client` (accès Cloud SQL)
  - `roles/redis.editor` (accès Memorystore)
  - `roles/logging.logWriter` (écriture logs)
  - `roles/monitoring.metricWriter` (écriture métriques)
  - `roles/secretmanager.secretAccessor` (accès secrets)

#### 3.5 Tester la Mise à l'Échelle Automatique
```bash
# Générer du trafic pour tester la mise à l'échelle
for i in {1..100}; do
  curl https://tshiakani-vtc-backend-xxxxx.run.app/health &
done
wait

# Vérifier le nombre d'instances
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.conditions)"
```

**Vérifications**:
- [ ] Mise à l'échelle automatique fonctionnelle
- [ ] Nouvelles instances créées sous charge
- [ ] Instances supprimées lorsque le trafic diminue
- [ ] Performance stable sous charge

#### 3.6 Tester les Endpoints API
```bash
# Tester l'authentification
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "code": "123456"
  }'

# Tester la création de course
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }'
```

**Vérifications**:
- [ ] Authentification fonctionnelle
- [ ] Création de course fonctionnelle
- [ ] Tous les endpoints API fonctionnels
- [ ] Gestion des erreurs correcte
- [ ] Latence acceptable (< 500ms p95)

---

## 🗺️ Étape 4 : Les Services Clés (Google Maps & FCM)

### 🎯 Objectif Principal
**L'intégration des API Maps doit être précise pour garantir une tarification et des ETA fiables, même avec la complexité du trafic à Kinshasa.**

### ✅ Actions Clés

#### 4.1 Activer les APIs Google Maps
```bash
# Activer les APIs Google Maps
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# Vérifier l'activation
gcloud services list --enabled --filter="name:routes OR name:places OR name:geocoding"
```

**Vérifications**:
- [ ] Routes API activée
- [ ] Places API activée
- [ ] Geocoding API activée
- [ ] Quotas configurés (si nécessaire)

#### 4.2 Configurer la Clé API Google Maps
```bash
# Créer une clé API
gcloud alpha services api-keys create \
  --display-name="Tshiakani VTC Maps API Key" \
  --api-target=service=routes.googleapis.com

# Configurer les restrictions
gcloud alpha services api-keys update <API_KEY_ID> \
  --restrictions-api-targets=service=routes.googleapis.com,service=places.googleapis.com,service=geocoding.googleapis.com
```

**Vérifications**:
- [ ] Clé API créée
- [ ] Restrictions configurées (IP, référent, application)
- [ ] Clé API stockée dans Secret Manager
- [ ] Clé API accessible depuis Cloud Run

#### 4.3 Tester le Calcul d'Itinéraire
```bash
# Tester le calcul d'itinéraire
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
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

**Vérifications**:
- [ ] Itinéraire calculé avec succès
- [ ] Distance calculée correctement (en km)
- [ ] Durée calculée correctement (en minutes)
- [ ] Prise en compte du trafic (TRAFFIC_AWARE)
- [ ] Performance acceptable (< 1s)

#### 4.4 Tester la Tarification Dynamique
```bash
# Vérifier la tarification dans la réponse de création de course
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }' | jq '.estimatedPrice'
```

**Vérifications**:
- [ ] Prix calculé avec la formule : Base + (Distance × Prix/km) + (Temps × Multiplicateur)
- [ ] Multiplicateurs appliqués (heure de pointe, nuit, week-end)
- [ ] Surge pricing appliqué (si applicable)
- [ ] Prix en CDF (Franc congolais)
- [ ] Prix fixe pour le client (pas de changement)

#### 4.5 Tester les Notifications FCM
```bash
# Vérifier l'envoi de notifications lors de la création d'une course
# (Les notifications sont envoyées automatiquement aux conducteurs disponibles)
```

**Vérifications**:
- [ ] Notifications envoyées aux conducteurs disponibles
- [ ] Notifications reçues sur les appareils mobiles
- [ ] Contenu de la notification correct (adresse, prix, distance)
- [ ] Notifications de statut de course fonctionnelles
- [ ] Gestion des erreurs (appareil non enregistré, etc.)

#### 4.6 Tester la Géocodage
```bash
# Tester la conversion d'adresse en coordonnées
curl -X GET "https://tshiakani-vtc-backend-xxxxx.run.app/api/geocode?address=Avenue%20de%20la%20Justice,%20Kinshasa" \
  -H "Authorization: Bearer <token>"
```

**Vérifications**:
- [ ] Adresse convertie en coordonnées (latitude, longitude)
- [ ] Coordonnées précises pour Kinshasa
- [ ] Gestion des adresses partielles
- [ ] Performance acceptable (< 500ms)

---

## 📊 Étape 5 : L'Opérabilité et la Mise en Service (Monitoring)

### 🎯 Objectif Principal
**Avant le lancement public, vous devez être certain que si un service échoue (par exemple, si l'API de paiement ne répond pas), vous êtes alerté dans les secondes qui suivent via Cloud Monitoring.**

### ✅ Actions Clés

#### 5.1 Configurer Cloud Logging
```bash
# Configurer le logging
./scripts/gcp-setup-monitoring.sh

# Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" --limit 10
```

**Vérifications**:
- [ ] Logs envoyés à Cloud Logging
- [ ] Logs structurés (JSON)
- [ ] Niveaux de log corrects (ERROR, WARN, INFO, DEBUG)
- [ ] Logs d'erreur visibles
- [ ] Logs de paiement visibles
- [ ] Logs de matching visibles

#### 5.2 Configurer Cloud Monitoring
```bash
# Configurer le monitoring
./scripts/gcp-setup-monitoring.sh

# Vérifier les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Métriques enregistrées dans Cloud Monitoring
- [ ] Métriques de latence API visibles
- [ ] Métriques d'erreurs visibles
- [ ] Métriques de paiement visibles
- [ ] Métriques de matching visibles
- [ ] Métriques de courses visibles

#### 5.3 Créer les Alertes
```bash
# Créer les alertes
./scripts/gcp-create-alerts.sh

# Vérifier les alertes
gcloud alpha monitoring policies list --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Alerte de latence API créée (> 2000ms)
- [ ] Alerte de taux d'erreurs créée (> 5%)
- [ ] Alerte d'utilisation mémoire Cloud Run créée (> 80%)
- [ ] Alerte d'utilisation CPU Cloud Run créée (> 80%)
- [ ] Alerte d'utilisation mémoire Cloud SQL créée (> 80%)
- [ ] Alerte d'utilisation CPU Cloud SQL créée (> 80%)
- [ ] Alerte d'erreurs de paiement créée (> 10 erreurs)
- [ ] Alerte d'erreurs de matching créée (> 10 erreurs)

#### 5.4 Tester les Alertes
```bash
# Simuler une erreur de paiement
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/payment/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "rideId": "invalid-ride-id",
    "amount": 1000,
    "paymentToken": "invalid-token"
  }'

# Vérifier que l'alerte est déclenchée
gcloud alpha monitoring policies list --project=tshiakani-vtc \
  --filter="displayName:Erreurs de paiement"
```

**Vérifications**:
- [ ] Alerte déclenchée en cas d'erreur de paiement
- [ ] Notification envoyée (email, SMS, webhook)
- [ ] Alerte déclenchée en cas d'erreur de matching
- [ ] Alerte déclenchée en cas de latence élevée
- [ ] Alerte déclenchée en cas d'utilisation élevée des ressources

#### 5.5 Créer les Tableaux de Bord
```bash
# Créer les tableaux de bord
./scripts/gcp-create-dashboard.sh

# Vérifier les tableaux de bord
gcloud monitoring dashboards list --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Tableau de bord principal créé
- [ ] Métriques de latence API visibles
- [ ] Métriques d'erreurs visibles
- [ ] Métriques de paiement visibles
- [ ] Métriques de matching visibles
- [ ] Métriques de courses visibles
- [ ] Métriques de ressources visibles

#### 5.6 Configurer les Notifications d'Alertes
```bash
# Créer un canal de notification
gcloud alpha monitoring channels create \
  --display-name="Email Alerts" \
  --type=email \
  --channel-labels=email_address=admin@tshiakani-vtc.com

# Associer le canal aux alertes
gcloud alpha monitoring policies update <POLICY_ID> \
  --notification-channels=<CHANNEL_ID>
```

**Vérifications**:
- [ ] Canal de notification créé (email, SMS, webhook)
- [ ] Canal associé aux alertes
- [ ] Notifications reçues en cas d'alerte
- [ ] Notifications en temps réel (< 1 minute)

#### 5.7 Tester le Monitoring End-to-End
```bash
# Créer une course et vérifier les métriques
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }'

# Vérifier les métriques dans Cloud Monitoring
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/rides/created"' \
  --project=tshiakani-vtc
```

**Vérifications**:
- [ ] Métriques enregistrées lors de la création de course
- [ ] Métriques de matching enregistrées
- [ ] Métriques de paiement enregistrées (si applicable)
- [ ] Logs enregistrés dans Cloud Logging
- [ ] Alertes déclenchées en cas d'erreur

---

## 🎯 Checklist Complète de Vérification

### Étape 1 : Base de Données
- [ ] Instance Cloud SQL créée et accessible
- [ ] Tables Users, Drivers, Rides créées
- [ ] Index créés et fonctionnels
- [ ] Extension PostGIS activée
- [ ] Inscriptions utilisateurs fonctionnelles
- [ ] Inscriptions conducteurs fonctionnelles
- [ ] Requêtes géospatiales performantes

### Étape 2 : Redis
- [ ] Instance Memorystore créée et accessible
- [ ] Connexion Redis fonctionnelle depuis Cloud Run
- [ ] Écriture de position (HSET) fonctionnelle
- [ ] Lecture de position (HGETALL) fonctionnelle
- [ ] Mise à jour continue (2-3 secondes) fonctionnelle
- [ ] Matching avec Redis fonctionnel
- [ ] Recherche de conducteurs disponibles fonctionnelle

### Étape 3 : Cloud Run
- [ ] Image Docker buildée et testée
- [ ] Service Cloud Run déployé et accessible
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Mise à l'échelle automatique fonctionnelle
- [ ] Endpoints API fonctionnels
- [ ] Performance acceptable (< 500ms p95)

### Étape 4 : Google Maps & FCM
- [ ] APIs Google Maps activées
- [ ] Clé API configurée et sécurisée
- [ ] Calcul d'itinéraire fonctionnel
- [ ] Tarification dynamique fonctionnelle
- [ ] Notifications FCM fonctionnelles
- [ ] Géocodage fonctionnel
- [ ] Prise en compte du trafic fonctionnelle

### Étape 5 : Monitoring
- [ ] Cloud Logging configuré et fonctionnel
- [ ] Cloud Monitoring configuré et fonctionnel
- [ ] Métriques enregistrées correctement
- [ ] Alertes créées et fonctionnelles
- [ ] Tableaux de bord créés et visibles
- [ ] Notifications d'alertes configurées
- [ ] Tests end-to-end réussis

---

## 🚨 Scénarios de Test Critiques

### Test 1 : Échec de l'API de Paiement
```bash
# Simuler un échec de paiement
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/payment/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "rideId": "test-ride-id",
    "amount": 1000,
    "paymentToken": "invalid-token"
  }'

# Vérifier que l'alerte est déclenchée dans les secondes qui suivent
```

**Résultat attendu**:
- [ ] Erreur enregistrée dans Cloud Logging
- [ ] Métrique d'erreur de paiement enregistrée
- [ ] Alerte déclenchée dans Cloud Monitoring
- [ ] Notification envoyée (< 1 minute)

### Test 2 : Échec de Matching
```bash
# Créer une course sans conducteurs disponibles
curl -X POST https://tshiakani-vtc-backend-xxxxx.run.app/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }'

# Vérifier que l'alerte est déclenchée si aucun conducteur n'est trouvé
```

**Résultat attendu**:
- [ ] Erreur de matching enregistrée dans Cloud Logging
- [ ] Métrique d'erreur de matching enregistrée
- [ ] Alerte déclenchée si trop d'erreurs (> 10)
- [ ] Notification envoyée si nécessaire

### Test 3 : Latence Élevée
```bash
# Générer du trafic pour augmenter la latence
for i in {1..1000}; do
  curl https://tshiakani-vtc-backend-xxxxx.run.app/health &
done
wait

# Vérifier que l'alerte est déclenchée si la latence dépasse 2000ms
```

**Résultat attendu**:
- [ ] Latence mesurée et enregistrée
- [ ] Alerte déclenchée si latence > 2000ms (p95)
- [ ] Notification envoyée
- [ ] Mise à l'échelle automatique déclenchée

### Test 4 : Utilisation Élevée des Ressources
```bash
# Générer du trafic pour augmenter l'utilisation des ressources
# (simuler une charge élevée)

# Vérifier que l'alerte est déclenchée si l'utilisation dépasse 80%
```

**Résultat attendu**:
- [ ] Utilisation CPU/mémoire mesurée
- [ ] Alerte déclenchée si utilisation > 80%
- [ ] Notification envoyée
- [ ] Mise à l'échelle automatique déclenchée

---

## 📚 Documentation de Référence

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL (Base de données)
- `GCP_SETUP_ETAPE3.md` - Memorystore (Redis)
- `GCP_SETUP_ETAPE4.md` - Cloud Run (Déploiement)
- `GCP_SETUP_ETAPE5.md` - Monitoring (Observabilité)

### Guides Techniques
- `backend/ALGORITHME_MATCHING_TARIFICATION.md` - Algorithme de matching
- `backend/MONITORING_INTEGRATION.md` - Intégration monitoring
- `backend/REDIS_STRUCTURE.md` - Structure Redis
- `backend/DATABASE_SCHEMA.md` - Schéma de base de données

### Guides de Déploiement
- `GCP_DEPLOYMENT_QUICK_START.md` - Démarrage rapide
- `GCP_5_ETAPES_DEPLOIEMENT.md` - Les 5 étapes de déploiement
- `PROCHAINES_ETAPES.md` - Prochaines étapes
- `ROADMAP_COMPLET.md` - Roadmap complète

---

## 🎉 Résumé

### Actions Clés Réalisées
- ✅ **Étape 1** : Cloud SQL provisionné, tables prêtes pour les inscriptions
- ✅ **Étape 2** : Redis testé, interaction application Chauffeur fonctionnelle
- ✅ **Étape 3** : Backend déployé sur Cloud Run, mise à l'échelle automatique
- ✅ **Étape 4** : Google Maps intégré, tarification et ETA fiables
- ✅ **Étape 5** : Monitoring configuré, alertes en temps réel

### Prochaines Étapes
- ⏳ Tests end-to-end complets
- ⏳ Optimisations de performance
- ⏳ Déploiement du dashboard admin
- ⏳ Configuration des applications iOS
- ⏳ Lancement en production

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide détaillé des actions clés pour le déploiement

