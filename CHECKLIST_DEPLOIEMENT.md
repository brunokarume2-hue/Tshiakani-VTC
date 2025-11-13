# ✅ Checklist de Déploiement Firebase/GCP

Checklist complète pour déployer Tshiakani VTC sur Firebase/GCP.

## 📋 Préparation

### Firebase
- [ ] Créer un compte Firebase
- [ ] Créer un projet Firebase: `tshiakani-vtc`
- [ ] Configurer Firebase Authentication (Phone)
- [ ] Configurer Firestore Database
- [ ] Configurer les règles de sécurité Firestore
- [ ] Ajouter l'application iOS (Bundle ID: `com.bruno.tshiakaniVTC`)
- [ ] Télécharger `GoogleService-Info.plist`
- [ ] Ajouter `GoogleService-Info.plist` au projet Xcode
- [ ] Configurer Firebase Admin SDK
- [ ] Télécharger le fichier de service account JSON
- [ ] Placer le fichier dans `backend/config/firebase-service-account.json`

### Google Cloud Platform
- [ ] Créer un compte GCP
- [ ] Créer un projet GCP: `tshiakani-vtc`
- [ ] Activer la facturation (requis pour Cloud SQL)
- [ ] Installer Google Cloud SDK
- [ ] S'authentifier: `gcloud auth login`
- [ ] Configurer le projet: `gcloud config set project tshiakani-vtc`

## 🔧 Configuration Backend

### Variables d'environnement
- [ ] Copier `backend/ENV.example` vers `backend/.env`
- [ ] Configurer `DATABASE_URL` ou les variables DB_*
- [ ] Générer `JWT_SECRET` (utiliser `openssl rand -hex 32`)
- [ ] Configurer `ADMIN_API_KEY`
- [ ] Configurer `CORS_ORIGIN`
- [ ] Configurer `FIREBASE_SERVICE_ACCOUNT_PATH`
- [ ] Configurer `STRIPE_SECRET_KEY` et `STRIPE_PUBLISHABLE_KEY`
- [ ] Configurer `GOOGLE_MAPS_API_KEY`

### Base de données
- [ ] Exécuter le script de configuration GCP: `./backend/scripts/setup-gcp.sh`
- [ ] Vérifier que l'instance Cloud SQL est créée
- [ ] Vérifier que la base de données est créée
- [ ] Vérifier que l'utilisateur est créé
- [ ] Exécuter les migrations SQL si nécessaire
- [ ] Vérifier que PostGIS est activé

### Secrets GCP
- [ ] Créer le secret `jwt-secret` dans Secret Manager
- [ ] Créer le secret `admin-api-key` dans Secret Manager
- [ ] Créer le secret `stripe-secret-key` dans Secret Manager
- [ ] Créer le secret `database-password` dans Secret Manager
- [ ] Vérifier que les secrets sont accessibles

## 🚀 Déploiement Backend

### Option A: Cloud Run (Recommandé)
- [ ] Activer les APIs nécessaires (Cloud Run, Cloud Build, Container Registry)
- [ ] Builder l'image Docker: `gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api`
- [ ] Déployer sur Cloud Run: `./backend/scripts/deploy-cloud-run.sh`
- [ ] Vérifier que le service est déployé
- [ ] Tester l'endpoint `/health`
- [ ] Vérifier les logs: `gcloud run services logs read tshiakani-vtc-api`

### Option B: App Engine
- [ ] Activer les APIs nécessaires (App Engine)
- [ ] Déployer sur App Engine: `./backend/scripts/deploy-app-engine.sh`
- [ ] Vérifier que le service est déployé
- [ ] Tester l'endpoint `/health`
- [ ] Vérifier les logs: `gcloud app logs tail`

## 🖥️ Déploiement Dashboard

### Configuration
- [ ] Installer Firebase CLI: `npm install -g firebase-tools`
- [ ] S'authentifier: `firebase login`
- [ ] Configurer le projet: `firebase use tshiakani-vtc`
- [ ] Créer le fichier `.env.production` dans `admin-dashboard/`
- [ ] Configurer `VITE_API_URL` avec l'URL du backend déployé

### Build et déploiement
- [ ] Installer les dépendances: `cd admin-dashboard && npm install`
- [ ] Builder le dashboard: `npm run build`
- [ ] Vérifier que le dossier `dist/` est créé
- [ ] Déployer sur Firebase Hosting: `./scripts/deploy-firebase.sh`
- [ ] Vérifier que le dashboard est accessible
- [ ] Tester la connexion au backend

