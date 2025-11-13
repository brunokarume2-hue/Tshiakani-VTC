# 🏍️ Wewa Taxi - Application de Transport

Application mobile iOS pour commander des moto-taxis (wewa) à Kinshasa, avec paiement digital et suivi en temps réel.

## 📋 Fonctionnalités

### Côté Client
- ✅ Géolocalisation et visualisation des wewa disponibles
- ✅ Réservation rapide de trajet
- ✅ Estimation automatique du prix selon la distance
- ✅ Suivi en temps réel du conducteur
- ✅ Historique des trajets
- 🔄 Paiement (cash et Mobile Money) - En cours

### Côté Conducteur
- ✅ Interface de gestion des demandes de course
- ✅ Statut en ligne/hors ligne
- ✅ Profil conducteur avec statistiques
- 🔄 Navigation GPS intégrée - À implémenter
- 🔄 Historique des revenus - À implémenter

### Côté Admin
- ✅ Tableau de bord avec statistiques
- ✅ Gestion des conducteurs et courses
- 🔄 Système de support - À implémenter

## 🏗️ Architecture

L'application utilise une architecture MVVM (Model-View-ViewModel) avec SwiftUI :

```
wewa taxi/
├── Models/          # Modèles de données
│   ├── User.swift
│   ├── Location.swift
│   ├── Ride.swift
│   └── Payment.swift
├── Views/          # Interfaces utilisateur
│   ├── Auth/
│   ├── Client/
│   ├── Driver/
│   └── Admin/
├── ViewModels/      # Logique métier
│   ├── AuthViewModel.swift
│   └── RideViewModel.swift
├── Services/        # Services (API, Location, Payment)
│   ├── APIService.swift
│   ├── LocationService.swift
│   └── PaymentService.swift
└── Utils/           # Utilitaires et extensions
    └── Extensions.swift
```

## 🚀 Installation

1. Ouvrir le projet dans Xcode
2. Configurer les permissions de localisation dans `Info.plist` :
   - `NSLocationWhenInUseUsageDescription`
   - `NSLocationAlwaysAndWhenInUseUsageDescription`
3. Compiler et exécuter sur un simulateur ou un appareil iOS

## 🔧 Configuration

### Services à configurer

1. **Backend API** : Modifier `APIService.swift` avec l'URL de votre backend
2. **Paiement Mobile Money** : Intégrer les SDKs M-Pesa, Airtel Money, Orange Money
3. **Cartes** : Configurer Google Maps API ou utiliser MapKit (déjà intégré)

## 📱 Écrans principaux

- **WelcomeView** : Authentification et sélection du rôle (Client/Conducteur)
- **ClientMainView** : Carte interactive avec bouton de commande
- **RideRequestView** : Formulaire de réservation
- **RideTrackingView** : Suivi de course en cours
- **DriverMainView** : Interface conducteur avec demandes de course
- **AdminDashboardView** : Tableau de bord administrateur

## 🎨 Design

- Interface simple et intuitive
- Couleurs vives (orange, rouge) pour l'identité visuelle
- Boutons larges pour faciliter l'utilisation
- Maximum 3 clics pour commander un trajet

## 🔐 Sécurité

- Vérification des conducteurs (à implémenter)
- Système de notation et avis
- Partage de position en temps réel (à implémenter)

## 📅 Prochaines étapes

- [ ] Intégration complète du paiement Mobile Money
- [ ] Navigation GPS pour les conducteurs
- [ ] Système de notifications push
- [ ] Réservation programmée
- [ ] Abonnements pour trajets réguliers
- [ ] Tests utilisateurs à Kinshasa

## 📄 Licence

Propriétaire - Wewa Taxi

