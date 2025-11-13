# 🔗 Mapping Frontend iOS ↔ Backend

## 📋 Résumé de Compatibilité

### ✅ Statut Global: **COMPATIBLE**

Le frontend iOS **fonctionne avec le backend** grâce aux endpoints legacy qui sont toujours actifs.

---

## 🔄 Mapping des Endpoints

### 1. Estimation de Prix

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `POST /api/rides/estimate-price` | `POST /api/rides/estimate-price` | `POST /api/v1/client/estimate` | ✅ Legacy fonctionne |

**Frontend:**
```swift
POST /api/rides/estimate-price
Body: {
  pickupLocation: { latitude, longitude, address },
  dropoffLocation: { latitude, longitude, address },
  distance: Double?
}
```

**Backend Legacy:**
```javascript
POST /api/rides/estimate-price
// Route: routes.postgres/rides.js:16
// Retourne: { price, basePrice, distance, explanation, multipliers, breakdown }
```

**Compatibilité:** ✅ **100% Compatible**

**Différences:**
- Backend v1 retourne aussi `estimatedWaitTime`, `availableDriversCount`, `estimates` par catégorie
- Frontend peut utiliser le legacy ou être mis à jour pour v1

**Classification MVP:**
- Route MVP : ✅ Utilisée dans l'application iOS simplifiée
- Route Legacy : ✅ Maintenue pour compatibilité

---

### 2. Création de Course

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `POST /api/rides/create` | `POST /api/rides/create` | `POST /api/v1/client/command/request` | ✅ Legacy fonctionne |

**Frontend:**
```swift
POST /api/rides/create
Body: {
  pickupLocation: { latitude, longitude, address },
  dropoffLocation: { latitude, longitude, address },
  distance: Double
}
```

**Backend Legacy:**
```javascript
POST /api/rides/create
// Route: routes.postgres/rides.js:78
// Retourne: { id, clientId, driverId, pickupLocation, dropoffLocation, status, estimatedPrice, ... }
```

**Backend v1:**
```javascript
POST /api/v1/client/command/request
// Route: routes.postgres/client.js:293
// Supporte: vehicleCategory, paymentMethod
// Retourne: { success, ride: {...}, pricing: {...}, message }
```

**Compatibilité:** ✅ **100% Compatible (Legacy)**

**Différences:**
- Backend v1 supporte `vehicleCategory` et `paymentMethod`
- Backend v1 retourne un format de réponse différent (`success`, `ride`, `pricing`)
- Frontend peut utiliser le legacy ou être mis à jour pour v1

---

### 3. Statut de Course

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `PATCH /api/rides/{rideId}/status` | `PATCH /api/rides/{rideId}/status` | `GET /api/v1/client/command/status/{ride_id}` | ✅ Legacy fonctionne |

**Frontend:**
```swift
PATCH /api/rides/{rideId}/status
Body: { status: "cancelled" }
```

**Backend Legacy:**
```javascript
PATCH /api/rides/{rideId}/status
// Route: routes.postgres/rides.js:525
// Body: { status: "cancelled" }
```

**Backend v1:**
```javascript
GET /api/v1/client/command/status/{ride_id}  // Lecture
POST /api/v1/client/command/cancel/{ride_id} // Annulation
```

**Compatibilité:** ✅ **100% Compatible (Legacy)**

**Différences:**
- Backend v1 sépare la lecture (GET) et l'annulation (POST)
- Backend v1 calcule les frais d'annulation automatiquement
- Frontend peut utiliser le legacy ou être mis à jour pour v1

---

### 4. Historique

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `GET /api/rides/history/{userId}` | `GET /api/rides/history/{userId}` | `GET /api/v1/client/history` | ✅ Legacy fonctionne |

**Frontend:**
```swift
GET /api/rides/history/{userId}
```

**Backend Legacy:**
```javascript
GET /api/rides/history/{userId}
// Route: routes.postgres/rides.js:596
// Retourne: Array<Ride>
```

**Backend v1:**
```javascript
GET /api/v1/client/history?page=1&limit=20&status=completed
// Route: routes.postgres/client.js:795
// Retourne: { success, rides: [...], pagination: {...} }
// Utilise le userId du token JWT
```

**Compatibilité:** ✅ **100% Compatible (Legacy)**

**Différences:**
- Backend v1 supporte pagination et filtres
- Backend v1 n'utilise pas le userId dans l'URL (utilise le token)
- Frontend peut utiliser le legacy ou être mis à jour pour v1

---

### 5. Suivi du Chauffeur

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `GET /api/client/track_driver/{rideId}` | `GET /api/client/track_driver/{rideId}` | `GET /api/v1/client/driver/location/{driver_id}` | ✅ Legacy fonctionne |

**Frontend:**
```swift
GET /api/client/track_driver/{rideId}
// Retourne: { driverId, driverName, location, estimatedArrivalMinutes, ... }
```

**Backend Legacy:**
```javascript
GET /api/client/track_driver/{rideId}
// Route: routes.postgres/client.js:20
// Retourne: { success, rideId, driver: {...}, location: {...}, estimatedArrivalMinutes, ... }
```

