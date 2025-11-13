# 🧪 Guide de Test - Architecture Temps Réel

## 📋 Prérequis

### Backend
- [ ] Backend déployé sur Cloud Run
- [ ] Redis (Memorystore) configuré et accessible
- [ ] VPC Connector configuré pour Cloud Run
- [ ] Variables d'environnement configurées (`REDIS_HOST`, `REDIS_PORT`)

### iOS
- [ ] App iOS compilée et installée
- [ ] Configuration API URL pointant vers Cloud Run
- [ ] Token JWT valide pour l'authentification

## 🧪 Tests Backend

### Test 1 : Vérifier la Connexion Redis

**Objectif** : Vérifier que Redis est accessible depuis Cloud Run

**Commande** :
```bash
# Vérifier les logs Cloud Run
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend" --limit 50 --format json
```

**Logs attendus** :
```json
{
  "textPayload": "Redis connecté avec succès",
  "severity": "INFO"
}
```

**Si erreur** :
- Vérifier que le VPC Connector est configuré
- Vérifier que `REDIS_HOST` et `REDIS_PORT` sont corrects
- Vérifier les règles de firewall

### Test 2 : Vérifier le DriverLocationBroadcaster

**Objectif** : Vérifier que le broadcaster démarre correctement

**Logs attendus** :
```json
{
  "textPayload": "DriverLocationBroadcaster initialisé et démarré",
  "severity": "INFO",
  "jsonPayload": {
    "intervalMs": 2000
  }
}
```

### Test 3 : Tester la Mise à Jour de Position

**Objectif** : Vérifier que la position est stockée dans Redis et distribuée

**Requête** :
```bash
curl -X POST https://YOUR_CLOUD_RUN_URL/api/driver/location/update \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3136,
    "status": "en_route_to_pickup",
    "currentRideId": 123,
    "heading": 45,
    "speed": 30
  }'
```

**Réponse attendue** :
```json
{
  "success": true,
  "location": {
    "latitude": -4.3276,
    "longitude": 15.3136
  },
  "status": "en_route_to_pickup",
  "updatedIn": {
    "redis": true,
    "postgres": true
  }
}
```

**Logs attendus** :
```json
{
  "textPayload": "Driver location updated in Redis",
  "severity": "DEBUG",
  "jsonPayload": {
    "driverId": 1,
    "latitude": -4.3276,
    "longitude": 15.3136,
    "status": "en_route_to_pickup",
    "currentRideId": 123
  }
}
```

```json
{
  "textPayload": "Driver location distributed to ride clients",
  "severity": "DEBUG",
  "jsonPayload": {
    "driverId": 1,
    "rideId": 123,
    "latitude": -4.3276,
    "longitude": 15.3136
  }
}
```

### Test 4 : Tester la Distribution WebSocket

**Objectif** : Vérifier que les positions sont distribuées via WebSocket

**Script Node.js** :
```javascript
const io = require('socket.io-client');

const socket = io('https://YOUR_CLOUD_RUN_URL/ws/client', {
  query: { token: 'YOUR_JWT_TOKEN' },
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('✅ Connecté au WebSocket');
  
  // Rejoindre la room de la course
  socket.emit('ride:join', '123');
  console.log('✅ Rejoint la room ride:123');
});

socket.on('ride:joined', (data) => {
  console.log('✅ Confirmé dans la room:', data);
});

socket.on('driver:location:update', (data) => {
  console.log('📍 Position reçue:', {
    driverId: data.driverId,
    rideId: data.rideId,
    location: data.location,
    timestamp: data.timestamp
  });
});

socket.on('error', (error) => {
  console.error('❌ Erreur:', error);
});

// Attendre 30 secondes pour recevoir les mises à jour
setTimeout(() => {
  socket.disconnect();
  process.exit(0);
}, 30000);
```

**Résultat attendu** :
- Connexion réussie
- Room rejointe avec succès
- Positions reçues toutes les 2 secondes (si un chauffeur met à jour sa position)

## 🧪 Tests iOS

### Test 1 : Vérifier la Connexion WebSocket

**Objectif** : Vérifier que l'app iOS se connecte au WebSocket

**Étapes** :
1. Ouvrir l'app iOS
2. Se connecter en tant que client
3. Vérifier les logs Xcode

**Logs attendus** :
```
✅ IntegrationBridge: Connecté au backend
✅ SocketIOService: Connecté au serveur WebSocket
```

**Si erreur** :
- Vérifier que l'URL du WebSocket est correcte
- Vérifier que le token JWT est valide
- Vérifier la configuration CORS dans le backend

