# 🚀 Commencer Maintenant - Déploiement Backend VTC sur GCP

## 📋 Vue d'Ensemble

Ce document présente les **étapes à exécuter dans l'ordre** pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP).

---

## 🎯 Ordre d'Exécution Complet

### ⏱️ Temps Total Estimé : 95-150 minutes (1h35 - 2h30)

---

## ✅ ÉTAPE 1 : Vérifier les Prérequis (5-10 minutes)

### Action 1.1 : Vérifier gcloud

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

**✅ Vérification** : `gcloud --version` doit afficher la version installée

---

### Action 1.2 : Vérifier Docker

```bash
# Vérifier que Docker est installé
docker --version

# Vérifier que Docker fonctionne
docker ps
```

**✅ Vérification** : `docker --version` doit afficher la version installée

---

### Action 1.3 : Activer les APIs GCP

```bash
# Activer toutes les APIs nécessaires
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
gcloud services list --enabled | grep -E "run|sql|redis|routes|places|geocoding|logging|monitoring|secret|artifact"
```

**✅ Vérification** : Toutes les APIs doivent être listées comme activées

---

## ✅ ÉTAPE 2 : Créer Cloud SQL (10-15 minutes)

### Action 2.1 : Créer l'Instance Cloud SQL

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-create-cloud-sql.sh

# Exécuter le script de création
./scripts/gcp-create-cloud-sql.sh

# Attendre que l'instance soit créée (5-10 minutes)
# Vérifier le statut
gcloud sql instances describe tshiakani-vtc-db \
  --project=tshiakani-vtc \
  --format="value(state)"
```

**✅ Vérification** : Le statut doit être `RUNNABLE`

**⏱️ Temps d'attente** : 5-10 minutes

---

### Action 2.2 : Initialiser la Base de Données

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-init-database.sh

# Exécuter le script d'initialisation
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

-- Vérifier l'extension PostGIS
SELECT PostGIS_version();

-- Quitter
\q
```

**✅ Vérification** : Les tables `users` et `rides` doivent être listées

---

## ✅ ÉTAPE 3 : Créer Memorystore Redis (15-25 minutes)

### Action 3.1 : Créer l'Instance Memorystore

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-create-redis.sh

# Exécuter le script de création
./scripts/gcp-create-redis.sh

# Attendre que l'instance soit créée (10-15 minutes)
# Vérifier le statut
gcloud redis instances describe tshiakani-vtc-redis \
  --region=us-central1 \
  --project=tshiakani-vtc \
  --format="value(state)"
```

**✅ Vérification** : Le statut doit être `READY`

**⏱️ Temps d'attente** : 10-15 minutes

---

### Action 3.2 : Créer le VPC Connector

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

**✅ Vérification** : Le VPC Connector doit être listé comme `READY`

**⏱️ Temps d'attente** : 2-5 minutes

---

## ✅ ÉTAPE 4 : Déployer Cloud Run (20-30 minutes)

### Action 4.1 : Build l'Image Docker

```bash
# Aller dans le répertoire backend
cd backend

# Build l'image Docker
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .

# Vérifier que l'image est créée
docker images | grep tshiakani-vtc-backend

# Revenir à la racine du projet
cd ..
```

**✅ Vérification** : L'image doit être listée dans `docker images`

---

### Action 4.2 : Créer Artifact Registry

```bash
# Créer un dépôt Artifact Registry
gcloud artifacts repositories create tshiakani-vtc-repo \
  --repository-format=docker \
  --location=us-central1 \
  --description="Repository pour les images Docker Tshiakani VTC"

# Configurer Docker pour utiliser gcloud comme credential helper
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**✅ Vérification** : Le dépôt doit être créé avec succès

---

### Action 4.3 : Push l'Image Docker

```bash
# Tagger l'image pour Artifact Registry
docker tag gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest

# Push l'image
docker push us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest
```

**✅ Vérification** : L'image doit être poussée avec succès

---

### Action 4.4 : Déployer sur Cloud Run

```bash
# Rendre les scripts exécutables
chmod +x scripts/gcp-deploy-backend.sh
chmod +x scripts/gcp-verify-cloud-run.sh

# Exécuter le script de déploiement
./scripts/gcp-deploy-backend.sh

# Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

**✅ Vérification** : Le service doit être accessible via URL HTTPS

**⏱️ Temps d'attente** : 5-10 minutes

---

### Action 4.5 : Configurer les Variables d'Environnement

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-set-cloud-run-env.sh

# Exécuter le script de configuration
./scripts/gcp-set-cloud-run-env.sh

# Vérifier les variables
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

**✅ Vérification** : Toutes les variables d'environnement doivent être listées

**⚠️ Important** : Vérifier que les variables suivantes sont configurées :
- `DATABASE_URL`
- `INSTANCE_CONNECTION_NAME`
- `REDIS_HOST`
- `REDIS_PORT`
- `JWT_SECRET`
- `GOOGLE_MAPS_API_KEY`
- `FIREBASE_PROJECT_ID`

---

### Action 4.6 : Configurer les Permissions IAM

```bash
# Obtenir le service account Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

