# 📱 API Client V1 - Documentation Complète

## Vue d'ensemble

Ce document décrit l'API Backend Client pour la gestion des demandes de course. Tous les endpoints sont préfixés par `/api/v1/client`.

## Authentification

Tous les endpoints nécessitent une authentification JWT via le header `Authorization`:
```
Authorization: Bearer <token>
```

## Endpoints

### 1. POST /api/v1/client/estimate

Calcule l'itinéraire, l'estimation de prix (fourchette), la distance et le temps d'attente pour différentes catégories de véhicules.

**Requête:**
```json
{
  "pickupLocation": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Gombe, Kinshasa"
  },
  "dropoffLocation": {
    "latitude": -4.3416,
    "longitude": 15.3106,
    "address": "Kinshasa, RDC"
  },
  "vehicleCategory": "standard" // optionnel: "standard", "premium", "luxury"
}
```

**Réponse:**
```json
{
  "success": true,
  "distance": {
    "kilometers": 2.5,
    "meters": 2500
  },
  "estimatedDuration": {
    "minutes": 5,
    "seconds": 300
  },
  "estimatedWaitTime": {
    "minutes": 3,
    "seconds": 180
  },
  "availableDriversCount": 5,
  "estimates": {
    "standard": {
      "priceRange": {
        "min": 1800,
        "max": 2200
      },
      "estimatedPrice": 2000,
      "basePrice": 1500,
      "multiplier": 1.0
    },
    "premium": {
      "priceRange": {
        "min": 2340,
        "max": 2860
      },
      "estimatedPrice": 2600,
      "basePrice": 1950,
      "multiplier": 1.3
    },
    "luxury": {
      "priceRange": {
        "min": 2880,
        "max": 3520
      },
      "estimatedPrice": 3200,
      "basePrice": 2400,
      "multiplier": 1.6
    }
  },
  "pricing": {
    "breakdown": {
      "base": 500,
      "distance": 1000,
      "timeAdjustment": 0,
      "dayAdjustment": 0,
      "surgeAdjustment": 0
    },
    "explanation": "Tarif standard",
    "multipliers": {
      "time": 1.0,
      "day": 1.0,
      "surge": 1.0
    }
  },
  "route": {
    "pickup": {
      "latitude": -4.3276,
      "longitude": 15.3136,
      "address": "Gombe, Kinshasa"
    },
    "dropoff": {
      "latitude": -4.3416,
      "longitude": 15.3106,
      "address": "Kinshasa, RDC"
    }
  },
  "timestamp": "2025-01-15T10:30:00.000Z"
}
```

---

### 2. POST /api/v1/client/command/request

Passe une nouvelle commande de course. Enregistre la demande en base de données, la met en statut "Pending" et initie le processus d'attribution à un chauffeur.

**Requête:**
```json
{
  "pickupLocation": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Gombe, Kinshasa"
  },
  "dropoffLocation": {
    "latitude": -4.3416,
    "longitude": 15.3106,
    "address": "Kinshasa, RDC"
  },
  "paymentMethod": "cash", // optionnel: "cash", "mobile_money", "card"
  "vehicleCategory": "standard" // optionnel: "standard", "premium", "luxury"
}
```

**Réponse:**
```json
{
  "success": true,
  "ride": {
    "id": 123,
    "status": "pending",
    "clientId": 1,
    "driverId": null,
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136,
      "address": "Gombe, Kinshasa"
    },
    "dropoffLocation": {
      "latitude": -4.3416,
      "longitude": 15.3106,
      "address": "Kinshasa, RDC"
    },
    "estimatedPrice": 2000,
    "distance": 2.5,
    "paymentMethod": "cash",
    "vehicleCategory": "standard",
    "createdAt": "2025-01-15T10:30:00.000Z"
  },
  "pricing": {
    "estimatedPrice": 2000,
    "basePrice": 1500,
    "breakdown": {
      "base": 500,
      "distance": 1000,
      "timeAdjustment": 0,
      "dayAdjustment": 0,
      "surgeAdjustment": 0
    },
    "explanation": "Tarif standard"
  },
  "message": "Commande créée avec succès. Recherche de chauffeur en cours..."
}
```

---

### 3. GET /api/v1/client/command/status/:ride_id

Récupère le statut actuel de la course.

**Statuts possibles:**
- `Pending`: Course créée, en attente
- `Searching`: Recherche de chauffeur en cours
- `Accepted`: Chauffeur assigné
- `InProgress`: Course en cours
- `Completed`: Course terminée
- `Canceled`: Course annulée

