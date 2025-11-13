# Architecture Temps Réel Optimisée - Tshiakani VTC

## 🎯 Vue d'ensemble

Cette architecture garantit une expérience utilisateur fluide et performante pour une application VTC en temps réel, similaire à Uber ou Yango.

## 📊 Architecture des Protocoles

### 1. HTTP/HTTPS (REST API)
**Utilisation** : Actions uniques/non-urgentes
- Connexion (authentification)
- Réservation initiale de course
- Paiement
- Mise à jour du profil

**Service GCP** : Cloud Run (Endpoints API standard)

### 2. WebSockets (Socket.IO)
**Utilisation** : Actions asynchrones/instantanées
- Suivi de la position du chauffeur sur la carte client
- Notification immédiate d'une nouvelle course pour le chauffeur
- Mises à jour de statut de course en temps réel

**Service GCP** : Cloud Run (configuré pour supporter les connexions persistantes)

## 🔄 Flux de Géolocalisation (Driver → Redis → Passenger)

### Étape 1 : Mise à jour Position (Chauffeur)
```
App Chauffeur → Backend (HTTP POST /api/driver/location/update)
- Fréquence : Toutes les 2-3 secondes
- Données : latitude, longitude, status, heading, speed, currentRideId
```

### Étape 2 : Stockage Rapide (Backend → Redis)
```
Backend (Cloud Run) → Redis (Memorystore)
- Commande : HSET driver:<id> {lat, lon, status, currentRideId, heading, speed}
- TTL : 5 minutes (expiration automatique si pas de mise à jour)
- Performance : < 1ms (latence ultra-faible)
```

### Étape 3 : Distribution (Backend → Clients)
```
Backend (Cloud Run) → Clients via WebSocket
- Protocole : Socket.IO (namespace /ws/client)
- Room : ride:<rideId>
- Événement : driver:location:update
- Fréquence : Toutes les 2 secondes (automatique depuis Redis)
```

## 🚀 Services Backend

### 1. DriverLocationBroadcaster
**Fichier** : `backend/services/DriverLocationBroadcaster.js`

**Responsabilités** :
- Diffusion automatique des positions depuis Redis
- Distribution ciblée uniquement aux clients qui suivent une course active
- Fréquence : 2 secondes par défaut

**Méthodes principales** :
- `start(intervalMs)` : Démarre la diffusion automatique
- `stop()` : Arrête la diffusion
- `broadcastDriverLocations()` : Diffuse les positions de tous les chauffeurs actifs
- `broadcastDriverLocation(driverId, rideId)` : Diffusion manuelle pour un chauffeur spécifique

### 2. RedisService
**Fichier** : `backend/services/RedisService.js`

**Responsabilités** :
- Stockage des positions des chauffeurs en temps réel
- Gestion des statuts (available, en_route_to_pickup, in_progress, offline)
- Récupération des chauffeurs disponibles

**Méthodes principales** :
- `updateDriverLocation(driverId, locationData)` : Met à jour la position
- `getDriverLocation(driverId)` : Récupère la position
- `getAvailableDrivers()` : Récupère tous les chauffeurs disponibles
- `updateDriverStatus(driverId, status, currentRideId)` : Met à jour le statut

### 3. RealtimeRideService
**Fichier** : `backend/modules/rides/realtimeService.js`

**Responsabilités** :
- Gestion des courses en temps réel
- Matching chauffeur-client
- Notifications WebSocket et FCM

## 📡 Routes API

### POST /api/driver/location/update
**Rôle** : Mise à jour de la position du chauffeur

**Flux** :
1. Validation des données (latitude, longitude, status, etc.)
2. Mise à jour PostgreSQL (persistance, toutes les 30 secondes)
3. Mise à jour Redis (temps réel, toutes les 2-3 secondes)
4. Distribution WebSocket immédiate (si course active)
5. Réponse HTTP

**Distribution WebSocket** :
- Ciblée : uniquement aux clients dans la room `ride:<rideId>`
- Namespace : `/ws/client`
- Événement : `driver:location:update`

### POST /api/location/update
**Rôle** : Mise à jour de la position (route alternative)

**Flux** : Similaire à `/api/driver/location/update`

### GET /api/client/track_driver/:rideId
**Rôle** : Suivi de la position du chauffeur (HTTP REST)

**Utilisation** : Fallback ou polling occasionnel
**Note** : Le WebSocket est préféré pour le temps réel

## 🔔 Notifications

### WebSocket (App ouverte)
**Utilisation** : Mises à jour en direct
- Position du chauffeur sur la carte
- Changements de statut de course
- Notifications instantanées

