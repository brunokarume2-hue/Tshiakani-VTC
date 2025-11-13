# 🎉 Wewa Taxi - Projet Complet

Application complète de transport urbain pour Kinshasa avec frontend iOS, backend Node.js et dashboard admin React.js.

## 📁 Structure du Projet

```
wewa taxi/
├── wewa taxi/              # Application iOS (SwiftUI)
│   ├── Models/             # Modèles de données
│   ├── Views/              # Interfaces utilisateur
│   ├── ViewModels/         # Logique métier
│   └── Services/           # Services (API, Location, etc.)
│
├── backend/                # Backend Node.js
│   ├── models/             # Modèles MongoDB
│   ├── routes/             # Routes API
│   ├── middlewares/        # Middlewares (auth, etc.)
│   ├── utils/              # Utilitaires
│   └── server.js           # Serveur principal
│
└── admin-dashboard/        # Dashboard Admin React.js
    ├── src/
    │   ├── components/     # Composants réutilisables
    │   ├── pages/          # Pages principales
    │   └── services/       # Services API
    └── package.json
```

## 🚀 Démarrage Rapide

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env
# Configurer .env avec vos paramètres
npm run dev
```

Le backend sera disponible sur http://localhost:3000

### 2. Dashboard Admin

```bash
cd admin-dashboard
npm install
npm run dev
```

Le dashboard sera disponible sur http://localhost:3001

### 3. Application iOS

1. Ouvrir `wewa taxi.xcodeproj` dans Xcode
2. Configurer les permissions dans `Info.plist`
3. Compiler et exécuter sur simulateur ou appareil

## 📡 API Endpoints

### Authentification
- `POST /api/auth/signin` - Connexion/Inscription
- `GET /api/auth/verify` - Vérifier le token
- `PUT /api/auth/profile` - Mettre à jour le profil

### Courses
- `POST /api/rides` - Créer une demande
- `POST /api/rides/:id/accept` - Accepter (conducteur)
- `PATCH /api/rides/:id/status` - Mettre à jour le statut
- `GET /api/rides/history` - Historique
- `POST /api/rides/:id/rate` - Noter une course

### Géolocalisation
- `POST /api/location/update` - Mettre à jour position
- `GET /api/location/drivers/nearby` - Conducteurs proches
- `POST /api/location/online` - Activer/désactiver disponibilité

### Admin
- `GET /api/admin/stats` - Statistiques
- `GET /api/admin/rides` - Toutes les courses
- `GET /api/users` - Liste utilisateurs
- `POST /api/users/:id/ban` - Bannir utilisateur

## 🔌 Socket.io Events

### Client → Server
- `driver:join` - Rejoindre en tant que conducteur
- `driver:location` - Mettre à jour position
- `ride:join` - Rejoindre une course
- `ride:status:update` - Mettre à jour statut

### Server → Client
- `ride:new` - Nouvelle demande
- `driver:location:update` - Position conducteur
- `ride:status:changed` - Changement statut

## 🎨 Design

- **Couleurs** : Orange doux (#FF6B00), Vert profond (#2D5016), Gris clair (#F5F5F5)
- **Typographie** : Système iOS, claire et lisible
- **Icônes** : SF Symbols (iOS), simples et reconnaissables

## 🔐 Sécurité

- JWT pour l'authentification
- Helmet pour les en-têtes de sécurité
- Rate limiting
- Validation des données
- CORS configuré

## 📊 Base de données MongoDB

### Collections
- `users` - Utilisateurs (clients, conducteurs, admins)
- `rides` - Courses
- `notifications` - Notifications

### Index
- Géospatial pour les recherches de proximité
- Par rôle, statut, dates

## 📱 Fonctionnalités iOS

✅ Onboarding avec sélection de rôle
✅ Géolocalisation automatique
✅ Carte interactive avec conducteurs
✅ Menu latéral complet
✅ Historique des courses
✅ Système de notation
✅ Sécurité (bouton SOS, partage position)
✅ Notifications

## 🖥️ Fonctionnalités Dashboard

### Dashboard Admin
✅ Vue d'ensemble avec statistiques
✅ Graphiques (Chart.js)
✅ Gestion des courses avec filtres
✅ Gestion des utilisateurs
✅ Carte en temps réel (simulation)

## 🚧 Prochaines étapes

- [ ] Intégration Google Maps dans le dashboard
- [ ] Tests unitaires et d'intégration
- [ ] Déploiement production
- [ ] Optimisation des performances
- [ ] Analytics et monitoring

## 📝 Notes

- Le backend utilise MongoDB avec Mongoose
- Socket.io pour la géolocalisation en temps réel
- Firebase Admin pour les notifications push (optionnel)
- Le dashboard utilise Vite pour un build rapide

## 📄 Licence

Propriétaire - Wewa Taxi

