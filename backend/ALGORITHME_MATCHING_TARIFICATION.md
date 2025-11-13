# 🧠 Algorithme de Matching et Tarification - Tshiakani VTC

## 🎯 Vue d'Ensemble

Ce document décrit l'implémentation de l'algorithme de matching des conducteurs et de tarification dynamique utilisant Google Maps Routes API et Redis (Memorystore).

---

## 📍 1. Fonction de Recherche de Chauffeurs

### Stratégie Hybride: Redis (Temps Réel) + PostGIS (Fallback)

Lorsqu'un passager demande une course, l'endpoint `/api/v1/ride/request` utilise une stratégie hybride :

1. **Redis (Priorité)** - Récupération rapide depuis Memorystore
2. **PostGIS (Fallback)** - Si Redis n'est pas disponible

### Implémentation

```javascript
// Dans DriverMatchingService.findBestDriver()

// 1. Récupérer depuis Redis (temps réel)
const availableDrivers = await redisService.getAvailableDrivers();

// 2. Filtrer par rayon de 5 km
const nearbyDrivers = availableDrivers
  .map(driver => {
    const distance = calculateHaversineDistance(
      pickupLocation,
      { latitude: driver.latitude, longitude: driver.longitude }
    );
    return { ...driver, distance_km: distance };
  })
  .filter(driver => driver.distance_km <= 5) // Rayon de 5 km
  .sort((a, b) => a.distance_km - b.distance_km);

// 3. Fallback vers PostGIS si Redis n'est pas disponible
if (nearbyDrivers.length === 0) {
  nearbyDrivers = await User.findNearbyDrivers(
    pickupLocation.latitude,
    pickupLocation.longitude,
    5, // Rayon de 5 km
    AppDataSource
  );
}
```

### Critères de Matching

Le système calcule un score pour chaque conducteur basé sur :

- **Distance (40%)** - Plus proche = meilleur score
- **Note (25%)** - Note du conducteur (1-5 étoiles)
- **Disponibilité (15%)** - Statut en ligne et disponible
- **Performance (10%)** - Taux de complétion des courses
- **Taux d'acceptation (10%)** - Taux d'acceptation des courses

### Score Minimum

Un conducteur doit avoir un score minimum de 30 pour être assigné automatiquement.

---

## 💰 2. Fonction de Tarification

### Utilisation de Google Maps Routes API

La tarification utilise Google Maps Routes API pour calculer :
- **Distance réelle** du trajet
- **Temps de trajet** estimé
- **Itinéraire optimisé** (avec trafic)

### Formule de Tarification

```
Prix = (Prix de base + Distance × Prix par km) × Multiplicateurs
```

#### Composantes

1. **Prix de base** : 500 CDF (configurable)
2. **Prix par km** : 200 CDF/km (configurable)
3. **Multiplicateurs** :
   - **Heure** : Heures de pointe (1.5x), Nuit (1.3x), Normal (1.0x)
   - **Jour** : Week-end (1.2x), Semaine (1.0x)
   - **Demande** : Surge pricing selon la demande (0.9x à 1.6x)

### Implémentation

```javascript
// Dans PricingService.calculateDynamicPrice()

// 1. Calculer la distance et le temps avec Google Maps Routes API
const routeData = await GoogleMapsService.calculateRoute(
  pickupLocation,
  dropoffLocation,
  {
    travelMode: 'DRIVE',
    routingPreference: 'TRAFFIC_AWARE',
    language: 'fr'
  }
);

const distance = routeData.distance.kilometers;
const duration = routeData.duration;

// 2. Calculer le prix de base
const basePrice = config.basePrice + (distance * config.pricePerKm);

// 3. Appliquer les multiplicateurs
const finalPrice = Math.round(
  basePrice * timeMultiplier * dayMultiplier * surgeMultiplier
);
```

### Surge Pricing

Le surge pricing est calculé en fonction du ratio demande/offre :

- **Faible demande** (< 0.5) : 0.9x
- **Normale** (0.5 - 1.0) : 1.0x
- **Élevée** (1.0 - 1.5) : 1.2x
- **Très élevée** (1.5 - 2.0) : 1.4x
- **Extrême** (> 2.0) : 1.6x

---

## 🤝 3. Notification et Acceptation

### Notifications FCM aux Meilleurs Conducteurs

Lorsqu'aucun conducteur n'est assigné automatiquement, le système envoie des notifications push aux 5 meilleurs conducteurs :

```javascript
// Dans BackendAgentPrincipal.createRide()

// 1. Récupérer les conducteurs disponibles depuis Redis
const availableDrivers = await redisService.getAvailableDrivers();

// 2. Trier par distance et prendre les 5 meilleurs
const topDrivers = availableDrivers
  .map(driver => {
    const distance = calculateHaversineDistance(
      pickupLocation,
      { latitude: driver.latitude, longitude: driver.longitude }
    );
    return { ...driver, distance };
  })
  .filter(driver => driver.distance <= 5) // Dans un rayon de 5 km
  .sort((a, b) => a.distance - b.distance)
  .slice(0, 5); // Top 5

// 3. Envoyer les notifications push via FCM
await sendMulticastNotification(fcmTokens, {
  title: 'Nouvelle course disponible 🚗',
  body: `${pickupAddress} → ${dropoffAddress} (${distance} km, ${price} CDF)`,
  data: {
    type: 'ride_offer',
    rideId: savedRide.id.toString(),
    estimatedPrice: pricing.price.toString(),
    estimatedDistance: distance.toString(),
    estimatedDuration: duration.text
  },
  priority: 'high'
});
```