**Namespace** : `/ws/client`
**Événements** :
- `driver:location:update` : Mise à jour de position
- `ride_update` : Mise à jour de course
- `ride:status:changed` : Changement de statut

### Firebase Cloud Messaging (FCM)
**Utilisation** : Notifications critiques (app fermée/arrière-plan)
- "Votre chauffeur est à 1 minute"
- "Course acceptée"
- "Course terminée"

**Configuration** : `backend/utils/notifications.js`

## 🔧 Configuration Cloud Run

### Paramètres Recommandés
```yaml
concurrency: 80
maxInstances: 10
minInstances: 1
timeout: 3600s  # 1 heure (pour WebSocket)
memory: 512Mi
cpu: 1
```

### Variables d'Environnement
```env
REDIS_HOST=10.x.x.x  # IP du Memorystore
REDIS_PORT=6379
REDIS_PASSWORD=  # Optionnel
NODE_ENV=production
PORT=3000
```

## 📈 Optimisations

### 1. Distribution Ciblée
- ❌ Avant : `io.emit()` → Tous les clients
- ✅ Maintenant : `clientNamespace.to('ride:<rideId>').emit()` → Clients de la course uniquement

### 2. Stockage Hybride
- **Redis** : Temps réel (2-3 secondes)
- **PostgreSQL** : Persistance (30 secondes)
- **Performance** : Réduction de 90% de la charge sur PostgreSQL

### 3. Diffusion Automatique
- **DriverLocationBroadcaster** : Diffusion automatique toutes les 2 secondes
- **Source** : Redis (pas de requête PostgreSQL)
- **Ciblage** : Uniquement les courses actives

### 4. Gestion des Erreurs
- Fallback PostgreSQL si Redis indisponible
- Mode dégradé sans interruption de service
- Logging détaillé pour le debugging

## 🧪 Tests

### Test de Connexion WebSocket
```javascript
const io = require('socket.io-client');
const socket = io('http://localhost:3000/ws/client', {
  query: { token: 'your-jwt-token' }
});

socket.on('connect', () => {
  console.log('✅ Connecté');
  socket.emit('ride:join', rideId);
});

socket.on('driver:location:update', (data) => {
  console.log('📍 Position:', data.location);
});
```

### Test de Mise à Jour Position
```bash
curl -X POST http://localhost:3000/api/driver/location/update \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3136,
    "status": "en_route_to_pickup",
    "currentRideId": 123
  }'
```

## 📊 Monitoring

### Métriques à Surveiller
- Nombre de connexions WebSocket actives
- Latence Redis (devrait être < 5ms)
- Nombre de positions diffusées par seconde
- Taux d'erreur de distribution WebSocket
- Utilisation mémoire Redis

### Logs Importants
- `DriverLocationBroadcaster démarré` : Service actif
- `Driver location updated in Redis` : Mise à jour réussie
- `Driver location distributed to ride clients` : Distribution réussie
- `Failed to distribute driver location` : Erreur de distribution

## 🚨 Troubleshooting

### Redis Non Disponible
**Symptôme** : Positions non diffusées
**Solution** : Vérifier la connexion Redis et le VPC Connector

### WebSocket Non Connecté
**Symptôme** : Client ne reçoit pas les mises à jour
**Solution** : Vérifier le token JWT et la connexion au namespace `/ws/client`

### Distribution Non Ciblée
**Symptôme** : Tous les clients reçoivent les positions
**Solution** : Vérifier que `clientNamespace.to('ride:<rideId>')` est utilisé (pas `io.emit()`)

## 📚 Références

- [Socket.IO Documentation](https://socket.io/docs/v4/)
- [Redis Documentation](https://redis.io/documentation)
- [Cloud Run WebSockets](https://cloud.google.com/run/docs/triggering/websockets)
- [Memorystore for Redis](https://cloud.google.com/memorystore/docs/redis)

## ✅ Checklist de Déploiement

- [ ] Redis (Memorystore) configuré et accessible
- [ ] VPC Connector configuré pour Cloud Run
- [ ] Variables d'environnement Redis configurées
- [ ] WebSocket namespaces configurés (`/ws/client`, `/ws/driver`)
- [ ] DriverLocationBroadcaster démarré
- [ ] Tests de connexion WebSocket réussis
- [ ] Tests de mise à jour position réussis
- [ ] Monitoring configuré
- [ ] Logs vérifiés

## 🎉 Résultat Attendu

- ✅ Positions diffusées en temps réel (< 2 secondes)
- ✅ Distribution ciblée (uniquement clients de la course)
- ✅ Performance optimale (Redis < 5ms)
- ✅ Scalabilité (support de milliers de connexions)
- ✅ Fiabilité (fallback PostgreSQL)

