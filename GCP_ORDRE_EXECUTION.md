# 🚀 Ordre d'Exécution - Déploiement Backend VTC sur GCP

## 📋 Vue d'Ensemble

Ce document présente les actions à effectuer **dans l'ordre chronologique** pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP).

---

## ✅ Étape 0 : Vérification des Prérequis

### Action 0.1 : Vérifier l'Installation de gcloud

```bash
# Vérifier que gcloud est installé
gcloud --version

# Vérifier la configuration
gcloud config list

# Vérifier le projet actif
gcloud config get-value project

# Si le projet n'est pas configuré, le définir
gcloud config set project tshiakani-vtc
```

**Vérifications** :
- [ ] gcloud installé et configuré
- [ ] Projet GCP configuré
- [ ] Authentification effectuée (`gcloud auth login`)

### Action 0.2 : Vérifier Docker

```bash
# Vérifier que Docker est installé
docker --version

# Vérifier que Docker fonctionne
docker ps
```

**Vérifications** :
- [ ] Docker installé
- [ ] Docker fonctionne

### Action 0.3 : Activer les APIs Nécessaires

```bash
# Activer les APIs GCP nécessaires
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable redis.googleapis.com
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Vérifier que les APIs sont activées
gcloud services list --enabled
```

**Vérifications** :
- [ ] Toutes les APIs sont activées
- [ ] Pas d'erreurs d'activation

---

## 🗄️ Étape 1 : Créer et Configurer Cloud SQL

### Action 1.1 : Créer l'Instance Cloud SQL

```bash
# Exécuter le script de création
chmod +x scripts/gcp-create-cloud-sql.sh
./scripts/gcp-create-cloud-sql.sh

# Attendre que l'instance soit créée (peut prendre 5-10 minutes)
# Vérifier le statut
gcloud sql instances describe tshiakani-vtc-db \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Instance Cloud SQL créée avec succès
- [ ] Statut : `RUNNABLE`
- [ ] Version PostgreSQL 14+ installée

**⏱️ Temps estimé** : 5-10 minutes

### Action 1.2 : Initialiser la Base de Données

```bash
# Exécuter le script d'initialisation
chmod +x scripts/gcp-init-database.sh
./scripts/gcp-init-database.sh

# Vérifier que les tables sont créées
gcloud sql connect tshiakani-vtc-db \
  --user=postgres \
  --database=tshiakani_vtc \
  --quiet
```

**Dans la console SQL, exécuter** :
```sql
-- Vérifier les tables
\dt

-- Vérifier la table users
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users';

-- Vérifier l'extension PostGIS
SELECT PostGIS_version();

-- Quitter
\q
```

**Vérifications** :
- [ ] Tables `users`, `rides` créées
- [ ] Extension PostGIS activée
- [ ] Index créés

**⏱️ Temps estimé** : 2-3 minutes

### Action 1.3 : Tester les Inscriptions (Optionnel - Local)

```bash
# Si le backend est démarré localement, tester l'inscription
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "name": "Test User",
    "role": "client"
  }'
```

**Vérifications** :
- [ ] Inscription utilisateur réussie
- [ ] Données correctement enregistrées dans la base de données

**⏱️ Temps estimé** : 1-2 minutes

---

## 🔴 Étape 2 : Créer et Configurer Memorystore (Redis)

### Action 2.1 : Créer l'Instance Memorystore

```bash
# Exécuter le script de création
chmod +x scripts/gcp-create-redis.sh
./scripts/gcp-create-redis.sh

# Attendre que l'instance soit créée (peut prendre 10-15 minutes)
# Vérifier le statut
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Instance Memorystore créée avec succès
- [ ] Statut : `READY`
- [ ] Version Redis 6+ installée
- [ ] Adresse IP assignée

**⏱️ Temps estimé** : 10-15 minutes

### Action 2.2 : Configurer le VPC Connector (Si nécessaire)

```bash
# Vérifier si un VPC Connector existe
gcloud compute networks vpc-access connectors list \
  --region=us-central1

# Si aucun VPC Connector n'existe, le créer
gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28
```

**Vérifications** :
- [ ] VPC Connector créé (si nécessaire)
- [ ] VPC Connector accessible depuis Cloud Run

**⏱️ Temps estimé** : 5-10 minutes

### Action 2.3 : Tester la Connexion Redis (Après déploiement Cloud Run)

```bash
# Après le déploiement du backend sur Cloud Run, tester la connexion
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.url)")

curl $SERVICE_URL/health
```

