# 🔗 Système de Communication - Wewa Taxi

## Vue d'ensemble

Le système de communication en temps réel permet la synchronisation fluide entre les applications Client, Driver et le Dashboard Admin.

## Architecture

### Services principaux

1. **RealtimeService** : Gestion de la communication en temps réel
2. **NotificationService** : Gestion des notifications push et locales
3. **APIService** : Communication avec le backend REST

## Flux de communication

### 1. Client → Backend → Driver

#### Demande de course
```
1. Client crée une demande (RideRequestView)
   ↓
2. RideViewModel.requestRide() 
   ↓
3. RealtimeService.sendRideRequest()
   ↓
4. Backend reçoit la demande
   ↓
5. Backend notifie les drivers proches
   ↓
6. DriverViewModel reçoit via onNewRideRequest
   ↓
7. NotificationService.notifyNewRideRequest()
```

#### Statut de la course
```
Client suit le statut via:
- RealtimeService.onRideStatusChanged
- RealtimeService.onRideAccepted
- RealtimeService.onDriverLocationUpdated
```

### 2. Driver → Backend → Client

#### Acceptation de course
```
1. Driver accepte (DriverViewModel.acceptRide())
   ↓
2. RealtimeService.acceptRide()
   ↓
3. Backend met à jour le statut
   ↓
4. Client reçoit via onRideAccepted
   ↓
5. NotificationService.notifyRideAccepted()
```

#### Mise à jour de position
```
1. Driver envoie sa position (toutes les 5 secondes)
   ↓
2. RealtimeService.updateDriverLocation()
   ↓
3. Backend diffuse la position
   ↓
4. Client reçoit via onDriverLocationUpdated
   ↓
5. Carte mise à jour en temps réel
```

#### Changement de statut
```
Statuts possibles:
- pending → En attente
- accepted → Accepté par un driver
- driverArriving → Driver en route
- inProgress → Trajet en cours
- completed → Terminé
- cancelled → Annulé
```

### 3. Admin → Backend → Client/Driver

#### Supervision
```
1. AdminViewModel charge toutes les données
   ↓
2. RealtimeService.onRideStatusChanged (écoute toutes les courses)
   ↓
3. Dashboard mis à jour en temps réel
   ↓
4. Statistiques recalculées automatiquement
```

## Types de messages

### RealtimeMessage

```swift
enum MessageType {
    case rideRequest          // Nouvelle demande
    case rideAccepted         // Course acceptée
    case rideRejected         // Course refusée
    case rideStatusUpdate     // Changement de statut
    case driverLocationUpdate // Position du driver
    case rideCancelled        // Course annulée
}
```

## Notifications

### Pour le Client
- ✅ Course acceptée par un driver
- ✅ Driver en route vers le point de départ
- ✅ Course terminée (demande de notation)
- ✅ Course annulée

### Pour le Driver
- ✅ Nouvelle demande de course disponible
- ✅ Course annulée par le client
- ✅ Course terminée

## Implémentation technique

### WebSocket (recommandé pour production)

```swift
// Connexion WebSocket
let url = URL(string: "wss://api.wewataxi.com/ws")!
let task = URLSession.shared.webSocketTask(with: url)
task.resume()

// Envoi de message
let message = URLSessionWebSocketTask.Message.string(jsonString)
task.send(message) { error in
    // Gestion erreur
}

// Réception de message
task.receive { result in
    switch result {
    case .success(let message):
        // Traiter le message
    case .failure(let error):
        // Gestion erreur
    }
}
```

### Firebase Realtime Database (alternative)

```swift
// Écouter les changements
database.reference()
    .child("rides")
    .child(rideId)
    .observe(.value) { snapshot in
        // Mettre à jour la course
    }

// Mettre à jour
database.reference()
    .child("rides")
    .child(rideId)
    .setValue(rideData)
```

## Sécurité

### Authentification
- Chaque message doit inclure un token d'authentification
- Vérification des permissions (client/driver/admin)

### Validation
- Validation des données côté backend
- Vérification de la cohérence des statuts
- Protection contre les courses multiples simultanées

## Gestion des erreurs

### Reconnexion automatique
```swift
func reconnect() {
    // Tentative de reconnexion avec backoff exponentiel
    // Max 5 tentatives
}
```

### Queue de messages
```swift
// Stocker les messages en cas de déconnexion
// Les renvoyer une fois reconnecté
```

## Performance

### Optimisations
- Mise à jour de position toutes les 5 secondes (pas en continu)
- Filtrage des drivers par zone géographique
- Cache des données fréquemment utilisées

### Monitoring
- Temps de réponse des messages
- Taux de succès des connexions
- Latence de mise à jour

## Tests

### Scénarios à tester
1. Client crée une demande → Driver reçoit
2. Driver accepte → Client est notifié
3. Driver met à jour position → Client voit sur carte
4. Client annule → Driver est notifié
5. Admin voit toutes les courses en temps réel

## Prochaines étapes

- [ ] Implémenter WebSocket réel (actuellement simulé)
- [ ] Ajouter la queue de messages pour offline
- [ ] Implémenter la reconnexion automatique
- [ ] Ajouter le monitoring et analytics
- [ ] Optimiser la consommation de batterie

