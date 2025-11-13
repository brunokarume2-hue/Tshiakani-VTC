# 🚀 Guide d'Implémentation de l'Architecture Google Cloud

Guide étape par étape pour implémenter l'architecture Google Cloud centralisée pour Tshiakani VTC.

## 📋 Prérequis

- Compte Google Cloud Platform avec facturation activée
- Compte Firebase
- Google Cloud SDK installé
- Node.js 18+ installé
- Git installé

---

## 🎯 Étapes d'Implémentation

### Étape 1: Configuration Google Cloud Storage ✅

**Objectif:** Configurer le stockage de fichiers (permis, cartes grises, assurances)

#### 1.1 Créer le bucket Cloud Storage

```bash
cd backend
chmod +x scripts/setup-cloud-storage.sh
./scripts/setup-cloud-storage.sh
```

Ou manuellement:

```bash
# Activer l'API Cloud Storage
gcloud services enable storage.googleapis.com

# Créer le bucket
gsutil mb -p tshiakani-vtc -l us-central1 -c STANDARD gs://tshiakani-vtc-documents

# Configurer CORS
gsutil cors set backend/config/cors-storage.json gs://tshiakani-vtc-documents

# Activer la versioning
gsutil versioning set on gs://tshiakani-vtc-documents
```

#### 1.2 Installer les dépendances

```bash
cd backend
npm install @google-cloud/storage multer
```

#### 1.3 Configurer les variables d'environnement

Ajoutez dans votre fichier `.env`:

```env
GCP_PROJECT_ID=tshiakani-vtc
GCS_BUCKET_NAME=tshiakani-vtc-documents
GOOGLE_APPLICATION_CREDENTIALS=./config/gcp-service-account.json
```

#### 1.4 Tester l'upload

```bash
# Tester l'endpoint d'upload
curl -X POST http://localhost:3000/api/documents/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test.pdf" \
  -F "documentType=permis" \
  -F "folder=permis"
```

---

### Étape 2: Configuration GitHub Actions ✅

**Objectif:** Automatiser les déploiements avec CI/CD

#### 2.1 Créer un service account pour GitHub Actions

```bash
# Créer un service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account"

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

# Créer une clé JSON
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions@tshiakani-vtc.iam.gserviceaccount.com
```

#### 2.2 Configurer les secrets GitHub

1. Allez dans votre dépôt GitHub > Settings > Secrets and variables > Actions
2. Ajoutez le secret `GCP_SA_KEY` avec le contenu du fichier `github-actions-key.json`

#### 2.3 Tester le workflow

```bash
# Push vers la branche main
git add .
git commit -m "Configure GitHub Actions"
git push origin main
```

Le workflow se déclenchera automatiquement et déploiera sur Cloud Run.

---

### Étape 3: Configuration Cloud Monitoring ❌

**Objectif:** Surveiller l'application et configurer des alertes

#### 3.1 Activer Cloud Monitoring

```bash
# Activer les APIs
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

#### 3.2 Créer des alertes

1. Allez dans [Cloud Console > Monitoring > Alerting](https://console.cloud.google.com/monitoring/alerting)
2. Créez des alertes pour:
   - **Temps de réponse de l'API** (> 2 secondes)
   - **Taux d'erreur HTTP** (> 5%)
   - **Utilisation de la CPU** (> 80%)
   - **Utilisation de la mémoire** (> 80%)
   - **Erreurs de base de données**

#### 3.3 Créer un dashboard

1. Allez dans [Cloud Console > Monitoring > Dashboards](https://console.cloud.google.com/monitoring/dashboards)
2. Créez un nouveau dashboard avec:
   - Graphique du temps de réponse
   - Graphique du taux d'erreur
   - Graphique de l'utilisation des ressources
   - Graphique du nombre de requêtes

#### 3.4 Configurer les logs structurés

Le endpoint `/health` existe déjà. Assurez-vous qu'il fonctionne correctement:

```bash
curl https://your-cloud-run-url.run.app/health
```

---

### Étape 4: Migration vers Secret Manager ⚠️

**Objectif:** Sécuriser les secrets avec Secret Manager

#### 4.1 Créer les secrets

```bash
# JWT Secret
echo -n "your-jwt-secret" | gcloud secrets create jwt-secret --data-file=-

# Admin API Key
echo -n "your-admin-api-key" | gcloud secrets create admin-api-key --data-file=-

# Database Password
echo -n "your-database-password" | gcloud secrets create database-password --data-file=-

# Stripe Secret Key
echo -n "your-stripe-secret-key" | gcloud secrets create stripe-secret-key --data-file=-
```

#### 4.2 Donner l'accès à Cloud Run

```bash
# Obtenir le service account de Cloud Run
SERVICE_ACCOUNT=$(gcloud run services describe tshiakani-vtc-api \
  --region us-central1 \
  --format 'value(spec.template.spec.serviceAccountName)')

# Donner l'accès aux secrets
gcloud secrets add-iam-policy-binding jwt-secret \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding admin-api-key \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding database-password \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding stripe-secret-key \
  --member="serviceAccount:${SERVICE_ACCOUNT}" \
  --role="roles/secretmanager.secretAccessor"
```

#### 4.3 Mettre à jour Cloud Run

```bash
gcloud run services update tshiakani-vtc-api \
  --region us-central1 \
  --update-secrets="JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest,DB_PASSWORD=database-password:latest,STRIPE_SECRET_KEY=stripe-secret-key:latest"
```

---

## ✅ Checklist de Vérification

### Cloud Storage
- [ ] Bucket créé
- [ ] CORS configuré
- [ ] Permissions IAM configurées
- [ ] Service StorageService implémenté
- [ ] Routes API créées
- [ ] Test d'upload réussi

### GitHub Actions
- [ ] Service account créé
- [ ] Secrets GitHub configurés
- [ ] Workflow créé
- [ ] Déploiement automatique testé

### Cloud Monitoring
- [ ] APIs activées
- [ ] Alertes configurées
- [ ] Dashboard créé
- [ ] Logs structurés implémentés

### Secret Manager
- [ ] Secrets créés
- [ ] Permissions IAM configurées
- [ ] Cloud Run mis à jour
- [ ] Secrets utilisés dans l'application

---

## 🐛 Dépannage

### Erreur d'upload Cloud Storage

```bash
# Vérifier les permissions
gsutil iam get gs://tshiakani-vtc-documents

# Vérifier CORS
gsutil cors get gs://tshiakani-vtc-documents
```

### Erreur GitHub Actions

```bash
# Vérifier les permissions du service account
gcloud projects get-iam-policy tshiakani-vtc \
  --flatten="bindings[].members" \
  --filter="bindings.members:github-actions@tshiakani-vtc.iam.gserviceaccount.com"
```

### Erreur Secret Manager

```bash
# Vérifier l'accès aux secrets
gcloud secrets get-iam-policy jwt-secret
```

---

## 📚 Ressources

- [Documentation Cloud Storage](https://cloud.google.com/storage/docs)
- [Documentation GitHub Actions](https://docs.github.com/en/actions)
- [Documentation Cloud Monitoring](https://cloud.google.com/monitoring/docs)
- [Documentation Secret Manager](https://cloud.google.com/secret-manager/docs)

---

**Date de création:** Novembre 2025  
**Version:** 1.0.0

