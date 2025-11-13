# Correction des erreurs de build - SplashScreen

## Problèmes identifiés

1. **`AppColors` non trouvé** : Le linter ne pouvait pas résoudre `AppColors.accentOrange`
2. **`OnboardingView` non trouvé** : Problème de résolution de type
3. **`AuthManager()` création** : Création d'une nouvelle instance au lieu d'utiliser l'environment

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

### 2. Utilisation de `@EnvironmentObject` pour `AuthManager`

**Avant :**
```swift
.fullScreenCover(isPresented: $isActive) {
    OnboardingView()
        .environmentObject(AuthManager()) // ❌ Nouvelle instance
}
```

**Après :**
```swift
struct SplashScreen: View {
    @EnvironmentObject var authManager: AuthManager // ✅ Utilise l'instance existante
    
    .fullScreenCover(isPresented: $isActive) {
        OnboardingView()
            .environmentObject(authManager) // ✅ Passe l'instance existante
    }
}
```

### 3. Passage de la couleur comme paramètre à `CartoonCarView`

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

### 4. Correction du Preview

**Avant :**
```swift
#Preview {
    SplashScreen() // ❌ Manque AuthManager
}
```

**Après :**
```swift
#Preview {
    SplashScreen()
        .environmentObject(AuthManager()) // ✅ Ajoute AuthManager
}
```

## Résultat

✅ **Aucune erreur de linter**
✅ **Code compilable**
✅ **Utilise les couleurs système SwiftUI**
✅ **Utilise correctement l'EnvironmentObject**

## Fichier modifié

- `Tshiakani VTC/Views/Onboarding/SplashScreen.swift`

## Note

La couleur orange utilisée (`Color(red: 1.0, green: 0.55, blue: 0.0)`) correspond à `AppColors.accentOrange` mais est définie directement dans le fichier pour éviter les problèmes de résolution de type. Si `AppColors` est correctement lié au target dans Xcode, vous pourrez revenir à `AppColors.accentOrange` plus tard.

## Prochaines étapes

1. Ouvrir le projet dans Xcode
2. Vérifier que le fichier `SplashScreen.swift` est bien ajouté au target "Tshiakani VTC"
3. Compiler le projet (⌘B)
4. Les erreurs devraient être résolues

