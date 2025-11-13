# 🚀 Guide de Démarrage Rapide GCP

## 📋 Vue d'Ensemble

Ce guide vous permet de configurer rapidement Google Cloud Platform pour Tshiakani VTC.

---

## ⚡ Démarrage Rapide (5 minutes)

### 1. Prérequis

```bash
# Vérifier que gcloud est installé
gcloud --version

# Si non installé sur macOS
brew install google-cloud-sdk

# Se connecter à GCP
gcloud auth login
```

### 2. Configuration Automatique

```bash
# Aller dans le répertoire du projet
cd "/Users/admin/Documents/Tshiakani VTC"

# Exécuter le script de configuration
./scripts/gcp-setup-etape1.sh
```

Le script va :
- ✅ Créer le projet GCP
- ✅ Activer la facturation
- ✅ Activer toutes les APIs nécessaires
- ✅ Créer le compte de service
- ✅ Configurer les permissions IAM

### 3. Configuration Manuelle (Alternative)

Si vous préférez configurer manuellement, suivez les étapes dans `GCP_SETUP_ETAPE1.md`.

---

## 🔧 Configuration des Variables d'Environnement

### 1. Créer le fichier .env.gcp

```bash
# Copier le fichier d'exemple
cp .env.gcp.example .env.gcp

# Éditer le fichier
nano .env.gcp
```

### 2. Remplir les valeurs

```bash
# GCP Configuration
GCP_PROJECT_ID=tshiakani-vtc
GCP_REGION=us-central1
GCP_BILLING_ACCOUNT_ID=VOTRE_BILLING_ACCOUNT_ID

# Google Maps API Key
GOOGLE_MAPS_API_KEY=VOTRE_CLE_API_GOOGLE_MAPS
```

### 3. Charger les variables

```bash
# Charger les variables d'environnement
source .env.gcp

# Vérifier
echo $GCP_PROJECT_ID
```

---

## 🔍 Vérification

### Vérifier la Configuration

```bash
# Exécuter le script de vérification
./scripts/verifier-gcp-setup.sh
```

### Vérification Manuelle

```bash
# Vérifier le projet
gcloud config get-value project

# Vérifier la facturation
gcloud billing projects describe $(gcloud config get-value project)

# Vérifier les APIs
gcloud services list --enabled | grep -E "run|sql|redis|routes|places"

# Vérifier le compte de service
gcloud iam service-accounts list
```

---

## 📝 Créer une Clé API Google Maps

### Via la Console GCP

1. Aller sur https://console.cloud.google.com/apis/credentials
2. Cliquer sur "Créer des identifiants" → "Clé API"
3. Copier la clé API
4. Restreindre la clé (Recommandé) :
   - Restrictions d'application : iOS, Android
   - Restrictions d'API : Routes API, Places API, Geocoding API

### Via gcloud CLI

```bash
# Créer une clé API
gcloud alpha services api-keys create \
  --display-name="Tshiakani VTC Maps API Key" \
  --api-target=service=routes.googleapis.com \
  --api-target=service=places.googleapis.com \
  --api-target=service=geocoding-backend.googleapis.com

# Lister les clés API
gcloud alpha services api-keys list
```

---

## ✅ Checklist de Vérification

- [ ] Projet GCP créé
- [ ] Facturation activée
- [ ] Cloud Run API activée
- [ ] Cloud SQL API activée
- [ ] Memorystore (Redis) API activée
- [ ] Google Maps Platform APIs activées
  - [ ] Routes API
  - [ ] Places API
  - [ ] Geocoding API
- [ ] Clé API Google Maps créée
- [ ] Compte de service créé
- [ ] Permissions IAM configurées
- [ ] Variables d'environnement définies

---

## 🚨 Dépannage

### Erreur: "Billing account not found"

```bash
# Lister les comptes de facturation
gcloud billing accounts list

# Lier le compte de facturation
gcloud billing projects link PROJECT_ID --billing-account=BILLING_ACCOUNT_ID
```

### Erreur: "Permission denied"

```bash
# Vérifier les permissions
gcloud projects get-iam-policy PROJECT_ID

# Demander les permissions à l'administrateur
```

### Erreur: "API not enabled"

```bash
# Activer l'API
gcloud services enable NOM_API.googleapis.com

# Vérifier
gcloud services list --enabled --filter="name:NOM_API.googleapis.com"
```

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée :

1. **Étape 2**: Configuration de Cloud SQL (PostgreSQL + PostGIS)
2. **Étape 3**: Configuration de Memorystore (Redis)
3. **Étape 4**: Déploiement du Backend sur Cloud Run
4. **Étape 5**: Configuration du Dashboard Admin

---

## 📚 Documentation

- **Guide complet**: `GCP_SETUP_ETAPE1.md`
- **Script de configuration**: `scripts/gcp-setup-etape1.sh`
- **Script de vérification**: `scripts/verifier-gcp-setup.sh`
- **Variables d'environnement**: `.env.gcp.example`

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