## 📱 Configuration iOS

### Firebase
- [ ] Ajouter `GoogleService-Info.plist` au projet Xcode
- [ ] Installer les dépendances Firebase via Swift Package Manager
- [ ] Initialiser Firebase dans `TshiakaniVTCApp.swift`
- [ ] Tester l'authentification Firebase

### Configuration API
- [ ] Modifier l'URL de l'API dans `APIService.swift` (ou fichier de configuration)
- [ ] Utiliser l'URL du backend déployé (Cloud Run ou App Engine)
- [ ] Tester la connexion à l'API
- [ ] Tester l'authentification
- [ ] Tester la création d'une course

### Notifications Push
- [ ] Configurer les certificats APNs dans Firebase Console
- [ ] Tester les notifications push
- [ ] Vérifier que les notifications sont reçues

## 🔒 Sécurité

### Backend
- [ ] Vérifier que les secrets sont dans Secret Manager (pas en texte clair)
- [ ] Vérifier que CORS est configuré correctement
- [ ] Vérifier que le rate limiting est activé
- [ ] Vérifier que HTTPS est activé
- [ ] Vérifier que l'authentification JWT fonctionne

### Firebase
- [ ] Vérifier que les règles Firestore sont configurées
- [ ] Vérifier que Firebase Authentication est configuré
- [ ] Vérifier que les permissions sont correctes

### Base de données
- [ ] Vérifier que la base de données est sécurisée
- [ ] Vérifier que les backups sont configurés
- [ ] Vérifier que les connexions sont sécurisées (SSL)

## 📊 Monitoring

### Cloud Monitoring
- [ ] Configurer Cloud Monitoring
- [ ] Créer des alertes pour les erreurs
- [ ] Créer des alertes pour les performances
- [ ] Configurer les dashboards

### Logs
- [ ] Vérifier que les logs sont configurés
- [ ] Vérifier que les logs sont accessibles
- [ ] Configurer la rétention des logs

### Backups
- [ ] Configurer les backups automatiques de Cloud SQL
- [ ] Tester la restauration d'un backup
- [ ] Vérifier la fréquence des backups

## 🧪 Tests

### Backend
- [ ] Tester l'endpoint `/health`
- [ ] Tester l'authentification
- [ ] Tester la création d'une course
- [ ] Tester les WebSockets
- [ ] Tester les notifications

### Dashboard
- [ ] Tester la connexion au backend
- [ ] Tester l'authentification
- [ ] Tester l'affichage des données
- [ ] Tester les fonctionnalités admin

### iOS App
- [ ] Tester l'authentification par téléphone
- [ ] Tester la création d'une course
- [ ] Tester la géolocalisation
- [ ] Tester les notifications push
- [ ] Tester les WebSockets

## 🚨 Dépannage

### Erreurs courantes
- [ ] Vérifier les logs du backend
- [ ] Vérifier les logs Firebase
- [ ] Vérifier les logs Cloud Run/App Engine
- [ ] Vérifier la connexion à la base de données
- [ ] Vérifier les variables d'environnement
- [ ] Vérifier les permissions

## ✅ Vérification finale

- [ ] Backend accessible et fonctionnel
- [ ] Dashboard accessible et fonctionnel
- [ ] Application iOS fonctionnelle
- [ ] Base de données accessible
- [ ] Authentification fonctionnelle
- [ ] Notifications push fonctionnelles
- [ ] WebSockets fonctionnels
- [ ] Monitoring configuré
- [ ] Backups configurés
- [ ] Sécurité vérifiée

## 📝 Notes

- **URL Backend**: `https://tshiakani-vtc-api-xxxxx.run.app` (Cloud Run)
- **URL Dashboard**: `https://tshiakani-vtc.firebaseapp.com`
- **Bundle ID iOS**: `com.bruno.tshiakaniVTC`
- **Projet Firebase**: `tshiakani-vtc`
- **Projet GCP**: `tshiakani-vtc`

## 🆘 Support

En cas de problème:
1. Vérifier les logs
2. Vérifier la documentation: `GUIDE_DEPLOIEMENT_FIREBASE_GCP.md`
3. Vérifier les variables d'environnement
4. Vérifier les permissions
5. Vérifier la configuration Firebase/GCP

---

**Date de création**: $(date)
**Dernière mise à jour**: $(date)

