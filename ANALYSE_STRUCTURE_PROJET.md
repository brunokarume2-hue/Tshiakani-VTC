# 📊 Analyse de la Structure du Projet Tshiakani VTC

## 🎯 Vue d'ensemble

**Tshiakani VTC** est une application de transport à Kinshasa (RDC) avec trois composants principaux :
1. **Application iOS Client** (SwiftUI)
2. **Application iOS Driver** (séparée, non présente dans ce repo)
3. **Backend Node.js** (Express + PostgreSQL + PostGIS)
4. **Dashboard Admin** (React.js + Vite)

---

## 📁 Structure du Projet

### 1. Application iOS Client (`Tshiakani VTC/`)

#### Architecture : **MVVM (Model-View-ViewModel)**

```
Tshiakani VTC/
├── Models/                    # Modèles de données
│   ├── User.swift
│   ├── Ride.swift
│   ├── RideRequest.swift
│   ├── Location.swift
│   ├── Payment.swift
│   ├── Chauffeur.swift
│   ├── VehicleType.swift
│   └── PriceEstimate.swift
│
├── Views/                     # Interfaces utilisateur (SwiftUI)
│   ├── Auth/                  # Authentification
│   │   ├── WelcomeView.swift
│   │   ├── RegistrationView.swift
│   │   ├── SMSVerificationView.swift
│   │   └── AuthGateView.swift
│   │
│   ├── Client/                # Vues client (50+ fichiers)
│   │   ├── ClientHomeView.swift
│   │   ├── ClientMainView.swift
│   │   ├── RideRequestView.swift
│   │   ├── RideTrackingView.swift
│   │   ├── GoogleMapView.swift
│   │   ├── SearchingDriversView.swift
│   │   └── ... (cartes, paiements, notifications)
│   │
│   ├── Driver/                # Vues conducteur
│   │   └── DriverMainView.swift
│   │
│   ├── Admin/                 # Vues administrateur
│   │   └── AdminDashboardView.swift
│   │
│   ├── Onboarding/            # Onboarding
│   ├── Profile/               # Profil utilisateur
│   ├── Common/                # Composants partagés
│   └── Shared/                # Vues partagées
│
├── ViewModels/                # Logique métier (MVVM)
│   ├── AuthManager.swift      # Gestion de l'authentification
│   ├── AuthViewModel.swift    # ViewModel authentification
│   ├── RideViewModel.swift    # ViewModel des courses
│   └── AdminViewModel.swift   # ViewModel admin
│
├── Services/                  # Services (API, Location, etc.)
│   ├── APIService.swift       # Communication REST API
│   ├── SocketIOService.swift  # Communication WebSocket
│   ├── LocationService.swift  # Géolocalisation
│   ├── GoogleMapsService.swift # Intégration Google Maps
│   ├── GooglePlacesService.swift # Recherche d'adresses
│   ├── RealtimeService.swift  # Service temps réel
│   ├── NotificationService.swift # Notifications push
│   ├── PaymentService.swift   # Paiements
│   ├── StripeService.swift    # Intégration Stripe
│   ├── ConfigurationService.swift # Configuration centralisée
│   ├── DataTransformService.swift # Transformation de données
│   └── ... (autres services)
│
├── Resources/                 # Ressources
│   ├── Colors/                # Couleurs de l'app
│   │   └── AppColors.swift
│   ├── Fonts/                 # Polices
│   │   └── AppTypography.swift
│   ├── Localization/          # Internationalisation
│   │   ├── fr.lproj/
│   │   ├── en.lproj/
│   │   └── ln.lproj/          # Lingala
│   └── DesignSystem.swift     # Système de design
│
└── Extensions/                # Extensions Swift
    ├── StringExtensions.swift
    ├── ViewExtensions.swift
    └── NavigationExtensions.swift
```

#### Technologies iOS
- **SwiftUI** : Framework UI
- **Swift** : Langage de programmation
- **Google Maps SDK** : Cartes et géolocalisation
- **Socket.io Client** : Communication temps réel
- **Firebase** : Notifications push (optionnel)

---

### 2. Backend Node.js (`backend/`)

#### Architecture : **REST API + WebSocket (Socket.io)**

