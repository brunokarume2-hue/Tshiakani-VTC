# 🚀 Actions Immédiates - Déploiement Backend VTC sur GCP

## 📋 Vue d'Ensemble

Ce document liste les **actions immédiates** à effectuer pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP).

---

## 🎯 Actions Immédiates (À faire maintenant)

### ✅ Étape 1 : Vérifier les Prérequis (5-10 min)

```bash
# 1. Vérifier gcloud
gcloud --version
gcloud config get-value project
gcloud config set project tshiakani-vtc

# 2. Vérifier Docker
docker --version

# 3. Activer les APIs
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com routes.googleapis.com places.googleapis.com geocoding.googleapis.com logging.googleapis.com monitoring.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
```

**Vérifications** :
- [ ] gcloud installé et configuré
- [ ] Docker installé
- [ ] APIs activées

---

### ✅ Étape 2 : Créer Cloud SQL (10-15 min)

```bash
# 1. Créer l'instance Cloud SQL
chmod +x scripts/gcp-create-cloud-sql.sh
./scripts/gcp-create-cloud-sql.sh

# 2. Attendre que l'instance soit créée (5-10 minutes)
gcloud sql instances describe tshiakani-vtc-db --format="value(state)"

# 3. Initialiser la base de données
chmod +x scripts/gcp-init-database.sh
./scripts/gcp-init-database.sh
```

**Vérifications** :
- [ ] Instance Cloud SQL créée
- [ ] Base de données initialisée
- [ ] Tables créées

---

### ✅ Étape 3 : Créer Memorystore (15-25 min)

```bash
# 1. Créer l'instance Memorystore
chmod +x scripts/gcp-create-redis.sh
./scripts/gcp-create-redis.sh

# 2. Attendre que l'instance soit créée (10-15 minutes)
gcloud redis instances describe tshiakani-vtc-redis --region=us-central1 --format="value(state)"

# 3. Créer le VPC Connector
gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28
```

**Vérifications** :
- [ ] Instance Memorystore créée
- [ ] VPC Connector créé

---

### ✅ Étape 4 : Déployer Cloud Run (20-30 min)

```bash
# 1. Build l'image Docker
cd backend
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .
cd ..

# 2. Créer Artifact Registry
gcloud artifacts repositories create tshiakani-vtc-repo \
  --repository-format=docker \
  --location=us-central1

# 3. Configurer Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# 4. Push l'image
docker tag gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest
docker push us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest

# 5. Déployer sur Cloud Run
chmod +x scripts/gcp-deploy-backend.sh
./scripts/gcp-deploy-backend.sh

# 6. Configurer les variables d'environnement
chmod +x scripts/gcp-set-cloud-run-env.sh
./scripts/gcp-set-cloud-run-env.sh

# 7. Configurer les permissions IAM
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(spec.template.spec.serviceAccountName)")
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/cloudsql.client"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/monitoring.metricWriter"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
```

**Vérifications** :
- [ ] Image Docker buildée
- [ ] Service Cloud Run déployé
- [ ] Variables d'environnement configurées
- [ ] Permissions IAM configurées

---

### ✅ Étape 5 : Configurer Google Maps & FCM (20-30 min)

```bash
# 1. Activer les APIs Google Maps (déjà fait, mais vérifier)
gcloud services enable routes.googleapis.com places.googleapis.com geocoding.googleapis.com

# 2. Créer la clé API Google Maps (via console GCP)
# Aller sur https://console.cloud.google.com/apis/credentials

# 3. Stocker la clé dans Secret Manager
echo -n "YOUR_GOOGLE_MAPS_API_KEY" | gcloud secrets create google-maps-api-key --data-file=-

# 4. Donner accès au service account
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(spec.template.spec.serviceAccountName)")
gcloud secrets add-iam-policy-binding google-maps-api-key --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"

# 5. Configurer Firebase (via console Firebase)
# Aller sur https://console.firebase.google.com
```

**Vérifications** :
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Firebase configuré

---

### ✅ Étape 6 : Configurer le Monitoring (15-25 min)