### Fallback WebSocket

Si FCM n'est pas disponible, le système utilise WebSocket comme fallback :

```javascript
// Notifier tous les conducteurs disponibles via WebSocket
driverNamespace.emit('ride_request', {
  type: 'ride_request',
  ride: {
    id: savedRide.id.toString(),
    pickupAddress: savedRide.pickupAddress,
    dropoffAddress: savedRide.dropoffAddress,
    estimatedDistance: distance,
    estimatedPrice: pricing.price,
    estimatedDuration: duration.text
  }
});
```

---

## 🔄 Flux Complet

### 1. Demande de Course

```
Client → POST /api/v1/ride/request
  ↓
BackendAgentPrincipal.createRide()
  ↓
1. Calculer distance/temps (Google Maps Routes API)
2. Calculer prix (PricingService)
3. Créer la course (statut: pending)
```

### 2. Matching des Conducteurs

```
DriverMatchingService.findBestDriver()
  ↓
1. Récupérer depuis Redis (temps réel)
2. Filtrer par rayon de 5 km
3. Calculer le score pour chaque conducteur
4. Sélectionner le meilleur (score >= 30)
```

### 3. Assignation Automatique

```
Si conducteur trouvé:
  - Assigner automatiquement
  - Notifier le conducteur (WebSocket)
  - Notifier le client (FCM)
  
Si aucun conducteur:
  - Notifier les 5 meilleurs (FCM)
  - Notifier tous (WebSocket fallback)
```

---

## 📊 Structure des Données

### Redis (Memorystore)

**Clé**: `driver:<driver_id>`

**Valeur (Hash)**:
- `lat` - Latitude
- `lon` - Longitude
- `status` - Statut (available, en_route_to_pickup, in_progress, offline)
- `last_update` - Horodatage ISO 8601
- `current_ride_id` - ID de la course actuelle
- `heading` - Direction (0-360°)
- `speed` - Vitesse (km/h)

**TTL**: 300 secondes (5 minutes)

### Course (Ride)

```javascript
{
  id: 123,
  clientId: 456,
  driverId: 789,
  pickupLocation: { type: 'Point', coordinates: [15.3136, -4.3276] },
  dropoffLocation: { type: 'Point', coordinates: [15.3146, -4.3286] },
  pickupAddress: "Avenue X, Kinshasa",
  dropoffAddress: "Avenue Y, Kinshasa",
  status: 'pending',
  estimatedPrice: 1500,
  distance: 2.5,
  estimatedDuration: 8,
  paymentMethod: 'cash'
}
```

---

## 🔧 Configuration

### Variables d'Environnement

```bash
# Google Maps API
GOOGLE_MAPS_API_KEY=your_api_key_here

# Redis (Memorystore)
REDIS_HOST=10.0.0.3
REDIS_PORT=6379
REDIS_PASSWORD=

# Firebase (FCM)
FIREBASE_PROJECT_ID=tshiakani-vtc
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...
```

### Paramètres de Matching

```javascript
// Dans DriverMatchingService
MAX_DISTANCE_KM = 5; // Rayon maximum de recherche
PREFERRED_DISTANCE_KM = 2; // Distance préférée
MIN_SCORE = 30; // Score minimum pour assignation automatique
```

### Paramètres de Tarification

```javascript
// Dans PricingService
DEFAULT_BASE_PRICE = 500; // Prix de base en CDF
DEFAULT_PRICE_PER_KM = 200; // Prix par km en CDF
RUSH_HOUR_MULTIPLIER = 1.5; // Multiplicateur heures de pointe
NIGHT_MULTIPLIER = 1.3; // Multiplicateur nuit
WEEKEND_MULTIPLIER = 1.2; // Multiplicateur week-end
```

---

## 🚀 Optimisations Futures

### 1. Geo-spatial Indexing Redis

Utiliser Redis GEO pour une recherche géospatiale plus efficace :

```redis
GEOADD drivers:locations 15.3136 -4.3276 driver:4523
GEORADIUS drivers:locations 15.3136 -4.3276 5 km WITHDIST
```

### 2. Cache des Itinéraires

Mettre en cache les itinéraires calculés par Google Maps Routes API pour réduire les appels API.

### 3. Machine Learning

Utiliser le machine learning pour prédire :
- Temps d'arrivée estimé
- Probabilité d'acceptation
- Prix optimal

---

## 📚 Documentation

- **Service Google Maps**: `backend/services/GoogleMapsService.js`
- **Service Matching**: `backend/services/DriverMatchingService.js`
- **Service Tarification**: `backend/services/PricingService.js`
- **Agent Principal**: `backend/services/BackendAgentPrincipal.js`
- **Service Redis**: `backend/services/RedisService.js`

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