```
backend/
├── server.postgres.js         # Point d'entrée principal
│
├── config/                    # Configuration
│   └── database.js            # Configuration TypeORM + PostgreSQL
│
├── entities/                  # Entités TypeORM (modèles de données)
│   ├── User.js                # Utilisateur (client/driver/admin)
│   ├── Ride.js                # Course
│   ├── Notification.js        # Notification
│   ├── PriceConfiguration.js  # Configuration des prix
│   └── SOSReport.js           # Signalement SOS
│
├── routes.postgres/           # Routes API (PostgreSQL)
│   ├── auth.js                # Authentification
│   ├── rides.js               # Gestion des courses
│   ├── users.js               # Gestion des utilisateurs
│   ├── driver.js              # Routes spécifiques driver
│   ├── driver.v1.js           # API v1 pour driver
│   ├── client.js              # Routes spécifiques client
│   ├── admin.js               # Routes administrateur
│   ├── agent.js               # Routes agent
│   ├── location.js            # Géolocalisation
│   ├── notifications.js       # Notifications
│   ├── paiements.js           # Paiements Stripe
│   ├── pricing.js             # Configuration des prix
│   └── sos.js                 # Signalements SOS
│
├── middlewares.postgres/      # Middlewares
│   ├── auth.js                # Authentification JWT
│   ├── adminApiKey.js         # Clé API admin
│   └── geofencing.js          # Géofencing
│
├── services/                  # Services métier
│   ├── PricingService.js      # Calcul des prix
│   ├── PaymentService.js      # Gestion des paiements
│   ├── TransactionService.js  # Transactions
│   └── DriverMatchingService.js # Appariement driver
│
├── modules/                   # Modules spécifiques
│   └── rides/
│       └── realtimeService.js # Service temps réel des courses
│
├── migrations/                # Migrations SQL
│   ├── 001_init_postgis.sql   # Initialisation PostGIS
│   ├── 002_create_price_configurations.sql
│   ├── 003_optimize_indexes.sql
│   └── 004_add_name_column.sql
│
├── utils/                     # Utilitaires
│   └── notifications.js       # Utilitaires notifications
│
└── package.json               # Dépendances Node.js
```

#### Technologies Backend
- **Node.js** : Runtime JavaScript
- **Express** : Framework web
- **TypeORM** : ORM pour PostgreSQL
- **PostgreSQL + PostGIS** : Base de données avec support géospatial
- **Socket.io** : WebSocket pour temps réel
- **JWT** : Authentification
- **Stripe** : Paiements
- **Firebase Admin** : Notifications push

#### Base de données
- **PostgreSQL** avec extension **PostGIS** pour la géolocalisation
- Tables principales :
  - `users` : Utilisateurs (clients, drivers, admins)
  - `rides` : Courses
  - `notifications` : Notifications
  - `price_configurations` : Configuration des prix
  - `sos_reports` : Signalements SOS

---

### 3. Dashboard Admin (`admin-dashboard/`)

#### Architecture : **React.js + Vite**

```
admin-dashboard/
├── src/
│   ├── App.jsx                # Composant principal
│   ├── main.jsx               # Point d'entrée
│   │
│   ├── pages/                 # Pages
│   │   ├── Login.jsx          # Connexion
│   │   ├── Dashboard.jsx      # Tableau de bord
│   │   ├── Rides.jsx          # Gestion des courses
│   │   ├── Drivers.jsx        # Gestion des conducteurs
│   │   ├── Clients.jsx        # Gestion des clients
│   │   ├── Users.jsx          # Gestion des utilisateurs
│   │   ├── Finance.jsx        # Finance
│   │   ├── Pricing.jsx        # Configuration des prix
│   │   ├── Notifications.jsx  # Notifications
│   │   ├── SOSAlerts.jsx      # Alertes SOS
│   │   └── MapView.jsx        # Vue carte
│   │
│   ├── components/            # Composants React
│   │   └── Layout.jsx         # Layout principal
│   │
│   ├── services/              # Services
│   │   ├── api.js             # Service API
│   │   └── AuthContext.jsx    # Contexte d'authentification
│   │
│   └── utils/                 # Utilitaires
│
├── package.json               # Dépendances
└── vite.config.js             # Configuration Vite
```

#### Technologies Dashboard
- **React.js** : Framework UI
- **Vite** : Build tool
- **React Router** : Routing
- **Axios** : Client HTTP
- **Chart.js** : Graphiques
- **Tailwind CSS** : Styling
- **Socket.io Client** : Communication temps réel