```bash
# 1. Configurer Cloud Logging
chmod +x scripts/gcp-setup-monitoring.sh
./scripts/gcp-setup-monitoring.sh

# 2. Créer les alertes
chmod +x scripts/gcp-create-alerts.sh
./scripts/gcp-create-alerts.sh

# 3. Créer les tableaux de bord
chmod +x scripts/gcp-create-dashboard.sh
./scripts/gcp-create-dashboard.sh
```

**Vérifications** :
- [ ] Cloud Logging configuré
- [ ] Alertes créées
- [ ] Tableaux de bord créés

---

### ✅ Étape 7 : Tester les Fonctionnalités (10-15 min)

```bash
# 1. Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(status.url)")

# 2. Tester le health check
curl $SERVICE_URL/health

# 3. Tester l'authentification
curl -X POST $SERVICE_URL/api/auth/signup -H "Content-Type: application/json" -d '{"phoneNumber": "+243900000001", "name": "Test", "role": "client"}'

# 4. Tester la création de course
curl -X POST $SERVICE_URL/api/ride/request -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -d '{"pickupLocation": {"latitude": -4.3276, "longitude": 15.3363}, "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}}'
```

**Vérifications** :
- [ ] Health check fonctionnel
- [ ] Authentification fonctionnelle
- [ ] Création de course fonctionnelle
- [ ] Alertes fonctionnelles

---

## 📊 Résumé des Actions

| Étape | Actions | Temps | Priorité |
|-------|---------|-------|----------|
| **1. Prérequis** | Vérifier gcloud, Docker, APIs | 5-10 min | 🔴 Haute |
| **2. Cloud SQL** | Créer instance, initialiser BDD | 10-15 min | 🔴 Haute |
| **3. Memorystore** | Créer instance, VPC Connector | 15-25 min | 🔴 Haute |
| **4. Cloud Run** | Build, push, déployer, configurer | 20-30 min | 🔴 Haute |
| **5. Google Maps** | APIs, clé API, Firebase | 20-30 min | 🔴 Haute |
| **6. Monitoring** | Logging, alertes, dashboards | 15-25 min | 🟡 Moyenne |
| **7. Tests** | Health check, auth, course | 10-15 min | 🟡 Moyenne |

**Temps total** : 95-150 minutes (1h35 - 2h30)

---

## ✅ Checklist Rapide

### Étape 1 : Prérequis
- [ ] gcloud installé
- [ ] Docker installé
- [ ] APIs activées

### Étape 2 : Cloud SQL
- [ ] Instance créée
- [ ] BDD initialisée
- [ ] Tables créées

### Étape 3 : Redis
- [ ] Instance créée
- [ ] VPC Connector créé

### Étape 4 : Cloud Run
- [ ] Image buildée
- [ ] Service déployé
- [ ] Variables configurées
- [ ] Permissions configurées

### Étape 5 : Google Maps
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Firebase configuré

### Étape 6 : Monitoring
- [ ] Logging configuré
- [ ] Alertes créées
- [ ] Dashboards créés

### Étape 7 : Tests
- [ ] Health check OK
- [ ] Authentification OK
- [ ] Création course OK
- [ ] Alertes OK

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

### Vérifications
- Vérifier chaque étape avant de passer à la suivante
- Vérifier les logs en cas d'erreur
- Vérifier les permissions IAM
- Vérifier les variables d'environnement

---

## 📚 Documentation

### Guides Complets
- `GCP_PROCHAINES_ETAPES_FINAL.md` - Guide détaillé des prochaines étapes
- `GCP_ORDRE_EXECUTION.md` - Ordre d'exécution
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

### Action Immédiate 1 : Vérifier les Prérequis
```bash
gcloud --version
gcloud config get-value project
docker --version
```

### Action Immédiate 2 : Activer les APIs
```bash
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com routes.googleapis.com places.googleapis.com geocoding.googleapis.com logging.googleapis.com monitoring.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
```

### Action Immédiate 3 : Créer Cloud SQL
```bash
./scripts/gcp-create-cloud-sql.sh
./scripts/gcp-init-database.sh
```

---

## 🎉 Résumé

### Actions Immédiates
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

### Prochaines Étapes
- Suivre l'ordre d'exécution
- Vérifier chaque étape
- Tester chaque fonctionnalité
- Configurer le monitoring
- Déployer le dashboard admin
- Configurer les applications iOS

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Actions immédiates pour le déploiement

