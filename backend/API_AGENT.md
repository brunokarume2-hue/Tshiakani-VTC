# API Agent Backend - Documentation

## Vue d'ensemble

L'API Agent permet aux agents (gestionnaires) de gérer les chauffeurs, les courses, les clients et les alertes SOS dans l'application Tshiakani VTC.

## Authentification

Toutes les routes de l'API Agent nécessitent une authentification avec un token JWT. L'utilisateur doit avoir le rôle `agent` ou `admin`.

### Headers requis
```
Authorization: Bearer <token_jwt>
```

### Middleware
- `agentAuth`: Vérifie que l'utilisateur est authentifié et a le rôle `agent` ou `admin`

## Endpoints

### Statistiques

#### GET /api/agent/stats
Obtenir les statistiques générales pour les agents.

**Réponse:**
```json
{
  "drivers": {
    "total": 150,
    "active": 45,
    "pending": 12
  },
  "rides": {
    "total": 5432,
    "today": 125,
    "pending": 8,
    "active": 15,
    "completed": 5409
  },
  "revenue": {
    "total": 1250000.50
  }
}
```

### Gestion des Chauffeurs

#### GET /api/agent/drivers
Obtenir la liste des chauffeurs avec filtres.

**Query Parameters:**
- `status` (string, optionnel): Filtrer par statut des documents (`pending`, `validated`, `rejected`)
- `isOnline` (boolean, optionnel): Filtrer par statut en ligne (`true`, `false`)
- `page` (number, optionnel): Numéro de page (défaut: 1)
- `limit` (number, optionnel): Nombre d'éléments par page (défaut: 50)
- `search` (string, optionnel): Recherche par nom ou numéro de téléphone

**Réponse:**
```json
{
  "drivers": [
    {
      "id": 1,
      "name": "Jean Dupont",
      "phoneNumber": "+243900000000",
      "isVerified": true,
      "driverInfo": {
        "isOnline": true,
        "status": "available",
        "documentsStatus": "validated",
        "rating": 4.5,
        "totalRides": 150
      },
      "location": {
        "latitude": -4.3276,
        "longitude": 15.3136
      },
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 150,
    "pages": 3
  }
}
```

#### GET /api/agent/drivers/:driverId
Obtenir les détails d'un chauffeur.

