# 🚀 Guide d'Exécution Rapide - Actions Suivantes

## 📋 Vue d'Ensemble

Ce guide vous permet d'exécuter **toutes les actions suivantes** pour déployer le backend Tshiakani VTC sur Google Cloud Platform (GCP).

---

## 🎯 Méthode 1 : Exécution Automatique (Recommandée)

### Utiliser le Script Maître

Le script `executer-actions-suivantes.sh` exécute toutes les actions dans l'ordre, avec des vérifications à chaque étape.

```bash
# Exécuter le script maître
./scripts/executer-actions-suivantes.sh
```

**Avantages** :
- ✅ Exécution automatique de toutes les étapes
- ✅ Vérifications à chaque étape
- ✅ Gestion des erreurs
- ✅ Pauses pour confirmation
- ✅ Logs détaillés

**⏱️ Temps** : 95-150 minutes (1h35 - 2h30)

---

## 🎯 Méthode 2 : Exécution Manuelle

Si vous préférez exécuter les actions manuellement, suivez les étapes ci-dessous.

### ✅ Action 1 : Vérifier les Prérequis

```bash
# Vérifier gcloud
gcloud --version
gcloud config get-value project
gcloud config set project tshiakani-vtc

# Vérifier Docker
docker --version

# Activer les APIs
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com routes.googleapis.com places.googleapis.com geocoding.googleapis.com logging.googleapis.com monitoring.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
```

**⏱️ Temps** : 5-10 minutes

---

### ✅ Action 2 : Créer Cloud SQL

```bash
# Créer l'instance Cloud SQL
chmod +x scripts/gcp-create-cloud-sql.sh
./scripts/gcp-create-cloud-sql.sh

# Attendre que l'instance soit créée (5-10 minutes)
gcloud sql instances wait tshiakani-vtc-db --timeout=600

# Initialiser la base de données
chmod +x scripts/gcp-init-database.sh
./scripts/gcp-init-database.sh
```

**⏱️ Temps** : 10-15 minutes

---

### ✅ Action 3 : Créer Memorystore Redis

```bash
# Créer l'instance Memorystore
chmod +x scripts/gcp-create-redis.sh
./scripts/gcp-create-redis.sh

# Attendre que l'instance soit créée (10-15 minutes)
while true; do
    STATE=$(gcloud redis instances describe tshiakani-vtc-redis --region=us-central1 --format="value(state)" 2>/dev/null || echo "CREATING")
    echo "État: $STATE"
    if [ "$STATE" = "READY" ]; then
        break
    fi
    sleep 30
done

# Créer le VPC Connector
gcloud compute networks vpc-access connectors create tshiakani-vtc-connector \
  --region=us-central1 \
  --network=default \
  --range=10.8.0.0/28
```

**⏱️ Temps** : 15-25 minutes

---

### ✅ Action 4 : Déployer Cloud Run

```bash
# Build l'image Docker
cd backend
docker build -t gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest .
cd ..

# Créer Artifact Registry
gcloud artifacts repositories create tshiakani-vtc-repo \
  --repository-format=docker \
  --location=us-central1

# Configurer Docker
gcloud auth configure-docker us-central1-docker.pkg.dev

# Tag et push l'image
docker tag gcr.io/tshiakani-vtc/tshiakani-vtc-backend:latest \
  us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest
docker push us-central1-docker.pkg.dev/tshiakani-vtc/tshiakani-vtc-repo/tshiakani-vtc-backend:latest

# Déployer sur Cloud Run
chmod +x scripts/gcp-deploy-backend.sh
./scripts/gcp-deploy-backend.sh

# Configurer les variables d'environnement
chmod +x scripts/gcp-set-cloud-run-env.sh
./scripts/gcp-set-cloud-run-env.sh

# Configurer les permissions IAM
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(spec.template.spec.serviceAccountName)")
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/cloudsql.client"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/logging.logWriter"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/monitoring.metricWriter"
gcloud projects add-iam-policy-binding tshiakani-vtc --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"
```

**⏱️ Temps** : 20-30 minutes

---

### ✅ Action 5 : Configurer Google Maps et FCM

```bash
# Activer les APIs Google Maps
gcloud services enable routes.googleapis.com places.googleapis.com geocoding.googleapis.com

# Créer la clé API Google Maps (via console GCP)
# 1. Aller sur https://console.cloud.google.com/apis/credentials
# 2. Créer une clé API
# 3. Copier la clé API

# Stocker la clé dans Secret Manager
echo -n "YOUR_GOOGLE_MAPS_API_KEY" | gcloud secrets create google-maps-api-key --data-file=-

# Donner accès au service account
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(spec.template.spec.serviceAccountName)")
gcloud secrets add-iam-policy-binding google-maps-api-key --member="serviceAccount:${SERVICE_ACCOUNT}" --role="roles/secretmanager.secretAccessor"

# Mettre à jour la variable d'environnement
gcloud run services update tshiakani-vtc-backend --region=us-central1 \
  --update-env-vars="GOOGLE_MAPS_API_KEY=$(gcloud secrets versions access latest --secret=google-maps-api-key)"

# Configurer Firebase (via console Firebase)
# 1. Aller sur https://console.firebase.google.com
# 2. Créer un projet Firebase
# 3. Activer Cloud Messaging (FCM)
# 4. Télécharger le fichier de configuration
# 5. Placer le fichier dans backend/firebase-service-account.json
```

