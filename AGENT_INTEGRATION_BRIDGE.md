# 🌉 Agent Intégration / Bridge - Tshiakani VTC

## 📋 Vue d'ensemble

L'**Agent Intégration / Bridge** est un système unifié qui facilite la communication entre l'application iOS et le backend Node.js. Il centralise la configuration, gère les connexions WebSocket/Socket.io, transforme les données entre formats, et fournit une interface cohérente pour tous les services.

## 🏗️ Architecture

### Services Principaux

#### 1. **ConfigurationService** 
Service de configuration centralisé qui gère :
- URLs de base (API et WebSocket)
- Endpoints API
- Configuration des timeouts et reconnexions
- Gestion des tokens d'authentification
- Stockage des préférences utilisateur

**Localisation**: `Tshiakani VTC/Services/ConfigurationService.swift`

**Fonctionnalités**:
- Configuration des URLs (développement/production)
- Gestion centralisée des endpoints
- Configuration des timeouts HTTP et WebSocket
- Gestion des tokens JWT
- Stockage sécurisé des credentials

#### 2. **DataTransformService**
Service de transformation des données qui convertit :
- Modèles iOS (Ride, User, Location) ↔ Format backend JSON
- Gestion des formats de dates (ISO8601)
- Transformation bidirectionnelle des données

**Localisation**: `Tshiakani VTC/Services/DataTransformService.swift`

**Fonctionnalités**:
- Conversion Ride iOS ↔ Backend
- Conversion User iOS ↔ Backend
- Conversion Location iOS ↔ Backend
- Conversion DriverInfo iOS ↔ Backend
- Parsing des messages Socket.io

#### 3. **SocketIOService**
Service de communication WebSocket/Socket.io qui gère :
- Connexions WebSocket avec le backend
- Reconnexion automatique
- Ping/Pong (keep-alive)
- Émission et réception d'événements
- Gestion des erreurs de connexion

**Localisation**: `Tshiakani VTC/Services/SocketIOService.swift`

**Fonctionnalités**:
- Connexion WebSocket avec authentification
- Reconnexion automatique avec backoff exponentiel
- Ping/Pong pour maintenir la connexion
- Émission d'événements Socket.io
- Réception et traitement des événements
- Gestion des files d'attente de messages

#### 4. **IntegrationBridgeService**
Service principal d'intégration qui unifie :
- ConfigurationService
- SocketIOService
- DataTransformService
- APIService (indirectement)

**Localisation**: `Tshiakani VTC/Services/IntegrationBridgeService.swift`

**Fonctionnalités**:
- Connexion unifiée au backend
- Gestion des rooms Socket.io
- Callbacks unifiés pour les événements
- Gestion de l'authentification
- Synchronisation entre API REST et WebSocket

## 🔌 Intégration avec le Backend

### Communication REST API

L'application iOS communique avec le backend via des requêtes HTTP REST :

```
iOS App → APIService → ConfigurationService → Backend API
```

**Endpoints principaux**:
- `POST /api/auth/signin` - Authentification
- `POST /api/rides/create` - Création de course
- `POST /api/rides/estimate-price` - Calcul de prix
- `GET /api/client/track_driver/:rideId` - Suivi du chauffeur
- `GET /api/rides/history/:userId` - Historique des courses

### Communication WebSocket/Socket.io

L'application iOS communique en temps réel avec le backend via WebSocket :

```
iOS App → SocketIOService → Backend Socket.io
```

**Événements Socket.io**:
- `ride_request` - Nouvelle demande de course
- `ride:status:changed` - Changement de statut de course
- `driver:location:update` - Mise à jour de position du chauffeur
- `ride:accepted` - Course acceptée
- `ride:cancelled` - Course annulée

**Namespaces**:
- `/ws/driver` - Namespace pour les conducteurs
- `/` (default) - Namespace pour les clients

## 📱 Utilisation dans l'Application iOS

### Configuration Initiale

```swift
// Dans AppDelegate ou SceneDelegate
let bridge = IntegrationBridgeService.shared

// Configurer l'authentification après connexion
bridge.setAuthentication(
    userId: user.id,
    userRole: user.role,
    token: authToken
)

// Se connecter au backend
bridge.connect()
```

### Écouter les Événements

```swift
let bridge = IntegrationBridgeService.shared

// Écouter les nouvelles demandes de course
bridge.onRideRequest = { ride in
    print("Nouvelle course: \(ride.id)")
}

// Écouter les changements de statut
bridge.onRideStatusChanged = { ride in
    print("Statut de la course \(ride.id): \(ride.status)")
}

// Écouter les mises à jour de position du chauffeur
bridge.onDriverLocationUpdate = { driverId, location in
    print("Position du chauffeur \(driverId): \(location)")
}
```

### Rejoindre une Room Socket.io

```swift
// Rejoindre la room d'une course pour recevoir les mises à jour
bridge.joinRideRoom(rideId: "123")

// Quitter la room
bridge.leaveRideRoom(rideId: "123")
```