**Vérifications** :
- [ ] Health check retourne `redis.status: "connected"`
- [ ] Pas d'erreurs de connexion dans les logs

**⏱️ Temps estimé** : 1-2 minutes (après déploiement)

---

## 🚀 Étape 3 : Déployer le Backend sur Cloud Run

### Action 3.1 : Build l'Image Docker

```bash
# Aller dans le répertoire backend
cd backend

# Build l'image Docker
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .

# Vérifier que l'image est créée
docker images | grep tshiakani-vtc-backend
```

**Vérifications** :
- [ ] Image Docker buildée avec succès
- [ ] Aucune erreur de build

**⏱️ Temps estimé** : 5-10 minutes

### Action 3.2 : Configurer Artifact Registry

```bash
# Revenir à la racine du projet
cd ..

# Créer un dépôt Artifact Registry (si nécessaire)
gcloud artifacts repositories create tshiakani-vtc-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Repository pour les images Docker Tshiakani VTC"

# Configurer Docker pour utiliser gcloud comme credential helper
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**Vérifications** :
- [ ] Dépôt Artifact Registry créé
- [ ] Docker configuré pour utiliser Artifact Registry

**⏱️ Temps estimé** : 2-3 minutes

### Action 3.3 : Push l'Image Docker

```bash
# Tagger l'image pour Artifact Registry
docker tag gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest

# Push l'image
docker push us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest
```

**Vérifications** :
- [ ] Image poussée avec succès
- [ ] Image visible dans Artifact Registry

**⏱️ Temps estimé** : 5-10 minutes

### Action 3.4 : Déployer sur Cloud Run

```bash
# Exécuter le script de déploiement
chmod +x scripts/gcp-deploy-backend.sh
./scripts/gcp-deploy-backend.sh

# Vérifier le déploiement
chmod +x scripts/gcp-verify-cloud-run.sh
./scripts/gcp-verify-cloud-run.sh
```

**Vérifications** :
- [ ] Service Cloud Run créé avec succès
- [ ] Service accessible via URL HTTPS
- [ ] Health check retourne 200

**⏱️ Temps estimé** : 5-10 minutes

### Action 3.5 : Configurer les Variables d'Environnement

```bash
# Exécuter le script de configuration
chmod +x scripts/gcp-set-cloud-run-env.sh
./scripts/gcp-set-cloud-run-env.sh

# Vérifier les variables
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

**Variables à configurer** :
- `DATABASE_URL` - Connexion Cloud SQL
- `REDIS_HOST` - Adresse Redis
- `REDIS_PORT` - Port Redis
- `JWT_SECRET` - Secret JWT
- `GOOGLE_MAPS_API_KEY` - Clé API Google Maps
- `FIREBASE_PROJECT_ID` - ID projet Firebase
- `STRIPE_SECRET_KEY` - Clé secrète Stripe (si applicable)

**Vérifications** :
- [ ] Toutes les variables d'environnement configurées
- [ ] Aucune variable manquante

**⏱️ Temps estimé** : 2-3 minutes

### Action 3.6 : Configurer les Permissions IAM

```bash
# Obtenir le service account Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

# Donner les permissions Cloud SQL
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/cloudsql.client"

# Donner les permissions Redis (via VPC)
# (Les permissions Redis sont gérées via le VPC Connector)

# Donner les permissions Logging
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/logging.logWriter"

# Donner les permissions Monitoring
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/monitoring.metricWriter"

# Donner les permissions Secret Manager (si utilisé)
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

**Vérifications** :
- [ ] Permissions IAM configurées
- [ ] Service account a accès à Cloud SQL
- [ ] Service account a accès à Logging/Monitoring

**⏱️ Temps estimé** : 2-3 minutes

### Action 3.7 : Tester les Endpoints API

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.url)")

# Tester le health check
curl $SERVICE_URL/health

# Tester l'authentification (si disponible)
curl -X POST $SERVICE_URL/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "code": "123456"
  }'
```

**Vérifications** :
- [ ] Health check fonctionnel
- [ ] Endpoints API fonctionnels
- [ ] Latence acceptable (< 500ms)

**⏱️ Temps estimé** : 2-3 minutes

---

## 🗺️ Étape 4 : Configurer Google Maps et FCM

### Action 4.1 : Activer les APIs Google Maps

```bash
# Activer les APIs Google Maps (déjà fait à l'étape 0, mais vérifier)
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

**⏱️ Temps estimé** : 1-2 minutes

### Action 4.2 : Créer et Configurer la Clé API Google Maps

```bash
# Créer une clé API (via la console GCP)
# Aller sur https://console.cloud.google.com/apis/credentials
# Créer une clé API et la copier