# Donner les permissions Cloud SQL
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/cloudsql.client"

# Donner les permissions Logging
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/logging.logWriter"

# Donner les permissions Monitoring
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/monitoring.metricWriter"

# Donner les permissions Secret Manager
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

**✅ Vérification** : Les permissions doivent être ajoutées avec succès

---

## ✅ ÉTAPE 5 : Configurer Google Maps et FCM (20-30 minutes)

### Action 5.1 : Activer les APIs Google Maps

```bash
# Activer les APIs Google Maps (déjà fait à l'étape 1, mais vérifier)
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding.googleapis.com

# Vérifier l'activation
gcloud services list --enabled \
  --filter="name:routes OR name:places OR name:geocoding"
```

**✅ Vérification** : Les APIs doivent être listées comme activées

---

### Action 5.2 : Créer et Configurer la Clé API Google Maps

```bash
# Créer une clé API (via la console GCP)
# 1. Aller sur https://console.cloud.google.com/apis/credentials
# 2. Cliquer sur "Créer des identifiants" > "Clé API"
# 3. Copier la clé API générée

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

**✅ Vérification** : La clé API doit être stockée dans Secret Manager et accessible

**⚠️ Important** : Remplacer `YOUR_GOOGLE_MAPS_API_KEY` par votre clé API réelle

---

### Action 5.3 : Configurer Firebase Cloud Messaging (FCM)

```bash
# Configurer Firebase (via la console Firebase)
# 1. Aller sur https://console.firebase.google.com
# 2. Créer un projet Firebase (ou utiliser un projet existant)
# 3. Activer Cloud Messaging
# 4. Télécharger le fichier de configuration (google-services.json)

# Stocker les credentials Firebase dans Secret Manager
echo -n "YOUR_FIREBASE_PRIVATE_KEY" | \
  gcloud secrets create firebase-private-key \
  --data-file=-

# Donner accès au service account
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(spec.template.spec.serviceAccountName)")

gcloud secrets add-iam-policy-binding firebase-private-key \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

# Mettre à jour les variables d'environnement
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --update-env-vars="FIREBASE_PROJECT_ID=tshiakani-vtc,FIREBASE_PRIVATE_KEY=$(gcloud secrets versions access latest --secret=firebase-private-key)"
```

**✅ Vérification** : Firebase doit être configuré et les credentials stockés

**⚠️ Important** : Remplacer `YOUR_FIREBASE_PRIVATE_KEY` par votre clé privée réelle

---

## ✅ ÉTAPE 6 : Configurer le Monitoring (15-25 minutes)

### Action 6.1 : Configurer Cloud Logging

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-setup-monitoring.sh

# Exécuter le script de configuration
./scripts/gcp-setup-monitoring.sh

# Vérifier les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" \
  --limit=10 \
  --format=json
```

**✅ Vérification** : Les logs doivent être visibles dans Cloud Logging

---

### Action 6.2 : Créer les Alertes

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-create-alerts.sh

# Exécuter le script de création des alertes
./scripts/gcp-create-alerts.sh

# Vérifier les alertes
gcloud alpha monitoring policies list \
  --project=tshiakani-vtc
```

**✅ Vérification** : Les alertes doivent être créées et listées

---

### Action 6.3 : Créer les Tableaux de Bord

```bash
# Rendre le script exécutable
chmod +x scripts/gcp-create-dashboard.sh

# Exécuter le script de création des tableaux de bord
./scripts/gcp-create-dashboard.sh

# Vérifier les tableaux de bord
gcloud monitoring dashboards list \
  --project=tshiakani-vtc
```

**✅ Vérification** : Les tableaux de bord doivent être créés et accessibles

---

## ✅ ÉTAPE 7 : Tester les Fonctionnalités (10-15 minutes)

### Action 7.1 : Tester le Health Check

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --format="value(status.url)")

# Tester le health check
curl $SERVICE_URL/health
```

**✅ Vérification** : La réponse doit être `{"status":"OK",...}`

---

### Action 7.2 : Tester l'Authentification

```bash
# Tester l'inscription
curl -X POST $SERVICE_URL/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "name": "Test User",
    "role": "client"
  }'

# Tester la connexion
curl -X POST $SERVICE_URL/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "code": "123456"
  }'
```

**✅ Vérification** : L'inscription et la connexion doivent réussir

---

### Action 7.3 : Tester la Création de Course

