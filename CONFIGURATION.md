# Configuration - Wewa Taxi

## 📱 Permissions iOS

Pour que l'application fonctionne correctement, vous devez ajouter les permissions suivantes dans le fichier `Info.plist` du projet Xcode :

### Localisation

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Wewa Taxi a besoin de votre localisation pour trouver les conducteurs disponibles près de vous et vous permettre de commander un trajet.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Wewa Taxi a besoin de votre localisation en arrière-plan pour suivre votre trajet en temps réel.</string>
```

### Accès au réseau (si nécessaire)

L'application nécessite une connexion Internet pour :
- Communiquer avec le backend
- Charger les cartes
- Traiter les paiements

## 🔧 Configuration du Backend

### APIService.swift

Modifier la constante `baseURL` dans `APIService.swift` :

```swift
private let baseURL = "https://votre-api.wewataxi.com"
```

### Services de paiement

Pour intégrer les services de paiement Mobile Money, vous devrez :

1. **M-Pesa** : Obtenir les clés API depuis Safaricom
2. **Airtel Money** : Obtenir les credentials depuis Airtel
3. **Orange Money** : Obtenir les credentials depuis Orange

Modifier `PaymentService.swift` pour intégrer les SDKs correspondants.

## 🗺️ Configuration des cartes

L'application utilise MapKit par défaut. Pour utiliser Google Maps :

1. Ajouter le SDK Google Maps via Swift Package Manager
2. Obtenir une clé API Google Maps
3. Modifier les vues de carte pour utiliser Google Maps au lieu de MapKit

## 🔐 Configuration de l'authentification

Actuellement, l'authentification est simulée. Pour une implémentation réelle :

1. Intégrer Firebase Authentication ou votre propre système d'authentification
2. Implémenter la vérification OTP par SMS
3. Ajouter la gestion des tokens d'authentification

## 📊 Base de données

L'application est conçue pour fonctionner avec :
- **Firebase Firestore** (recommandé pour le MVP)
- **PostgreSQL** (pour une solution plus robuste)

Modifier `APIService.swift` pour utiliser votre backend réel.

## 🚀 Déploiement

### TestFlight / App Store

1. Configurer les certificats de développement
2. Créer un profil de provisioning
3. Archiver l'application
4. Uploader vers TestFlight ou App Store Connect

### Configuration requise

- iOS 15.0 ou supérieur
- Xcode 14.0 ou supérieur
- Swift 5.7 ou supérieur

