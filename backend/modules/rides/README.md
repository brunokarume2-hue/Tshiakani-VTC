# Module de Communication Temps Réel pour les Courses

Ce module gère la communication en temps réel entre les clients, les chauffeurs et le serveur via Socket.io et Firebase Cloud Messaging.

## 🚀 Fonctionnalités

### Événements Socket.io

1. **ride_request** : Quand un client crée une course
   - Le serveur trouve les chauffeurs proches
   - Envoie `ride_offer` à tous les chauffeurs proches

2. **ride_offer** : Offre de course envoyée aux chauffeurs proches
   - Envoyé via Socket.io (si le chauffeur est connecté)
   - Envoyé via Firebase Cloud Messaging (notification push)

3. **ride_accepted** : Quand un chauffeur accepte une course
   - Gestion de la concurrence : seul le premier chauffeur qui accepte gagne
   - Notifie le client via Socket.io et FCM
   - Notifie les autres chauffeurs que la course a été acceptée

4. **ride_update** : Mises à jour en temps réel
   - Statuts : `driverArriving`, `inProgress`, `completed`, `cancelled`
   - Notifie les deux parties (client et chauffeur) via Socket.io et FCM

## 📡 Architecture

### Service Temps Réel (`realtimeService.js`)

- **processRideRequest(ride)** : Traite une nouvelle demande de course
- **handleRideAcceptance(driverId, rideId, socket)** : Gère l'acceptation d'une course
- **handleRideRejection(driverId, rideId)** : Gère le rejet d'une course
- **handleRideStatusUpdate(driverId, rideId, status)** : Gère les mises à jour de statut
- **findNearbyDrivers(latitude, longitude, radiusKm)** : Trouve les chauffeurs proches

### Gestion de la Concurrence

Le système gère la concurrence pour éviter qu'une course soit acceptée par plusieurs chauffeurs :

1. Quand une course est créée, elle est ajoutée à `activeRides` avec `accepted: false`
2. Les chauffeurs notifiés sont ajoutés à `pendingOffers[rideId]`
3. Quand un chauffeur accepte :
   - Vérification atomique : `if (!rideStatus.accepted)`
   - Marquage immédiat : `rideStatus.accepted = true`
   - Les autres chauffeurs reçoivent `ride:unavailable`

## 🔔 Notifications Firebase Cloud Messaging

### Types de notifications

- **ride_offer** : Nouvelle course disponible
- **ride_accepted** : Course acceptée
- **ride_rejected** : Course refusée
- **ride_status_update** : Mise à jour de statut
- **ride_completed** : Course terminée
- **payment_validated** : Paiement validé

### Configuration

Les notifications sont configurées pour :
- **Android** : Canal `rides_channel`, priorité haute
- **iOS** : Badge, son, content-available
- **Web** : Icon et badge

## 🛠️ Utilisation

### Dans les routes

```javascript
const { getRealtimeRideService } = require('../server.postgres');

// Créer une course
const realtimeRideService = getRealtimeRideService();
await realtimeRideService.processRideRequest(ride);
```

### Dans l'app Client (Socket.io)

```javascript
// Se connecter
const socket = io('http://localhost:3000');

// Rejoindre une course
socket.emit('ride:join', rideId);

// Écouter les mises à jour
socket.on('ride_update', (data) => {
  console.log('Mise à jour:', data);
  // data.type: 'searching_drivers', 'ride_accepted', 'ride_update', etc.
});
```

### Dans l'app Driver (Socket.io)

```javascript
// Se connecter au namespace driver
const socket = io('http://localhost:3000/ws/driver', {
  query: { token: driverToken }
});

// Écouter les offres de course
socket.on('ride_offer', (data) => {
  console.log('Nouvelle course:', data.ride);
});

// Accepter une course
socket.emit('ride:accept', { rideId: rideId });

// Refuser une course
socket.emit('ride:reject', { rideId: rideId });

// Mettre à jour le statut
socket.emit('ride:status:update', {
  rideId: rideId,
  status: 'driverArriving' // ou 'inProgress', 'completed'
});
```

## 🔧 Configuration

### Variables d'environnement

```env
# Firebase Cloud Messaging
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# JWT pour l'authentification Socket.io
JWT_SECRET=your-jwt-secret
```

### Nettoyage automatique

Les courses expirées (plus de 10 minutes sans acceptation) sont nettoyées automatiquement toutes les 5 minutes.

## 📝 Notes

- Le système fonctionne même si Firebase n'est pas configuré (les notifications push seront simplement ignorées)
- Les notifications Socket.io fonctionnent en temps réel
- Les notifications FCM fonctionnent même si l'app est en arrière-plan
- La gestion de la concurrence garantit qu'une course ne peut être acceptée qu'une seule fois

