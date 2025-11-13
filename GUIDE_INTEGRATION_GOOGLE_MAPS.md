# Guide d'Intégration Google Maps Platform

Ce guide explique comment intégrer Google Maps SDK, Google Places SDK et Google Directions API dans l'application Tshiakani VTC.

## 📋 Vue d'ensemble

L'application utilise trois composants principaux de Google Maps Platform :

1. **Google Maps SDK** - Affichage de la carte (remplace MapKit)
2. **Google Places SDK** - Autocomplétion d'adresses
3. **Google Directions API** - Calcul des trajets avec trafic en temps réel

## 🔑 Étape 1 : Obtenir une Clé API Google Maps

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez les APIs suivantes :
   - **Maps SDK for iOS**
   - **Places API**
   - **Directions API**
   - **Geocoding API** (optionnel, pour le géocodage inverse)
4. Créez une clé API :
   - Allez dans "APIs & Services" > "Credentials"
   - Cliquez sur "Create Credentials" > "API Key"
   - Copiez la clé API générée

## 📦 Étape 2 : Installer les SDKs via Swift Package Manager

### Option A : Via Xcode (Recommandé)

1. Ouvrez le projet dans Xcode
2. Allez dans **File** > **Add Package Dependencies...**
3. Ajoutez les packages suivants :

#### Google Maps SDK for iOS
```
https://github.com/googlemaps/ios-maps-sdk
```

#### Google Places SDK for iOS
```
https://github.com/googlemaps/ios-places-sdk
```

4. Sélectionnez la dernière version stable
5. Ajoutez les produits suivants à votre target :
   - `GoogleMaps`
   - `GooglePlaces`

### Option B : Via Package.swift (si vous utilisez Swift Package Manager en ligne de commande)

Ajoutez ces dépendances à votre `Package.swift` :

```swift
dependencies: [
    .package(url: "https://github.com/googlemaps/ios-maps-sdk", from: "7.0.0"),
    .package(url: "https://github.com/googlemaps/ios-places-sdk", from: "7.0.0")
]
```

## 🔐 Étape 3 : Configurer la Clé API

### Méthode 1 : Info.plist (Recommandé pour la production)

1. Ouvrez `Info.plist` dans Xcode
2. Ajoutez une nouvelle entrée :
   - **Key**: `GOOGLE_MAPS_API_KEY`
   - **Type**: String
   - **Value**: Votre clé API Google Maps

### Méthode 2 : Variables d'environnement (Pour le développement)

Créez un fichier `.env` ou configurez les variables dans Xcode :
- Scheme > Edit Scheme > Run > Arguments > Environment Variables
- Ajoutez : `GOOGLE_MAPS_API_KEY` = `votre_clé_api`

### Méthode 3 : Configuration directe (Déconseillé pour la production)

Modifiez `TshiakaniVTCApp.swift` et remplacez `"YOUR_API_KEY_HERE"` par votre clé API.

⚠️ **Attention** : Ne commitez jamais votre clé API dans le dépôt Git !

## 🗺️ Étape 4 : Configuration du projet Xcode

### Ajouter les frameworks requis

1. Sélectionnez votre target dans Xcode
2. Allez dans **Build Phases** > **Link Binary With Libraries**
3. Assurez-vous que les frameworks suivants sont présents :
   - `GoogleMaps.framework`
   - `GooglePlaces.framework`
   - `CoreLocation.framework` (déjà présent)

### Configurer les permissions de localisation

1. Ouvrez `Info.plist`
2. Ajoutez les clés suivantes si elles n'existent pas déjà :
   - `NSLocationWhenInUseUsageDescription` : "Nous avons besoin de votre localisation pour trouver les chauffeurs à proximité et calculer les trajets."
   - `NSLocationAlwaysAndWhenInUseUsageDescription` : "Nous avons besoin de votre localisation pour suivre votre course en temps réel."

## 🚀 Étape 5 : Utilisation dans le Code

### Initialisation (déjà fait dans TshiakaniVTCApp.swift)

L'initialisation est automatique au démarrage de l'application. Vérifiez que la clé API est bien configurée.

### Utiliser l'autocomplétion d'adresses

```swift
import SwiftUI

struct MyView: View {
    @StateObject private var placesService = GooglePlacesService.shared
    
    var body: some View {
        GooglePlacesAutocompleteView(
            selectedLocation: $myLocation,
            address: $myAddress
        )
    }
}
```

### Utiliser la carte Google Maps