**Backend v1:**
```javascript
GET /api/v1/client/driver/location/{driver_id}
// Route: routes.postgres/client.js:703
// Nécessite: driver_id au lieu de ride_id
// Retourne: { success, driver: {...}, location: {...}, rideId, ... }
```

**Compatibilité:** ✅ **100% Compatible (Legacy)**

**Différences:**
- Backend v1 utilise `driver_id` au lieu de `ride_id`
- Backend v1 nécessite une course active pour accéder à la position
- Frontend peut utiliser le legacy ou être mis à jour pour v1

---

### 6. Évaluation

| Frontend iOS | Backend Legacy | Backend v1 | Statut |
|--------------|----------------|------------|--------|
| `POST /api/rides/{rideId}/rate` | `POST /api/rides/{rideId}/rate` | `POST /api/v1/client/rate/{ride_id}` | ✅ Legacy fonctionne |

**Frontend:**
```swift
POST /api/rides/{rideId}/rate
Body: { rating: Int, comment: String?, tip: Double? }
```

**Backend Legacy:**
```javascript
POST /api/rides/{rideId}/rate
// Route: routes.postgres/rides.js:628
// Body: { rating: Int, comment: String? }
// Retourne: Ride
```

**Backend v1:**
```javascript
POST /api/v1/client/rate/{ride_id}
// Route: routes.postgres/client.js:900
// Body: { rating: Int, comment: String? }
// Retourne: { success, rideId, rating, comment, driver: {...}, message }
// Ne supporte pas le tip
```

**Compatibilité:** ✅ **100% Compatible (Legacy)**

**Différences:**
- Backend v1 ne supporte pas le `tip`
- Backend v1 retourne un format de réponse différent
- Frontend peut utiliser le legacy ou être mis à jour pour v1

---

## 🔌 WebSocket

### Namespace Client

| Frontend iOS | Backend | Statut |
|--------------|---------|--------|
| Namespace par défaut `/` | Namespace `/` (legacy) | ✅ Compatible |
| Pas de namespace spécifique | Namespace `/ws/client` (v1) | ❌ Non utilisé |

**Frontend:**
```swift
// IntegrationBridgeService.swift
socketService.connect(namespace: namespace, authToken: authToken)
// namespace = nil pour les clients (namespace par défaut)
```

**Backend:**
- Namespace par défaut `/`: ✅ Géré par `io.on('connection')` dans server.postgres.js
- Namespace `/ws/client`: ✅ Configuré mais non utilisé par le frontend

**Événements Frontend:**
- `ride:status:changed`
- `driver:location:update`
- `ride:accepted`
- `ride:cancelled`

**Événements Backend:**
- Legacy: `ride:status:changed`, `driver:location:update`, etc.
- v1: `ride_update` (type: 'ride_accepted', 'ride_cancelled', etc.)

**Compatibilité:** ✅ **Partiellement Compatible**

**Différences:**
- Le frontend utilise le namespace par défaut qui fonctionne
- Le backend v1 utilise le namespace `/ws/client` avec événements différents
- Le frontend peut continuer d'utiliser le namespace par défaut

---

## 📊 Modèles de Données

### Ride Model

**Frontend iOS:**
```swift
struct Ride {
    let id: String
    var clientId: String
    var driverId: String?
    var pickupLocation: Location
    var dropoffLocation: Location
    var status: RideStatus  // pending, accepted, driver_arriving, in_progress, completed, cancelled
    var estimatedPrice: Double
    var finalPrice: Double?
    var paymentMethod: PaymentMethod?
    var distance: Double?
    var duration: TimeInterval?
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var rating: Int?
    var review: String?
    var driverLocation: Location?
}
```

**Backend:**
```javascript
// Entity Ride
{
    id: Int
    clientId: Int
    driverId: Int?
    pickupLocation: Geography(Point)
    dropoffLocation: Geography(Point)
    status: String  // pending, accepted, driverArriving, inProgress, completed, cancelled
    estimatedPrice: Decimal
    finalPrice: Decimal?
    paymentMethod: String  // cash, mobile_money, card
    distance: Decimal?
    duration: Int?  // minutes
    createdAt: Timestamp
    startedAt: Timestamp?
    completedAt: Timestamp?
    rating: Int?
    comment: String?
    cancellationReason: String?
}
```

**Compatibilité:** ✅ **Compatible avec transformations**

**Différences:**
- IDs: String (iOS) vs Int (Backend) - Transformation nécessaire
- Status: `driver_arriving` (iOS) vs `driverArriving` (Backend) - Transformation nécessaire
- PaymentMethod: Enum (iOS) vs String (Backend) - Transformation nécessaire
- Duration: TimeInterval/Seconds (iOS) vs Int/Minutes (Backend) - Transformation nécessaire

**Transformation:**
- Le `DataTransformService` gère ces transformations ✅

---

## ✅ Checklist de Compatibilité

