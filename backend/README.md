# 🚀 Tshiakani VTC Backend API

API REST sécurisée pour l'application Tshiakani VTC avec support Socket.io pour la géolocalisation en temps réel.

## 📋 Prérequis

- Node.js 18+
- PostgreSQL 12+ avec PostGIS
- Redis (pour le stockage des OTP et le cache)
  - **Option 1** : Upstash Redis (GRATUIT, recommandé pour production)
  - **Option 2** : Redis Local (pour développement)
  - **Option 3** : Redis Memorystore (payant, ~30 $/mois)
- npm ou yarn

## 🚀 Installation

1. Installer les dépendances :
```bash
npm install
```

2. Configurer les variables d'environnement :
```bash
cp .env.example .env
# Éditer .env avec vos configurations
```

3. Configurer PostgreSQL et Redis :
```bash
# Démarrer PostgreSQL (selon votre installation)

# Option 1: Upstash Redis (GRATUIT, recommandé pour production)
# Créer un compte sur https://upstash.com/ et récupérer REDIS_URL

# Option 2: Redis Local (pour développement)
# Démarrer Redis local (selon votre installation)
redis-server
```

4. Configurer les variables d'environnement Redis dans `.env` :

**Option 1 : Upstash Redis (Recommandé)**
```env
REDIS_URL=redis://default:your_token@endpoint.upstash.io:6379
REDIS_CONNECT_TIMEOUT=10000
```

**Option 2 : Redis Local**
```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_CONNECT_TIMEOUT=10000
```

Consultez [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md) pour la configuration complète.

5. Démarrer le serveur :
```bash
# Mode développement
npm run dev

# Mode production
npm start
```

## 📡 Endpoints API

### Authentification (OTP-only)

Le système d'authentification utilise un système OTP (One-Time Password) uniquement, sans mot de passe.

#### Inscription
1. **`POST /api/auth/register`** - Envoie un code OTP de confirmation
   - Body: `{ phoneNumber: string, name: string, role?: 'client' | 'driver' }`
   - Réponse: `{ success: true, message: string, phoneNumber: string, remainingAttempts: number }`

2. **`POST /api/auth/verify-otp`** - Vérifie l'OTP et finalise l'inscription
   - Body: `{ phoneNumber: string, code: string, type: 'register' }`
   - Réponse: `{ success: true, token: string, user: object }`

#### Connexion
1. **`POST /api/auth/login`** - Envoie un code OTP de confirmation
   - Body: `{ phoneNumber: string }`
   - Réponse: `{ success: true, message: string, phoneNumber: string, remainingAttempts: number }`

2. **`POST /api/auth/verify-otp`** - Vérifie l'OTP et finalise la connexion
   - Body: `{ phoneNumber: string, code: string, type: 'login' }`
   - Réponse: `{ success: true, token: string, user: object }`

#### Autres routes
- `GET /api/auth/verify` - Vérifier le token JWT
- `PUT /api/auth/profile` - Mettre à jour le profil (authentifié)
- `POST /api/auth/forgot-password` - Demande de réinitialisation (utilisateurs existants avec mot de passe)
- `POST /api/auth/reset-password` - Réinitialisation avec OTP (utilisateurs existants avec mot de passe)

### Courses
- `POST /api/rides` - Créer une demande de course
- `POST /api/rides/:rideId/accept` - Accepter une course (conducteur)
- `PATCH /api/rides/:rideId/status` - Mettre à jour le statut
- `GET /api/rides/history` - Historique des courses
- `POST /api/rides/:rideId/rate` - Noter une course
- `GET /api/rides/:rideId` - Obtenir une course

### Géolocalisation
- `POST /api/location/update` - Mettre à jour la position (conducteur)
- `GET /api/location/drivers/nearby` - Conducteurs proches
- `POST /api/location/online` - Activer/désactiver disponibilité

### Notifications
- `GET /api/notifications` - Obtenir les notifications
- `PATCH /api/notifications/:id/read` - Marquer comme lue
- `PATCH /api/notifications/read-all` - Tout marquer comme lu

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

## 🔐 Sécurité

- **OTP-only authentication** : Authentification sans mot de passe utilisant des codes OTP à usage unique
- **Redis pour OTP** : Stockage sécurisé des codes OTP avec expiration automatique (10 minutes)
  - **Upstash Redis** (gratuit, recommandé) : 10 000 commandes/jour, suffisant pour < 3000 clients
  - **Redis Local** (développement) : Stockage local
  - **Redis Memorystore** (production GCP) : Stockage hébergé par Google Cloud
- **Rate limiting** : Limitation à 3 tentatives d'envoi d'OTP par numéro par heure
- **JWT pour l'authentification** : Tokens JWT pour l'authentification des sessions
- **Helmet** : En-têtes de sécurité HTTP
- **Rate limiting général** : Protection contre les abus de requêtes
- **Validation des données** : Validation avec express-validator

## 📊 Base de données

### PostgreSQL (avec PostGIS)
- `users` - Utilisateurs (clients, conducteurs, admins)
- `rides` - Courses
- `notifications` - Notifications
- `sos_reports` - Signaux de détresse
- `price_configurations` - Configurations de prix

### Redis (Upstash Redis, Redis Local, ou Redis Memorystore)
- **OTP** : Stockage des codes OTP avec expiration (clé: `otp:{phoneNumber}`)
- **Pending registrations** : Données d'inscription en attente (clé: `pending:register:{phoneNumber}`)
- **Pending logins** : Demandes de connexion en attente (clé: `pending:login:{phoneNumber}`)
- **Rate limiting** : Compteurs de rate limiting pour OTP (clé: `otp:rate:{phoneNumber}`)
- **Driver locations** : Positions des conducteurs en temps réel (clé: `driver:{driverId}`)

**Recommandation** : Utilisez **Upstash Redis** (gratuit, 10k commandes/jour) pour réduire les coûts.
Consultez [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md) pour la configuration.

## 🧪 Tests

```bash
npm test
```

## 📚 Documentation

### Documentation Principale
- `README.md` - Ce fichier (documentation principale)
- `README_POSTGRES.md` - Guide PostgreSQL
- `API_CLIENT_V1.md` - Documentation complète de l'API Client v1
- `BACKEND_ROUTES_MVP.md` - Classification des routes MVP/Futures/À développer

### Documentation Technique
- `VERIFICATION_COMPLETUDE_BACKEND.md` - Vérification de complétude du backend
- `MAPPING_FRONTEND_BACKEND.md` - Mapping frontend/backend
- `ROUTES_DRIVER_IMPLEMENTATION.md` - Routes Driver
- `COMPATIBILITE_FRONTEND_BACKEND.md` - Compatibilité frontend/backend

### Classification des Routes
Pour connaître quelles routes sont utilisées dans le MVP, lesquelles sont disponibles pour les futures versions, et lesquelles doivent être développées, consultez :
- **`BACKEND_ROUTES_MVP.md`** - Documentation complète de la classification des routes

## 📝 Licence

Propriétaire - Tshiakani VTC

