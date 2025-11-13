# 🚕 Tshiakani VTC - Application de Transport

## 🎯 Vue d'Ensemble

Tshiakani VTC est une application de transport (VTC) complète développée pour Kinshasa, avec :
- **Backend Node.js/Express** - API REST + WebSocket pour temps réel
- **Applications iOS** - Client et Driver (SwiftUI)
- **Dashboard Admin** - React + Tailwind CSS
- **Infrastructure GCP** - Cloud Run, Cloud SQL, Memorystore Redis

---

## 🏗️ Architecture

### Backend
- **Framework**: Node.js + Express.js
- **Base de données**: PostgreSQL + PostGIS (Cloud SQL)
- **Cache temps réel**: Redis (Memorystore)
- **WebSocket**: Socket.io
- **Authentification**: JWT
- **Paiements**: Stripe
- **Notifications**: Firebase Cloud Messaging (FCM)
- **Géolocalisation**: Google Maps Platform APIs

### Applications iOS
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **État**: Combine
- **Géolocalisation**: Core Location + Google Maps SDK
- **Paiements**: Stripe SDK
- **Notifications**: Firebase Cloud Messaging

### Dashboard Admin
- **Framework**: React.js
- **Styling**: Tailwind CSS
- **Build**: Vite
- **Charts**: Chart.js
- **HTTP**: Axios
- **WebSocket**: Socket.io Client

### Infrastructure
- **Hosting**: Google Cloud Run
- **Base de données**: Cloud SQL (PostgreSQL)
- **Cache**: Memorystore (Redis)
- **Monitoring**: Cloud Logging + Cloud Monitoring
- **Storage**: Cloud Storage (documents)

---

## 📁 Structure du Projet

```
Tshiakani VTC/
├── backend/                 # Backend Node.js/Express
│   ├── services/           # Services métier
│   ├── routes.postgres/    # Routes API
│   ├── entities/           # Entités TypeORM
│   ├── middlewares.postgres/ # Middlewares
│   ├── utils/              # Utilitaires
│   ├── migrations/         # Migrations SQL
│   └── server.postgres.js  # Serveur principal
├── admin-dashboard/        # Dashboard Admin React
├── Tshiakani VTC/         # Application iOS Client
├── scripts/               # Scripts d'automatisation
├── docs/                  # Documentation
└── README.md             # Ce fichier
```

---

## 🚀 Démarrage Rapide

### Prérequis
- Node.js 18+
- PostgreSQL (ou Cloud SQL)
- Redis (ou Memorystore)
- Google Cloud SDK (gcloud)
- Docker (pour le déploiement)

### Installation

```bash
# 1. Cloner le projet
git clone [repository-url]
cd "Tshiakani VTC"

# 2. Installer les dépendances du backend
cd backend
npm install

# 3. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos configurations

# 4. Démarrer le backend
npm run dev
```

### Déploiement GCP

```bash
# 1. Initialiser GCP
./scripts/gcp-setup-etape1.sh

# 2. Configurer Cloud SQL
./scripts/gcp-create-cloud-sql.sh
./scripts/gcp-init-database.sh

# 3. Configurer Redis
./scripts/gcp-create-redis.sh

# 4. Déployer le backend
./scripts/gcp-deploy-backend.sh
./scripts/gcp-set-cloud-run-env.sh

# 5. Configurer le monitoring
./scripts/gcp-setup-monitoring.sh
./scripts/gcp-create-alerts.sh
```

---

## 📚 Documentation

### Guides de Configuration GCP
- `GCP_SETUP_ETAPE1.md` - Initialisation GCP
- `GCP_SETUP_ETAPE2.md` - Cloud SQL
- `GCP_SETUP_ETAPE3.md` - Memorystore Redis
- `GCP_SETUP_ETAPE4.md` - Déploiement Backend
- `GCP_SETUP_ETAPE5.md` - Monitoring
- `GCP_DEPLOYMENT_QUICK_START.md` - Démarrage rapide

### Guides Techniques
- `backend/ALGORITHME_MATCHING_TARIFICATION.md` - Algorithme de matching
- `backend/MONITORING_INTEGRATION.md` - Intégration monitoring
- `backend/REDIS_STRUCTURE.md` - Structure Redis
- `backend/DATABASE_SCHEMA.md` - Schéma de base de données

### Guides de Déploiement
- `GCP_SETUP_ETAPE4.md` - Déploiement Backend
- `GCP_MONITORING_DASHBOARD.md` - Tableaux de bord
- `PROCHAINES_ETAPES.md` - Prochaines étapes
- `ROADMAP_COMPLET.md` - Roadmap complète

---

## 🔧 Configuration

### Variables d'Environnement

#### Backend
```bash
# Base de données
DATABASE_URL=postgresql://user:password@host:5432/database
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=tshiakani_vtc

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# Sécurité
JWT_SECRET=your_jwt_secret
ADMIN_API_KEY=your_admin_api_key

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Firebase
FIREBASE_PROJECT_ID=tshiakani-vtc
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...

# Stripe
STRIPE_SECRET_KEY=sk_live_...
STRIPE_PUBLISHABLE_KEY=pk_live_...

# GCP
GCP_PROJECT_ID=tshiakani-vtc
GCP_REGION=us-central1
INSTANCE_CONNECTION_NAME=tshiakani-vtc:us-central1:tshiakani-vtc-db
```