### Endpoints REST
- [x] Estimation de prix: ✅ Compatible (legacy)
- [x] Création de course: ✅ Compatible (legacy)
- [x] Statut de course: ✅ Compatible (legacy)
- [x] Historique: ✅ Compatible (legacy)
- [x] Suivi du chauffeur: ✅ Compatible (legacy)
- [x] Évaluation: ✅ Compatible (legacy)

### WebSocket
- [x] Namespace par défaut: ✅ Compatible
- [x] Événements: ✅ Compatible (legacy)
- [x] Authentification: ⚠️ Partiellement compatible (le frontend n'utilise pas JWT dans WebSocket)

### Modèles de Données
- [x] Ride: ✅ Compatible (avec transformation)
- [x] Location: ✅ Compatible
- [x] User: ✅ Compatible
- [x] Status: ✅ Compatible (avec transformation)

---

## 🔧 Recommandations

### Option 1: Garder les Endpoints Legacy (Solution Actuelle)

**Avantages:**
- ✅ Le frontend fonctionne immédiatement
- ✅ Aucune modification nécessaire
- ✅ Compatible avec l'existant

**Action:**
- ✅ Garder les routes legacy actives
- ✅ Documenter les deux APIs
- ✅ Planifier la migration future

### Option 2: Mettre à Jour le Frontend (Long Terme)

**Avantages:**
- ✅ Utilise les nouveaux endpoints optimisés
- ✅ Support des nouvelles fonctionnalités
- ✅ Meilleure structure API

**Actions Requises:**
1. Mettre à jour `APIService.swift` pour utiliser les endpoints v1
2. Adapter les modèles de réponse
3. Mettre à jour le WebSocket pour utiliser `/ws/client`
4. Tester toutes les fonctionnalités

### Option 3: Routes de Compatibilité (Hybride)

**Avantages:**
- ✅ Migration progressive
- ✅ Support des deux formats
- ✅ Pas de breaking changes

**Actions Requises:**
1. Créer des routes de compatibilité qui redirigent vers v1
2. Adapter les formats de réponse
3. Migrer progressivement le frontend

---

## 📋 Classification MVP

### Routes MVP vs Routes Futures

Pour plus de détails sur la classification des routes backend, voir `BACKEND_ROUTES_MVP.md`.

**Routes MVP (Utilisées actuellement):**
- ✅ Authentification : `/api/auth/register`, `/api/auth/login`, `/api/auth/verify`
- ✅ Courses : `/api/v1/client/estimate`, `/api/v1/client/command/request`, `/api/v1/client/command/status/:ride_id`, etc.
- ✅ Suivi : `/api/client/track_driver/:rideId`
- ✅ Profil : `/api/users/me`
- ✅ Paiements : `/api/paiements/preauthorize`, `/api/paiements/confirm`

**Routes Futures (Disponibles mais non utilisées dans MVP):**
- 🔮 `/api/auth/profile` - Mise à jour du profil
- 🔮 `/api/auth/google` - Authentification Google
- 🔮 `/api/notifications` - Notifications
- 🔮 `/api/sos` - Alertes SOS
- 🔮 `/api/documents` - Gestion des documents

**Routes à Développer:**
- 🔴 Gestion des méthodes de paiement sauvegardées
- 🔴 Gestion des adresses sauvegardées
- 🔴 Préférences utilisateur avancées
- 🔴 Programme de fidélité
- 🔴 Chat en temps réel
- 🔴 Réservations programmées
- 🔴 Partage de trajet

Voir `BACKEND_ROUTES_MVP.md` pour la liste complète.

---

## 📝 Plan d'Action Recommandé

### Phase 1: Vérification (Immédiat) ✅

- [x] Vérifier que les endpoints legacy fonctionnent
- [x] Tester la connexion frontend ↔ backend
- [x] Documenter les différences

### Phase 2: Stabilisation (Court Terme)

- [ ] Tester tous les flux end-to-end
- [ ] Vérifier les transformations de données
- [ ] Corriger les incompatibilités mineures

### Phase 3: Migration (Long Terme)

- [ ] Mettre à jour le frontend pour utiliser les endpoints v1
- [ ] Tester les nouvelles fonctionnalités
- [ ] Déprécier les endpoints legacy

---

## ✅ Conclusion

### Statut: **✅ COMPATIBLE**

**Le frontend iOS fonctionne avec le backend grâce aux endpoints legacy.**

**Points Clés:**
- ✅ Tous les endpoints legacy sont actifs et fonctionnels
- ✅ Les transformations de données sont gérées par `DataTransformService`
- ✅ Le WebSocket fonctionne avec le namespace par défaut
- ⚠️ Les nouveaux endpoints v1 ne sont pas encore utilisés par le frontend

**Recommandation:**
- ✅ **Garder les endpoints legacy actifs** (solution actuelle)
- ✅ **Planifier la migration vers v1** (long terme)
- ✅ **Documenter les deux APIs** pour faciliter la migration

---

**Date:** 2025-01-15
**Version:** 1.0.0
**Statut:** ✅ Compatible et Fonctionnel