### Test 2 : Tester le Rejoindre une Room

**Objectif** : Vérifier qu'un client peut rejoindre la room d'une course

**Étapes** :
1. Créer une course
2. Accepter la course (simuler un chauffeur)
3. Vérifier les logs

**Logs attendus (iOS)** :
```
✅ Rejoint la room ride:123
```

**Logs attendus (Backend)** :
```
Client a rejoint la course { clientId: '...', rideId: '123' }
```

### Test 3 : Tester la Réception des Positions

**Objectif** : Vérifier qu'un client reçoit les mises à jour de position

**Étapes** :
1. Créer une course et l'accepter
2. Mettre à jour la position du chauffeur (simuler)
3. Vérifier que le client reçoit l'événement
4. Vérifier que la carte se met à jour

**Logs attendus (iOS)** :
```
📍 Position du chauffeur reçue pour la course 123
Driver location: latitude: -4.3276, longitude: 15.3136
```

**Logs attendus (Backend)** :
```
Driver location distributed to ride clients { driverId: 1, rideId: 123 }
```

### Test 4 : Test de Performance

**Objectif** : Vérifier que les positions sont reçues rapidement

**Métriques** :
- Latence entre mise à jour et réception : < 2 secondes
- Fréquence de mise à jour : ~2 secondes
- Pas de perte de messages

**Test** :
1. Mettre à jour la position du chauffeur
2. Mesurer le temps jusqu'à la réception sur iOS
3. Vérifier que la latence est < 2 secondes

## 🐛 Troubleshooting

### Problème 1 : Redis Non Disponible

**Symptôme** : Positions non diffusées

**Vérifications** :
1. Vérifier que Redis est accessible depuis Cloud Run
2. Vérifier que le VPC Connector est configuré
3. Vérifier les variables d'environnement

**Solution** :
```bash
# Vérifier la connexion Redis depuis Cloud Run
gcloud run services describe tshiakani-vtc-backend --region us-central1
```

### Problème 2 : WebSocket Non Connecté

**Symptôme** : Client ne reçoit pas les mises à jour

**Vérifications** :
1. Vérifier que le token JWT est valide
2. Vérifier que le namespace `/ws/client` est utilisé
3. Vérifier la configuration CORS

**Solution** :
- Vérifier les logs backend pour les erreurs d'authentification
- Vérifier que le token est envoyé dans la query string

### Problème 3 : Distribution Non Ciblée

**Symptôme** : Tous les clients reçoivent les positions

**Vérifications** :
1. Vérifier que `clientNamespace.to('ride:<rideId>')` est utilisé
2. Vérifier que le client a rejoint la room `ride:<rideId>`

**Solution** :
- Vérifier les logs backend pour voir quelle room est utilisée
- Vérifier que `ride:join` est émis avec le bon `rideId`

### Problème 4 : Positions Non Reçues

**Symptôme** : Client ne reçoit pas les mises à jour

**Vérifications** :
1. Vérifier que le client a rejoint la room `ride:<rideId>`
2. Vérifier que le chauffeur a un `currentRideId` dans Redis
3. Vérifier que le broadcaster fonctionne

**Solution** :
- Vérifier les logs backend pour voir si la distribution est tentée
- Vérifier que le chauffeur a bien un `currentRideId`

## 📊 Métriques à Surveiller

### Backend
- Nombre de connexions WebSocket actives
- Latence Redis (devrait être < 5ms)
- Nombre de positions diffusées par seconde
- Taux d'erreur de distribution WebSocket
- Utilisation mémoire Redis

### iOS
- Latence de réception des positions
- Fréquence de mise à jour
- Taux de perte de messages
- État de la connexion WebSocket

## ✅ Checklist de Validation

- [ ] Redis est accessible depuis Cloud Run
- [ ] DriverLocationBroadcaster démarre correctement
- [ ] Les positions sont stockées dans Redis
- [ ] Les positions sont distribuées via WebSocket
- [ ] L'app iOS se connecte au WebSocket
- [ ] L'app iOS rejoint la room de la course
- [ ] L'app iOS reçoit les mises à jour de position
- [ ] La carte se met à jour en temps réel
- [ ] La latence est < 2 secondes
- [ ] Il n'y a pas de perte de messages

## 🎯 Résultat Attendu

Après avoir complété tous les tests :
- ✅ Positions diffusées en temps réel (< 2 secondes)
- ✅ Distribution ciblée (uniquement clients de la course)
- ✅ Performance optimale (Redis < 5ms)
- ✅ Scalabilité (support de milliers de connexions)
- ✅ Fiabilité (fallback PostgreSQL)




