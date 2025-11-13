# 🚀 Guide de Démarrage Rapide - FrontendAgentPrincipal

## 📋 Introduction

Ce guide vous aidera à intégrer rapidement le `FrontendAgentPrincipal` dans votre application iOS Tshiakani VTC.

## ⚡ Démarrage en 5 Minutes

### Étape 1 : Importer l'Agent

Dans votre vue ou ViewModel, importez et créez une instance de l'agent :

```swift
import SwiftUI

struct MyView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    
    var body: some View {
        // Votre vue
    }
}
```

### Étape 2 : Utiliser l'Authentification

```swift
Button("Se connecter") {
    Task {
        do {
            let user = try await agent.authenticate(
                phoneNumber: "+243900000000",
                role: .client,
                name: "John Doe"
            )
            print("Connecté: \(user.name)")
        } catch {
            print("Erreur: \(error.localizedDescription)")
        }
    }
}
```

### Étape 3 : Créer une Course

```swift
Button("Créer une course") {
    Task {
        do {
            let ride = try await agent.createRide(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                paymentMethod: .cash
            )
            print("Course créée: \(ride.id)")
        } catch {
            print("Erreur: \(error.localizedDescription)")
        }
    }
}
```

### Étape 4 : Observer l'État

```swift
struct MyView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    
    var body: some View {
        VStack {
            if agent.isLoading {
                ProgressView()
            }
            
            if let error = agent.errorMessage {
                Text("Erreur: \(error)")
                    .foregroundColor(.red)
            }
            
            if let user = agent.currentUser {
                Text("Utilisateur: \(user.name)")
            }
            
            if let ride = agent.currentRide {
                Text("Course: \(ride.id)")
                    .onChange(of: ride.status) { status in
                        print("Statut changé: \(status)")
                    }
            }
        }
    }
}
```

### Étape 5 : Configurer les Callbacks

```swift
struct MyView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    
    var body: some View {
        VStack {
            // Votre vue
        }
        .onAppear {
            setupCallbacks()
        }
    }
    
    private func setupCallbacks() {
        agent.onRideStatusChanged = { ride in
            print("Statut changé: \(ride.status)")
        }
        
        agent.onDriverLocationUpdated = { location in
            print("Position conducteur: \(location.latitude), \(location.longitude)")
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
    }
}
```

## 📱 Exemples Complets

### Exemple 1 : Vue d'Authentification

```swift
struct LoginView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    @State private var phoneNumber = ""
    @State private var name = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Numéro de téléphone", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Nom", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Se connecter") {
                Task {
                    do {
                        let user = try await agent.authenticate(
                            phoneNumber: phoneNumber,
                            role: .client,
                            name: name.isEmpty ? nil : name
                        )
                        // Navigation automatique si agent.isAuthenticated devient true
                    } catch {
                        // L'erreur est automatiquement dans agent.errorMessage
                    }
                }
            }
            .disabled(agent.isLoading)
            
            if agent.isLoading {
                ProgressView()
            }
            
            if let error = agent.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onChange(of: agent.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                // Naviguer vers l'écran d'accueil
            }
        }
    }
}
```

### Exemple 2 : Vue de Création de Course

```swift
struct RideRequestView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    @State private var pickupLocation: Location?
    @State private var dropoffLocation: Location?
    @State private var searchQuery = ""
    
    var body: some View {
        VStack {
            // Recherche d'adresses
            TextField("Rechercher une adresse", text: $searchQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    Task {
                        do {
                            let addresses = try await agent.searchAddresses(query: searchQuery)
                            // Afficher les résultats
                        } catch {
                            // Gérer l'erreur
                        }
                    }
                }
            
            // Sélection de l'adresse de départ
            if let pickup = pickupLocation {
                Text("Départ: \(pickup.address ?? "Adresse inconnue")")
            }
            
            // Sélection de l'adresse d'arrivée
            if let dropoff = dropoffLocation {
                Text("Arrivée: \(dropoff.address ?? "Adresse inconnue")")
            }
            
            // Bouton de création
            Button("Créer la course") {
                Task {
                    guard let pickup = pickupLocation,
                          let dropoff = dropoffLocation else {
                        return
                    }
                    
                    do {
                        let ride = try await agent.createRide(
                            pickupLocation: pickup,
                            dropoffLocation: dropoff,
                            paymentMethod: .cash
                        )
                        // Navigation automatique vers l'écran de suivi
                    } catch {
                        // L'erreur est dans agent.errorMessage
                    }
                }
            }
            .disabled(agent.isLoading || pickupLocation == nil || dropoffLocation == nil)
        }
        .padding()
        .onAppear {
            agent.requestLocationPermission()
            agent.startLocationUpdates()
        }
    }
}
```

