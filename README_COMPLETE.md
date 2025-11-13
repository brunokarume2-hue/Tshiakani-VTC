# 🏍️ Wewa Taxi - Application Complète

Application complète de transport urbain pour Kinshasa avec **frontend iOS**, **backend Node.js** et **dashboard admin React.js**.

## 🎯 Vue d'ensemble

Wewa Taxi est une plateforme de transport urbain connectant des clients à des conducteurs de moto-taxi à Kinshasa. L'application comprend :

- 📱 **Application iOS** (SwiftUI) pour clients et conducteurs
- 🖥️ **Backend API** (Node.js + MongoDB + Socket.io)
- 📊 **Dashboard Admin** (React.js + Tailwind CSS)

## 📁 Structure du Projet

```
wewa taxi/
├── wewa taxi/              # Application iOS (SwiftUI)
│   ├── Models/              # Modèles de données
│   ├── Views/              # Interfaces utilisateur
│   │   ├── Auth/           # Authentification
│   │   ├── Client/         # Vues client
│   │   ├── Driver/         # Vues conducteur
│   │   ├── Admin/          # Vues admin
│   │   └── Common/         # Composants partagés
│   ├── ViewModels/         # Logique métier (MVVM)
│   ├── Services/           # Services (API, Location, etc.)
│   └── Utils/              # Utilitaires
│
├── backend/                 # Backend Node.js
│   ├── models/             # Modèles MongoDB
│   ├── routes/             # Routes API REST
│   ├── middlewares/        # Middlewares (auth, etc.)
│   ├── utils/              # Utilitaires
│   └── server.js           # Serveur principal
│
└── admin-dashboard/        # Dashboard Admin React.js
    ├── src/
    │   ├── components/     # Composants réutilisables
    │   ├── pages/          # Pages principales
    │   └── services/        # Services API
    └── package.json
```

## 🚀 Démarrage Rapide

### 1. Backend (Node.js + MongoDB)

```bash
cd backend
npm install
cp .env.example .env
# Configurer .env avec vos paramètres
npm run dev
```

Le backend sera disponible sur **http://localhost:3000**

### 2. Dashboard Admin (React.js)

```bash
cd admin-dashboard
npm install
npm run dev
```

Le dashboard sera disponible sur **http://localhost:3001**

### 3. Application iOS

1. Ouvrir `wewa taxi.xcodeproj` dans Xcode
2. Configurer les permissions dans `Info.plist`
3. Compiler et exécuter sur simulateur ou appareil

## 📱 Fonctionnalités iOS

### Pour les Clients
- ✅ Onboarding avec sélection de rôle
- ✅ Géolocalisation automatique
- ✅ Carte interactive avec conducteurs disponibles
- ✅ Bouton "Où et pour combien ?" pour commander
- ✅ Menu latéral (Ville, Historique, Notifications, Sécurité, Paramètres, Aide)
- ✅ Historique des courses avec détails
- ✅ Système de notation et commentaires
- ✅ Sécurité (bouton SOS, partage de position)
- ✅ Notifications push

### Pour les Conducteurs
- ✅ Interface dédiée avec résumé du jour
- ✅ Activation/désactivation de disponibilité
- ✅ Réception des demandes de course
- ✅ Acceptation/refus de courses
- ✅ Suivi des courses actives
- ✅ Mise à jour de position en temps réel

## 🖥️ Fonctionnalités Dashboard Admin

- ✅ **Vue d'ensemble** : Statistiques générales avec graphiques
- ✅ **Gestion des courses** : Historique avec filtres (date, statut, zone)
- ✅ **Gestion des utilisateurs** : Liste, recherche, bannissement
- ✅ **Carte en temps réel** : Visualisation des conducteurs en ligne et courses actives

## 🔌 API Endpoints

### Authentification
- `POST /api/auth/signin` - Connexion/Inscription
- `GET /api/auth/verify` - Vérifier le token
- `PUT /api/auth/profile` - Mettre à jour le profil