---

## 🔄 Flux de Communication

### Architecture en 3 Tiers

```
┌─────────────────────────────────────────────────────────┐
│              COUCHE PRÉSENTATION                        │
├─────────────────────────────────────────────────────────┤
│  iOS Client App  │  iOS Driver App  │  Admin Dashboard │
│   (SwiftUI)      │    (Séparée)     │    (React.js)    │
└────────┬─────────┴────────┬──────────┴────────┬─────────┘
         │                  │                   │
         │  REST API        │  REST API         │  REST API
         │  WebSocket       │  WebSocket        │  WebSocket
         │                  │                   │
┌────────▼──────────────────▼───────────────────▼─────────┐
│              COUCHE API (Node.js + Express)             │
├─────────────────────────────────────────────────────────┤
│  Routes │  Middlewares │  Services │  Socket.io        │
└────────┬────────────────────────────────────────────────┘
         │
┌────────▼────────────────────────────────────────────────┐
│     COUCHE DONNÉES (PostgreSQL + PostGIS)               │
├─────────────────────────────────────────────────────────┤
│  users │  rides │  notifications │  price_configurations│
└─────────────────────────────────────────────────────────┘
```

### Communication Temps Réel

#### WebSocket Namespaces
1. **`/ws/driver`** : Communication avec les drivers
2. **`/ws/client`** : Communication avec les clients
3. **Default namespace** : Communication générale (legacy)

#### Événements Socket.io

**Client → Backend**
- `ride:join` : Rejoindre une course
- `ride:leave` : Quitter une course
- `ping` : Keep-alive

**Backend → Client**
- `connected` : Confirmation de connexion
- `ride_request` : Nouvelle demande de course (driver)
- `ride:status:changed` : Changement de statut
- `ride:joined` : Confirmation de rejoindre une course
- `pong` : Réponse ping

---

## 🔐 Sécurité

### Authentification
- **JWT (JSON Web Tokens)** : Authentification des utilisateurs
- **Middleware d'authentification** : Vérification des tokens
- **Clés API admin** : Authentification pour le dashboard

### Sécurité des données
- **Helmet** : Sécurisation des en-têtes HTTP
- **CORS** : Configuration des origines autorisées
- **Rate Limiting** : Protection contre les abus
- **Compression** : Optimisation des réponses
- **Géofencing** : Validation des positions géographiques

---

## 📊 Base de Données

### Schéma Principal

#### Table `users`
- `id` : Identifiant unique
- `name` : Nom de l'utilisateur
- `phone_number` : Numéro de téléphone (unique)
- `role` : Rôle (client, driver, admin, agent)
- `is_verified` : Vérification du compte
- `location` : Position géographique (PostGIS Point)
- `fcm_token` : Token Firebase Cloud Messaging
- `created_at` : Date de création
- `updated_at` : Date de mise à jour

#### Table `rides`
- `id` : Identifiant unique
- `client_id` : ID du client
- `driver_id` : ID du driver (nullable)
- `pickup_location` : Point de prise en charge (PostGIS)
- `pickup_address` : Adresse de prise en charge
- `dropoff_location` : Point de destination (PostGIS)
- `dropoff_address` : Adresse de destination
- `status` : Statut (pending, accepted, in_progress, completed, cancelled)
- `estimated_price` : Prix estimé
- `final_price` : Prix final
- `distance_km` : Distance en kilomètres
- `duration_min` : Durée en minutes
- `payment_method` : Méthode de paiement
- `rating` : Note (1-5)
- `comment` : Commentaire
- `created_at` : Date de création
- `started_at` : Date de début
- `completed_at` : Date de fin
- `cancelled_at` : Date d'annulation

### Index Spatiaux
- **GIST indexes** sur les colonnes géographiques pour optimiser les requêtes spatiales
- **Index composites** pour les requêtes fréquentes
- **Index partiels** pour les requêtes conditionnelles

---

## 🚀 Déploiement

### Backend
- **Google Cloud Run** : Déploiement du backend
- **PostgreSQL** : Base de données (Cloud SQL ou autre)
- **Docker** : Containerisation (Dockerfile présent)

### Dashboard Admin
- **Vercel** : Déploiement du dashboard (optionnel)
- **Build statique** : Génération avec Vite

### Application iOS
- **App Store** : Distribution (à venir)
- **Firebase** : Notifications push (optionnel)