### Mettre à Jour le Statut d'une Course

```swift
// Émettre un événement de mise à jour de statut
bridge.emitRideStatusUpdate(
    rideId: "123",
    status: .inProgress
)
```

### Mettre à Jour la Position du Chauffeur

```swift
// Mettre à jour la position en temps réel
let location = Location(
    latitude: 4.3276,
    longitude: 15.3136,
    address: nil
)

bridge.updateDriverLocation(
    driverId: "456",
    location: location
)
```

## 🔄 Flux de Communication

### Création d'une Course

```
1. Client crée une course
   ↓
2. APIService.createRide() → Backend API
   ↓
3. Backend crée la course et assigne un chauffeur
   ↓
4. Backend émet événement Socket.io "ride_request"
   ↓
5. SocketIOService reçoit l'événement
   ↓
6. IntegrationBridgeService.onRideRequest callback
   ↓
7. Application iOS met à jour l'UI
```

### Suivi d'une Course en Temps Réel

```
1. Client rejoint la room de la course
   ↓
2. SocketIOService.joinRoom("ride:123")
   ↓
3. Backend émet événements "ride:status:changed"
   ↓
4. SocketIOService reçoit les événements
   ↓
5. IntegrationBridgeService.onRideStatusChanged callback
   ↓
6. Application iOS met à jour l'UI en temps réel
```

### Mise à Jour de Position du Chauffeur

```
1. Chauffeur met à jour sa position
   ↓
2. IntegrationBridgeService.updateDriverLocation()
   ↓
3. SocketIOService émet événement "driver:location"
   ↓
4. Backend reçoit et diffuse la position
   ↓
5. Clients dans la room reçoivent "driver:location:update"
   ↓
6. Application iOS met à jour la carte
```

## 🔐 Sécurité

### Authentification

- **JWT Token**: Stocké dans `ConfigurationService` via `UserDefaults`
- **WebSocket Authentication**: Token passé en query parameter lors de la connexion
- **Token Refresh**: Géré par `APIService` lors des requêtes HTTP

### Configuration

- **URLs**: Configurables via `ConfigurationService` (développement/production)
- **Timeouts**: Configurables pour HTTP et WebSocket
- **Reconnexion**: Automatique avec backoff exponentiel

## 🛠️ Configuration

### URLs de Développement

```swift
// ConfigurationService.swift
#if DEBUG
return "http://localhost:3000/api"  // API
return "http://localhost:3000"      // WebSocket
#else
return "https://api.tshiakani-vtc.com/api"  // API
return "https://api.tshiakani-vtc.com"      // WebSocket
#endif
```

### Configuration des Timeouts

```swift
// ConfigurationService.swift
var httpTimeout: TimeInterval {
    return 30.0  // 30 secondes
}

var socketConnectionTimeout: TimeInterval {
    return 10.0  // 10 secondes
}

var socketReconnectInterval: TimeInterval {
    return 5.0   // 5 secondes
}
```

## 📊 Avantages

### 1. **Centralisation**
- Toute la configuration est centralisée dans `ConfigurationService`
- Facilite la maintenance et les changements

### 2. **Réutilisabilité**
- Services réutilisables dans toute l'application
- Interface cohérente pour tous les services

### 3. **Robustesse**
- Reconnexion automatique en cas de déconnexion
- Gestion des erreurs centralisée
- Files d'attente pour les messages

### 4. **Flexibilité**
- Supporte différents environnements (dev/prod)
- Configuration facile des timeouts et reconnexions
- Extensible pour de nouveaux endpoints

### 5. **Maintenabilité**
- Code modulaire et bien organisé
- Documentation complète
- Facile à tester et déboguer

## 🚀 Prochaines Étapes

### Améliorations Futures

1. **Cache Local**
   - Mise en cache des données fréquemment utilisées
   - Synchronisation automatique avec le backend

2. **Offline Support**
   - Support du mode hors ligne
   - File d'attente des requêtes en attente

3. **Analytics**
   - Suivi des performances
   - Logging des erreurs

4. **Tests Unitaires**
   - Tests pour chaque service
   - Tests d'intégration

5. **Documentation**
   - Documentation API complète
   - Exemples d'utilisation

## 📝 Notes Techniques

### Socket.io Protocol

Le service utilise `URLSessionWebSocketTask` natif d'iOS pour se connecter au serveur Socket.io. Le protocole Socket.io est géré manuellement pour la compatibilité avec le backend Node.js.

### Transformation des Données

Les transformations de données utilisent `JSONSerialization` et `Codable` pour convertir entre les modèles iOS et le format JSON du backend.

### Gestion des Erreurs

Toutes les erreurs sont capturées et propagées via les callbacks `onError` pour une gestion centralisée.

## 🔗 Liens Utiles

- [Backend API Documentation](../backend/README.md)
- [Socket.io Documentation](https://socket.io/docs/v4/)
- [URLSessionWebSocketTask Documentation](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)

---

**Créé le**: 08/11/2025  
**Version**: 1.0.0  
**Auteur**: Admin

