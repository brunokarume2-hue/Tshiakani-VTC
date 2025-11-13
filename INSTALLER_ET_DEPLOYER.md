# 🔧 Installer gcloud et Déployer le Backend

## 📋 Étape 1: Installer Google Cloud CLI

### Option A: Installation via Homebrew (macOS)

```bash
# Installer Homebrew si nécessaire
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer Google Cloud SDK
brew install --cask google-cloud-sdk
```

### Option B: Installation Manuelle

1. **Télécharger Google Cloud SDK** :
   - Allez sur https://cloud.google.com/sdk/docs/install
   - Téléchargez l'installer pour macOS

2. **Installer** :
   ```bash
   # Extraire et installer
   tar -xzf google-cloud-sdk-*.tar.gz
   ./google-cloud-sdk/install.sh
   ```

3. **Ajouter au PATH** :
   ```bash
   # Ajouter à ~/.zshrc ou ~/.bash_profile
   echo 'source ~/google-cloud-sdk/path.bash.inc' >> ~/.zshrc
   echo 'source ~/google-cloud-sdk/completion.bash.inc' >> ~/.zshrc
   source ~/.zshrc
   ```

### Option C: Installation via le Script Officiel

```bash
# Télécharger et exécuter le script d'installation
curl https://sdk.cloud.google.com | bash

# Redémarrer le shell
exec -l $SHELL
```

---

## 📋 Étape 2: Initialiser Google Cloud

```bash
# Se connecter à Google Cloud
gcloud init

# Ou se connecter sans initialiser
gcloud auth login

# Configurer le projet
gcloud config set project tshiakani-vtc
```

---

## 📋 Étape 3: Vérifier l'Installation

```bash
# Vérifier la version
gcloud --version

# Vérifier la configuration
gcloud config list

# Vérifier l'authentification
gcloud auth list
```

---

## 📋 Étape 4: Déployer le Backend

### Option A: Utiliser le Script Automatique

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Exécuter le script de déploiement
./SCRIPT_DEPLOIEMENT_COMPLET.sh
```

### Option B: Déploiement Manuel

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# 1. Builder l'image Docker
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api --timeout=1200s

# 2. Déployer sur Cloud Run
gcloud run deploy tshiakani-driver-backend \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production,PORT=8080,JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab,ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8,CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
```

### Option C: Utiliser Cloud Build (Recommandé pour CI/CD)

1. **Aller dans Google Cloud Console** :
   - Allez sur https://console.cloud.google.com/
   - Sélectionnez le projet `tshiakani-vtc`
   - Allez dans **Cloud Build** > **Triggers**

2. **Créer un nouveau trigger** :
   - Cliquez sur **Créer un trigger**
   - Configurez la source (GitHub, Cloud Source Repositories, etc.)
   - Utilisez le fichier `cloudbuild.yaml`

3. **Déclencher le build** :
   - Cliquez sur **Exécuter** sur le trigger
   - Attendez que le build se termine

---

## 📋 Étape 5: Vérifier le Déploiement

```bash
# Obtenir l'URL du service
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(status.url)"

# Tester le health check
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Tester la route admin/login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

---

## 🆘 Dépannage

### Erreur: "gcloud: command not found"

**Solution** : Vérifier que gcloud est dans le PATH
```bash
# Vérifier où gcloud est installé
which gcloud

# Si non trouvé, ajouter au PATH
export PATH=$PATH:~/google-cloud-sdk/bin
```

### Erreur: "Permission denied"

**Solution** : Vérifier les permissions
```bash
# Vérifier les permissions du projet
gcloud projects get-iam-policy tshiakani-vtc

# Vérifier que vous avez les rôles nécessaires
# - Cloud Run Admin
# - Service Account User
# - Cloud Build Service Account
```

### Erreur: "Project not found"

**Solution** : Vérifier le projet
```bash
# Lister les projets disponibles
gcloud projects list

# Configurer le bon projet
gcloud config set project tshiakani-vtc
```

---

## 📝 Checklist

- [ ] Google Cloud CLI installé
- [ ] Authentification Google Cloud configurée
- [ ] Projet configuré (`tshiakani-vtc`)
- [ ] Permissions vérifiées
- [ ] Code vérifié (routes existent)
- [ ] Dockerfile vérifié
- [ ] Image Docker builder
- [ ] Service déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Health check fonctionne
- [ ] Route admin/login fonctionne

---

**Date** : $(date)

