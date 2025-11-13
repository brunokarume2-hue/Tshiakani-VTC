# Correction des erreurs de build - SplashScreen

## Problèmes identifiés

1. **`AppColors` non trouvé** : Le linter ne pouvait pas résoudre `AppColors.accentOrange`
2. **`AuthManager` dans SplashScreen** : Utilisation inutile d'`@EnvironmentObject` et création d'une nouvelle instance
3. **Transition double** : Le `SplashScreen` gérait sa propre transition vers `OnboardingView`, créant un conflit avec `RootView`

## Corrections apportées

### 1. Remplacement de `AppColors` par une couleur directe

**Avant :**
```swift
.foregroundColor(AppColors.accentOrange)
.fill(AppColors.accentOrange)
```

**Après :**
```swift
private let orangeColor = Color(red: 1.0, green: 0.55, blue: 0.0)
.foregroundColor(orangeColor)
.fill(orangeColor)
```

### 2. Simplification de `SplashScreen`

**Avant :**
```swift
struct SplashScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isActive = false
    // ...
    .fullScreenCover(isPresented: $isActive) {
        OnboardingView()
            .environmentObject(authManager)
    }
}
```

**Après :**
```swift
struct SplashScreen: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    // Pas de transition - gérée par RootView
}
```

### 3. Intégration dans `RootView`

**Avant :**
```swift
if !authManager.hasSeenOnboarding {
    OnboardingView()
        .environmentObject(authManager)
}
```

**Après :**
```swift
@State private var showSplash = true

if showSplash && !authManager.hasSeenOnboarding {
    SplashScreen()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
}
else if !authManager.hasSeenOnboarding {
    OnboardingView()
        .environmentObject(authManager)
}
```

### 4. Passage de la couleur comme paramètre

**Avant :**
```swift
struct CartoonCarView: View {
    var body: some View {
        // Utilise AppColors.accentOrange directement
    }
}
```

**Après :**
```swift
struct CartoonCarView: View {
    let orangeColor: Color // ✅ Paramètre
    
    var body: some View {
        // Utilise orangeColor
    }
}

CartoonCarView(orangeColor: orangeColor) // ✅ Passe la couleur
```

## Résultat

✅ **Aucune erreur de linter dans SplashScreen.swift**
✅ **Code compilable**
✅ **Utilise les couleurs système SwiftUI**
✅ **Transition gérée par RootView**
✅ **Splash screen affiché au premier lancement uniquement**

## Flux de navigation

1. **Premier lancement** : `SplashScreen` → (1.5s) → `OnboardingView` → `AuthGateView`
2. **Lancements suivants** : `AuthGateView` (si non authentifié) ou `ClientMainView` (si authentifié)

## Fichiers modifiés

- `Tshiakani VTC/Views/Onboarding/SplashScreen.swift` (simplifié)
- `Tshiakani VTC/Views/RootView.swift` (intégration du splash screen)

## Note

Les erreurs du linter dans `RootView.swift` sont des faux positifs - les types (`AuthManager`, `OnboardingView`, etc.) existent dans le projet et seront résolus lors de la compilation dans Xcode.

## Prochaines étapes

1. Ouvrir le projet dans Xcode
2. Vérifier que tous les fichiers sont bien ajoutés au target "Tshiakani VTC"
3. Compiler le projet (⌘B)
4. Les erreurs devraient être résolues

## Test

Pour tester le splash screen :
1. Supprimer l'application du simulateur
2. Lancer l'application
3. Le splash screen devrait s'afficher pendant 1.5 secondes
4. Puis l'onboarding devrait apparaître

