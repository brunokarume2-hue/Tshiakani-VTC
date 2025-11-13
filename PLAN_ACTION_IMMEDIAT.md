# 🎯 Plan d'Action Immédiat - Prochaines Étapes

Plan détaillé et actionnable pour finaliser l'implémentation de l'architecture Google Cloud.

## 📋 Vue d'ensemble

### ✅ Ce qui est fait
- ✅ Architecture complètement implémentée
- ✅ Services et routes créés
- ✅ Scripts de configuration prêts
- ✅ Documentation complète
- ✅ CI/CD configuré

### ⚠️ Ce qui reste à faire
1. Installation des dépendances
2. Configuration des variables d'environnement
3. Configuration Cloud Storage (production)
4. Configuration GitHub Actions (optionnel)
5. Tests et vérifications

---

## 🚀 Phase 1: Configuration Locale (5 minutes)

### Étape 1.1: Installer les dépendances

```bash
cd backend
npm install
```

**Vérification:**
```bash
# Vérifier que les packages sont installés
npm list @google-cloud/storage multer
```

### Étape 1.2: Configurer les variables d'environnement

```bash
# Créer le fichier .env s'il n'existe pas
cd backend
if [ ! -f .env ]; then
    cp ENV.example .env
    echo "✅ Fichier .env créé"
else
    echo "⚠️  Fichier .env existe déjà"
fi
```

**Variables minimales à configurer:**

1. **Base de données:**
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=postgres
   DB_PASSWORD=votre_mot_de_passe
   DB_NAME=tshiakani_vtc
   ```

2. **Sécurité:**
   ```env
   JWT_SECRET=$(openssl rand -hex 32)
   ADMIN_API_KEY=$(openssl rand -hex 32)
   ```

3. **Cloud Storage (développement local - optionnel):**
   ```env
   GCP_PROJECT_ID=tshiakani-vtc
   GCS_BUCKET_NAME=tshiakani-vtc-documents
   GOOGLE_APPLICATION_CREDENTIALS=./config/gcp-service-account.json
   ```

### Étape 1.3: Vérifier la configuration locale

```bash
# Vérifier la configuration
./scripts/pre-deploy-check.sh
```

---

## ☁️ Phase 2: Configuration Cloud Storage (10 minutes)

### Étape 2.1: Prérequis

**Vérifier que vous avez:**
- ✅ Compte Google Cloud Platform
- ✅ Projet GCP créé
- ✅ Google Cloud SDK installé
- ✅ Authentification gcloud configurée

### Étape 2.2: Créer le bucket Cloud Storage

```bash
# Option 1: Utiliser le script automatique (recommandé)
cd backend
chmod +x scripts/setup-cloud-storage.sh
./scripts/setup-cloud-storage.sh

# Option 2: Manuellement
gcloud config set project tshiakani-vtc
gsutil mb -p tshiakani-vtc -l us-central1 -c STANDARD gs://tshiakani-vtc-documents
gsutil cors set backend/config/cors-storage.json gs://tshiakani-vtc-documents
gsutil versioning set on gs://tshiakani-vtc-documents
```

### Étape 2.3: Configurer les permissions IAM

```bash
# Donner les permissions au service account Cloud Run
# (À faire après le déploiement sur Cloud Run)
SERVICE_ACCOUNT="tshiakani-vtc@tshiakani-vtc.iam.gserviceaccount.com"
gsutil iam ch serviceAccount:$SERVICE_ACCOUNT:objectAdmin gs://tshiakani-vtc-documents
```

### Étape 2.4: Vérifier la configuration

```bash
# Vérifier que Cloud Storage est configuré
npm run verify:storage
```

---

## 🔄 Phase 3: Configuration CI/CD GitHub Actions (15 minutes)

### Étape 3.1: Créer un service account pour GitHub Actions

```bash
# Créer le service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account" \
  --project=tshiakani-vtc

# Donner les permissions nécessaires
gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding tshiakani-vtc \
  --member="serviceAccount:github-actions@tshiakani-vtc.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### Étape 3.2: Créer la clé JSON

```bash
# Créer la clé JSON
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions@tshiakani-vtc.iam.gserviceaccount.com \
  --project=tshiakani-vtc

# Afficher la clé (à copier dans GitHub Secrets)
cat github-actions-key.json
```

### Étape 3.3: Configurer les secrets GitHub

1. Allez dans votre dépôt GitHub
2. Settings > Secrets and variables > Actions
3. Ajoutez le secret `GCP_SA_KEY` avec le contenu de `github-actions-key.json`

### Étape 3.4: Tester le workflow

```bash
# Commit et push pour déclencher le workflow
git add .
git commit -m "Configure GitHub Actions CI/CD"
git push origin main
```

---

## 🔒 Phase 4: Configuration Secret Manager (10 minutes)

### Étape 4.1: Créer les secrets

```bash
# JWT Secret
echo -n "votre-jwt-secret-ici" | gcloud secrets create jwt-secret \
  --data-file=- \
  --project=tshiakani-vtc

# Admin API Key
echo -n "votre-admin-api-key-ici" | gcloud secrets create admin-api-key \
  --data-file=- \
  --project=tshiakani-vtc

# Database Password
echo -n "votre-database-password-ici" | gcloud secrets create database-password \
  --data-file=- \
  --project=tshiakani-vtc

# Stripe Secret Key (si utilisé)
echo -n "votre-stripe-secret-key-ici" | gcloud secrets create stripe-secret-key \
  --data-file=- \
  --project=tshiakani-vtc
```

### Étape 4.2: Donner l'accès au service account Cloud Run