**Réponse:**
```json
{
  "success": true,
  "rideId": 123,
  "status": "Accepted",
  "statusCode": "accepted",
  "clientId": 1,
  "driverId": 5,
  "driver": {
    "id": 5,
    "name": "Jean Dupont",
    "phoneNumber": "+243900000000"
  },
  "pickupLocation": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Gombe, Kinshasa"
  },
  "dropoffLocation": {
    "latitude": -4.3416,
    "longitude": 15.3106,
    "address": "Kinshasa, RDC"
  },
  "estimatedPrice": 2000,
  "finalPrice": null,
  "distance": 2.5,
  "paymentMethod": "cash",
  "createdAt": "2025-01-15T10:30:00.000Z",
  "startedAt": null,
  "completedAt": null,
  "cancelledAt": null,
  "timestamp": "2025-01-15T10:35:00.000Z"
}
```

---

### 4. POST /api/v1/client/command/cancel/:ride_id

Annule une course. Gère la logique des frais d'annulation si applicable (selon le statut).

**Règles de frais d'annulation:**
- Avant acceptation (pending/searching): 0% (gratuit)
- Après acceptation mais avant départ (accepted): 20% du prix estimé
- En cours (inProgress): 50% du prix estimé

**Requête:**
```json
{
  "reason": "Changement de plan" // optionnel
}
```

**Réponse:**
```json
{
  "success": true,
  "rideId": 123,
  "status": "Canceled",
  "cancelledAt": "2025-01-15T10:40:00.000Z",
  "cancellationReason": "Changement de plan",
  "cancellationFee": 400,
  "message": "Course annulée. Frais d'annulation: 400 CDF",
  "refundInfo": {
    "amount": 400,
    "currency": "CDF",
    "message": "Les frais d'annulation seront débités de votre compte"
  }
}
```

---

### 5. GET /api/v1/client/driver/location/:driver_id

Récupère la position GPS du chauffeur attribué en temps réel pour l'affichage sur la carte du client.

**Réponse:**
```json
{
  "success": true,
  "driver": {
    "id": 5,
    "name": "Jean Dupont",
    "phoneNumber": "+243900000000",
    "status": "en_route_to_pickup",
    "isOnline": true
  },
  "location": {
    "latitude": -4.3280,
    "longitude": 15.3140,
    "timestamp": "2025-01-15T10:35:00.000Z",
    "accuracy": null
  },
  "rideId": 123,
  "timestamp": "2025-01-15T10:35:00.000Z"
}
```

---

### 6. GET /api/v1/client/history

Récupère l'historique des courses du client.

**Paramètres de requête:**
- `page` (optionnel): Numéro de page (défaut: 1)
- `limit` (optionnel): Nombre de résultats par page (défaut: 20, max: 100)
- `status` (optionnel): Filtrer par statut ("pending", "accepted", "inProgress", "completed", "cancelled")

**Exemple:**
```
GET /api/v1/client/history?page=1&limit=20&status=completed
```

**Réponse:**
```json
{
  "success": true,
  "rides": [
    {
      "id": 123,
      "status": "completed",
      "driver": {
        "id": 5,
        "name": "Jean Dupont",
        "phoneNumber": "+243900000000"
      },
      "pickupLocation": {
        "latitude": -4.3276,
        "longitude": 15.3136,
        "address": "Gombe, Kinshasa"
      },
      "dropoffLocation": {
        "latitude": -4.3416,
        "longitude": 15.3106,
        "address": "Kinshasa, RDC"
      },
      "estimatedPrice": 2000,
      "finalPrice": 2000,
      "distance": 2.5,
      "paymentMethod": "cash",
      "rating": 5,
      "comment": "Excellent service !",
      "createdAt": "2025-01-15T10:30:00.000Z",
      "startedAt": "2025-01-15T10:35:00.000Z",
      "completedAt": "2025-01-15T10:40:00.000Z",
      "cancelledAt": null
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1,
    "hasNext": false,
    "hasPrev": false
  },
  "filters": {
    "status": "completed"
  },
  "timestamp": "2025-01-15T10:45:00.000Z"
}
```

---

### 7. POST /api/v1/client/rate/:ride_id

Soumet l'évaluation (note et commentaire) du chauffeur après la course.

**Requête:**
```json
{
  "rating": 5,
  "comment": "Excellent service, chauffeur ponctuel et professionnel !" // optionnel, max 500 caractères
}
```

**Réponse:**
```json
{
  "success": true,
  "rideId": 123,
  "rating": 5,
  "comment": "Excellent service, chauffeur ponctuel et professionnel !",
  "driver": {
    "id": 5,
    "name": "Jean Dupont",
    "newAverageRating": 4.8
  },
  "message": "Évaluation enregistrée avec succès",
  "timestamp": "2025-01-15T10:45:00.000Z"
}
```

