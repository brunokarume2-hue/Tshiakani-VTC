# 🎯 Prochaines Étapes - Guide Final

Guide complet et actionnable pour finaliser l'implémentation de l'architecture Google Cloud.

## ⚡ Démarrage Rapide (1 commande)

Pour configurer automatiquement tout ce qui est possible :

```bash
cd backend
npm run setup
```

Ce script va :
- ✅ Installer les dépendances
- ✅ Créer le fichier `.env`
- ✅ Générer les secrets (JWT_SECRET, ADMIN_API_KEY)
- ✅ Vérifier la configuration
- ✅ Optionnellement configurer Cloud Storage

---

## 📋 Étapes Détaillées

### Étape 1: Configuration Locale (5 minutes)

#### 1.1 Installer les dépendances

```bash
cd backend
npm install
```

#### 1.2 Configurer les variables d'environnement

**Option A: Script automatique (recommandé)**
```bash
npm run setup
```

**Option B: Manuellement**
```bash
# Créer le fichier .env
cp ENV.example .env

# Éditer le fichier .env
nano .env  # ou votre éditeur préféré
```

**Variables minimales à configurer:**
```env
# Base de données (OBLIGATOIRE)
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe_postgres
DB_NAME=tshiakani_vtc

# Sécurité (généré automatiquement par le script)
JWT_SECRET=...  # Généré automatiquement
ADMIN_API_KEY=...  # Généré automatiquement
```

#### 1.3 Vérifier la configuration

```bash
# Vérifier la configuration complète
npm run check

# Vérifier Cloud Storage (optionnel)
npm run verify:storage
```

---

### Étape 2: Tester Localement (5 minutes)

#### 2.1 Démarrer le serveur

```bash
cd backend
npm run dev
```

#### 2.2 Tester les endpoints

```bash
# Health check
curl http://localhost:3000/health

# Devrait retourner:
# {"status":"OK","database":"connected","timestamp":"..."}
```

#### 2.3 Tester l'upload de documents (optionnel)

```bash
# Obtenir un token d'authentification d'abord
# Puis tester l'upload
curl -X POST http://localhost:3000/api/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.pdf" \
  -F "documentType=permis"
```

---

### Étape 3: Configuration Cloud Storage (10 minutes)

#### 3.1 Prérequis

- ✅ Compte Google Cloud Platform
- ✅ Projet GCP créé
- ✅ Google Cloud SDK installé
- ✅ Authentification gcloud configurée

#### 3.2 Créer le bucket

**Option A: Script automatique (recommandé)**
```bash
npm run setup:storage
```

**Option B: Manuellement**
```bash
# Configurer le projet
gcloud config set project tshiakani-vtc

# Créer le bucket
gsutil mb -p tshiakani-vtc -l us-central1 -c STANDARD gs://tshiakani-vtc-documents

# Configurer CORS
gsutil cors set backend/config/cors-storage.json gs://tshiakani-vtc-documents

# Activer la versioning
gsutil versioning set on gs://tshiakani-vtc-documents
```

#### 3.3 Vérifier la configuration

```bash
npm run verify:storage
```

---

### Étape 4: Déploiement sur Cloud Run (15 minutes)

#### 4.1 Préparer le déploiement

```bash
# Vérifier la configuration
npm run check

# S'assurer que tout est prêt
gcloud config set project tshiakani-vtc
```

#### 4.2 Déployer

```bash
# Build et déployer
cd backend
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080
```

#### 4.3 Configurer les variables d'environnement

```bash
# Configurer les variables d'environnement
gcloud run services update tshiakani-vtc-api \
  --region us-central1 \
  --set-env-vars "NODE_ENV=production,PORT=8080" \
  --update-secrets "JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest"
```

#### 4.4 Vérifier le déploiement

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(status.url)')

# Tester
curl $SERVICE_URL/health
```

---

### Étape 5: Configuration CI/CD GitHub Actions (15 minutes)

#### 5.1 Créer le service account

```bash
# Créer le service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account" \
  --project=tshiakani-vtc

# Donner les permissions
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"
```

#### 5.2 Créer la clé JSON

```bash
# Créer la clé
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions@tshiakani-vtc.iam.gserviceaccount.com

