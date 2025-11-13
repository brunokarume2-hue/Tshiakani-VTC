# 🎯 Backend Agent Principal - Documentation

## Vue d'ensemble

Le **Backend Agent Principal** est l'orchestrateur central de toutes les opérations du backend Tshiakani VTC. Il coordonne les services, gère les transactions complexes, optimise les performances et garantit la cohérence des données.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│         Backend Agent Principal                         │
│  (Orchestrateur Central)                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Pricing    │  │   Matching   │  │   Payment    │ │
│  │   Service    │  │   Service    │  │   Service    │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Database   │  │  WebSocket   │  │ Notification │ │
│  │   (TypeORM)  │  │   (Socket.io)│  │   (FCM)      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Fonctionnalités

### 1. Gestion des Courses

#### `createRide(rideData)`
Crée une nouvelle course avec pricing automatique et matching de conducteur.

**Paramètres:**
- `rideData.clientId` (number) - ID du client
- `rideData.pickupLocation` (Object) - {latitude, longitude}
- `rideData.dropoffLocation` (Object) - {latitude, longitude}
- `rideData.pickupAddress` (string) - Adresse de départ
- `rideData.dropoffAddress` (string) - Adresse d'arrivée
- `rideData.paymentMethod` (string) - Méthode de paiement

**Retour:**
```javascript
{
  ride: Ride,
  pricing: {
    price: number,
    basePrice: number,
    multipliers: {
      time: number,
      day: number,
      surge: number
    }
  },
  matching: {
    driver: {
      id: number,
      name: string
    },
    score: number,
    breakdown: Object
  } | null
}
```

**Exemple:**
```javascript
const agent = new BackendAgentPrincipal(io, driverNamespace, clientNamespace);

const result = await agent.createRide({
  clientId: 1,
  pickupLocation: { latitude: -4.3276, longitude: 15.3136 },
  dropoffLocation: { latitude: -4.3376, longitude: 15.3236 },
  pickupAddress: "123 Rue Example",
  dropoffAddress: "456 Avenue Example",
  paymentMethod: "cash"
});
```

#### `acceptRide(rideId, driverId)`
Accepte une course par un conducteur.

**Paramètres:**
- `rideId` (number) - ID de la course
- `driverId` (number) - ID du conducteur

**Retour:**
```javascript
{
  ride: Ride,
  driver: {
    id: number,
    name: string,
    phoneNumber: string
  }
}
```

#### `updateRideStatus(rideId, status, options)`
Met à jour le statut d'une course.

**Paramètres:**
- `rideId` (number) - ID de la course
- `status` (string) - Nouveau statut ('pending', 'accepted', 'inProgress', 'completed', 'cancelled')
- `options` (Object) - Options supplémentaires
  - `finalPrice` (number) - Prix final (pour status 'completed')
  - `reason` (string) - Raison d'annulation (pour status 'cancelled')

**Retour:**
- `Ride` - Course mise à jour

### 2. Gestion des Conducteurs

#### `updateDriverLocation(driverId, location)`
Met à jour la position d'un conducteur.

**Paramètres:**
- `driverId` (number) - ID du conducteur
- `location` (Object) - {latitude, longitude}

**Retour:**
- `User` - Conducteur mis à jour

#### `updateDriverAvailability(driverId, isOnline)`
Met à jour le statut de disponibilité d'un conducteur.

**Paramètres:**
- `driverId` (number) - ID du conducteur
- `isOnline` (boolean) - Statut en ligne

**Retour:**
- `User` - Conducteur mis à jour

### 3. Utilitaires

#### `calculateDistance(point1, point2)`
Calcule la distance entre deux points (en kilomètres).

**Paramètres:**
- `point1` (Object) - {latitude, longitude}
- `point2` (Object) - {latitude, longitude}

**Retour:**
- `number` - Distance en kilomètres

#### `getStatistics()`
Obtient les statistiques globales du système.

**Retour:**
```javascript
{
  drivers: {
    total: number,
    active: number
  },
  clients: {
    total: number
  },
  rides: {
    total: number,
    today: number,
    pending: number,
    active: number,
    completed: number
  },
  revenue: {
    total: number
  }
}
```

## Intégration

### Dans le serveur principal

```javascript
const BackendAgentPrincipal = require('./services/BackendAgentPrincipal');
const { io, driverNamespace, clientNamespace } = require('./server.postgres');

// Initialiser l'agent principal
const backendAgent = new BackendAgentPrincipal(io, driverNamespace, clientNamespace);

// Si vous utilisez le service temps réel
const realtimeService = require('./server.postgres').getRealtimeRideService();
backendAgent.setRealtimeService(realtimeService);

// Exporter pour utilisation dans les routes
module.exports = backendAgent;
```

### Dans les routes

