# Configuration Firebase pour Wewa Taxi

Ce guide détaille les étapes nécessaires pour configurer Firebase dans votre application Wewa Taxi.

## 1. Création du projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/) et connectez-vous.
2. Cliquez sur "Ajouter un projet" ou "Add project".
3. Suivez les étapes pour créer votre projet Firebase.
4. Notez votre **Project ID** - vous en aurez besoin pour la configuration.

## 2. Ajout de l'application iOS

1. Dans votre projet Firebase, cliquez sur l'icône iOS pour ajouter une application iOS.
2. Entrez votre **Bundle ID** (ex: `com.wewataxi.app`).
3. Téléchargez le fichier `GoogleService-Info.plist`.
4. Ajoutez ce fichier à votre projet Xcode (glissez-le dans le dossier du projet).

## 3. Installation du package Firebase

Dans Xcode :

1. Allez dans `File > Add Package Dependencies...`
2. Entrez l'URL : `https://github.com/firebase/firebase-ios-sdk`
3. Sélectionnez les produits suivants :
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
4. Cliquez sur "Add Package".

## 4. Configuration de l'application

Ouvrez `wewa_taxiApp.swift` et ajoutez l'initialisation Firebase :

```swift
import SwiftUI
import FirebaseCore

@main
struct wewa_taxiApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Initialiser Firebase
        FirebaseApp.configure()
        
        // Demander les permissions de notification au démarrage
        NotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                if authViewModel.currentUser?.role == .client {
                    ClientMainView()
                } else if authViewModel.currentUser?.role == .driver {
                    DriverMainView()
                } else {
                    AdminDashboardView()
                }
            } else {
                WelcomeView()
            }
        }
        .environmentObject(authViewModel)
    }
}
```

## 5. Structure Firestore

Firestore est une base de données NoSQL. Voici la structure recommandée pour Wewa Taxi :

### Collection `users`

Chaque document représente un utilisateur (client, driver ou admin) :

```json
{
  "id": "user_id_123",
  "name": "Jean Dupont",
  "phoneNumber": "+243900000000",
  "role": "client", // ou "driver", "admin"
  "isVerified": true,
  "driverInfo": {
    "licensePlate": "ABC-123",
    "vehicleModel": "Honda CG",
    "rating": 4.5,
    "isOnline": false,
    "currentLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136,
      "address": "Kinshasa, RDC"
    }
  }
}
```

### Collection `rides`

Chaque document représente une course :

```json
{
  "id": "ride_id_456",
  "clientId": "user_id_123",
  "driverId": "driver_id_789",
  "pickupLocation": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Point de départ"
  },
  "dropoffLocation": {
    "latitude": -4.3500,
    "longitude": 15.3200,
    "address": "Destination"
  },
  "status": "pending", // "pending", "accepted", "driverArriving", "inProgress", "completed", "cancelled"
  "estimatedPrice": 5000,
  "finalPrice": 5000,
  "distance": 2.5,
  "createdAt": "2025-11-08T10:00:00Z",
  "startedAt": "2025-11-08T10:05:00Z",
  "completedAt": "2025-11-08T10:20:00Z"
}
```

### Collection `driverLocations`

Chaque document représente la position actuelle d'un driver :

```json
{
  "driver_id": "driver_id_789",
  "location": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Position actuelle"
  }
}
```

## 6. Règles de sécurité Firestore

Dans Firebase Console, allez dans `Firestore Database > Rules` et configurez les règles suivantes :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règles pour les utilisateurs
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Règles pour les courses
    match /rides/{rideId} {
      allow read: if request.auth != null && (
        resource.data.clientId == request.auth.uid ||
        resource.data.driverId == request.auth.uid ||
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
      );
      allow create: if request.auth != null && request.resource.data.clientId == request.auth.uid;
      allow update: if request.auth != null && (
        resource.data.clientId == request.auth.uid ||
        resource.data.driverId == request.auth.uid
      );
    }
    
    // Règles pour les positions des drivers
    match /driverLocations/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == driverId;
    }
  }
}
```

## 7. Configuration de l'authentification par téléphone

1. Dans Firebase Console, allez dans `Authentication > Sign-in method`.
2. Activez "Phone" comme méthode de connexion.
3. Configurez un fournisseur de SMS (Firebase utilise par défaut son propre service pour le développement).
4. Pour la production, configurez un fournisseur comme Twilio.

## 8. Index Firestore (optionnel mais recommandé)

Pour améliorer les performances des requêtes, créez des index composites dans Firebase Console :

1. Allez dans `Firestore Database > Indexes`.
2. Créez un index composite pour les courses :
   - Collection: `rides`
   - Champs: `clientId` (Ascending), `createdAt` (Descending)
3. Créez un autre index pour les drivers :
   - Collection: `rides`
   - Champs: `driverId` (Ascending), `status` (Ascending)

## 9. Test de la configuration

1. Compilez et lancez l'application.
2. Essayez de vous connecter avec un numéro de téléphone.
3. Vérifiez dans Firebase Console que les données sont bien créées dans Firestore.

## 10. Avantages de Firebase par rapport à Supabase

- **Plus simple à configurer** : Pas besoin de configurer une base de données SQL
- **Temps réel intégré** : Firestore offre des listeners en temps réel natifs
- **Authentification facile** : Firebase Auth est très simple à utiliser
- **Évolutif** : Firebase gère automatiquement la scalabilité
- **Gratuit pour commencer** : Plan gratuit généreux pour le développement

## Support

Pour plus d'informations, consultez la [documentation Firebase](https://firebase.google.com/docs/ios/setup).