---

## 🧪 Tests

### Tests Backend

```bash
# Tests unitaires
npm test

# Tests d'intégration
npm run test:integration

# Tests de performance
npm run test:performance
```

### Tests API

```bash
# Tester le health check
curl http://localhost:3000/health

# Tester l'authentification
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "code": "123456"
  }'
```

---

## 📊 Monitoring

### Cloud Logging

```bash
# Voir les logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" --limit 50

# Voir les erreurs
gcloud logging read "severity>=ERROR" --limit 50
```

### Cloud Monitoring

```bash
# Voir les métriques
gcloud monitoring time-series list \
  --filter='metric.type="custom.googleapis.com/api/latency"' \
  --project=tshiakani-vtc
```

### Tableaux de Bord

```
https://console.cloud.google.com/monitoring/dashboards
```

---

## 🚨 Alertes

### Alertes Configurées

1. **Latence API élevée** - > 2000ms
2. **Utilisation mémoire Cloud Run élevée** - > 80%
3. **Utilisation CPU Cloud Run élevée** - > 80%
4. **Utilisation mémoire Cloud SQL élevée** - > 80%
5. **Utilisation CPU Cloud SQL élevée** - > 80%
6. **Taux d'erreurs HTTP 5xx élevé** - > 5%
7. **Taux d'erreurs de paiement élevé** - > 10 erreurs
8. **Taux d'erreurs de matching élevé** - > 10 erreurs

---

## 🔐 Sécurité

### Authentification
- JWT pour l'authentification des utilisateurs
- API Key pour l'authentification admin
- Rate limiting pour prévenir les abus

### Autorisation
- Rôles: client, driver, admin, agent
- Permissions basées sur les rôles
- Validation des données d'entrée

### Sécurité des Données
- Chiffrement des mots de passe (bcrypt)
- Tokens de paiement (pas d'informations bancaires stockées)
- HTTPS pour toutes les communications
- CORS configuré

---

## 🎯 Fonctionnalités

### Client
- Inscription/Connexion
- Création de courses
- Estimation de prix
- Suivi en temps réel
- Paiement (Stripe)
- Historique des courses
- Notifications push

### Driver
- Inscription/Connexion
- Mise à jour de position (2-3 secondes)
- Réception de courses
- Acceptation de courses
- Navigation
- Complétion de courses
- Historique des courses
- Notifications push

### Admin
- Dashboard de métriques
- Gestion des courses
- Gestion des conducteurs
- Gestion des clients
- Gestion des prix
- Rapports et analytics

---

## 📈 Métriques

### Métriques API
- Latence moyenne
- Taux de requêtes
- Taux d'erreurs
- Temps de réponse

### Métriques Business
- Nombre de courses
- Taux de matching
- Taux d'acceptation
- Taux de complétion
- Revenus

### Métriques Techniques
- Utilisation CPU
- Utilisation mémoire
- Utilisation réseau
- Nombre de connexions

---

## 🔄 Workflow de Développement

### Développement Local

```bash
# 1. Démarrer PostgreSQL
# 2. Démarrer Redis
# 3. Démarrer le backend
cd backend
npm run dev

# 4. Démarrer le dashboard admin
cd admin-dashboard
npm run dev
```

### Déploiement

```bash
# 1. Build et test
npm run build
npm test

# 2. Déployer sur Cloud Run
./scripts/gcp-deploy-backend.sh

# 3. Vérifier le déploiement
./scripts/gcp-verify-cloud-run.sh
```

---

## 🐛 Dépannage

### Erreurs Courantes

#### Erreur: "Connection refused to Cloud SQL"
- Vérifier que Cloud SQL est accessible depuis Cloud Run
- Vérifier les permissions IAM
- Vérifier la configuration INSTANCE_CONNECTION_NAME

#### Erreur: "Connection refused to Redis"
- Vérifier que Redis est accessible depuis Cloud Run
- Vérifier le VPC Connector
- Vérifier les variables d'environnement REDIS_HOST

#### Erreur: "API not enabled"
- Activer les APIs nécessaires
- Vérifier les permissions IAM
- Vérifier la facturation

---

## 📞 Support

### Ressources
- **Documentation GCP**: https://cloud.google.com/docs
- **Documentation Node.js**: https://nodejs.org/docs
- **Documentation React**: https://react.dev
- **Documentation SwiftUI**: https://developer.apple.com/documentation/swiftui

### Contact
- **Support technique**: [À définir]
- **Email**: [À définir]
- **Documentation**: Voir les fichiers MD dans le projet

---

## 📝 License

[À définir]

---

## 👥 Équipe

[À définir]

---

## 🎉 Remerciements

[À définir]

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0  
**Statut**: En cours de développement