```bash
# Obtenir le service account de Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(spec.template.spec.serviceAccountName)' \
  --project=tshiakani-vtc)

# Donner l'accès aux secrets
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=tshiakani-vtc

gcloud secrets add-iam-policy-binding admin-api-key \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=tshiakani-vtc

gcloud secrets add-iam-policy-binding database-password \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor" \
  --project=tshiakani-vtc
```

### Étape 4.3: Mettre à jour Cloud Run

```bash
# Mettre à jour Cloud Run pour utiliser les secrets
gcloud run services update tshiakani-vtc-api \
  --region us-central1 \
  --update-secrets="JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest,DB_PASSWORD=database-password:latest" \
  --project=tshiakani-vtc
```

---

## 📊 Phase 5: Configuration Monitoring (10 minutes)

### Étape 5.1: Activer les APIs

```bash
# Activer les APIs Monitoring et Logging
gcloud services enable monitoring.googleapis.com \
  --project=tshiakani-vtc

gcloud services enable logging.googleapis.com \
  --project=tshiakani-vtc
```

### Étape 5.2: Créer des alertes

1. Allez dans [Cloud Console > Monitoring > Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Créez des alertes pour:
   - **Temps de réponse API** (> 2 secondes)
   - **Taux d'erreur HTTP** (> 5%)
   - **Utilisation CPU** (> 80%)
   - **Utilisation mémoire** (> 80%)
   - **Erreurs de base de données**

### Étape 5.3: Créer un dashboard

1. Allez dans [Cloud Console > Monitoring > Dashboards](https://console.cloud.google.com/monitoring/dashboards)
2. Créez un nouveau dashboard avec:
   - Graphique du temps de réponse
   - Graphique du taux d'erreur
   - Graphique de l'utilisation des ressources
   - Graphique du nombre de requêtes

---

## 🧪 Phase 6: Tests et Vérifications (10 minutes)

### Étape 6.1: Tester localement

```bash
# Démarrer le serveur
cd backend
npm start

# Tester le health check
curl http://localhost:3000/health

# Tester l'upload de document (avec token)
curl -X POST http://localhost:3000/api/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.pdf" \
  -F "documentType=permis"
```

### Étape 6.2: Vérifier le déploiement Cloud Run

```bash
# Obtenir l'URL du service
SERVICE_URL=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(status.url)' \
  --project=tshiakani-vtc)

# Tester le health check
curl $SERVICE_URL/health
```

### Étape 6.3: Vérifier les logs

```bash
# Voir les logs Cloud Run
gcloud run services logs read tshiakani-vtc-api \
  --region us-central1 \
  --project=tshiakani-vtc \
  --limit=50
```

---

## ✅ Checklist Complète

### Configuration Locale
- [ ] Dépendances installées (`npm install`)
- [ ] Fichier `.env` créé et configuré
- [ ] Variables d'environnement définies
- [ ] Configuration vérifiée (`./scripts/pre-deploy-check.sh`)

### Cloud Storage
- [ ] Bucket créé
- [ ] CORS configuré
- [ ] Permissions IAM configurées
- [ ] Configuration vérifiée (`npm run verify:storage`)

### CI/CD GitHub Actions
- [ ] Service account créé
- [ ] Permissions configurées
- [ ] Clé JSON créée
- [ ] Secret GitHub configuré
- [ ] Workflow testé

### Secret Manager
- [ ] Secrets créés
- [ ] Permissions IAM configurées
- [ ] Cloud Run mis à jour
- [ ] Secrets utilisés dans l'application

### Monitoring
- [ ] APIs activées
- [ ] Alertes configurées
- [ ] Dashboard créé
- [ ] Logs vérifiés

### Tests
- [ ] Tests locaux réussis
- [ ] Déploiement Cloud Run réussi
- [ ] Health check réussi
- [ ] Upload de documents testé
- [ ] Logs vérifiés

---

## 🎯 Ordre d'exécution recommandé

1. **Phase 1** - Configuration locale (5 min)
2. **Phase 6** - Tests locaux (10 min)
3. **Phase 2** - Cloud Storage (10 min)
4. **Phase 3** - CI/CD GitHub Actions (15 min)
5. **Phase 4** - Secret Manager (10 min)
6. **Phase 5** - Monitoring (10 min)
7. **Phase 6** - Tests finaux (10 min)

**Total estimé: ~70 minutes**

---

## 🚨 Problèmes courants et solutions

### Erreur: "Cloud Storage n'est pas configuré"
- Vérifier que `GCP_PROJECT_ID` est défini
- Vérifier que `GCS_BUCKET_NAME` est défini
- Exécuter `npm run verify:storage`

### Erreur: "Permission denied"
- Vérifier les permissions IAM
- Vérifier que le service account a les rôles nécessaires
- Vérifier les permissions du bucket

### Erreur: "Bucket does not exist"
- Créer le bucket avec `gsutil mb`
- Vérifier que le nom du bucket est correct
- Vérifier que le projet GCP est correct

### Erreur: "Secret does not exist"
- Créer le secret dans Secret Manager
- Vérifier que le nom du secret est correct
- Vérifier les permissions IAM

---

## 📚 Documentation

- **Quick Start:** `QUICK_START.md`
- **Architecture:** `ARCHITECTURE_GOOGLE_CLOUD_CENTRALISEE.md`
- **Implémentation:** `GUIDE_IMPLEMENTATION_ARCHITECTURE.md`
- **Cloud Storage:** `backend/README_STORAGE.md`

---

**Date de création:** Novembre 2025  
**Version:** 1.0.0