# Stocker la clé dans Secret Manager
echo -n "YOUR_GOOGLE_MAPS_API_KEY" | \
  gcloud secrets create google-maps-api-key \
  --data-file=-

# Donner accès au service account Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

gcloud secrets add-iam-policy-binding google-maps-api-key \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

# Mettre à jour la variable d'environnement Cloud Run
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --update-env-vars="GOOGLE_MAPS_API_KEY=$(gcloud secrets versions access latest --secret=google-maps-api-key)"
```

**Vérifications** :
- [ ] Clé API créée
- [ ] Clé API stockée dans Secret Manager
- [ ] Service account a accès à la clé
- [ ] Variable d'environnement configurée

**⏱️ Temps estimé** : 5-10 minutes

### Action 4.3 : Tester le Calcul d'Itinéraire

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
- [ ] Distance calculée correctement
- [ ] Durée calculée correctement
- [ ] Prise en compte du trafic

**⏱️ Temps estimé** : 2-3 minutes

### Action 4.4 : Configurer Firebase Cloud Messaging (FCM)

```bash
# Configurer Firebase (via la console Firebase)
# Aller sur https://console.firebase.google.com
# Créer un projet Firebase (ou utiliser un projet existant)
# Activer Cloud Messaging
# Télécharger le fichier de configuration (google-services.json)

# Stocker les credentials Firebase dans Secret Manager
echo -n "YOUR_FIREBASE_PRIVATE_KEY" | \
  gcloud secrets create firebase-private-key \
  --data-file=-

# Donner accès au service account
gcloud secrets add-iam-policy-binding firebase-private-key \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

# Mettre à jour les variables d'environnement
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --update-env-vars="FIREBASE_PROJECT_ID=tshiakani-vtc,FIREBASE_PRIVATE_KEY=$(gcloud secrets versions access latest --secret=firebase-private-key)"
```

**Vérifications** :
- [ ] Firebase configuré
- [ ] Cloud Messaging activé
- [ ] Credentials stockés dans Secret Manager
- [ ] Variables d'environnement configurées

**⏱️ Temps estimé** : 10-15 minutes

---

## 📊 Étape 5 : Configurer le Monitoring

### Action 5.1 : Configurer Cloud Logging

```bash
# Exécuter le script de configuration
chmod +x scripts/gcp-setup-monitoring.sh
./scripts/gcp-setup-monitoring.sh

# Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=10 \
  --format=json
```

**Vérifications** :
- [ ] Logs envoyés à Cloud Logging
- [ ] Logs structurés (JSON)
- [ ] Niveaux de log corrects

**⏱️ Temps estimé** : 2-3 minutes

### Action 5.2 : Configurer Cloud Monitoring

```bash
# Vérifier que les métriques sont enregistrées
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc \
  --limit=10
```

**Vérifications** :
- [ ] Métriques enregistrées dans Cloud Monitoring
- [ ] Métriques de latence API visibles
- [ ] Métriques d'erreurs visibles

**⏱️ Temps estimé** : 1-2 minutes

### Action 5.3 : Créer les Alertes

```bash
# Exécuter le script de création des alertes
chmod +x scripts/gcp-create-alerts.sh
./scripts/gcp-create-alerts.sh

# Vérifier les alertes
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Alertes créées
- [ ] Alertes de latence API créées
- [ ] Alertes de taux d'erreurs créées
- [ ] Alertes d'utilisation ressources créées
- [ ] Alertes d'erreurs de paiement créées
- [ ] Alertes d'erreurs de matching créées

**⏱️ Temps estimé** : 5-10 minutes

### Action 5.4 : Configurer les Notifications d'Alertes

```bash
# Créer un canal de notification (email)
gcloud alpha monitoring channels create \
  --display-name="Email Alerts" \
  --type=email \
  --channel-labels=email_address=admin@tshiakani-vtc.com

# Associer le canal aux alertes (via la console GCP ou via les scripts)
# Les scripts gcp-create-alerts.sh devraient déjà configurer les notifications
```

**Vérifications** :
- [ ] Canal de notification créé
- [ ] Canal associé aux alertes
- [ ] Notifications reçues en cas d'alerte

**⏱️ Temps estimé** : 5-10 minutes

### Action 5.5 : Créer les Tableaux de Bord