---

## 📝 Documentation

Le projet contient une **documentation extensive** (500+ fichiers Markdown) :
- Guides de déploiement
- Guides de configuration
- Rapports de vérification
- Instructions d'installation
- Documentation des APIs
- Guides de correction d'erreurs

---

## 🎯 Fonctionnalités Principales

### Application Client
- ✅ Authentification par SMS (OTP)
- ✅ Géolocalisation et cartes Google Maps
- ✅ Recherche d'adresses (Google Places)
- ✅ Demande de course
- ✅ Suivi en temps réel
- ✅ Historique des courses
- ✅ Paiements (Stripe, cash)
- ✅ Notifications push
- ✅ Signalement SOS

### Application Driver
- ✅ Authentification
- ✅ Réception des demandes de course
- ✅ Acceptation/refus de courses
- ✅ Mise à jour de position en temps réel
- ✅ Statut en ligne/hors ligne

### Dashboard Admin
- ✅ Tableau de bord avec statistiques
- ✅ Gestion des utilisateurs
- ✅ Gestion des courses
- ✅ Configuration des prix
- ✅ Gestion des notifications
- ✅ Alertes SOS
- ✅ Visualisation sur carte

---

## 🔧 Technologies Clés

### Frontend iOS
- SwiftUI
- Google Maps SDK
- Socket.io Client
- Firebase (optionnel)

### Backend
- Node.js
- Express.js
- TypeORM
- PostgreSQL + PostGIS
- Socket.io
- JWT
- Stripe

### Dashboard
- React.js
- Vite
- Tailwind CSS
- Chart.js
- Axios
- Socket.io Client

---

## 📈 Points d'Amélioration Potentiels

1. **Séparation des applications** : L'application Driver devrait être dans un repo séparé
2. **Tests** : Ajouter des tests unitaires et d'intégration
3. **Documentation API** : Générer une documentation Swagger/OpenAPI
4. **Monitoring** : Ajouter des outils de monitoring (Sentry, LogRocket)
5. **CI/CD** : Mettre en place un pipeline CI/CD
6. **Cache** : Implémenter un cache Redis pour les requêtes fréquentes
7. **Queue** : Utiliser une queue (Bull, RabbitMQ) pour les tâches asynchrones

---

## 🎓 Conclusion

Le projet **Tshiakani VTC** est une application de transport complète avec :
- Architecture modulaire et scalable
- Communication temps réel via WebSocket
- Base de données géospatiale (PostGIS)
- Sécurité robuste (JWT, rate limiting, géofencing)
- Interface utilisateur moderne (SwiftUI, React.js)
- Documentation extensive

Le projet est prêt pour le déploiement en production avec quelques ajustements de configuration et de déploiement.

---

**Date d'analyse** : Novembre 2025
**Version du projet** : 1.0.0

---

## 📋 Résumé Exécutif

### Points Forts
✅ **Architecture modulaire** : Séparation claire des responsabilités  
✅ **Communication temps réel** : WebSocket pour les mises à jour en temps réel  
✅ **Base de données géospatiale** : PostGIS pour la géolocalisation  
✅ **Sécurité robuste** : JWT, rate limiting, géofencing  
✅ **Documentation extensive** : Plus de 500 fichiers de documentation  
✅ **Déploiement cloud** : Backend déployé sur Google Cloud Run  

### Technologies Principales
- **Frontend iOS** : SwiftUI, Google Maps SDK, Socket.io Client
- **Backend** : Node.js, Express, TypeORM, PostgreSQL + PostGIS, Socket.io
- **Dashboard** : React.js, Vite, Tailwind CSS, Chart.js
- **Déploiement** : Google Cloud Run, Cloud SQL (optionnel), Vercel (dashboard)

### Structure des Fichiers
- **~500 fichiers Markdown** : Documentation complète
- **Backend** : ~50 fichiers de code source
- **iOS Client** : ~100 fichiers Swift
- **Dashboard Admin** : ~20 fichiers React

### Endpoints API Principaux
- `/api/auth` : Authentification
- `/api/rides` : Gestion des courses
- `/api/driver` : Routes driver
- `/api/client` : Routes client
- `/api/admin` : Routes administrateur
- `/api/location` : Géolocalisation
- `/api/paiements` : Paiements Stripe
- `/ws/driver` : WebSocket driver
- `/ws/client` : WebSocket client