**⏱️ Temps** : 20-30 minutes

---

### ✅ Action 6 : Configurer le Monitoring

```bash
# Configurer Cloud Logging
chmod +x scripts/gcp-setup-monitoring.sh
./scripts/gcp-setup-monitoring.sh

# Créer les alertes
chmod +x scripts/gcp-create-alerts.sh
./scripts/gcp-create-alerts.sh

# Créer les tableaux de bord
chmod +x scripts/gcp-create-dashboard.sh
./scripts/gcp-create-dashboard.sh
```

**⏱️ Temps** : 15-25 minutes

---

### ✅ Action 7 : Tester les Fonctionnalités

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-backend --region=us-central1 --format="value(status.url)")

# Tester le health check
curl $SERVICE_URL/health

# Tester l'authentification
curl -X POST $SERVICE_URL/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001", "name": "Test User", "role": "client"}'

# Tester la création de course
curl -X POST $SERVICE_URL/api/ride/request \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"pickupLocation": {"latitude": -4.3276, "longitude": 15.3363}, "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}}'
```

**⏱️ Temps** : 10-15 minutes

---

## 📊 Résumé des Actions

| Action | Temps | Priorité | Dépendances |
|--------|-------|----------|-------------|
| **1. Prérequis** | 5-10 min | 🔴 Haute | Aucune |
| **2. Cloud SQL** | 10-15 min | 🔴 Haute | Aucune |
| **3. Memorystore** | 15-25 min | 🔴 Haute | Aucune |
| **4. Cloud Run** | 20-30 min | 🔴 Haute | 2, 3 |
| **5. Google Maps** | 20-30 min | 🔴 Haute | 4 |
| **6. Monitoring** | 15-25 min | 🟡 Moyenne | 4 |
| **7. Tests** | 10-15 min | 🟡 Moyenne | 4, 5, 6 |

**⏱️ Temps total** : 95-150 minutes (1h35 - 2h30)

---

## ✅ Checklist Rapide

### Action 1 : Prérequis
- [ ] gcloud installé
- [ ] Docker installé
- [ ] APIs activées

### Action 2 : Cloud SQL
- [ ] Instance créée
- [ ] BDD initialisée
- [ ] Tables créées

### Action 3 : Memorystore
- [ ] Instance créée
- [ ] VPC Connector créé

### Action 4 : Cloud Run
- [ ] Image buildée
- [ ] Service déployé
- [ ] Variables configurées
- [ ] Permissions configurées

### Action 5 : Google Maps
- [ ] APIs activées
- [ ] Clé API configurée
- [ ] Firebase configuré

### Action 6 : Monitoring
- [ ] Logging configuré
- [ ] Alertes créées
- [ ] Dashboards créés

### Action 7 : Tests
- [ ] Health check OK
- [ ] Authentification OK
- [ ] Création course OK

---

## 🚨 Points d'Attention

### Dépendances
- **Action 4** nécessite **Action 2** et **Action 3**
- **Action 5** nécessite **Action 4**
- **Action 6** nécessite **Action 4**
- **Action 7** nécessite **Action 4**, **Action 5** et **Action 6**

### Temps d'Attente
- **Cloud SQL** : 5-10 minutes
- **Memorystore** : 10-15 minutes
- **Cloud Run** : 5-10 minutes

### Vérifications
- Vérifier chaque action avant de passer à la suivante
- Vérifier les logs en cas d'erreur
- Vérifier les permissions IAM
- Vérifier les variables d'environnement

---

## 🎯 Commencer Maintenant

### Option 1 : Exécution Automatique (Recommandée)

```bash
# Exécuter le script maître
./scripts/executer-actions-suivantes.sh
```

### Option 2 : Exécution Manuelle

```bash
# Commencer par l'Action 1
gcloud --version
docker --version
gcloud services enable run.googleapis.com sqladmin.googleapis.com redis.googleapis.com routes.googleapis.com places.googleapis.com geocoding.googleapis.com logging.googleapis.com monitoring.googleapis.com secretmanager.googleapis.com artifactregistry.googleapis.com
```

---

## 📚 Documentation

### Guides Principaux
- `ACTIONS_SUIVANTES.md` - Actions suivantes détaillées
- `GCP_COMMENCER_MAINTENANT.md` - Guide pour commencer maintenant
- `GCP_PROCHAINES_ETAPES_FINAL.md` - Guide détaillé des prochaines étapes
- `GCP_ORDRE_EXECUTION.md` - Ordre d'exécution

### Guides de Référence
- `GCP_POINTS_ATTENTION.md` - Points d'attention
- `GCP_DEPANNAGE_RAPIDE.md` - Dépannage rapide
- `GCP_INDEX_DOCUMENTATION.md` - Index de la documentation

---

## 🎉 Résumé

### Actions Suivantes
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
- Vérifier chaque action
- Tester chaque fonctionnalité
- Consulter la documentation en cas de problème

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: Guide d'exécution rapide