# Afficher la clé (à copier dans GitHub Secrets)
cat github-actions-key.json
```

#### 5.3 Configurer GitHub Secrets

1. Allez dans votre dépôt GitHub
2. **Settings > Secrets and variables > Actions**
3. Cliquez sur **New repository secret**
4. Ajoutez le secret `GCP_SA_KEY` avec le contenu de `github-actions-key.json`

#### 5.4 Tester le workflow

```bash
# Commit et push
git add .
git commit -m "Configure CI/CD"
git push origin main

# Le workflow se déclenchera automatiquement
```

---

### Étape 6: Configuration Secret Manager (10 minutes)

#### 6.1 Créer les secrets

```bash
# JWT Secret
echo -n "votre-jwt-secret" | gcloud secrets create jwt-secret --data-file=-

# Admin API Key
echo -n "votre-admin-api-key" | gcloud secrets create admin-api-key --data-file=-

# Database Password
echo -n "votre-database-password" | gcloud secrets create database-password --data-file=-
```

#### 6.2 Donner l'accès au service account

```bash
# Obtenir le service account
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(spec.template.spec.serviceAccountName)')

# Donner l'accès
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"
```

#### 6.3 Mettre à jour Cloud Run

```bash
gcloud run services update tshiakani-vtc-api \
  --region us-central1 \
  --update-secrets="JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest"
```

---

### Étape 7: Configuration Monitoring (10 minutes)

#### 7.1 Activer les APIs

```bash
gcloud services enable monitoring.googleapis.com --project=tshiakani-vtc
gcloud services enable logging.googleapis.com --project=tshiakani-vtc
```

#### 7.2 Créer des alertes

1. Allez dans [Cloud Console > Monitoring > Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Créez des alertes pour:
   - Temps de réponse API (> 2 secondes)
   - Taux d'erreur HTTP (> 5%)
   - Utilisation CPU (> 80%)
   - Utilisation mémoire (> 80%)

#### 7.3 Créer un dashboard

1. Allez dans [Cloud Console > Monitoring > Dashboards](https://console.cloud.google.com/monitoring/dashboards)
2. Créez un nouveau dashboard avec les métriques importantes

---

## ✅ Checklist Complète

### Configuration Locale
- [ ] Dépendances installées (`npm install`)
- [ ] Fichier `.env` créé (`npm run setup`)
- [ ] Variables d'environnement configurées
- [ ] Configuration vérifiée (`npm run check`)
- [ ] Serveur testé localement (`npm run dev`)

### Cloud Storage
- [ ] Bucket créé (`npm run setup:storage`)
- [ ] CORS configuré
- [ ] Permissions IAM configurées
- [ ] Configuration vérifiée (`npm run verify:storage`)

### Déploiement Cloud Run
- [ ] Service déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Health check réussi
- [ ] Logs vérifiés

### CI/CD GitHub Actions
- [ ] Service account créé
- [ ] Permissions configurées
- [ ] Secret GitHub configuré
- [ ] Workflow testé

### Secret Manager
- [ ] Secrets créés
- [ ] Permissions IAM configurées
- [ ] Cloud Run mis à jour

### Monitoring
- [ ] APIs activées
- [ ] Alertes configurées
- [ ] Dashboard créé

---

## 🚨 Problèmes Courants

### Erreur: "Cloud Storage n'est pas configuré"
```bash
# Vérifier les variables d'environnement
echo $GCP_PROJECT_ID
echo $GCS_BUCKET_NAME

# Vérifier la configuration
npm run verify:storage
```

### Erreur: "Bucket does not exist"
```bash
# Créer le bucket
npm run setup:storage
```

### Erreur: "Permission denied"
```bash
# Vérifier les permissions
gsutil iam get gs://tshiakani-vtc-documents
```

---

## 📚 Documentation

- **Quick Start:** `QUICK_START.md`
- **Plan d'action:** `PLAN_ACTION_IMMEDIAT.md`
- **Architecture:** `ARCHITECTURE_GOOGLE_CLOUD_CENTRALISEE.md`
- **Implémentation:** `GUIDE_IMPLEMENTATION_ARCHITECTURE.md`
- **Cloud Storage:** `backend/README_STORAGE.md`

---

## 🎉 Résultat Final

Une fois toutes les étapes terminées, vous aurez :

- ✅ Backend déployé sur Cloud Run
- ✅ Cloud Storage configuré
- ✅ CI/CD automatisé
- ✅ Monitoring configuré
- ✅ Sécurité renforcée (Secret Manager)
- ✅ Documentation complète

**Votre architecture Google Cloud est complète et prête pour la production!** 🚀

---

**Date:** Novembre 2025  
**Version:** 1.0.0