### Exemple 3 : Vue de Suivi de Course

```swift
struct RideTrackingView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    
    var body: some View {
        VStack {
            if let ride = agent.currentRide {
                // Informations de la course
                Text("Course #\(ride.id)")
                Text("Statut: \(ride.status.rawValue)")
                
                // Prix
                if let finalPrice = ride.finalPrice {
                    Text("Prix: \(finalPrice) CDF")
                } else {
                    Text("Prix estimé: \(ride.estimatedPrice) CDF")
                }
                
                // Position du conducteur
                if let driverLocation = ride.driverLocation {
                    Text("Position conducteur: \(driverLocation.latitude), \(driverLocation.longitude)")
                }
                
                // Bouton d'annulation
                if ride.status == .pending || ride.status == .accepted {
                    Button("Annuler la course") {
                        Task {
                            do {
                                let cancelledRide = try await agent.cancelRide()
                                // La course est automatiquement mise à jour
                            } catch {
                                // Gérer l'erreur
                            }
                        }
                    }
                }
            } else {
                Text("Aucune course en cours")
            }
            
            if agent.isLoading {
                ProgressView()
            }
        }
        .padding()
        .onAppear {
            setupCallbacks()
        }
        .onChange(of: agent.currentRide?.status) { status in
            if let status = status {
                handleStatusChange(status)
            }
        }
    }
    
    private func setupCallbacks() {
        agent.onRideStatusChanged = { ride in
            print("Statut changé: \(ride.status)")
        }
        
        agent.onDriverLocationUpdated = { location in
            print("Position mise à jour: \(location.latitude), \(location.longitude)")
            // Mettre à jour la carte
        }
        
        agent.onRideAccepted = { ride, driver in
            print("Course acceptée par: \(driver.name)")
        }
        
        agent.onRideCompleted = { ride in
            print("Course terminée")
            // Naviguer vers l'écran d'évaluation
        }
        
        agent.onRideCancelled = { ride in
            print("Course annulée")
            // Naviguer vers l'écran d'accueil
        }
    }
    
    private func handleStatusChange(_ status: RideStatus) {
        switch status {
        case .accepted:
            // Afficher les informations du conducteur
            break
        case .driverArriving:
            // Afficher "Le conducteur arrive"
            break
        case .inProgress:
            // Afficher "Course en cours"
            break
        case .completed:
            // Naviguer vers l'écran d'évaluation
            break
        case .cancelled:
            // Naviguer vers l'écran d'accueil
            break
        default:
            break
        }
    }
}
```

### Exemple 4 : Vue d'Historique

```swift
struct RideHistoryView: View {
    @StateObject private var agent = FrontendAgentPrincipal.shared
    
    var body: some View {
        List(agent.rideHistory) { ride in
            VStack(alignment: .leading) {
                Text("Course #\(ride.id)")
                Text("Statut: \(ride.status.rawValue)")
                Text("Prix: \(ride.finalPrice ?? ride.estimatedPrice) CDF")
                Text("Date: \(ride.createdAt, style: .date)")
            }
        }
        .onAppear {
            Task {
                await agent.loadRideHistory()
            }
        }
        .refreshable {
            await agent.loadRideHistory()
        }
    }
}
```

## 🔧 Configuration Avancée

### Gestion des Erreurs Personnalisée

```swift
agent.onError = { error in
    if let apiError = error as? APIError {
        switch apiError.type {
        case .authentication:
            // Rediriger vers l'écran de connexion
            break
        case .network:
            // Afficher un message de réseau
            break
        case .server:
            // Afficher un message de serveur
            break
        default:
            // Afficher un message générique
            break
        }
    }
}
```

### Recherche de Conducteurs

```swift
Task {
    if let currentLocation = agent.locationService.currentLocation {
        await agent.findAvailableDrivers(near: currentLocation, radius: 5.0)
        
        // Les conducteurs sont dans agent.availableDrivers
        print("Conducteurs disponibles: \(agent.availableDrivers.count)")
    }
}
```

