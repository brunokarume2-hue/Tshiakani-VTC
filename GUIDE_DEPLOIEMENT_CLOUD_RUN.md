# 🚀 Guide de Déploiement - Backend sur Cloud Run

## 📋 Prérequis

1. **Google Cloud CLI (gcloud)** installé
2. **Projet Google Cloud** configuré (`tshiakani-vtc`)
3. **Authentification** Google Cloud configurée
4. **Permissions** pour déployer sur Cloud Run

---

## 🔧 Option 1: Déploiement Automatique (Recommandé)

### Étape 1: Installer Google Cloud CLI

Si gcloud n'est pas installé :

```bash
# macOS
brew install google-cloud-sdk

# Ou télécharger depuis
# https://cloud.google.com/sdk/docs/install
```

### Étape 2: Se Connecter à Google Cloud

```bash
# Se connecter
gcloud auth login

# Configurer le projet
gcloud config set project tshiakani-vtc
```

### Étape 3: Exécuter le Script de Déploiement

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Exécuter le script
./SCRIPT_DEPLOIEMENT_COMPLET.sh
```

Le script va :
1. ✅ Vérifier la configuration
2. ✅ Builder l'image Docker
3. ✅ Déployer sur Cloud Run
4. ✅ Configurer les variables d'environnement
5. ✅ Tester la route admin/login

---

## 🔧 Option 2: Déploiement Manuel

### Étape 1: Builder l'Image Docker

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Builder l'image
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api --timeout=1200s
```

### Étape 2: Déployer sur Cloud Run

```bash
# Variables d'environnement
JWT_SECRET="ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"
ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"

# Déployer
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
  --set-env-vars "NODE_ENV=production,PORT=8080,JWT_SECRET=${JWT_SECRET},ADMIN_API_KEY=${ADMIN_API_KEY},CORS_ORIGIN=${CORS_ORIGIN}"
```

### Étape 3: Obtenir l'URL du Service

```bash
# Obtenir l'URL
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(status.url)"
```

### Étape 4: Tester la Route

```bash
# Tester la route admin/login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

---

## 🔧 Option 3: Déploiement via Google Cloud Console

### Étape 1: Utiliser Cloud Build

1. Allez dans [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez le projet `tshiakani-vtc`
3. Allez dans **Cloud Build** > **Triggers**
4. Cliquez sur **Créer un trigger**
5. Configurez le trigger pour utiliser `cloudbuild.yaml`

### Étape 2: Déclencher le Build

1. Cliquez sur **Exécuter** sur le trigger
2. Attendez que le build se termine
3. Vérifiez que le service est déployé sur Cloud Run

---

## ⚙️ Variables d'Environnement Requises

Les variables d'environnement suivantes doivent être configurées :

- `NODE_ENV=production`
- `PORT=8080`
- `JWT_SECRET` : Clé secrète JWT
- `ADMIN_API_KEY` : Clé API Admin
- `CORS_ORIGIN` : URLs autorisées (Firebase)
- `DATABASE_URL` : URL de connexion PostgreSQL (si utilisée)

---

## 🔍 Vérification

### Vérifier le Health Check

```bash
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
```

**Résultat attendu** : `{"status":"ok",...}`

### Vérifier la Route Admin Login

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** : Token JWT et informations utilisateur

### Vérifier les Logs

```bash
# Voir les logs du service
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit=50
```

---

## 🆘 Dépannage

### Erreur: "gcloud not found"

**Solution** : Installer Google Cloud CLI
```bash
# macOS
brew install google-cloud-sdk

# Ou depuis
# https://cloud.google.com/sdk/docs/install
```

### Erreur: "Permission denied"

**Solution** : Vérifier les permissions
```bash
# Vérifier les permissions
gcloud projects get-iam-policy tshiakani-vtc

# Se connecter
gcloud auth login
```

### Erreur: "Image build failed"

**Solution** : Vérifier le Dockerfile
```bash
# Tester le build localement
docker build -t test-image .

# Vérifier les erreurs
docker build -t test-image . 2>&1 | grep -i error
```

### Erreur: "Route not found"

**Solution** : Vérifier que les routes sont montées
```bash
# Vérifier dans server.postgres.js
grep -n "app.use.*auth" server.postgres.js

# Vérifier que la route existe
grep -n "admin/login" routes.postgres/auth.js
```

---

## 📝 Checklist

- [ ] Google Cloud CLI installé
- [ ] Authentification Google Cloud configurée
- [ ] Projet configuré (`tshiakani-vtc`)
- [ ] Code vérifié (routes existent)
- [ ] Dockerfile vérifié
- [ ] Image Docker builder
- [ ] Service déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Health check fonctionne
- [ ] Route admin/login fonctionne
- [ ] Dashboard peut se connecter

---

**Date** : $(date)