### Courses
- `POST /api/rides` - Créer une demande de course
- `POST /api/rides/:id/accept` - Accepter une course (conducteur)
- `PATCH /api/rides/:id/status` - Mettre à jour le statut
- `GET /api/rides/history` - Historique des courses
- `POST /api/rides/:id/rate` - Noter une course
- `GET /api/rides/:id` - Obtenir une course

### Géolocalisation
- `POST /api/location/update` - Mettre à jour la position (conducteur)
- `GET /api/location/drivers/nearby` - Conducteurs proches
- `POST /api/location/online` - Activer/désactiver disponibilité

### Notifications
- `GET /api/notifications` - Obtenir les notifications
- `PATCH /api/notifications/:id/read` - Marquer comme lue

### Admin
- `GET /api/admin/stats` - Statistiques générales
- `GET /api/admin/rides` - Toutes les courses avec filtres
- `GET /api/users` - Liste des utilisateurs
- `POST /api/users/:id/ban` - Bannir un utilisateur

## 🔌 Socket.io Events

### Client → Server
- `driver:join` - Rejoindre en tant que conducteur
- `driver:location` - Mettre à jour la position
- `ride:join` - Rejoindre une course
- `ride:status:update` - Mettre à jour le statut

### Server → Client
- `ride:new` - Nouvelle demande de course
- `driver:location:update` - Mise à jour position conducteur
- `ride:status:changed` - Changement de statut

## 🎨 Design

### Palette de couleurs
- **Orange doux** : #FF6B00 (boutons principaux, accents)
- **Vert profond** : #2D5016 (éléments de navigation, succès)
- **Gris clair** : #F5F5F5 (arrière-plans)

### Principes
- Typographie claire et lisible
- Icônes simples et reconnaissables (SF Symbols)
- Transitions fluides
- Expérience mobile-first
- Design adapté au contexte local de Kinshasa

## 🔐 Sécurité

- **JWT** pour l'authentification
- **Helmet** pour les en-têtes de sécurité
- **Rate limiting** pour prévenir les abus
- **Validation des données** avec express-validator
- **CORS** configuré
- **Bouton SOS** pour les urgences
- **Partage de position** en temps réel

## 📊 Base de données MongoDB

### Collections
- `users` - Utilisateurs (clients, conducteurs, admins)
- `rides` - Courses
- `notifications` - Notifications

### Index
- Géospatial pour les recherches de proximité
- Par rôle, statut, dates

## 🛠️ Technologies

### Frontend iOS
- SwiftUI
- MapKit
- CoreLocation
- Combine
- Architecture MVVM

### Backend
- Node.js
- Express.js
- MongoDB + Mongoose
- Socket.io
- JWT
- Firebase Admin (notifications push)

### Dashboard Admin
- React.js 18
- React Router
- Tailwind CSS
- Chart.js
- Axios
- Socket.io Client
- Vite

## 📝 Documentation

- `PROJECT_COMPLETE.md` - Vue d'ensemble complète
- `DEPLOYMENT.md` - Guide de déploiement
- `backend/README.md` - Documentation backend
- `admin-dashboard/README.md` - Documentation dashboard

## 🧪 Tests

```bash
# Backend
cd backend
npm test

# Dashboard (à implémenter)
cd admin-dashboard
npm test
```

## 🚧 Prochaines étapes

- [ ] Intégration Google Maps dans le dashboard
- [ ] Tests unitaires et d'intégration complets
- [ ] Déploiement production
- [ ] Optimisation des performances
- [ ] Analytics et monitoring
- [ ] Intégration paiement Mobile Money
- [ ] Navigation GPS pour conducteurs

## 📄 Licence

Propriétaire - Wewa Taxi

## 👥 Équipe

Développé pour Wewa Taxi - Kinshasa, RDC

