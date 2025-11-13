# ⚠️ Problème de Permissions - Déploiement Backend

## 🔍 Problème

Erreur lors du déploiement :
```
ERROR: The user is forbidden from accessing the bucket [tshiakani-vtc-99cea_cloudbuild]
```

**Cause** : Permissions insuffisantes pour utiliser Cloud Build.

---

## ✅ Solutions

### Option 1: Demander les Permissions (Recommandé)

Contactez l'administrateur du projet Google Cloud pour obtenir les rôles suivants :

1. **Cloud Build Service Account** ou **Cloud Build Editor**
2. **Service Usage Admin** (pour utiliser les services)
3. **Cloud Run Admin** (pour déployer sur Cloud Run)
4. **Storage Admin** (pour accéder aux buckets Cloud Build)

### Option 2: Activer les APIs Manuellement

```bash
# Activer Cloud Build API
gcloud services enable cloudbuild.googleapis.com --project=tshiakani-vtc-99cea

# Activer Cloud Run API
gcloud services enable run.googleapis.com --project=tshiakani-vtc-99cea

# Activer Container Registry API
gcloud services enable containerregistry.googleapis.com --project=tshiakani-vtc-99cea
```

### Option 3: Utiliser Google Cloud Console

1. Allez sur https://console.cloud.google.com/
2. Sélectionnez le projet `tshiakani-vtc-99cea`
3. Allez dans **Cloud Build** > **Triggers**
4. Créez un nouveau trigger qui utilise `cloudbuild.yaml`
5. Déclenchez le build manuellement

### Option 4: Utiliser un Compte de Service

Si vous avez accès à un compte de service avec les permissions :

```bash
# Se connecter avec le compte de service
gcloud auth activate-service-account --key-file=/path/to/service-account-key.json

# Puis déployer
./scripts/deploy-cloud-run.sh
```

---

## 🔧 Vérification des Permissions

### Vérifier vos Rôles

```bash
gcloud projects get-iam-policy tshiakani-vtc-99cea \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:VOTRE_EMAIL"
```

### Vérifier les APIs Activées

```bash
gcloud services list --enabled --project=tshiakani-vtc-99cea
```

---

## 📝 Rôles Requis

Pour déployer sur Cloud Run, vous avez besoin de :

1. **Cloud Build Editor** (`roles/cloudbuild.builds.editor`)
2. **Service Usage Consumer** (`roles/serviceusage.serviceUsageConsumer`)
3. **Cloud Run Admin** (`roles/run.admin`)
4. **Storage Admin** (`roles/storage.admin`) - pour Cloud Build

---

## 🚀 Alternative: Déploiement via Console

Si vous n'avez pas les permissions CLI, utilisez Google Cloud Console :

1. **Cloud Build** :
   - Allez dans Cloud Build > Triggers
   - Créez un trigger avec `cloudbuild.yaml`
   - Déclenchez le build

2. **Cloud Run** :
   - Allez dans Cloud Run > Services
   - Créez un nouveau service
   - Utilisez l'image Docker builder

---

**Date** : $(date)
**Statut** : ⚠️ En attente de permissions