```bash
# Obtenir un token JWT (depuis la réponse de connexion)
TOKEN="YOUR_JWT_TOKEN"

# Tester la création de course
curl -X POST $SERVICE_URL/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
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

**✅ Vérification** : La course doit être créée avec succès

**⚠️ Important** : Remplacer `YOUR_JWT_TOKEN` par le token JWT obtenu lors de la connexion

---

### Action 7.4 : Tester les Alertes

```bash
# Simuler une erreur de paiement
curl -X POST $SERVICE_URL/api/payment/process \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
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

**✅ Vérification** : L'erreur doit être enregistrée et l'alerte déclenchée

---

## 📊 Résumé des Étapes

| Étape | Actions | Temps | Statut |
|-------|---------|-------|--------|
| **1. Prérequis** | Vérifier gcloud, Docker, APIs | 5-10 min | ⏳ |
| **2. Cloud SQL** | Créer instance, initialiser BDD | 10-15 min | ⏳ |
| **3. Memorystore** | Créer instance, VPC Connector | 15-25 min | ⏳ |
| **4. Cloud Run** | Build, push, déployer, configurer | 20-30 min | ⏳ |
| **5. Google Maps** | APIs, clé API, Firebase | 20-30 min | ⏳ |
| **6. Monitoring** | Logging, alertes, dashboards | 15-25 min | ⏳ |
| **7. Tests** | Health check, auth, course | 10-15 min | ⏳ |

**⏱️ Temps total** : 95-150 minutes (1h35 - 2h30)

---

## ✅ Checklist Globale

### Étape 1 : Prérequis
- [ ] gcloud installé et configuré
- [ ] Docker installé
- [ ] APIs activées

### Étape 2 : Cloud SQL
- [ ] Instance Cloud SQL créée
- [ ] Base de données initialisée
- [ ] Tables créées

### Étape 3 : Memorystore
- [ ] Instance Memorystore créée
- [ ] VPC Connector créé

### Étape 4 : Cloud Run
- [ ] Image Docker buildée
- [ ] Service Cloud Run déployé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées

### Étape 5 : Google Maps & FCM
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Firebase configuré

### Étape 6 : Monitoring
- [ ] Cloud Logging configuré
- [ ] Alertes créées
- [ ] Tableaux de bord créés

### Étape 7 : Tests
- [ ] Health check fonctionnel
- [ ] Authentification fonctionnelle
- [ ] Création de course fonctionnelle
- [ ] Alertes fonctionnelles

---

## 🚨 Points d'Attention

### Dépendances
- **Étape 4** nécessite **Étape 2** et **Étape 3**
- **Étape 5** nécessite **Étape 4**
- **Étape 6** nécessite **Étape 4**
- **Étape 7** nécessite **Étape 4**, **Étape 5** et **Étape 6**

### Temps d'Attente
- **Cloud SQL** : 5-10 minutes
- **Memorystore** : 10-15 minutes
- **Cloud Run** : 5-10 minutes
- **VPC Connector** : 2-5 minutes

### Vérifications
- Vérifier chaque étape avant de passer à la suivante
- Vérifier les logs en cas d'erreur
- Vérifier les permissions IAM
- Vérifier les variables d'environnement

---

## 📚 Documentation de Référence

### Guides Complets
- `GCP_PROCHAINES_ETAPES_FINAL.md` - Guide détaillé des prochaines étapes
- `GCP_ORDRE_EXECUTION.md` - Ordre d'exécution
- `GCP_ACTIONS_IMMEDIATES.md` - Actions immédiates
- `GCP_POINTS_ATTENTION.md` - Points d'attention
- `GCP_DEPANNAGE_RAPIDE.md` - Dépannage rapide

### Guides par Étape
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore
- `GCP_SETUP_ETAPE4.md` - Cloud Run
- `GCP_SETUP_ETAPE5.md` - Monitoring

---

## 🎯 Commencer Maintenant

### Première Action : Vérifier les Prérequis

```bash
# 1. Vérifier gcloud
gcloud --version

# 2. Vérifier Docker
docker --version

# 3. Activer les APIs
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com routes.googleapis.com places.googleapis.com geocoding.googleapis.com logging.googleapis.com monitoring.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
```

---

## 🎉 Résumé

### Prochaines Étapes
1. **Vérifier les prérequis** - gcloud, Docker, APIs
2. **Créer Cloud SQL** - Instance et base de données
3. **Créer Memorystore** - Instance Redis
4. **Déployer Cloud Run** - Backend sur Cloud Run
5. **Configurer Google Maps** - APIs et clé API
6. **Configurer FCM** - Firebase Cloud Messaging
7. **Configurer Monitoring** - Logging, alertes, tableaux de bord
8. **Tester les fonctionnalités** - Health check, authentification, création de course

### Temps Total
**95-150 minutes** (1h35 - 2h30)

### Points d'Attention
- Respecter l'ordre d'exécution
- Attendre que les instances soient prêtes
- Vérifier les permissions IAM
- Configurer toutes les variables d'environnement
- Tester chaque fonctionnalité après configuration

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide pour commencer le déploiement maintenant

