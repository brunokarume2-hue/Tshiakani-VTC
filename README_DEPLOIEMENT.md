# 🚀 Guide de Déploiement - Tshiakani VTC

## 📋 Vue d'ensemble

Ce projet est maintenant **prêt pour le déploiement** sur Firebase et Google Cloud Platform (GCP). Tous les fichiers de configuration nécessaires ont été créés et structurés.

## ✅ Ce qui a été préparé

### 1. Configuration Firebase
- ✅ `.firebaserc` - Configuration du projet Firebase
- ✅ `firebase.json` - Configuration Firebase Hosting et Functions
- ✅ Documentation complète dans `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md`

### 2. Configuration GCP
- ✅ `backend/Dockerfile` - Image Docker pour Cloud Run
- ✅ `backend/app.yaml` - Configuration pour App Engine
- ✅ `backend/cloudbuild.yaml` - Configuration pour Cloud Build
- ✅ `backend/.dockerignore` - Fichiers à ignorer pour Docker
- ✅ `backend/.gcloudignore` - Fichiers à ignorer pour GCP

### 3. Variables d'environnement
- ✅ `backend/ENV.example` - Template des variables d'environnement
- ✅ `backend/CONFIGURATION_VARIABLES_ENV.md` - Documentation complète

### 4. Scripts de déploiement
- ✅ `backend/scripts/setup-gcp.sh` - Configuration initiale GCP
- ✅ `backend/scripts/deploy-cloud-run.sh` - Déploiement sur Cloud Run
- ✅ `backend/scripts/deploy-app-engine.sh` - Déploiement sur App Engine
- ✅ `scripts/deploy-firebase.sh` - Déploiement sur Firebase Hosting

### 5. Documentation
- ✅ `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md` - Guide complet de déploiement
- ✅ `CHECKLIST_DEPLOIEMENT.md` - Checklist de déploiement
- ✅ `DEPLOIEMENT_FIREBASE_GCP_RESUME.md` - Résumé des fichiers créés

## 🚀 Démarrage rapide

### Étape 1: Configuration Firebase

1. Créer un projet Firebase: `tshiakani-vtc`
2. Configurer Firebase Authentication (Phone)
3. Configurer Firestore Database
4. Ajouter l'application iOS (Bundle ID: `com.bruno.tshiakaniVTC`)
5. Télécharger `GoogleService-Info.plist` et l'ajouter au projet Xcode

### Étape 2: Configuration GCP

```bash
# Installer Google Cloud SDK
brew install google-cloud-sdk  # macOS

# S'authentifier
gcloud auth login
gcloud config set project tshiakani-vtc

# Configuration initiale
cd backend
./scripts/setup-gcp.sh
```

### Étape 3: Déploiement Backend

**Option A: Cloud Run (Recommandé)**
```bash
cd backend
./scripts/deploy-cloud-run.sh
```

**Option B: App Engine**
```bash
cd backend
./scripts/deploy-app-engine.sh
```

### Étape 4: Déploiement Dashboard

```bash
./scripts/deploy-firebase.sh
```

## 📚 Documentation détaillée

Pour des instructions détaillées, consultez:
- **Guide complet**: `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md`
- **Checklist**: `CHECKLIST_DEPLOIEMENT.md`
- **Variables d'environnement**: `backend/CONFIGURATION_VARIABLES_ENV.md`

## 🔒 Sécurité

### Fichiers à ne pas commiter

Les fichiers suivants sont déjà dans `.gitignore`:
- `backend/.env` - Variables d'environnement
- `backend/config/firebase-service-account.json` - Credentials Firebase
- `Tshiakani VTC/GoogleService-Info.plist` - Configuration Firebase iOS (optionnel)

### Utiliser Secret Manager

Pour la production, utilisez GCP Secret Manager au lieu de variables d'environnement en texte clair:

```bash
# Créer un secret
echo -n "secret-value" | gcloud secrets create secret-name --data-file=-

# Utiliser dans Cloud Run
gcloud run deploy service-name \
  --set-secrets "SECRET_NAME=secret-name:latest"
```

## 📝 Prochaines étapes

1. **Configurer Firebase**
   - Créer le projet Firebase
   - Configurer Authentication et Firestore
   - Télécharger `GoogleService-Info.plist`

2. **Configurer GCP**
   - Créer le projet GCP
   - Exécuter le script de configuration
   - Créer les secrets dans Secret Manager

3. **Déployer le Backend**
   - Choisir entre Cloud Run ou App Engine
   - Déployer avec les scripts fournis

4. **Déployer le Dashboard**
   - Build le dashboard
   - Déployer sur Firebase Hosting

5. **Configurer l'application iOS**
   - Ajouter `GoogleService-Info.plist`
   - Configurer l'URL de l'API
   - Tester l'application

## ✅ Checklist

Suivez la checklist complète dans `CHECKLIST_DEPLOIEMENT.md` pour vérifier que tout est configuré correctement.

## 🆘 Support

En cas de problème:
1. Consultez `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md`
2. Vérifiez les logs: `gcloud run services logs read tshiakani-vtc-api`
3. Vérifiez les variables d'environnement
4. Vérifiez la configuration Firebase/GCP

## 📦 Structure du projet

```
Tshiakani VTC/
├── .firebaserc                    # Configuration Firebase
├── firebase.json                  # Configuration Firebase Hosting/Functions
├── GUIDE_DEPLOIEMENT_FIREBASE_GCP.md  # Guide complet
├── CHECKLIST_DEPLOIEMENT.md       # Checklist
├── DEPLOIEMENT_FIREBASE_GCP_RESUME.md # Résumé
├── README_DEPLOIEMENT.md          # Ce fichier
├── backend/
│   ├── Dockerfile                 # Image Docker
│   ├── app.yaml                   # Configuration App Engine
│   ├── cloudbuild.yaml            # Configuration Cloud Build
│   ├── ENV.example                # Template variables
│   ├── CONFIGURATION_VARIABLES_ENV.md  # Documentation variables
│   ├── scripts/
│   │   ├── setup-gcp.sh           # Configuration GCP
│   │   ├── deploy-cloud-run.sh    # Déploiement Cloud Run
│   │   └── deploy-app-engine.sh   # Déploiement App Engine
│   └── server.postgres.js         # Serveur (compatible Cloud Run)
└── scripts/
    └── deploy-firebase.sh         # Déploiement Firebase Hosting
```

## 🎉 Prêt pour le déploiement!

Tous les fichiers sont créés et prêts. Suivez le guide `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md` pour les instructions détaillées.

---

**Note**: Assurez-vous de remplir toutes les variables d'environnement avant le déploiement. Utilisez `backend/ENV.example` comme référence.

