# 🎯 Agent Principal Frontend - Documentation

## 📋 Vue d'ensemble

Le `FrontendAgentPrincipal` est l'orchestrateur central de toutes les opérations frontend de l'application Tshiakani VTC. Il coordonne les différents services, gère les transactions complexes, optimise les performances et assure une expérience utilisateur fluide.

## 🏗️ Architecture

Le `FrontendAgentPrincipal` orchestre les services suivants :

- **APIService** : Communication avec le backend
- **LocationService** : Gestion de la localisation
- **RealtimeService** : Communication en temps réel (WebSocket)
- **NotificationService** : Notifications push et locales
- **PaymentService** : Gestion des paiements
- **AddressSearchService** : Recherche d'adresses
- **LocalStorageService** : Stockage local
- **ConfigurationService** : Configuration de l'application

## 🚀 Utilisation

### Initialisation

Le `FrontendAgentPrincipal` est un singleton accessible via `FrontendAgentPrincipal.shared` :

```swift
let agent = FrontendAgentPrincipal.shared
```

### Authentification

#### Se connecter

```swift
let user = try await agent.authenticate(
    phoneNumber: "+243900000000",
    role: .client,
    name: "John Doe"
)
```

#### Se déconnecter

```swift
agent.logout()
```

#### Mettre à jour le profil

```swift
let updatedUser = try await agent.updateProfile(name: "John Doe Updated")
```

### Gestion des Courses

#### Créer une course

```swift
let ride = try await agent.createRide(
    pickupLocation: pickupLocation,
    dropoffLocation: dropoffLocation,
    paymentMethod: .cash
)
```

Le `FrontendAgentPrincipal` s'occupe automatiquement de :
- Vérifier les adresses
- Calculer la distance
- Estimer le prix (via le backend avec IA)
- Créer la course
- Faire le matching avec un conducteur
- Démarrer le suivi en temps réel

#### Annuler une course

```swift
let cancelledRide = try await agent.cancelRide()
// Ou avec un ID spécifique
let cancelledRide = try await agent.cancelRide(rideId: "123")
```

#### Mettre à jour le statut d'une course

```swift
let updatedRide = try await agent.updateRideStatus(
    rideId: "123",
    status: .completed
)
```

#### Évaluer une course

```swift
try await agent.rateRide(
    rideId: "123",
    rating: 5,
    comment: "Excellent service!",
    tip: 1000.0
)
```

### Gestion de la Localisation

#### Demander l'autorisation

```swift
agent.requestLocationPermission()
```

#### Démarrer la mise à jour de la localisation

```swift
agent.startLocationUpdates()
```

#### Arrêter la mise à jour

```swift
agent.stopLocationUpdates()
```

### Recherche d'Adresses

#### Rechercher des adresses

```swift
let addresses = try await agent.searchAddresses(query: "Kinshasa")
```

### Recherche de Conducteurs

#### Trouver des conducteurs disponibles

```swift
await agent.findAvailableDrivers(
    near: location,
    radius: 5.0 // km
)
```

### Historique des Courses

#### Charger l'historique

```swift
await agent.loadRideHistory()
```

### État Observé

Le `FrontendAgentPrincipal` expose plusieurs propriétés `@Published` que vous pouvez observer :

```swift
@StateObject private var agent = FrontendAgentPrincipal.shared

var body: some View {
    VStack {
        if agent.isLoading {
            ProgressView()
        }
        
        if let error = agent.errorMessage {
            Text("Erreur: \(error)")
        }
        
        if let user = agent.currentUser {
            Text("Utilisateur: \(user.name)")
        }
        
        if let ride = agent.currentRide {
            Text("Course: \(ride.id)")
        }
        
        Text("Conducteurs disponibles: \(agent.availableDrivers.count)")
    }
}
```

### Callbacks

Vous pouvez définir des callbacks pour être notifié des événements :

```swift
agent.onRideStatusChanged = { ride in
    print("Statut de course changé: \(ride.status)")
}

agent.onDriverLocationUpdated = { location in
    print("Position du conducteur: \(location.latitude), \(location.longitude)")
}

agent.onRideAccepted = { ride, driver in
    print("Course acceptée par: \(driver.name)")
}

agent.onRideCompleted = { ride in
    print("Course terminée: \(ride.id)")
}

agent.onRideCancelled = { ride in
    print("Course annulée: \(ride.id)")
}

agent.onError = { error in
    print("Erreur: \(error.localizedDescription)")
}
```

## 🔄 Flux de Création de Course

