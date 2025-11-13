# 📱 Flux d'Intégration et d'Authentification - Documentation

## ✅ Implémentation Complète

Ce document décrit l'implémentation complète du flux d'onboarding et d'authentification pour l'application Tshiakani VTC iOS.

## 🏗️ Architecture

### 1. AuthManager (Gestionnaire d'Authentification Global)

**Fichier**: `Tshiakani VTC/ViewModels/AuthManager.swift`

**Responsabilités**:
- Gère l'état global d'authentification (`isAuthenticated: Bool`)
- Gère le rôle de l'utilisateur (`userRole: UserRole?`)
- Gère l'état de l'onboarding (`hasSeenOnboarding: Bool` avec `@AppStorage`)
- Sauvegarde et récupère le token d'authentification
- Vérifie l'état d'authentification au démarrage

**Propriétés**:
```swift
@Published var isAuthenticated: Bool = false
@Published var userRole: UserRole? = nil
@AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
```

### 2. RootView (Point d'Entrée Principal)

**Fichier**: `Tshiakani VTC/Views/RootView.swift`

**Logique de Redirection**:
1. Si `!hasSeenOnboarding` → Affiche `OnboardingView`
2. Si `!isAuthenticated` → Affiche `AuthGateView`
3. Si `isAuthenticated`:
   - Si `userRole == .client` → Affiche `ClientMainView` (avec `LocationManager`)
   - Si `userRole == .driver` → Affiche `DriverMainView` (avec `LocationManager`)
   - Sinon → Affiche `AdminDashboardView`

### 3. Flux d'Onboarding

#### OnboardingView
**Fichier**: `Tshiakani VTC/Views/Onboarding/OnboardingView.swift`

- Carrousel avec `TabView` (2 pages d'illustrations)
- Bouton "Commencer" qui met à jour `AuthManager.hasSeenOnboarding = true`
- Navigation vers `AuthGateView`

#### AuthGateView
**Fichier**: `Tshiakani VTC/Views/Auth/AuthGateView.swift`

- Présente deux options: "S'inscrire" et "Se connecter"
- Navigation vers `RegistrationView` (inscription)
- Navigation vers `LoginView` (connexion)

#### RegistrationView
**Fichier**: `Tshiakani VTC/Views/Auth/RegistrationView.swift`

**Champs de saisie**:
- Nom complet (obligatoire)
- Numéro de téléphone (formatage automatique: XXX XXX XXX)
- Sélection du rôle (obligatoire): Client ou Conducteur

**Actions**:
- Validation du formulaire
- Envoi des données à l'API (simulé)
- Navigation vers `SMSVerificationView`

#### SMSVerificationView
**Fichier**: `Tshiakani VTC/Views/Auth/SMSVerificationView.swift`

**Fonctionnalités**:
- Champ de saisie pour code SMS (6 chiffres)
- Auto-focus et navigation entre champs
- Vérification automatique quand le code est complet
- Bouton "Renvoyer le code" avec timer (60 secondes)
- Intégration avec `AuthViewModel` pour l'authentification
- Mise à jour de `AuthManager` après vérification réussie

**Actions**:
- Vérifie le code avec l'API
- Met à jour `AuthManager.isAuthenticated = true`
- Met à jour `AuthManager.userRole` selon le rôle sélectionné
- Navigation vers `RootView` (qui redirige vers la vue principale)

#### LoginView
**Fichier**: `Tshiakani VTC/Views/Auth/AuthGateView.swift` (dans le même fichier)

**Fonctionnalités**:
- Champ téléphone
- Sélection du rôle
- Connexion via `AuthViewModel`
- Mise à jour de `AuthManager` après connexion réussie

## 🔄 Flux de Navigation (SÉQUENCE STRICTE)

```
TshiakaniVTCApp
    └── RootView (Point d'entrée unique)
        │
        ├── 1. OnboardingView (si !hasSeenOnboarding)
        │   └── NavigationStack
        │       └── Bouton "Commencer" → AuthGateView
        │
        ├── 2. AuthGateView (si hasSeenOnboarding && !isAuthenticated)
        │   └── NavigationStack
        │       ├── Bouton "S'inscrire" → RegistrationView
        │       └── Bouton "Se connecter" → LoginView
        │
        ├── 3. RegistrationView (si "S'inscrire" choisi)
        │   └── NavigationStack
        │       ├── Logo "Tshiakani VTC" + Message de bienvenue
        │       ├── Sélecteur de rôle (Client/Conducteur)
        │       ├── Champs: Nom (Optionnel) + Téléphone (+243)
        │       └── Bouton "Continuer" → SMSVerificationView
        │
        ├── 4. SMSVerificationView (après RegistrationView)
        │   └── NavigationStack
        │       ├── Champ code SMS (6 chiffres)
        │       └── Vérification → Met à jour AuthManager
        │           └── RootView redirige automatiquement
        │
        └── 5. Vues Principales (si isAuthenticated)
            ├── ClientMainView (si userRole == .client)
            │   └── Intègre LocationManager automatiquement
            ├── DriverMainView (si userRole == .driver)
            │   └── Intègre LocationManager automatiquement
            └── AdminDashboardView (sinon)
```

### Points Critiques de la Séquence

1. ✅ **OnboardingView** est la première vue si `!hasSeenOnboarding`
2. ✅ **AuthGateView** s'affiche après l'onboarding si `!isAuthenticated`
3. ✅ **RegistrationView** s'affiche uniquement si "S'inscrire" est choisi
4. ✅ **SMSVerificationView** s'affiche après RegistrationView
5. ✅ **RootView** redirige automatiquement quand `isAuthenticated` devient `true`

## 🔑 Points Clés

### Intégration LocationManager

Les vues principales (`ClientMainView` et `DriverMainView`) intègrent automatiquement `LocationManager`:
- Le suivi de localisation démarre automatiquement au chargement
- Les permissions sont demandées via `LocationManager.requestAuthorizationIfNeeded()`

### Gestion d'État

- **AuthManager**: Gère l'état global (onboarding, authentification, rôle)
- **AuthViewModel**: Utilisé pour les opérations d'authentification (signIn, etc.)
- Les deux coexistent: `AuthManager` pour l'état, `AuthViewModel` pour les opérations

### Persistance

- `hasSeenOnboarding`: Sauvegardé avec `@AppStorage`
- Token et rôle: Sauvegardés dans `UserDefaults`
- Vérification au démarrage: `AuthManager.checkAuthStatus()` dans `init()`

## 📝 Modifications Apportées

1. ✅ Création de `AuthManager.swift`
2. ✅ Création de `OnboardingView.swift`
3. ✅ Création de `AuthGateView.swift` (avec `LoginView`)
4. ✅ Création de `RegistrationView.swift`
5. ✅ Création de `SMSVerificationView.swift`
6. ✅ Création de `RootView.swift`
7. ✅ Modification de `TshiakaniVTCApp.swift` pour utiliser `RootView` et `AuthManager`

## 🎯 Utilisation

L'application démarre maintenant avec `RootView` qui gère automatiquement:
- L'affichage de l'onboarding pour les nouveaux utilisateurs
- La redirection vers l'authentification si non authentifié
- La redirection vers la vue principale selon le rôle si authentifié

Tout est géré automatiquement via `AuthManager` qui est injecté comme `@EnvironmentObject` dans toute l'application.

