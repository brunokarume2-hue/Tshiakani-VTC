# 🔧 Solution pour "Package resolution errors must be fixed before building"

## ❌ Problème

L'erreur `the package manifest at '/Package.swift' cannot be accessed` indique qu'un package essaie d'accéder à un Package.swift à la racine du système, ce qui est incorrect.

## 🔍 Cause Probable

Un des packages dépendants (probablement `google-maps-ios-utils` ou un de ses sous-packages) a une référence incorrecte ou un problème de résolution.

## ✅ Solutions

### Solution 1 : Résoudre dans Xcode (Recommandée)

1. **Ouvrez Xcode** avec le projet
2. **File > Packages > Reset Package Caches**
   - Attendez que l'opération se termine (quelques secondes)
3. **File > Packages > Resolve Package Versions**
   - Attendez 2-5 minutes
   - Vous verrez une barre de progression en bas de Xcode
4. **Vérifiez** dans le navigateur de projet :
   - "Package Dependencies" devrait apparaître
   - Les packages devraient être listés
5. **Compilez** : Product > Build (Cmd+B)

### Solution 2 : Supprimer et Réajouter les Packages

Si la Solution 1 ne fonctionne pas :

1. **Sélectionnez le projet** dans le navigateur
2. **Sélectionnez le target "Tshiakani VTC"**
3. **Onglet "Package Dependencies"**
4. **Supprimez tous les packages** :
   - `ios-maps-sdk`
   - `ios-places-sdk`
   - `google-maps-ios-utils`
   - `swift-algorithms`
5. **Réajoutez-les un par un** :
   - Cliquez sur **"+"**
   - Ajoutez : `https://github.com/googlemaps/ios-maps-sdk`
   - Sélectionnez le produit **GoogleMaps**
   - Répétez pour :
     - `https://github.com/googlemaps/ios-places-sdk` → **GooglePlaces**
     - `https://github.com/googlemaps/google-maps-ios-utils` → **GoogleMapsUtils** (si nécessaire)
     - `https://github.com/apple/swift-algorithms.git` → **Algorithms** (si nécessaire)

### Solution 3 : Supprimer Temporairement google-maps-ios-utils

Si le problème vient de `google-maps-ios-utils`, vous pouvez le supprimer temporairement :

1. **Sélectionnez le projet**
2. **Sélectionnez le target "Tshiakani VTC"**
3. **Onglet "Package Dependencies"**
4. **Supprimez** `google-maps-ios-utils`
5. **Résolvez les packages** : File > Packages > Resolve Package Versions
6. **Compilez** pour voir si ça fonctionne

## 🔍 Vérification

Pour vérifier que les packages sont résolus :

1. **Ouvrez** `Tshiakani VTC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
2. **Vérifiez** qu'il contient :
   - `ios-maps-sdk`
   - `ios-places-sdk`
   - `swift-algorithms`
   - (et éventuellement `google-maps-ios-utils`)

## 📋 Actions Effectuées

- ✅ Caches de packages supprimés
- ✅ Package.resolved supprimé pour forcer la résolution
- ✅ Script AppleScript créé pour automatiser la résolution

## 🎯 Prochaines Étapes

1. **Ouvrez Xcode**
2. **File > Packages > Reset Package Caches**
3. **File > Packages > Resolve Package Versions**
4. **Attendez 2-5 minutes**
5. **Compilez** avec Cmd+B

## ⚠️ Note

L'erreur `/Package.swift` est souvent causée par un problème temporaire de résolution des packages. La résolution manuelle dans Xcode devrait corriger le problème.

