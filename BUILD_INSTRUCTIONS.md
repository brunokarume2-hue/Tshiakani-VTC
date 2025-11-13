# 🚀 Instructions de Build - Tshiakani VTC

## ⚡ Build Rapide (5 minutes)

### Étape 1 : Ouvrir Xcode
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
open "Tshiakani VTC.xcodeproj"
```

### Étape 2 : Nettoyer le Build
Dans Xcode :
- **Product** > **Clean Build Folder** (⇧⌘K)
- Attendez que le nettoyage se termine

### Étape 3 : Vérifier les Target Memberships (CRITIQUE)

**C'est la cause principale des erreurs de build !**

Pour chaque fichier listé ci-dessous :
1. Sélectionnez le fichier dans le navigateur de projet (panneau gauche)
2. Ouvrez le **File Inspector** (⌥⌘1) dans le panneau de droite
3. Vérifiez la section **"Target Membership"**
4. **Cochez la case "Tshiakani VTC"** si elle n'est pas cochée

#### Fichiers Critiques à Vérifier :

**App Principal :**
- ✅ `TshiakaniVTCApp.swift`

**ViewModels :**
- ✅ `ViewModels/AuthManager.swift`
- ✅ `ViewModels/AuthViewModel.swift`
- ✅ `ViewModels/RideViewModel.swift`

**Services :**
- ✅ `Services/NotificationService.swift`
- ✅ `Services/APIService.swift`
- ✅ `Services/LocationService.swift`
- ✅ `Services/GoogleMapsService.swift`

**Vues Principales :**
- ✅ `Views/RootView.swift`
- ✅ `Views/Client/ClientHomeView.swift`
- ✅ `Views/Client/GoogleMapView.swift`

**Modèles :**
- ✅ `Models/User.swift`
- ✅ `Models/Location.swift`
- ✅ `Models/Ride.swift`
- ✅ `Models/VehicleType.swift`

**Ressources :**
- ✅ `Resources/Colors/AppColors.swift`
- ✅ `Resources/Fonts/AppTypography.swift`
- ✅ `Resources/DesignSystem.swift`

### Étape 4 : Compiler
Dans Xcode :
- **Product** > **Build** (⌘B)
- Attendez que la compilation se termine

### Étape 5 : Vérifier les Erreurs

Si des erreurs persistent :
1. Cliquez sur chaque erreur dans le panneau d'erreurs
2. Vérifiez que le fichier concerné est dans le target
3. Répétez l'étape 3 pour ce fichier

## 🔧 Erreurs Communes

### Erreur : "'main' attribute cannot be used in a module that contains top-level code"

**Solution :**
Cette erreur est généralement un faux positif. Vérifiez que :
1. `TshiakaniVTCApp.swift` est dans le target "Tshiakani VTC"
2. Aucun autre fichier n'a d'attribut `@main`
3. Nettoyez le build folder (⇧⌘K) et recompilez

### Erreur : "Cannot find 'AuthManager' in scope"

**Solution :**
1. Vérifiez que `ViewModels/AuthManager.swift` est dans le target
2. Nettoyez le build folder (⇧⌘K)
3. Recompilez (⌘B)

### Erreur : "Cannot find 'NotificationService' in scope"

**Solution :**
1. Vérifiez que `Services/NotificationService.swift` est dans le target
2. Nettoyez le build folder (⇧⌘K)
3. Recompilez (⌘B)

### Erreur : "Cannot find 'RootView' in scope"

**Solution :**
1. Vérifiez que `Views/RootView.swift` est dans le target
2. Nettoyez le build folder (⇧⌘K)
3. Recompilez (⌘B)

## ✅ Checklist de Build

- [ ] Xcode ouvert avec le projet
- [ ] Build folder nettoyé (⇧⌘K)
- [ ] TshiakaniVTCApp.swift dans le target
- [ ] Tous les ViewModels dans le target
- [ ] Tous les Services dans le target
- [ ] Toutes les Vues principales dans le target
- [ ] Tous les Modèles dans le target
- [ ] Toutes les Ressources dans le target
- [ ] Compilation réussie (⌘B)
- [ ] Aucune erreur dans le panneau d'erreurs

## 🎯 Résultat Attendu

Après ces étapes, vous devriez voir :
- ✅ **BUILD SUCCEEDED** dans Xcode
- ✅ Aucune erreur dans le panneau d'erreurs
- ✅ Le projet est prêt à être exécuté

## 📝 Note

**La plupart des erreurs sont des faux positifs du linter.** Elles disparaîtront une fois que :
1. Tous les fichiers sont ajoutés au target
2. Le build folder est nettoyé
3. Le projet est recompilé dans Xcode

Les types comme `AuthManager`, `NotificationService`, `RootView`, etc. existent tous dans le projet. Le problème est généralement que Xcode ne les voit pas parce qu'ils ne sont pas dans le target.

---

**Date**: $(date)  
**Statut**: ✅ **INSTRUCTIONS CRÉÉES**