```swift
import SwiftUI

struct MyMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        GoogleMapView(
            region: $region,
            pickupLocation: $pickupLocation,
            showsUserLocation: true,
            driverAnnotations: [],
            routePolyline: nil,
            onLocationUpdate: nil,
            onRegionChange: nil
        )
    }
}
```

### Calculer un itinéraire avec trafic

```swift
let route = try await GoogleDirectionsService.shared.calculateRoute(
    from: pickupLocation,
    to: dropoffLocation
)

print("Distance: \(route.distance) km")
print("Durée: \(route.duration / 60) minutes")
print("Durée avec trafic: \(route.durationInTraffic ?? route.duration) / 60) minutes")
```

## 📊 Fonctionnalités Implémentées

### ✅ Autocomplétion d'Adresses (Google Places SDK)

- Recherche en temps réel pendant la saisie
- Résultats filtrés pour Kinshasa, RDC
- Récupération des coordonnées précises
- Intégration dans `RideRequestView` et `AddressSearchView`

### ✅ Calcul d'Itinéraire (Google Directions API)

- Distance précise en kilomètres
- Temps de trajet avec trafic en temps réel
- Polyline pour tracer la route sur la carte
- Estimation de prix basée sur distance + temps

### ✅ Affichage de la Carte (Google Maps SDK)

- Remplacement de MapKit par Google Maps
- Marqueurs pour points de départ/destination
- Marqueurs pour les chauffeurs
- Affichage de la route (polyline)
- Suivi de la position en temps réel

## 🔧 Dépannage

### Erreur : "API key not valid"

1. Vérifiez que la clé API est bien configurée dans `Info.plist` ou variables d'environnement
2. Vérifiez que les APIs sont activées dans Google Cloud Console
3. Vérifiez les restrictions de la clé API (iOS Bundle ID, etc.)

### Erreur : "SDK not initialized"

1. Vérifiez que `GoogleMapsService.shared.initialize()` est appelé dans `TshiakaniVTCApp.init()`
2. Vérifiez que la clé API n'est pas vide

### La carte ne s'affiche pas

1. Vérifiez que les frameworks sont bien liés dans Build Phases
2. Vérifiez les logs Xcode pour les erreurs de chargement
3. Vérifiez que la clé API a les bonnes restrictions (Bundle ID)

### L'autocomplétion ne fonctionne pas

1. Vérifiez que Places API est activée dans Google Cloud Console
2. Vérifiez les quotas et limites de l'API
3. Vérifiez les logs pour les erreurs de requête

## 💰 Coûts et Quotas

Google Maps Platform propose un crédit mensuel gratuit :
- **$200 USD de crédit gratuit par mois**
- Cela couvre généralement :
  - ~28,000 requêtes Maps SDK
  - ~17,000 requêtes Places API
  - ~40,000 requêtes Directions API

Au-delà, les tarifs sont :
- Maps SDK : $7 par 1000 chargements de carte
- Places API : $17 par 1000 requêtes
- Directions API : $5 par 1000 requêtes

**Recommandation** : Configurez des alertes de quota dans Google Cloud Console pour éviter les dépassements.

## 📚 Ressources

- [Documentation Google Maps SDK iOS](https://developers.google.com/maps/documentation/ios-sdk)
- [Documentation Google Places SDK iOS](https://developers.google.com/maps/documentation/places/ios-sdk)
- [Documentation Google Directions API](https://developers.google.com/maps/documentation/directions)
- [Guide de tarification](https://developers.google.com/maps/billing-and-pricing/pricing)

## ✅ Checklist d'Installation

- [ ] Clé API Google créée
- [ ] APIs activées dans Google Cloud Console (Maps SDK, Places API, Directions API)
- [ ] Packages Swift installés (GoogleMaps, GooglePlaces)
- [ ] Clé API configurée dans Info.plist ou variables d'environnement
- [ ] Permissions de localisation configurées dans Info.plist
- [ ] Frameworks liés dans Build Phases
- [ ] Application testée avec autocomplétion
- [ ] Application testée avec calcul d'itinéraire
- [ ] Carte Google Maps affichée correctement
- [ ] Alertes de quota configurées dans Google Cloud Console

## 🎯 Prochaines Étapes

1. Tester l'autocomplétion dans `RideRequestView`
2. Tester le calcul de prix avec Google Directions
3. Remplacer toutes les vues MapKit par Google Maps
4. Ajouter le tracé de route sur la carte
5. Implémenter le suivi en temps réel du chauffeur

---

**Note** : Cette intégration remplace progressivement MapKit par Google Maps pour une meilleure précision et des fonctionnalités avancées (trafic en temps réel, meilleure couverture géographique, etc.).