### Mise à Jour du Profil

```swift
Button("Mettre à jour le profil") {
    Task {
        do {
            let updatedUser = try await agent.updateProfile(name: "Nouveau nom")
            print("Profil mis à jour: \(updatedUser.name)")
        } catch {
            print("Erreur: \(error.localizedDescription)")
        }
    }
}
```

## 📊 Bonnes Pratiques

### 1. Toujours Utiliser le Singleton

```swift
// ✅ Bon
@StateObject private var agent = FrontendAgentPrincipal.shared

// ❌ Mauvais
let agent = FrontendAgentPrincipal()
```

### 2. Observer l'État avec @StateObject

```swift
// ✅ Bon
@StateObject private var agent = FrontendAgentPrincipal.shared

// ❌ Mauvais
@ObservedObject private var agent = FrontendAgentPrincipal.shared
```

### 3. Gérer les Erreurs

```swift
// ✅ Bon
do {
    let result = try await agent.createRide(...)
} catch {
    // Gérer l'erreur
    print("Erreur: \(error.localizedDescription)")
}

// ❌ Mauvais
let result = try? await agent.createRide(...)
```

### 4. Configurer les Callbacks dans onAppear

```swift
// ✅ Bon
.onAppear {
    agent.onRideStatusChanged = { ride in
        // Gérer le changement
    }
}

// ❌ Mauvais
init() {
    agent.onRideStatusChanged = { ride in
        // Peut causer des problèmes de cycle de vie
    }
}
```

### 5. Nettoyer les Ressources

```swift
// ✅ Bon
.onDisappear {
    // L'agent nettoie automatiquement les ressources
    // Mais vous pouvez arrêter les mises à jour si nécessaire
    agent.stopLocationUpdates()
}
```

## 🚨 Problèmes Courants

### Problème 1 : L'agent n'est pas mis à jour

**Solution** : Assurez-vous d'utiliser `@StateObject` au lieu de `@ObservedObject`

```swift
// ❌ Mauvais
@ObservedObject private var agent = FrontendAgentPrincipal.shared

// ✅ Bon
@StateObject private var agent = FrontendAgentPrincipal.shared
```

### Problème 2 : Les callbacks ne sont pas appelés

**Solution** : Assurez-vous de configurer les callbacks après que l'agent soit connecté

```swift
.onAppear {
    if agent.isAuthenticated {
        setupCallbacks()
    }
}

.onChange(of: agent.isAuthenticated) { isAuthenticated in
    if isAuthenticated {
        setupCallbacks()
    }
}
```

### Problème 3 : Les erreurs ne sont pas affichées

**Solution** : Observer `agent.errorMessage` et l'afficher dans l'UI

```swift
if let error = agent.errorMessage {
    Text(error)
        .foregroundColor(.red)
}
```

## 📚 Ressources

- [Documentation complète](./FRONTEND_AGENT_PRINCIPAL.md)
- [Plan d'intégration](./PLAN_INTEGRATION_FRONTEND_AGENT.md)
- [BackendAgentPrincipal](../backend/services/BackendAgentPrincipal.js)

## ✅ Checklist de Démarrage

- [ ] Importer `FrontendAgentPrincipal` dans votre vue
- [ ] Créer une instance avec `@StateObject`
- [ ] Configurer les callbacks dans `onAppear`
- [ ] Observer l'état avec `onChange` ou `@Published`
- [ ] Gérer les erreurs avec `do-catch`
- [ ] Tester les fonctionnalités de base
- [ ] Vérifier que les notifications fonctionnent
- [ ] Valider l'expérience utilisateur

## 🎯 Prochaines Étapes

1. **Lire la documentation complète** : [FRONTEND_AGENT_PRINCIPAL.md](./FRONTEND_AGENT_PRINCIPAL.md)
2. **Suivre le plan d'intégration** : [PLAN_INTEGRATION_FRONTEND_AGENT.md](./PLAN_INTEGRATION_FRONTEND_AGENT.md)
3. **Commencer par AuthViewModel** : Migration la plus simple
4. **Tester intensivement** : S'assurer que tout fonctionne
5. **Migrer progressivement** : Une vue à la fois

