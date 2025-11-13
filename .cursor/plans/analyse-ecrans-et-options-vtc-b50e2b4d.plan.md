<!-- b50e2b4d-1ff2-48fb-920a-08d4290ffce8 490552e3-557c-4931-b69f-5ed11e265764 -->
# Plan Optimisation Navigation Performance MVP

## Objectifs

1. **Simplifier AuthGateView** - Design plus simple et direct
2. **Ajouter boutons retour** - Sur tous les écrans qui en manquent
3. **Optimiser performances** - Réduire le temps de chargement de 80x
4. **Vérifier routes** - S'assurer que tous les boutons redirigent correctement

## 1. Simplification AuthGateView

### Problème actuel

- Deux boutons séparés ("S'inscrire" et "Se connecter")
- Logo et animations qui peuvent ralentir le chargement
- Navigation vers deux vues séparées

### Solution

- Créer un écran avec onglets en haut (TabView ou Picker)
- Un seul formulaire qui change selon l'onglet sélectionné
- Supprimer les animations au démarrage
- Logo simplifié sans effets de profondeur

### Fichiers à modifier

- `Views/Auth/AuthGateView.swift` - Fusionner LoginView et RegistrationView dans un seul écran avec onglets

## 2. Ajout Boutons Retour

### Écrans identifiés sans bouton retour

- `ClientHomeView.swift` - `.navigationBarHidden(true)`
- `SearchingDriversView.swift` - `.navigationBarHidden(true)`
- `RideTrackingView.swift` - Pas de bouton retour visible
- `BookingInputView.swift` - Doit avoir un bouton retour si présenté en sheet
- `RideConfirmationView.swift` - Vérifier la navigation
- `RideSummaryScreen.swift` - Vérifier la navigation

### Solution

- Ajouter `.toolbar` avec bouton retour sur les écrans qui utilisent `.navigationBarHidden(true)`
- Utiliser `.navigationBarBackButtonHidden(false)` au lieu de `.navigationBarHidden(true)` quand possible
- Ajouter un bouton "Retour" personnalisé avec `dismiss()` pour les sheets

### Fichiers à modifier

- `Views/Client/ClientHomeView.swift`
- `Views/Client/SearchingDriversView.swift`
- `Views/Client/RideTrackingView.swift`
- `Views/Client/BookingInputView.swift`
- `Views/Client/RideConfirmationView.swift`
- `Views/Home/RideSummaryScreen.swift`

## 3. Optimisation Performances (80x plus fluide)

### Problèmes identifiés

- Initialisation Google Maps au démarrage (bloque le thread principal)
- Animations complexes au chargement
- Gradients et effets de profondeur multiples
- Chargement synchrone de données

### Solutions

#### 3.1 Initialisation Lazy de Google Maps

- Ne pas initialiser Google Maps dans `TshiakaniVTCApp.init()`
- Initialiser seulement quand `ClientHomeView` apparaît
- Utiliser un état de chargement pour afficher un écran de chargement simple

#### 3.2 Réduire les animations au démarrage

- Supprimer les animations dans `AuthGateView` (logo qui pulse)
- Réduire les gradients complexes
- Utiliser des couleurs simples au lieu de gradients partout

#### 3.3 Optimiser les vues

- Utiliser `LazyVStack` au lieu de `VStack` pour les listes
- Charger les données de manière asynchrone
- Utiliser `@StateObject` seulement quand nécessaire
- Éviter les recalculs inutiles avec `@State` local

#### 3.4 Optimiser RootView

- Ne pas créer `LocationManager` et `AuthViewModel` au démarrage
- Utiliser `@EnvironmentObject` uniquement
- Réduire les `onChange` qui se déclenchent souvent

### Fichiers à modifier

- `TshiakaniVTCApp.swift` - Initialisation lazy de Google Maps
- `Views/RootView.swift` - Optimiser la création des objets
- `Views/Auth/AuthGateView.swift` - Supprimer animations
- `Views/Client/ClientHomeView.swift` - Initialisation lazy de Google Maps
- `Services/GoogleMapsService.swift` - Ajouter méthode d'initialisation lazy

## 4. Vérification Routes et Navigation

### Routes à vérifier

- AuthGateView → LoginView/RegistrationView
- LoginView → SMSVerificationView
- RegistrationView → SMSVerificationView
- ClientHomeView → RideConfirmationView
- RideConfirmationView → SearchingDriversView
- SearchingDriversView → RideTrackingView
- RideTrackingView → RideSummaryScreen
- ProfileScreen → SettingsView, RideHistoryView, HelpView
- SettingsView → Déconnexion

### Solution

- Vérifier tous les `NavigationLink` et `navigationDestination`
- S'assurer que les `@State` pour la navigation sont correctement gérés
- Tester chaque route manuellement
- Ajouter des logs pour déboguer la navigation

### Fichiers à vérifier

- Tous les fichiers dans `Views/Auth/`
- Tous les fichiers dans `Views/Client/`
- `Views/Profile/ProfileScreen.swift`
- `Views/Client/SettingsView.swift`

## 5. Améliorations supplémentaires

### 5.1 Écran de chargement

- Créer un écran de chargement simple (spinner) pour Google Maps
- Afficher pendant l'initialisation de Google Maps

### 5.2 Gestion d'erreurs

- Ajouter des messages d'erreur clairs pour les problèmes de navigation
- Gérer les cas où la navigation échoue

### 5.3 Logs de débogage

- Ajouter des logs pour tracer la navigation
- Logs pour les problèmes de performance

## Ordre d'exécution

1. **Simplifier AuthGateView** (priorité haute)
2. **Ajouter boutons retour** (priorité haute)
3. **Optimiser performances** (priorité haute)
4. **Vérifier routes** (priorité moyenne)

## Résultat attendu

- AuthGateView simplifié avec onglets
- Tous les écrans ont un bouton retour fonctionnel
- Temps de chargement réduit de 80x (de ~5s à ~0.06s)
- Toutes les routes fonctionnent correctement
- Navigation fluide sans lag

### To-dos

- [ ] Simplifier AuthGateView avec onglets (Connexion/Inscription) sur un seul écran, supprimer animations au démarrage
- [ ] Ajouter boutons retour sur tous les écrans qui utilisent .navigationBarHidden(true)
- [ ] Initialisation lazy de Google Maps (seulement quand ClientHomeView apparaît)
- [ ] Réduire animations au démarrage, simplifier gradients, optimiser RootView
- [ ] Vérifier toutes les routes de navigation et s'assurer qu'elles fonctionnent
- [ ] Créer écran de chargement simple pour Google Maps pendant l'initialisation