**Réponse:**
```json
{
  "id": 1,
  "name": "Jean Dupont",
  "phoneNumber": "+243900000000",
  "isVerified": true,
  "driverInfo": {
    "isOnline": true,
    "status": "available",
    "documentsStatus": "validated",
    "documents": {
      "license": {
        "status": "validated",
        "validatedAt": "2024-01-01T00:00:00.000Z"
      }
    }
  },
  "location": {
    "latitude": -4.3276,
    "longitude": 15.3136
  },
  "stats": {
    "totalRides": 150,
    "averageRating": 4.5,
    "totalEarnings": 125000.50
  },
  "recentRides": [...],
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

#### POST /api/agent/drivers/:driverId/validate
Valider les documents d'un chauffeur.

**Body:**
```json
{
  "documentType": "license", // Optionnel: valider un document spécifique
  "reason": "Documents conformes" // Optionnel
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Documents validés avec succès",
  "driver": {
    "id": 1,
    "driverInfo": {...}
  }
}
```

#### POST /api/agent/drivers/:driverId/reject
Rejeter les documents d'un chauffeur.

**Body:**
```json
{
  "documentType": "license", // Optionnel: rejeter un document spécifique
  "reason": "Document expiré" // Requis
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Documents rejetés",
  "driver": {
    "id": 1,
    "driverInfo": {...}
  }
}
```

#### POST /api/agent/drivers/:driverId/activate
Activer un chauffeur.

**Réponse:**
```json
{
  "success": true,
  "message": "Chauffeur activé avec succès",
  "driver": {
    "id": 1,
    "driverInfo": {...}
  }
}
```

#### POST /api/agent/drivers/:driverId/deactivate
Désactiver un chauffeur.

**Body:**
```json
{
  "reason": "Violation des règles" // Optionnel
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Chauffeur désactivé avec succès",
  "driver": {
    "id": 1,
    "driverInfo": {...}
  }
}
```

### Gestion des Courses

#### GET /api/agent/rides
Obtenir la liste des courses avec filtres.

**Query Parameters:**
- `status` (string, optionnel): Filtrer par statut (`pending`, `accepted`, `inProgress`, `completed`, `cancelled`)
- `page` (number, optionnel): Numéro de page (défaut: 1)
- `limit` (number, optionnel): Nombre d'éléments par page (défaut: 50)
- `startDate` (string, optionnel): Date de début (ISO 8601)
- `endDate` (string, optionnel): Date de fin (ISO 8601)
- `driverId` (number, optionnel): Filtrer par ID du chauffeur
- `clientId` (number, optionnel): Filtrer par ID du client

**Réponse:**
```json
{
  "rides": [
    {
      "id": 1,
      "status": "accepted",
      "pickupAddress": "123 Rue Example",
      "dropoffAddress": "456 Avenue Example",
      "estimatedPrice": 5000,
      "finalPrice": 5200,
      "distance": 5.2,
      "duration": 15,
      "paymentMethod": "cash",
      "client": {
        "id": 10,
        "name": "Client Example",
        "phoneNumber": "+243900000001"
      },
      "driver": {
        "id": 1,
        "name": "Jean Dupont",
        "phoneNumber": "+243900000000"
      },
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 5432,
    "pages": 109
  }
}
```

#### GET /api/agent/rides/:rideId
Obtenir les détails d'une course.

**Réponse:**
```json
{
  "id": 1,
  "status": "accepted",
  "pickupLocation": {
    "latitude": -4.3276,
    "longitude": 15.3136
  },
  "pickupAddress": "123 Rue Example",
  "dropoffLocation": {
    "latitude": -4.3376,
    "longitude": 15.3236
  },
  "dropoffAddress": "456 Avenue Example",
  "estimatedPrice": 5000,
  "finalPrice": 5200,
  "distance": 5.2,
  "duration": 15,
  "paymentMethod": "cash",
  "rating": 5,
  "comment": "Excellent service",
  "client": {...},
  "driver": {...},
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

#### POST /api/agent/rides/:rideId/assign
Assigner manuellement un chauffeur à une course.

**Body:**
```json
{
  "driverId": 1
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Chauffeur assigné avec succès",
  "ride": {
    "id": 1,
    "status": "accepted",
    "driverId": 1
  }
}
```

#### POST /api/agent/rides/:rideId/cancel
Annuler une course (par un agent).

**Body:**
```json
{
  "reason": "Client n'a pas répondu"
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Course annulée avec succès",
  "ride": {
    "id": 1,
    "status": "cancelled",
    "cancelledAt": "2024-01-01T00:00:00.000Z",
    "cancellationReason": "Annulée par un agent: Client n'a pas répondu"
  }
}
```

### Gestion des Alertes SOS

#### GET /api/agent/sos
Obtenir la liste des alertes SOS.

**Query Parameters:**
- `status` (string, optionnel): Filtrer par statut (`pending`, `resolved`)
- `page` (number, optionnel): Numéro de page (défaut: 1)
- `limit` (number, optionnel): Nombre d'éléments par page (défaut: 50)

**Réponse:**
```json
{
  "sosReports": [
    {
      "id": 1,
      "status": "pending",
      "message": "Aide nécessaire",
      "location": {...},
      "user": {...},
      "ride": {...},
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 25,
    "pages": 1
  }
}
```

#### POST /api/agent/sos/:sosId/resolve
Résoudre une alerte SOS.

**Body:**
```json
{
  "resolution": "Problème résolu, assistance fournie" // Optionnel
}
```

**Réponse:**
```json
{
  "success": true,
  "message": "Alerte SOS résolue avec succès",
  "sosReport": {...}
}
```

### Gestion des Clients

#### GET /api/agent/clients
Obtenir la liste des clients.

**Query Parameters:**
- `page` (number, optionnel): Numéro de page (défaut: 1)
- `limit` (number, optionnel): Nombre d'éléments par page (défaut: 50)
- `search` (string, optionnel): Recherche par nom ou numéro de téléphone

**Réponse:**
```json
{
  "clients": [
    {
      "id": 10,
      "name": "Client Example",
      "phoneNumber": "+243900000001",
      "isVerified": true,
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 500,
    "pages": 10
  }
}
```

#### GET /api/agent/clients/:clientId
Obtenir les détails d'un client.

**Réponse:**
```json
{
  "id": 10,
  "name": "Client Example",
  "phoneNumber": "+243900000001",
  "isVerified": true,
  "stats": {
    "totalRides": 50,
    "completedRides": 48,
    "totalSpending": 250000.50
  },
  "recentRides": [...],
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Codes d'erreur

- `400`: Requête invalide (paramètres manquants ou invalides)
- `401`: Non authentifié (token manquant ou invalide)
- `403`: Accès refusé (rôle insuffisant)
- `404`: Ressource non trouvée
- `500`: Erreur serveur

## Notifications

L'API Agent envoie automatiquement des notifications push aux utilisateurs concernés lors de certaines actions :
- Validation/rejet de documents (chauffeur)
- Activation/désactivation de compte (chauffeur)
- Assignation manuelle de course (client et chauffeur)
- Annulation de course (client et chauffeur)
- Résolution d'alerte SOS (utilisateur)

## Exemple d'utilisation

### Obtenir les statistiques
```bash
curl -X GET http://localhost:3000/api/agent/stats \
  -H "Authorization: Bearer <token>"
```

### Valider les documents d'un chauffeur
```bash
curl -X POST http://localhost:3000/api/agent/drivers/1/validate \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Documents conformes"
  }'
```

### Assigner un chauffeur à une course
```bash
curl -X POST http://localhost:3000/api/agent/rides/1/assign \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "driverId": 1
  }'
```

### Résoudre une alerte SOS
```bash
curl -X POST http://localhost:3000/api/agent/sos/1/resolve \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "resolution": "Problème résolu, assistance fournie"
  }'
```

## Notes importantes

1. **Permissions**: Les agents ont accès à toutes les fonctionnalités de gestion, mais ne peuvent pas modifier les configurations système (réservé aux admins).

2. **Notifications**: Les notifications sont envoyées automatiquement via Firebase Cloud Messaging (FCM) si configuré.

3. **Transactions**: Les opérations critiques (comme l'assignation de courses) utilisent des transactions PostgreSQL pour garantir la cohérence des données.

4. **Pagination**: Toutes les listes supportent la pagination pour optimiser les performances.

5. **Recherche**: La recherche est disponible pour les chauffeurs et les clients par nom ou numéro de téléphone.