1. **Demande de course** : L'utilisateur crée une course via `createRide()`
2. **Validation** : Le `FrontendAgentPrincipal` vérifie les adresses
3. **Calcul de distance** : Calcul automatique de la distance
4. **Estimation du prix** : Appel au backend pour l'estimation avec IA
5. **Création de la course** : Création via l'API backend
6. **Matching automatique** : Le backend trouve le meilleur conducteur
7. **Notification** : Notification au client et au conducteur
8. **Suivi en temps réel** : Démarrage du suivi de la position du conducteur
9. **Mises à jour** : Mises à jour en temps réel via WebSocket

## 🔔 Notifications Temps Réel

Le `FrontendAgentPrincipal` gère automatiquement les notifications temps réel via `RealtimeService` :

- **Statut de course** : Mises à jour automatiques du statut
- **Position du conducteur** : Mises à jour toutes les 5 secondes
- **Acceptation de course** : Notification immédiate
- **Annulation** : Notification immédiate

## 💾 Cache Local

Le `FrontendAgentPrincipal` sauvegarde automatiquement :

- **Utilisateur connecté** : Sauvegarde dans le cache local
- **Token d'authentification** : Sauvegarde sécurisée
- **Courses actives** : Chargement au démarrage

## 🛡️ Gestion des Erreurs

Le `FrontendAgentPrincipal` gère les erreurs de manière centralisée :

- **Erreurs réseau** : Retry automatique (à implémenter)
- **Erreurs d'authentification** : Déconnexion automatique
- **Erreurs de validation** : Messages d'erreur clairs
- **Erreurs serveur** : Gestion gracieuse avec messages utilisateur

## 🎨 Exemple d'Intégration dans une Vue

```swift
struct RideRequestView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    @State private var pickupLocation: Location?
    @State private var dropoffLocation: Location?
    
    var body: some View {
        VStack {
            // Formulaire de course
            // ...
            
            Button("Créer la course") {
                Task {
                    do {
                        guard let pickup = pickupLocation,
                              let dropoff = dropoffLocation else {
                            return
                        }
                        
                        let ride = try await agent.createRide(
                            pickupLocation: pickup,
                            dropoffLocation: dropoff,
                            paymentMethod: .cash
                        )
                        
                        // Navigation vers l'écran de suivi
                    } catch {
                        // Gestion de l'erreur
                        print("Erreur: \(error.localizedDescription)")
                    }
                }
            }
            .disabled(agent.isLoading)
        }
        .onAppear {
            // Configurer les callbacks
            agent.onRideStatusChanged = { ride in
                // Mettre à jour l'UI
            }
            
            agent.onDriverLocationUpdated = { location in
                // Mettre à jour la carte
            }
        }
    }
}
```

## 📊 Statistiques et Métriques

Le `FrontendAgentPrincipal` peut être étendu pour collecter des métriques :

- Temps de réponse des API
- Taux de succès des courses
- Temps moyen de matching
- Erreurs rencontrées

## 🔧 Configuration

Le `FrontendAgentPrincipal` utilise `ConfigurationService` pour :

- URLs de l'API backend
- URLs WebSocket
- Timeouts
- Paramètres de retry

## 🚨 Bonnes Pratiques

1. **Toujours utiliser le singleton** : `FrontendAgentPrincipal.shared`
2. **Observer l'état** : Utiliser `@StateObject` ou `@ObservedObject`
3. **Gérer les erreurs** : Toujours gérer les erreurs dans les blocs `do-catch`
4. **Nettoyer les ressources** : Le `FrontendAgentPrincipal` nettoie automatiquement les ressources
5. **Utiliser les callbacks** : Définir les callbacks pour les événements importants

## 📝 Notes

- Le `FrontendAgentPrincipal` est thread-safe
- Toutes les opérations asynchrones utilisent `async/await`
- Les mises à jour de l'UI sont automatiquement dispatchées sur le thread principal
- Le cache local est automatiquement géré

## 🔄 Comparaison avec BackendAgentPrincipal

Le `FrontendAgentPrincipal` est le pendant frontend du `BackendAgentPrincipal` :

| BackendAgentPrincipal | FrontendAgentPrincipal |
|----------------------|----------------------|
| Orchestre les services backend | Orchestre les services frontend |
| Gère les transactions database | Gère les appels API |
| Matching des conducteurs | Affichage des résultats |
| Notifications FCM | Réception des notifications |
| WebSocket server | WebSocket client |

## 🎯 Prochaines Étapes

- [ ] Implémenter le retry automatique pour les erreurs réseau
- [ ] Ajouter la mise en cache des résultats de recherche
- [ ] Implémenter la collecte de métriques
- [ ] Ajouter le support offline
- [ ] Implémenter la synchronisation des données

