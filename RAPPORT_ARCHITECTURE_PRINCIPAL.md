# 🏛️ Rapport d'Architecture Principal - Tshiakani VTC

**Date**: 2025  
**Architecte Principal**: Agent Architecte Principal  
**Version**: 1.0

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture Globale](#architecture-globale)
3. [Composants Principaux](#composants-principaux)
4. [Patterns Architecturaux](#patterns-architecturaux)
5. [Flux de Données](#flux-de-données)
6. [Sécurité et Contraintes](#sécurité-et-contraintes)
7. [Points Forts](#points-forts)
8. [Recommandations d'Amélioration](#recommandations-damélioration)
9. [Roadmap Technique](#roadmap-technique)

---

## 🎯 Vue d'Ensemble

### Description du Système

**Tshiakani VTC** est une plateforme complète de transport urbain pour Kinshasa, composée de trois applications principales :

1. **Application iOS Client** (SwiftUI) - Application dédiée aux clients
2. **Application iOS Driver** (séparée) - Application dédiée aux conducteurs
3. **Backend Node.js** (Express + PostgreSQL + PostGIS) - API REST et WebSocket
4. **Dashboard Admin** (React.js + Tailwind CSS) - Interface d'administration

### Stack Technologique

#### Frontend iOS
- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Services**: Combine, Core Location, URLSession
- **Intégrations**: Google Maps SDK, Stripe SDK (paiements)

#### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Base de données**: PostgreSQL + PostGIS (géolocalisation)
- **ORM**: TypeORM
- **WebSocket**: Socket.io
- **Sécurité**: JWT, Helmet, Rate Limiting, bcrypt

#### Dashboard Admin
- **Framework**: React.js
- **Styling**: Tailwind CSS
- **Build Tool**: Vite
- **State Management**: Context API

---

## 🏗️ Architecture Globale

### Diagramme d'Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   iOS Client │  │  iOS Driver  │  │ Admin Dashboard│     │
│  │   (SwiftUI)  │  │  (Séparée)   │  │  (React.js)   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
└─────────┼──────────────────┼──────────────────┼───────────────┘
          │                  │                  │
          │  REST API        │  REST API        │  REST API
          │  WebSocket       │  WebSocket       │
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼───────────────┐
│         │                  │                  │               │
│  ┌──────▼──────────────────▼──────────────────▼───────┐      │
│  │         COUCHE API (Node.js + Express)             │      │
│  │                                                     │      │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  │      │
│  │  │  Routes    │  │ Middlewares│  │  Services  │  │      │
│  │  │  - Auth    │  │  - Auth    │  │  - Pricing │  │      │
│  │  │  - Rides   │  │  - GeoFence│  │  - Matching│  │      │
│  │  │  - Users   │  │  - Rate Lim│  │  - Payment │  │      │
│  │  │  - Admin   │  │            │  │  - Transaction│ │      │
│  │  └────────────┘  └────────────┘  └────────────┘  │      │
│  │                                                     │      │
│  │  ┌───────────────────────────────────────────────┐│      │
│  │  │         WebSocket (Socket.io)                 ││      │
│  │  │  - Real-time location updates                 ││      │
│  │  │  - Ride status notifications                  ││      │
│  │  │  - Driver matching                            ││      │
│  │  └───────────────────────────────────────────────┘│      │
│  └──────────────────┬───────────────────────────────────────┘
│                     │
│  ┌──────────────────▼───────────────────────────────────────┐
│  │         COUCHE DONNÉES (PostgreSQL + PostGIS)            │
│  │                                                           │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐│
│  │  │  Users   │  │  Rides   │  │ Notifications│Transactions││
│  │  │          │  │          │  │           │  │         ││
│  │  │ - Client │  │ - Status │  │ - Push    │  │ - Payment││
│  │  │ - Driver │  │ - Location│ │ - SMS     │  │ - Tip   ││
│  │  │ - Admin  │  │ - Pricing│  │           │  │         ││
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘│
│  │                                                           │
│  │  ┌──────────────────────────────────────────────────┐   │
│  │  │        PostGIS (Géolocalisation)                 │   │
│  │  │  - ST_DWithin (géofencing)                       │   │
│  │  │  - ST_MakePoint (points GPS)                     │   │
│  │  │  - Calculs de distance géographique              │   │
│  │  └──────────────────────────────────────────────────┘   │
│  └───────────────────────────────────────────────────────────┘
│
└───────────────────────────────────────────────────────────────┘
```

### Principes Architecturaux

1. **Séparation des Responsabilités**
   - Application Client séparée de l'application Driver
   - Backend centralisé avec API REST et WebSocket
   - Services métier isolés et réutilisables

2. **Scalabilité**
   - Architecture modulaire et extensible
   - Base de données relationnelle avec PostGIS pour la géolocalisation
   - WebSocket pour la communication temps réel

3. **Sécurité**
   - Authentification JWT
   - Géofencing pour la validation des positions
   - Transactions ACID pour l'intégrité des données
   - Rate limiting pour la protection contre les abus

---

## 🧩 Composants Principaux

### 1. Application iOS Client

#### Structure

```
Tshiakani VTC/
├── Models/              # Modèles de données
│   ├── User.swift
│   ├── Ride.swift
│   ├── Location.swift
│   └── Payment.swift
├── Views/               # Interfaces utilisateur
│   ├── Auth/           # Authentification
│   ├── Client/         # Vues client
│   ├── Onboarding/     # Onboarding
│   └── Profile/        # Profil utilisateur
├── ViewModels/         # Logique métier (MVVM)
│   ├── AuthManager.swift
│   ├── AuthViewModel.swift
│   └── RideViewModel.swift
├── Services/           # Services (API, Location, etc.)
│   ├── APIService.swift
│   ├── LocationService.swift
│   ├── PaymentService.swift
│   ├── RealtimeService.swift
│   └── NotificationService.swift
└── Resources/          # Ressources (couleurs, polices, etc.)
    ├── Colors/
    ├── Fonts/
    └── Localization/
```

#### Patterns Utilisés

**MVVM (Model-View-ViewModel)**
- **Models**: Structures de données (`Ride`, `User`, `Location`)
- **Views**: Interfaces SwiftUI (`ClientHomeView`, `RideMapView`)
- **ViewModels**: Logique métier (`RideViewModel`, `AuthViewModel`)

**Singleton Pattern**
- `APIService.shared`
- `LocationService.shared`
- `PaymentService.shared`
- `RealtimeService.shared`

**Observer Pattern**
- `@Published` properties dans les ViewModels
- `Combine` pour la réactivité

#### Flux de Navigation

```
SplashScreen
    ↓
OnboardingView
    ↓
AuthGateView
    ↓
LoginView / RegistrationView
    ↓
SMSVerificationView
    ↓
ClientMainView
    ↓
ClientHomeView
    ↓
BookingInputView
    ↓
RideMapView
    ↓
SearchingDriversView
    ↓
RideTrackingView
    ↓
RideSummaryScreen
```

### 2. Backend Node.js

#### Structure

```
backend/
├── config/
│   └── database.js           # Configuration TypeORM
├── entities/                 # Entités TypeORM
│   ├── User.js
│   ├── Ride.js
│   └── Notification.js
├── models/                   # Modèles métier
│   ├── User.js
│   └── Ride.js
├── routes.postgres/          # Routes API
│   ├── auth.js
│   ├── rides.js
│   ├── users.js
│   ├── client.js
│   └── driver.js
├── middlewares.postgres/     # Middlewares
│   ├── auth.js
│   └── geofencing.js
├── services/                 # Services métier
│   ├── PricingService.js
│   ├── DriverMatchingService.js
│   ├── PaymentService.js
│   └── TransactionService.js
└── server.postgres.js        # Serveur principal
```

#### Routes API Principales

**Authentification**
- `POST /api/auth/signin` - Connexion/Inscription
- `POST /api/auth/verify` - Vérifier le token
- `PUT /api/auth/profile` - Mettre à jour le profil

**Courses (Rides)**
- `POST /api/rides/create` - Créer une demande de course
- `GET /api/rides/history/:userId` - Historique des courses
- `PATCH /api/rides/:id/status` - Mettre à jour le statut
- `POST /api/rides/:id/rate` - Noter une course

**Client**
- `GET /api/client/track_driver/:rideId` - Suivre le conducteur
- `GET /api/location/drivers/nearby` - Chauffeurs à proximité

**Paiements**
- `POST /api/paiements/process` - Traiter un paiement
- `GET /api/paiements/history/:userId` - Historique des paiements

**Admin**
- `GET /api/admin/stats` - Statistiques
- `GET /api/admin/rides` - Liste des courses
- `GET /api/admin/users` - Liste des utilisateurs

#### WebSocket (Socket.io)

**Namespace Principal**
- `io.on('connection')` - Connexion générale
- `socket.on('ride:join')` - Rejoindre une course
- `socket.on('ride:status:update')` - Mettre à jour le statut

**Namespace Driver**
- `/ws/driver` - Connexion des conducteurs
- `socket.on('ping')` - Keep-alive
- `socket.emit('ride_request')` - Notification de nouvelle course

### 3. Base de Données PostgreSQL + PostGIS

#### Schéma Principal

**Table: users**
```sql
- id (SERIAL PRIMARY KEY)
- name (VARCHAR)
- phoneNumber (VARCHAR, UNIQUE)
- email (VARCHAR)
- role (ENUM: 'client', 'driver', 'admin')
- passwordHash (VARCHAR)
- driverInfo (JSONB) -- Pour les conducteurs
- createdAt (TIMESTAMP)
- updatedAt (TIMESTAMP)
```

**Table: rides**
```sql
- id (SERIAL PRIMARY KEY)
- clientId (INTEGER, FOREIGN KEY -> users.id)
- driverId (INTEGER, FOREIGN KEY -> users.id, NULLABLE)
- pickupLocation (GEOGRAPHY(Point)) -- PostGIS
- dropoffLocation (GEOGRAPHY(Point)) -- PostGIS
- pickupAddress (VARCHAR)
- dropoffAddress (VARCHAR)
- status (ENUM: 'pending', 'accepted', 'inProgress', 'completed', 'cancelled')
- estimatedPrice (DECIMAL)
- finalPrice (DECIMAL)
- distance (DECIMAL)
- estimatedDuration (INTEGER)
- createdAt (TIMESTAMP)
- updatedAt (TIMESTAMP)
```

**Table: transactions**
```sql
- id (SERIAL PRIMARY KEY)
- rideId (INTEGER, FOREIGN KEY -> rides.id)
- userId (INTEGER, FOREIGN KEY -> users.id)
- amount (DECIMAL)
- paymentToken (VARCHAR)
- status (ENUM: 'pending', 'completed', 'failed')
- createdAt (TIMESTAMP)
```

**Table: notifications**
```sql
- id (SERIAL PRIMARY KEY)
- userId (INTEGER, FOREIGN KEY -> users.id)
- type (VARCHAR)
- title (VARCHAR)
- message (TEXT)
- read (BOOLEAN)
- createdAt (TIMESTAMP)
```

#### PostGIS - Fonctionnalités Géospatiales

**Géofencing**
```sql
SELECT ST_DWithin(
  ST_MakePoint($1, $2)::geography,  -- Position chauffeur
  ST_MakePoint($3, $4)::geography,  -- Point de départ
  $5                                  -- Distance max (mètres)
) AS is_within_range
```

**Recherche de Chauffeurs Proches**
```sql
SELECT *
FROM users
WHERE role = 'driver'
  AND driverInfo->>'isOnline' = 'true'
  AND ST_DWithin(
    currentLocation::geography,
    ST_MakePoint($1, $2)::geography,
    $3  -- Rayon en mètres
  )
ORDER BY ST_Distance(
  currentLocation::geography,
  ST_MakePoint($1, $2)::geography
)
LIMIT 10;
```

---

## 🎨 Patterns Architecturaux

### 1. MVVM (Model-View-ViewModel)

**Avantages**
- Séparation claire des responsabilités
- Testabilité améliorée
- Réactivité avec Combine

**Implémentation iOS**
```swift
// ViewModel
class RideViewModel: ObservableObject {
    @Published var currentRide: Ride?
    @Published var isLoading = false
    
    private let apiService = APIService.shared
    
    func requestRide(pickup: Location, dropoff: Location) async {
        // Logique métier
    }
}

// View
struct RideMapView: View {
    @StateObject private var viewModel = RideViewModel()
    
    var body: some View {
        // Interface utilisateur
    }
}
```

### 2. Repository Pattern (Backend)

**Service Layer**
```javascript
// Service
class PricingService {
    async calculatePrice(pickup, dropoff, distance) {
        // Logique de calcul de prix
    }
}

// Route
router.post('/rides/create', auth, async (req, res) => {
    const price = await PricingService.calculatePrice(...);
    // ...
});
```

### 3. Singleton Pattern

**Services iOS**
```swift
class APIService: ObservableObject {
    static let shared = APIService()
    private init() {}
}
```

### 4. Observer Pattern

**Combine Framework**
```swift
@Published var currentRide: Ride?

// Écouter les changements
$currentRide
    .sink { ride in
        // Réagir aux changements
    }
```

### 5. Factory Pattern

**Création de Rides**
```swift
struct RideFactory {
    static func create(
        pickup: Location,
        dropoff: Location,
        clientId: String
    ) -> Ride {
        // Création d'un Ride
    }
}
```

---

## 🔄 Flux de Données

### 1. Flux de Création de Course

```
Client (iOS)
    ↓
RideViewModel.requestRide()
    ↓
APIService.createRide()
    ↓
POST /api/rides/create
    ↓
Backend: Routes -> Services -> Database
    ↓
PricingService.calculatePrice()
    ↓
DriverMatchingService.findBestDriver()
    ↓
TransactionService.createRideWithTransaction()
    ↓
PostgreSQL: INSERT INTO rides
    ↓
WebSocket: notifyAvailableDrivers()
    ↓
Driver App: receive ride_request
    ↓
Response -> Client (iOS)
    ↓
RideViewModel.currentRide = createdRide
```

### 2. Flux de Suivi en Temps Réel

```
Driver App
    ↓
Update location (toutes les 5 secondes)
    ↓
WebSocket: emit('driver:location:update')
    ↓
Backend: Socket.io
    ↓
Broadcast to clients in ride room
    ↓
Client App: RealtimeService.onDriverLocationUpdated
    ↓
RideViewModel.updateDriverLocation()
    ↓
UI: Update map with driver location
```

### 3. Flux de Paiement

```
Client (iOS)
    ↓
StripePaymentView
    ↓
Stripe SDK: createPaymentToken()
    ↓
PaymentService.processPayment()
    ↓
POST /api/paiements/process
    ↓
Backend: PaymentService.processPayment()
    ↓
Stripe API: charge payment
    ↓
TransactionService.completeRideWithTransaction()
    ↓
PostgreSQL: INSERT INTO transactions
    ↓
Update ride status to 'completed'
    ↓
Response -> Client (iOS)
    ↓
UI: Show success message
```

---

## 🔒 Sécurité et Contraintes

### 1. Authentification JWT

**Middleware d'Authentification**
```javascript
const { auth } = require('./middlewares.postgres/auth');

router.post('/rides/create', auth, async (req, res) => {
    // req.user contient l'utilisateur authentifié
    // req.userId contient l'ID de l'utilisateur
});
```

**Validation du Token**
- Vérification de la signature
- Vérification de l'expiration
- Vérification du rôle utilisateur

### 2. Géofencing

**Middleware de Géofencing**
```javascript
const { verifyDriverProximityWithST_DWithin } = require('./middlewares.postgres/geofencing');

router.put('/accept/:courseId', 
    auth, 
    verifyDriverProximityWithST_DWithin(2000), // 2000m = 2km
    async (req, res) => {
        // ...
    }
);
```

**Validation**
- Vérification de la distance avec PostGIS `ST_DWithin`
- Distance maximale configurable (par défaut 2km)
- Prévention de la fraude et des annulations tardives

### 3. Transactions ACID

**Service de Transactions**
```javascript
await TransactionService.acceptRideWithTransaction(
    rideId,
    driverId,
    driverLocation,
    pickupLocation,
    2000
);
```

**Opérations Atomiques**
- Mise à jour du statut de la course
- Attribution du chauffeur
- Mise à jour du statut du chauffeur
- Vérification de la proximité
- Rollback automatique en cas d'erreur

### 4. Rate Limiting

**Configuration**
```javascript
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // 100 requêtes par fenêtre
});
app.use('/api/', limiter);
```

### 5. Helmet (Sécurité HTTP)

**Configuration**
```javascript
app.use(helmet());
```

**Protections**
- Headers de sécurité HTTP
- Protection contre XSS
- Protection contre clickjacking
- Désactivation de la mise en cache des réponses sensibles

### 6. Validation des Données

**Express Validator**
```javascript
router.post('/rides/create',
    auth,
    [
        body('pickupLocation.latitude').isFloat(),
        body('pickupLocation.longitude').isFloat(),
        body('dropoffLocation.latitude').isFloat(),
        body('dropoffLocation.longitude').isFloat()
    ],
    async (req, res) => {
        // ...
    }
);
```

---

## ✅ Points Forts

### 1. Architecture Modulaire

- **Séparation claire** des responsabilités
- **Services réutilisables** et testables
- **Modularité** permettant l'évolution future

### 2. Scalabilité

- **PostgreSQL + PostGIS** pour la géolocalisation performante
- **WebSocket** pour la communication temps réel
- **Architecture REST** standard et extensible

### 3. Sécurité

- **JWT** pour l'authentification
- **Géofencing** pour la validation des positions
- **Transactions ACID** pour l'intégrité des données
- **Rate limiting** pour la protection contre les abus

### 4. Expérience Utilisateur

- **Interface SwiftUI** moderne et réactive
- **Temps réel** pour le suivi des courses
- **Notifications** push et locales
- **Design cohérent** avec orange vif (#FF8C00)

### 5. Maintenabilité

- **Code bien structuré** et documenté
- **Patterns standards** (MVVM, Repository, Singleton)
- **Tests unitaires** possibles (à implémenter)
- **Configuration centralisée** (.env)

---

## 🚀 Recommandations d'Amélioration

### 1. Tests

**Priorité: Haute**

- **Tests unitaires** pour les services backend
- **Tests d'intégration** pour les routes API
- **Tests UI** pour les vues SwiftUI
- **Tests de performance** pour les requêtes PostGIS

**Exemple**
```javascript
// Tests unitaires
describe('PricingService', () => {
    it('should calculate price correctly', async () => {
        const price = await PricingService.calculatePrice(...);
        expect(price).toBeGreaterThan(0);
    });
});
```

### 2. Monitoring et Logging

**Priorité: Haute**

- **Logging structuré** (Winston, Pino)
- **Monitoring des performances** (New Relic, Datadog)
- **Alertes** pour les erreurs critiques
- **Métriques** (temps de réponse, taux d'erreur)

**Exemple**
```javascript
const winston = require('winston');

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' })
    ]
});
```

### 3. Cache

**Priorité: Moyenne**

- **Redis** pour le cache des requêtes fréquentes
- **Cache des chauffeurs disponibles** près d'une localisation
- **Cache des prix estimés** pour les trajets similaires

**Exemple**
```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache des chauffeurs disponibles
const cacheKey = `drivers:nearby:${latitude}:${longitude}`;
const cachedDrivers = await client.get(cacheKey);

if (cachedDrivers) {
    return JSON.parse(cachedDrivers);
}
```

### 4. Gestion d'Erreurs

**Priorité: Moyenne**

- **Gestion centralisée** des erreurs
- **Codes d'erreur standardisés** (HTTP status codes)
- **Messages d'erreur utilisateur** clairs
- **Logging des erreurs** pour le débogage

**Exemple**
```javascript
// Middleware de gestion d'erreurs
app.use((err, req, res, next) => {
    logger.error(err);
    res.status(err.status || 500).json({
        error: err.message,
        code: err.code
    });
});
```

### 5. Documentation API

**Priorité: Moyenne**

- **Swagger/OpenAPI** pour la documentation de l'API
- **Exemples de requêtes** et réponses
- **Documentation des erreurs** possibles
- **Guide d'intégration** pour les développeurs

**Exemple**
```javascript
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
```

### 6. Performance

**Priorité: Basse**

- **Optimisation des requêtes PostGIS** (indexes)
- **Lazy loading** pour les listes longues
- **Compression** des réponses (gzip)
- **CDN** pour les assets statiques

**Exemple**
```sql
-- Index pour les requêtes géospatiales
CREATE INDEX idx_rides_pickup_location ON rides USING GIST (pickupLocation);
CREATE INDEX idx_rides_dropoff_location ON rides USING GIST (dropoffLocation);
```

### 7. Internationalisation

**Priorité: Basse**

- **Support multilingue** (français, anglais, lingala)
- **Localisation des dates** et montants
- **Format des numéros de téléphone** selon le pays

**Exemple**
```swift
// Localization
Text("ride.request.title", bundle: .main)
    .environment(\.locale, .current)
```

---

## 📅 Roadmap Technique

### Phase 1: Stabilisation (1-2 mois)

- [ ] Implémenter les tests unitaires
- [ ] Ajouter le logging structuré
- [ ] Améliorer la gestion d'erreurs
- [ ] Documenter l'API (Swagger)

### Phase 2: Performance (2-3 mois)

- [ ] Implémenter le cache Redis
- [ ] Optimiser les requêtes PostGIS
- [ ] Ajouter la compression des réponses
- [ ] Implémenter le lazy loading

### Phase 3: Fonctionnalités Avancées (3-6 mois)

- [ ] Réservation programmée
- [ ] Partage de trajet
- [ ] Chat avec conducteur
- [ ] Système de SOS/Emergency
- [ ] Gestion des favoris

### Phase 4: Scalabilité (6-12 mois)

- [ ] Mise en place d'un load balancer
- [ ] Réplication de la base de données
- [ ] Mise en cache distribuée
- [ ] Microservices (si nécessaire)

---

## 📊 Métriques de Qualité

### Code Quality

- **Couverture de tests**: 0% (objectif: 80%)
- **Complexité cyclomatique**: Moyenne
- **Maintenabilité**: Bonne
- **Documentation**: Moyenne

### Performance

- **Temps de réponse API**: < 200ms (objectif)
- **Temps de chargement iOS**: < 2s (objectif)
- **Throughput**: À mesurer
- **Latence WebSocket**: < 100ms (objectif)

### Sécurité

- **Authentification**: ✅ JWT implémenté
- **Géofencing**: ✅ PostGIS implémenté
- **Transactions ACID**: ✅ Implémenté
- **Rate Limiting**: ✅ Implémenté
- **Validation des données**: ✅ Express Validator

---

## 🎓 Conclusion

L'architecture de **Tshiakani VTC** est **solide et bien structurée**, avec une séparation claire des responsabilités et des patterns standards. Le système est **scalable** et **sécurisé**, avec des fonctionnalités avancées comme la géolocalisation en temps réel et le géofencing.

### Points Clés

1. **Architecture modulaire** et extensible
2. **Sécurité robuste** (JWT, géofencing, transactions ACID)
3. **Performance** avec PostGIS pour la géolocalisation
4. **Expérience utilisateur** optimale avec SwiftUI et WebSocket
5. **Maintenabilité** avec des patterns standards et une structure claire

### Prochaines Étapes

1. **Implémenter les tests** pour améliorer la qualité du code
2. **Ajouter le monitoring** pour suivre les performances
3. **Optimiser les performances** avec le cache et les indexes
4. **Documenter l'API** pour faciliter l'intégration
5. **Ajouter les fonctionnalités avancées** selon la roadmap

---

**Document créé par**: Agent Architecte Principal  
**Date**: 2025  
**Version**: 1.0

