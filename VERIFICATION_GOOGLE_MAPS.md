# 🔍 Vérification de l'Utilisation de Google Maps

## 📋 Problème

L'application utilise MapKit au lieu de Google Maps, même après la migration.

## ✅ Ce qui a été fait

1. ✅ Packages Google Maps installés :
   - `GoogleMaps` @ 10.4.0
   - `GooglePlaces` @ 10.4.0

2. ✅ Clé API configurée dans Build Settings :
   - `INFOPLIST_KEY_GOOGLE_MAPS_API_KEY = "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"`

3. ✅ `RideMapView.swift` modifié pour utiliser `GoogleMapView`

4. ✅ `GoogleMapView.swift` créé avec fallback MapKit

## 🔍 Diagnostic

### Vérification 1 : Packages liés au target

Dans Xcode :
1. Sélectionnez le projet dans le Project Navigator
2. Sélectionnez le target **Tshiakani VTC**
3. Allez dans l'onglet **General**
4. Vérifiez dans **Frameworks, Libraries, and Embedded Content** :
   - ✅ `GoogleMaps.xcframework` doit être présent
   - ✅ `GooglePlaces.xcframework` doit être présent
   - ✅ Status doit être "Do Not Embed" ou "Embed & Sign"

### Vérification 2 : Initialisation du SDK

Lors du lancement de l'app, vérifiez dans la console Xcode :

**Si vous voyez :**
```
✅ Google Maps SDK initialisé avec succès
```
→ Le SDK est bien initialisé

**Si vous voyez :**
```
⚠️ Google Maps SDK non disponible. Installez le package : https://github.com/googlemaps/ios-maps-sdk
```
→ Les packages ne sont pas correctement liés au target

**Si vous voyez :**
```
⚠️ GOOGLE_MAPS_API_KEY non trouvée
```
→ La clé API n'est pas accessible (problème de Build Settings)

### Vérification 3 : Code de GoogleMapView

Le code dans `GoogleMapView.swift` vérifie :
```swift
#if canImport(GoogleMaps)
// Utilise GMSMapView (Google Maps)
#else
// Utilise MKMapView (MapKit - fallback)
#endif
```

Si `canImport(GoogleMaps)` retourne `false`, cela signifie que :
- Les packages ne sont pas liés au target
- Les frameworks ne sont pas dans le chemin de recherche

## 🛠️ Solution

### Étape 1 : Vérifier la liaison des packages

1. Dans Xcode, ouvrez le projet
2. Sélectionnez le projet dans le Project Navigator
3. Sélectionnez le target **Tshiakani VTC**
4. Allez dans l'onglet **Build Phases**
5. Vérifiez **Link Binary With Libraries** :
   - `GoogleMaps.xcframework` doit être présent
   - `GooglePlaces.xcframework` doit être présent

Si absents :
1. Cliquez sur le **+**
2. Ajoutez `GoogleMaps` et `GooglePlaces`
3. Assurez-vous que le status est "Required"

### Étape 2 : Nettoyer et reconstruire

1. Dans Xcode : **Product** > **Clean Build Folder** (⇧⌘K)
2. Fermez Xcode
3. Supprimez les DerivedData :
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
```
4. Rouvrez Xcode
5. **Product** > **Build** (⌘B)

### Étape 3 : Vérifier les Build Settings

Dans **Build Settings**, recherchez :
- `FRAMEWORK_SEARCH_PATHS` : Doit contenir les chemins vers les frameworks Google Maps
- `OTHER_LDFLAGS` : Doit contenir les flags de liaison pour Google Maps

### Étape 4 : Test

1. Lancez l'application
2. Allez dans `RideRequestView`
3. Saisissez une adresse et confirmez
4. La carte Google Maps devrait s'afficher (pas MapKit)

## 🎯 Points à vérifier

- [ ] Packages Google Maps dans "Frameworks, Libraries, and Embedded Content"
- [ ] Message "✅ Google Maps SDK initialisé avec succès" dans la console
- [ ] Clé API accessible (`GOOGLE_MAPS_API_KEY` dans Info.plist généré)
- [ ] APIs activées dans Google Cloud Console
- [ ] Restrictions de la clé API configurées (Bundle ID)

## 📱 Test Rapide

Pour vérifier rapidement si Google Maps est utilisé :

1. Ajoutez un `print` dans `GoogleMapView.makeUIView` :
```swift
#if canImport(GoogleMaps)
print("✅ Utilisation de Google Maps")
#else
print("⚠️ Utilisation de MapKit (fallback)")
#endif
```

2. Lancez l'app et naviguez vers une vue avec carte
3. Vérifiez la console Xcode

## 🔧 Si le problème persiste

1. Vérifiez que les packages sont bien dans le **Package Dependencies**
2. Vérifiez que le target utilise la bonne configuration
3. Vérifiez les erreurs de compilation liées aux imports
4. Vérifiez que les frameworks sont bien dans le bundle de l'app

