# ☁️ Étape 1 : Initialisation et Configuration GCP

## 🎯 Objectif

Configurer Google Cloud Platform pour déployer Tshiakani VTC avec :
- Cloud Run (backend)
- Cloud SQL (PostgreSQL + PostGIS)
- Memorystore (Redis pour cache)
- Google Maps Platform (Routes, Places, Geocoding)

---

## 📋 Prérequis

1. **Compte Google Cloud Platform** avec facturation activée
2. **gcloud CLI** installé et configuré
3. **Permissions** pour créer des projets et activer des APIs

---

## 🚀 Étapes d'Initialisation

### 1. Installer Google Cloud CLI

#### Sur macOS
```bash
# Installer via Homebrew
brew install google-cloud-sdk

# Ou télécharger depuis: https://cloud.google.com/sdk/docs/install
```

#### Vérifier l'installation
```bash
gcloud --version
```

### 2. Se connecter à GCP

```bash
# Se connecter à votre compte Google
gcloud auth login

# Configurer le compte par défaut
gcloud config set account VOTRE_EMAIL@gmail.com
```

### 3. Créer un Projet GCP

```bash
# Définir les variables d'environnement
export PROJECT_ID="tshiakani-vtc"
export REGION="us-central1"  # ou "europe-west1" pour l'Europe
export BILLING_ACCOUNT_ID="VOTRE_BILLING_ACCOUNT_ID"

# Créer le projet
gcloud projects create $PROJECT_ID \
  --name="Tshiakani VTC" \
  --labels=environment=production,team=backend

# Définir le projet actif
gcloud config set project $PROJECT_ID

# Lier le compte de facturation (OBLIGATOIRE)
gcloud billing projects link $PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT_ID
```

**⚠️ Important**: Vous devez obtenir votre `BILLING_ACCOUNT_ID` depuis la console GCP :
1. Aller sur https://console.cloud.google.com/billing
2. Copier l'ID du compte de facturation (format: `XXXXXX-XXXXXX-XXXXXX`)

---

### 4. Activer les APIs Requises

#### Activer toutes les APIs en une fois

```bash
# APIs de base
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com

# Cloud Run API
gcloud services enable run.googleapis.com

# Cloud SQL API
gcloud services enable sqladmin.googleapis.com
gcloud services enable sql-component.googleapis.com

# Memorystore (Redis) API
gcloud services enable redis.googleapis.com

# Google Maps Platform APIs
gcloud services enable routes.googleapis.com
gcloud services enable places.googleapis.com
gcloud services enable geocoding-backend.googleapis.com
gcloud services enable maps-backend.googleapis.com

# APIs supplémentaires utiles
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
```

#### Vérifier les APIs activées

```bash
# Lister toutes les APIs activées
gcloud services list --enabled

# Vérifier une API spécifique
gcloud services list --enabled --filter="name:run.googleapis.com"
```

---

### 5. Configurer Google Maps Platform

#### Créer une Clé API Google Maps

1. **Aller sur Google Cloud Console**
   - https://console.cloud.google.com/apis/credentials

2. **Créer une clé API**
   ```bash
   # Via gcloud CLI
   gcloud alpha services api-keys create \
     --display-name="Tshiakani VTC Maps API Key" \
     --api-target=service=routes.googleapis.com \
     --api-target=service=places.googleapis.com \
     --api-target=service=geocoding-backend.googleapis.com
   ```

3. **Restreindre la clé API** (Recommandé pour la production)
   - **Restrictions d'application** : iOS, Android, HTTP referrers
   - **Restrictions d'API** : Routes API, Places API, Geocoding API

4. **Sauvegarder la clé API**
   ```bash
   # Enregistrer dans un fichier sécurisé
   echo "VOTRE_CLE_API_GOOGLE_MAPS" > .env.gcp.maps
   chmod 600 .env.gcp.maps
   ```

---

### 6. Configurer les Permissions IAM

```bash
# Activer l'API IAM si nécessaire
gcloud services enable iam.googleapis.com

# Créer un compte de service pour Cloud Run
gcloud iam service-accounts create tshiakani-vtc-backend \
  --display-name="Tshiakani VTC Backend Service Account" \
  --description="Service account pour le backend Cloud Run"

# Accorder les permissions nécessaires
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/redis.editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role="roles/secretmanager.secretAccessor" \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com"
```

---

### 7. Vérifier la Configuration

```bash
# Vérifier le projet actif
gcloud config get-value project

# Vérifier la facturation
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID

# Vérifier les APIs activées
gcloud services list --enabled --project=$PROJECT_ID

# Vérifier les permissions
gcloud projects get-iam-policy $PROJECT_ID
```

---

## 📝 Variables d'Environnement à Configurer

Créez un fichier `.env.gcp` avec les variables suivantes :

```bash
# GCP Configuration
export GCP_PROJECT_ID="tshiakani-vtc"
export GCP_REGION="us-central1"
export GCP_BILLING_ACCOUNT_ID="VOTRE_BILLING_ACCOUNT_ID"

# Google Maps API
export GOOGLE_MAPS_API_KEY="VOTRE_CLE_API_GOOGLE_MAPS"

# Service Account
export GCP_SERVICE_ACCOUNT="tshiakani-vtc-backend@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
```

---

## 🔍 Vérification Finale

### Checklist de Vérification

- [ ] Projet GCP créé
- [ ] Facturation activée et liée
- [ ] Cloud Run API activée
- [ ] Cloud SQL API activée
- [ ] Memorystore (Redis) API activée
- [ ] Google Maps Platform APIs activées
  - [ ] Routes API
  - [ ] Places API
  - [ ] Geocoding API
- [ ] Clé API Google Maps créée et configurée
- [ ] Compte de service créé
- [ ] Permissions IAM configurées
- [ ] Variables d'environnement définies

### Commandes de Vérification

```bash
# Vérifier le projet
gcloud config get-value project

# Vérifier la facturation
gcloud billing projects describe $(gcloud config get-value project)

# Vérifier les APIs
gcloud services list --enabled | grep -E "run|sql|redis|routes|places|geocoding"

# Vérifier le compte de service
gcloud iam service-accounts list

# Vérifier les permissions
gcloud projects get-iam-policy $(gcloud config get-value project) \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tshiakani-vtc-backend@*"
```

---

## 🚨 Dépannage

### Erreur: "Billing account not found"
```bash
# Vérifier les comptes de facturation disponibles
gcloud billing accounts list

# Lier manuellement le compte de facturation
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

### Erreur: "Permission denied"
```bash
# Vérifier les permissions
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:user:VOTRE_EMAIL"

# Demander les permissions nécessaires à l'administrateur du projet
```

### Erreur: "API not enabled"
```bash
# Activer l'API manuellement
gcloud services enable NOM_DE_L_API.googleapis.com

# Vérifier l'état de l'API
gcloud services list --enabled --filter="name:NOM_DE_L_API.googleapis.com"
```

---

## 📚 Ressources Utiles

- **Documentation GCP**: https://cloud.google.com/docs
- **Cloud Run**: https://cloud.google.com/run/docs
- **Cloud SQL**: https://cloud.google.com/sql/docs
- **Memorystore**: https://cloud.google.com/memorystore/docs
- **Google Maps Platform**: https://developers.google.com/maps

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée, vous pouvez passer à :
1. **Étape 2**: Configuration de Cloud SQL (PostgreSQL + PostGIS)
2. **Étape 3**: Configuration de Memorystore (Redis)
3. **Étape 4**: Déploiement du Backend sur Cloud Run
4. **Étape 5**: Configuration du Dashboard Admin

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