---

## WebSocket - Suivi en Temps Réel

### Connexion

Pour recevoir les mises à jour en temps réel, connectez-vous au namespace WebSocket `/ws/client`:

```javascript
const socket = io('http://localhost:3000/ws/client', {
  query: {
    token: 'your_jwt_token'
  }
});
```

### Événements Client → Serveur

#### `ride:join`
Rejoindre la room d'une course pour recevoir les mises à jour:
```javascript
socket.emit('ride:join', rideId);
```

#### `ride:leave`
Quitter la room d'une course:
```javascript
socket.emit('ride:leave', rideId);
```

#### `ping`
Envoyer un ping pour maintenir la connexion:
```javascript
socket.emit('ping');
```

### Événements Serveur → Client

#### `connected`
Connexion établie:
```json
{
  "type": "connected",
  "message": "Connexion établie",
  "clientId": 1
}
```

#### `ride:joined`
Confirmation de rejoindre une course:
```json
{
  "type": "ride_joined",
  "rideId": 123,
  "message": "Vous suivez maintenant cette course"
}
```

#### `ride_update`
Mise à jour de la course en temps réel:
```json
{
  "type": "ride_accepted",
  "rideId": "123",
  "driverId": "5",
  "driverName": "Jean Dupont",
  "timestamp": "2025-01-15T10:35:00.000Z",
  "ride": {
    "id": 123,
    "status": "accepted",
    "driverId": 5,
    "driverName": "Jean Dupont",
    "pickupAddress": "Gombe, Kinshasa",
    "dropoffAddress": "Kinshasa, RDC",
    "estimatedPrice": 2000
  }
}
```

**Types de mises à jour:**
- `searching_drivers`: Recherche de chauffeur en cours
- `ride_accepted`: Course acceptée par un chauffeur
- `ride_update`: Mise à jour du statut de la course
- `ride_cancelled`: Course annulée
- `no_driver_available`: Aucun chauffeur disponible
- `all_drivers_rejected`: Tous les chauffeurs ont refusé

#### `error`
Erreur:
```json
{
  "type": "ride_not_found",
  "message": "Course non trouvée"
}
```

#### `pong`
Réponse au ping:
```json
{
  "type": "pong"
}
```

---

## Gestion des Erreurs

### Codes de statut HTTP

- `200`: Succès
- `201`: Créé avec succès
- `400`: Requête invalide (données manquantes ou invalides)
- `401`: Non authentifié (token manquant ou invalide)
- `403`: Accès refusé (permissions insuffisantes)
- `404`: Ressource non trouvée
- `500`: Erreur serveur

### Format des erreurs

```json
{
  "error": "Course non trouvée",
  "message": "Aucune course trouvée avec l'ID 123"
}
```

---

## Exemples d'utilisation

### Flux complet d'une course

1. **Estimer le prix:**
```bash
POST /api/v1/client/estimate
```

2. **Créer la commande:**
```bash
POST /api/v1/client/command/request
```

3. **Se connecter au WebSocket et rejoindre la course:**
```javascript
socket.emit('ride:join', rideId);
socket.on('ride_update', (data) => {
  console.log('Mise à jour:', data);
});
```

4. **Vérifier le statut:**
```bash
GET /api/v1/client/command/status/:ride_id
```

5. **Suivre la position du chauffeur:**
```bash
GET /api/v1/client/driver/location/:driver_id
```

6. **Évaluer après la course:**
```bash
POST /api/v1/client/rate/:ride_id
```

---

## Notes importantes

1. **Géolocalisation**: Le système utilise PostGIS pour les calculs de distance et la recherche de chauffeurs à proximité.

2. **Temps réel**: Pour un suivi en temps réel optimal, utilisez le namespace WebSocket `/ws/client` plutôt que de poller régulièrement les endpoints REST.

3. **Frais d'annulation**: Les frais d'annulation sont calculés automatiquement selon le statut de la course au moment de l'annulation.

4. **Catégories de véhicules**: 
   - `standard`: Multiplicateur 1.0
   - `premium`: Multiplicateur 1.3
   - `luxury`: Multiplicateur 1.6

5. **Prix dynamique**: Le système calcule automatiquement le prix en fonction de:
   - La distance
   - L'heure de la journée (heures de pointe, nuit)
   - Le jour de la semaine (week-end)
   - La demande (surge pricing)

---

## Support

Pour toute question ou problème, contactez l'équipe de développement.