```bash
# Exécuter le script de création des tableaux de bord
chmod +x scripts/gcp-create-dashboard.sh
./scripts/gcp-create-dashboard.sh

# Vérifier les tableaux de bord
gcloud monitoring dashboards list \
  --project=tshiakani-vtc
```

**Vérifications** :
- [ ] Tableaux de bord créés
- [ ] Métriques visibles dans les tableaux de bord
- [ ] Tableaux de bord accessibles via la console GCP

**⏱️ Temps estimé** : 5-10 minutes

### Action 5.6 : Tester les Alertes

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
- [ ] Métrique d'erreur enregistrée
- [ ] Alerte déclenchée (si seuil dépassé)
- [ ] Notification envoyée

**⏱️ Temps estimé** : 2-3 minutes

---

## 🎯 Résumé de l'Ordre d'Exécution

### Ordre Chronologique

1. **Étape 0** : Vérification des prérequis (5-10 minutes)
2. **Étape 1** : Créer et configurer Cloud SQL (10-15 minutes)
3. **Étape 2** : Créer et configurer Memorystore (15-25 minutes)
4. **Étape 3** : Déployer le backend sur Cloud Run (20-30 minutes)
5. **Étape 4** : Configurer Google Maps et FCM (20-30 minutes)
6. **Étape 5** : Configurer le monitoring (15-25 minutes)

### Temps Total Estimé

**Temps total** : 85-135 minutes (1h30 - 2h15)

### Points d'Attention

- **Cloud SQL** : La création de l'instance peut prendre 5-10 minutes
- **Memorystore** : La création de l'instance peut prendre 10-15 minutes
- **Cloud Run** : Le déploiement peut prendre 5-10 minutes
- **Google Maps** : La configuration de la clé API peut prendre 5-10 minutes
- **Firebase** : La configuration de FCM peut prendre 10-15 minutes

---

## ✅ Checklist Globale

### Étape 0 : Prérequis
- [ ] gcloud installé et configuré
- [ ] Docker installé
- [ ] APIs activées

### Étape 1 : Cloud SQL
- [ ] Instance Cloud SQL créée
- [ ] Base de données initialisée
- [ ] Tables créées
- [ ] Test d'inscription réussi

### Étape 2 : Redis
- [ ] Instance Memorystore créée
- [ ] VPC Connector configuré
- [ ] Connexion Redis fonctionnelle

### Étape 3 : Cloud Run
- [ ] Image Docker buildée
- [ ] Image poussée vers Artifact Registry
- [ ] Service Cloud Run déployé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées
- [ ] Endpoints API fonctionnels

### Étape 4 : Google Maps & FCM
- [ ] APIs Google Maps activées
- [ ] Clé API configurée
- [ ] Firebase configuré
- [ ] Test de calcul d'itinéraire réussi

### Étape 5 : Monitoring
- [ ] Cloud Logging configuré
- [ ] Cloud Monitoring configuré
- [ ] Alertes créées
- [ ] Notifications configurées
- [ ] Tableaux de bord créés
- [ ] Test d'alerte réussi

---

## 📚 Documentation de Référence

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore
- `GCP_SETUP_ETAPE4.md` - Cloud Run
- `GCP_SETUP_ETAPE5.md` - Monitoring

### Guides de Déploiement
- `GCP_PROCHAINES_ACTIONS.md` - Guide détaillé des actions
- `GCP_CHECKLIST_RAPIDE.md` - Checklist rapide
- `GCP_5_ETAPES_DEPLOIEMENT.md` - Vue d'ensemble des 5 étapes

---

## 🚨 En Cas d'Erreur

### Erreur : Instance Cloud SQL non créée
```bash
# Vérifier les logs
gcloud sql operations list --instance=tshiakani-vtc-db

# Vérifier les quotas
gcloud compute project-info describe --project=tshiakani-vtc
```

### Erreur : Instance Memorystore non créée
```bash
# Vérifier les logs
gcloud redis instances describe tshiakani-vtc-redis --region=us-central1

# Vérifier les quotas
gcloud compute project-info describe --project=tshiakani-vtc
```

### Erreur : Déploiement Cloud Run échoué
```bash
# Vérifier les logs
gcloud run services describe tshiakani-vtc-backend --region=us-central1

# Vérifier les logs de build
gcloud builds list --limit=5
```

### Erreur : Connexion Redis échouée
```bash
# Vérifier le VPC Connector
gcloud compute networks vpc-access connectors list --region=us-central1

# Vérifier les règles de firewall
gcloud compute firewall-rules list
```

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide d'ordre d'exécution pour le déploiement