```javascript
const backendAgent = require('../services/BackendAgentPrincipal');

// Créer une course
router.post('/rides/create', async (req, res) => {
  try {
    const result = await backendAgent.createRide(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Accepter une course
router.post('/rides/:rideId/accept', async (req, res) => {
  try {
    const result = await backendAgent.acceptRide(
      parseInt(req.params.rideId),
      req.user.id
    );
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Gestion des Transactions

Toutes les opérations critiques utilisent des transactions PostgreSQL pour garantir la cohérence des données :

- Création de course
- Acceptation de course
- Mise à jour de statut
- Assignation de conducteur

En cas d'erreur, les transactions sont automatiquement annulées (rollback).

## Notifications

L'agent principal envoie automatiquement des notifications via :

1. **WebSocket (Socket.io)** - Pour les mises à jour en temps réel
2. **Firebase Cloud Messaging (FCM)** - Pour les notifications push

### Événements WebSocket

**Client:**
- `ride:status:changed` - Changement de statut de course
- `driver:location:update` - Mise à jour de position du conducteur

**Conducteur:**
- `ride_request` - Nouvelle demande de course
- `ride:status:changed` - Changement de statut de course

## Optimisations

### Cache
- Configuration des prix mise en cache (5 minutes)
- Réduction des requêtes à la base de données

### Transactions
- Transactions optimisées pour réduire les verrous
- Rollback automatique en cas d'erreur

### Requêtes
- Requêtes optimisées avec PostGIS
- Index spatiaux pour les recherches géographiques

## Gestion d'erreurs

Toutes les erreurs sont loggées avec :
- Message d'erreur
- Stack trace
- Contexte (paramètres, IDs, etc.)

Les erreurs sont également propagées pour être gérées par le middleware d'erreurs Express.

## Exemples d'utilisation

### Créer une course avec matching automatique

```javascript
const result = await backendAgent.createRide({
  clientId: 1,
  pickupLocation: { latitude: -4.3276, longitude: 15.3136 },
  dropoffLocation: { latitude: -4.3376, longitude: 15.3236 },
  pickupAddress: "Avenue Example",
  dropoffAddress: "Boulevard Example",
  paymentMethod: "cash"
});

if (result.matching) {
  console.log(`Conducteur assigné: ${result.matching.driver.name}`);
  console.log(`Score de matching: ${result.matching.score}`);
} else {
  console.log('Aucun conducteur disponible, en attente...');
}
```

### Mettre à jour le statut d'une course

```javascript
// Course en cours
await backendAgent.updateRideStatus(rideId, 'inProgress');

// Course terminée
await backendAgent.updateRideStatus(rideId, 'completed', {
  finalPrice: 5500
});

// Course annulée
await backendAgent.updateRideStatus(rideId, 'cancelled', {
  reason: 'Client n\'a pas répondu'
});
```

### Obtenir les statistiques

```javascript
const stats = await backendAgent.getStatistics();

console.log(`Conducteurs actifs: ${stats.drivers.active}`);
console.log(`Courses aujourd'hui: ${stats.rides.today}`);
console.log(`Revenus totaux: ${stats.revenue.total} CDF`);
```

## Notes importantes

1. **Transactions**: Toutes les opérations critiques utilisent des transactions pour garantir la cohérence des données.

2. **Notifications**: Les notifications sont envoyées automatiquement via WebSocket et FCM.

3. **Matching**: Le matching automatique utilise un algorithme de scoring basé sur la distance, la note, la disponibilité et la performance.

4. **Pricing**: Le pricing dynamique prend en compte l'heure, le jour, la demande et la distance.

5. **Performance**: Les requêtes sont optimisées avec des index spatiaux PostGIS pour les recherches géographiques.

## Dépendances

- `typeorm` - ORM pour PostgreSQL
- `socket.io` - WebSocket pour les communications temps réel
- `firebase-admin` - Notifications push (FCM)
- `DriverMatchingService` - Service de matching de conducteurs
- `PricingService` - Service de pricing dynamique
- `PaymentService` - Service de paiement

## Tests

Pour tester l'agent principal :

```javascript
const BackendAgentPrincipal = require('./services/BackendAgentPrincipal');

// Initialiser avec mock IO
const mockIO = {
  to: () => ({
    emit: () => {}
  })
};

const agent = new BackendAgentPrincipal(mockIO, mockIO, mockIO);

// Tester la création de course
const result = await agent.createRide({
  clientId: 1,
  pickupLocation: { latitude: -4.3276, longitude: 15.3136 },
  dropoffLocation: { latitude: -4.3376, longitude: 15.3236 },
  pickupAddress: "Test",
  dropoffAddress: "Test",
  paymentMethod: "cash"
});
```

## Support

Pour toute question ou problème, consultez la documentation du projet ou contactez l'équipe de développement.

