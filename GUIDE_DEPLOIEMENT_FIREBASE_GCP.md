# 🚀 Guide de Déploiement Firebase/GCP - Tshiakani VTC

Guide complet pour déployer l'application Tshiakani VTC sur Firebase Hosting et Google Cloud Platform (GCP).

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Architecture de déploiement](#architecture-de-déploiement)
3. [I. Configuration Firebase](#i-configuration-firebase)
4. [II. Déploiement Backend sur GCP](#ii-déploiement-backend-sur-gcp)
5. [III. Déploiement Dashboard sur Firebase Hosting](#iii-déploiement-dashboard-sur-firebase-hosting)
6. [IV. Configuration de l'application iOS](#iv-configuration-de-lapplication-ios)
7. [V. Vérification et tests](#v-vérification-et-tests)
8. [VI. Monitoring et maintenance](#vi-monitoring-et-maintenance)

---

## Prérequis

- Compte [Google Cloud Platform](https://cloud.google.com) (avec facturation activée)
- Compte [Firebase](https://firebase.google.com) (gratuit)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installé
- [Firebase CLI](https://firebase.google.com/docs/cli) installé
- Node.js 18+ installé
- Git installé
- Compte développeur Apple (pour l'application iOS)

---

## Architecture de déploiement

```
┌─────────────────────────────────────────────────────────────┐
│                     Tshiakani VTC                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────┐  │
│  │   iOS App    │──────│  Backend API │──────│  Cloud   │  │
│  │  (Firebase)  │      │  (Cloud Run) │      │   SQL    │  │
│  └──────────────┘      └──────────────┘      └──────────┘  │
│         │                      │                             │
│         │                      │                             │
│  ┌──────────────┐      ┌──────────────┐                    │
│  │   Firebase   │      │  Firebase    │                    │
│  │   Auth &     │      │  Hosting     │                    │
│  │  Firestore   │      │ (Dashboard)  │                    │
│  └──────────────┘      └──────────────┘                    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## I. Configuration Firebase

### Étape 1: Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur **"Ajouter un projet"** ou **"Add project"**
3. Nom du projet: `tshiakani-vtc`
4. Activez Google Analytics (optionnel mais recommandé)
5. Créez le projet

### Étape 2: Configurer Firebase Authentication

1. Dans Firebase Console, allez dans **Authentication > Sign-in method**
2. Activez **Phone** comme méthode de connexion
3. Configurez un fournisseur de SMS (Firebase utilise par défaut son propre service)
4. Pour la production, configurez un fournisseur comme Twilio

### Étape 3: Configurer Firestore Database

1. Allez dans **Firestore Database**
2. Cliquez sur **"Créer une base de données"**
3. Choisissez le mode **Production**
4. Sélectionnez une région (ex: `europe-west` pour l'Europe)
5. Configurez les règles de sécurité (voir `FIREBASE_SETUP.md`)

### Étape 4: Ajouter l'application iOS

1. Dans Firebase Console, cliquez sur l'icône **iOS**
2. Bundle ID: `com.bruno.tshiakaniVTC`
3. Téléchargez le fichier `GoogleService-Info.plist`
4. Ajoutez ce fichier à votre projet Xcode dans le dossier `Tshiakani VTC/`

### Étape 5: Configurer Firebase Admin SDK

1. Allez dans **Project Settings > Service Accounts**
2. Cliquez sur **"Generate new private key"**
3. Téléchargez le fichier JSON
4. Placez-le dans `backend/config/firebase-service-account.json`
5. **IMPORTANT**: Ajoutez ce fichier à `.gitignore`

---

## II. Déploiement Backend sur GCP

### Option A: Déploiement sur Cloud Run (Recommandé)

#### Étape 1: Installer Google Cloud SDK

```bash
# macOS
brew install google-cloud-sdk

# Ou téléchargez depuis https://cloud.google.com/sdk/docs/install
```

#### Étape 2: Authentifier avec GCP

```bash
gcloud auth login
gcloud config set project tshiakani-vtc
```

#### Étape 3: Activer les APIs nécessaires

```bash
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  sqladmin.googleapis.com \
  containerregistry.googleapis.com
```

#### Étape 4: Créer une instance Cloud SQL

```bash
# Créer une instance PostgreSQL
gcloud sql instances create tshiakani-vtc-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --root-password=VOTRE_MOT_DE_PASSE

# Créer la base de données
gcloud sql databases create tshiakani_vtc \
  --instance=tshiakani-vtc-db

# Créer un utilisateur
gcloud sql users create tshiakani_user \
  --instance=tshiakani-vtc-db \
  --password=VOTRE_MOT_DE_PASSE
```

#### Étape 5: Configurer les variables d'environnement

1. Allez dans [Cloud Console > Secret Manager](https://console.cloud.google.com/security/secret-manager)
2. Créez les secrets suivants:
   - `jwt-secret`: Votre clé JWT (générer avec `openssl rand -hex 32`)
   - `admin-api-key`: Votre clé API admin
   - `stripe-secret-key`: Votre clé secrète Stripe
   - `database-password`: Mot de passe de la base de données

#### Étape 6: Builder et déployer l'image Docker

```bash
cd backend

# Builder l'image
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api

# Déployer sur Cloud Run
gcloud run deploy tshiakani-vtc-api \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production" \
  --add-cloudsql-instances tshiakani-vtc:us-central1:tshiakani-vtc-db \
  --set-secrets "JWT_SECRET=jwt-secret:latest,ADMIN_API_KEY=admin-api-key:latest,DB_PASSWORD=database-password:latest"
```

#### Étape 7: Configurer la connexion Cloud SQL

Modifiez la variable `DATABASE_URL` pour utiliser la connexion Unix socket:

```env
DATABASE_URL=postgresql://tshiakani_user:password@/tshiakani_vtc?host=/cloudsql/tshiakani-vtc:us-central1:tshiakani-vtc-db
```

### Option B: Déploiement sur App Engine

#### Étape 1: Configurer app.yaml

Le fichier `app.yaml` est déjà configuré dans le projet.

#### Étape 2: Déployer

```bash
cd backend
gcloud app deploy
```

#### Étape 3: Vérifier le déploiement

```bash
gcloud app browse
```

---

## III. Déploiement Dashboard sur Firebase Hosting

### Étape 1: Installer Firebase CLI

```bash
npm install -g firebase-tools
```

### Étape 2: Authentifier avec Firebase

```bash
firebase login
```

### Étape 3: Initialiser Firebase dans le projet

```bash
# Depuis la racine du projet
firebase init hosting

# Sélectionnez:
# - Use an existing project: tshiakani-vtc
# - Public directory: admin-dashboard/dist
# - Configure as single-page app: Yes
# - Set up automatic builds: No
```

### Étape 4: Build du dashboard

```bash
cd admin-dashboard
npm install
npm run build
```

### Étape 5: Configurer les variables d'environnement

Créez un fichier `.env.production` dans `admin-dashboard/`:

```env
VITE_API_URL=https://tshiakani-vtc-api-xxxxx.run.app/api
```

### Étape 6: Déployer sur Firebase Hosting

```bash
# Depuis la racine du projet
firebase deploy --only hosting
```

### Étape 7: Vérifier le déploiement

Visitez: `https://tshiakani-vtc.firebaseapp.com`

---

## IV. Configuration de l'application iOS

### Étape 1: Ajouter GoogleService-Info.plist

1. Téléchargez `GoogleService-Info.plist` depuis Firebase Console
2. Ajoutez-le à votre projet Xcode dans `Tshiakani VTC/`
3. Cochez **"Copy items if needed"** et **"Add to targets: Tshiakani VTC"**

### Étape 2: Configurer l'URL de l'API

Modifiez `APIService.swift` (ou le fichier de configuration):

```swift
private let baseURL = "https://tshiakani-vtc-api-xxxxx.run.app/api"
```

### Étape 3: Installer les dépendances Firebase

Dans Xcode:
1. Allez dans **File > Add Package Dependencies...**
2. Ajoutez: `https://github.com/firebase/firebase-ios-sdk`
3. Sélectionnez:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
   - `FirebaseMessaging` (pour les notifications push)

### Étape 4: Initialiser Firebase dans l'application

Modifiez `TshiakaniVTCApp.swift`:

```swift
import FirebaseCore

@main
struct TshiakaniVTCApp: App {
    init() {
        FirebaseApp.configure()
        // ... reste du code
    }
}
```

---

## V. Vérification et tests

### Vérifier le backend

```bash
# Health check
curl https://tshiakani-vtc-api-xxxxx.run.app/health

# Réponse attendue:
# {"status":"OK","database":"connected","timestamp":"..."}
```

### Vérifier le dashboard

1. Visitez: `https://tshiakani-vtc.firebaseapp.com`
2. Connectez-vous avec les identifiants admin
3. Vérifiez que les données s'affichent correctement

### Vérifier l'application iOS

1. Lancez l'application sur un appareil iOS
2. Testez l'authentification par téléphone
3. Testez la création d'une course
4. Vérifiez les notifications push

---

## VI. Monitoring et maintenance

### Cloud Monitoring

1. Allez dans [Cloud Console > Monitoring](https://console.cloud.google.com/monitoring)
2. Configurez des alertes pour:
   - Temps de réponse de l'API
   - Taux d'erreur
   - Utilisation de la base de données
   - Utilisation des ressources

### Logs

```bash
# Voir les logs de Cloud Run
gcloud run services logs read tshiakani-vtc-api --region us-central1

# Voir les logs de Firebase
firebase functions:log
```

### Backup de la base de données

```bash
# Créer un backup manuel
gcloud sql export sql tshiakani-vtc-db gs://tshiakani-vtc-backups/backup-$(date +%Y%m%d).sql \
  --database=tshiakani_vtc

# Configurer des backups automatiques
gcloud sql instances patch tshiakani-vtc-db \
  --backup-start-time=03:00
```

### Mise à jour du code

```bash
# Backend
cd backend
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
gcloud run deploy tshiakani-vtc-api --image gcr.io/tshiakani-vtc/tshiakani-vtc-api

# Dashboard
cd admin-dashboard
npm run build
firebase deploy --only hosting
```

---

## 🔒 Sécurité

### Checklist de sécurité

- [ ] Variables d'environnement stockées dans Secret Manager
- [ ] HTTPS activé pour toutes les connexions
- [ ] CORS configuré correctement
- [ ] Rate limiting activé
- [ ] Authentification JWT configurée
- [ ] Règles Firestore configurées
- [ ] Backups de base de données configurés
- [ ] Monitoring et alertes configurés

### Recommandations

1. **Ne commitez jamais** les fichiers `.env` ou les clés API
2. **Utilisez Secret Manager** pour toutes les informations sensibles
3. **Activez les backups automatiques** de la base de données
4. **Configurez des alertes** pour les erreurs et les performances
5. **Mettez à jour régulièrement** les dépendances
6. **Utilisez HTTPS** partout
7. **Configurez des règles Firestore** strictes

---

## 📝 Checklist de déploiement

### Firebase
- [ ] Projet Firebase créé
- [ ] Authentication configurée
- [ ] Firestore configuré
- [ ] Règles de sécurité configurées
- [ ] GoogleService-Info.plist ajouté à l'app iOS
- [ ] Firebase Admin SDK configuré

### GCP Backend
- [ ] Projet GCP créé
- [ ] APIs activées
- [ ] Cloud SQL instance créée
- [ ] Secrets configurés dans Secret Manager
- [ ] Backend déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Health check fonctionnel

### Dashboard
- [ ] Dashboard buildé
- [ ] Variables d'environnement configurées
- [ ] Déployé sur Firebase Hosting
- [ ] URL de l'API configurée

### iOS App
- [ ] GoogleService-Info.plist ajouté
- [ ] URL de l'API configurée
- [ ] Dépendances Firebase installées
- [ ] Firebase initialisé dans l'app
- [ ] Testé sur appareil

### Monitoring
- [ ] Cloud Monitoring configuré
- [ ] Alertes configurées
- [ ] Logs configurés
- [ ] Backups configurés

---

## 🆘 Dépannage

### Erreur de connexion à la base de données

```bash
# Vérifier la connexion Cloud SQL
gcloud sql connect tshiakani-vtc-db --user=tshiakani_user
```

### Erreur de déploiement Cloud Run

```bash
# Voir les logs de build
gcloud builds list
gcloud builds log BUILD_ID
```

### Erreur Firebase Hosting

```bash
# Voir les logs
firebase deploy --only hosting --debug
```

---

## 📚 Ressources

- [Documentation Firebase](https://firebase.google.com/docs)
- [Documentation Cloud Run](https://cloud.google.com/run/docs)
- [Documentation Cloud SQL](https://cloud.google.com/sql/docs)
- [Documentation Firebase Hosting](https://firebase.google.com/docs/hosting)

---

## ✅ Résumé

Une fois toutes les étapes terminées, vous aurez:

1. ✅ Backend API déployé sur Cloud Run
2. ✅ Base de données PostgreSQL sur Cloud SQL
3. ✅ Dashboard admin déployé sur Firebase Hosting
4. ✅ Application iOS configurée avec Firebase
5. ✅ Monitoring et alertes configurés
6. ✅ Backups automatiques configurés

Votre application Tshiakani VTC est maintenant prête pour la production! 🎉

