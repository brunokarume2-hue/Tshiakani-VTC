# 🔧 Solution : MapKit au lieu de Google Maps

## 🔍 Diagnostic

L'application utilise MapKit au lieu de Google Maps. Voici comment résoudre le problème.

## ✅ Vérifications à faire dans Xcode

### 1. Vérifier que les packages sont liés au target

1. Ouvrez Xcode
2. Sélectionnez le projet **Tshiakani VTC** dans le Project Navigator
3. Sélectionnez le target **Tshiakani VTC**
4. Allez dans l'onglet **General**
5. Scrollez jusqu'à **Frameworks, Libraries, and Embedded Content**
6. Vérifiez que vous voyez :
   - ✅ `GoogleMaps.xcframework`
   - ✅ `GooglePlaces.xcframework`
   - Status : "Do Not Embed" ou "Embed & Sign"

**Si les frameworks ne sont PAS présents :**

1. Cliquez sur le **+** en bas de la liste
2. Recherchez "GoogleMaps"
3. Ajoutez `GoogleMaps` et `GooglePlaces`
4. Assurez-vous que le status est "Do Not Embed" (pour les frameworks système)

### 2. Vérifier les Build Settings

1. Sélectionnez le target **Tshiakani VTC**
2. Allez dans l'onglet **Build Settings**
3. Recherchez `FRAMEWORK_SEARCH_PATHS`
4. Vérifiez que les chemins vers les packages Google Maps sont présents

### 3. Vérifier la console au démarrage

Lancez l'application et vérifiez dans la console Xcode :

**✅ Si vous voyez :**
```
✅ Google Maps SDK initialisé avec succès - Clé API: AIzaSyBBSO...
✅ GoogleMapView: Utilisation de Google Maps (GMSMapView)
✅ GoogleMapView: SDK Google Maps initialisé
```
→ Google Maps est utilisé correctement !

**⚠️ Si vous voyez :**
```
⚠️ Google Maps SDK non disponible. Les packages sont peut-être installés mais pas correctement liés au target.
⚠️ GoogleMapView: Google Maps non disponible, utilisation de MapKit (fallback)
```
→ Les packages ne sont pas correctement liés au target

## 🛠️ Solution : Relier les packages au target

### Méthode 1 : Via l'interface Xcode (Recommandée)

1. **File** > **Add Package Dependencies...**
2. Ajoutez (si pas déjà fait) :
   - `https://github.com/googlemaps/ios-maps-sdk`
   - `https://github.com/googlemaps/ios-places-sdk`
3. Sélectionnez le target **Tshiakani VTC**
4. Cliquez sur **Add Package**
5. Dans la fenêtre de sélection des produits, cochez :
   - ✅ `GoogleMaps`
   - ✅ `GooglePlaces`
6. Cliquez sur **Add Package**

### Méthode 2 : Vérifier le fichier project.pbxproj

Les packages doivent être dans la section `packageProductDependencies` du target.

### Méthode 3 : Nettoyer et reconstruire

1. **Product** > **Clean Build Folder** (⇧⌘K)
2. Fermez Xcode
3. Supprimez les DerivedData :
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
```
4. Rouvrez Xcode
5. **Product** > **Build** (⌘B)

## 🎯 Test

1. Lancez l'application
2. Vérifiez la console Xcode
3. Vous devriez voir :
   - `✅ Google Maps SDK initialisé avec succès`
   - `✅ GoogleMapView: Utilisation de Google Maps (GMSMapView)`
4. Naviguez vers une vue avec carte (ex: `RideRequestView` > confirmer une course)
5. La carte Google Maps devrait s'afficher (vous pouvez le voir car elle a un style différent de MapKit)

## 📝 Vues migrées

- ✅ `RideMapView.swift` : Utilise `GoogleMapView`
- ⏳ `MapLocationPickerView.swift` : Utilise encore `Map { }` (MapKit)
- ⏳ `DriversMapViewOptimized.swift` : Utilise encore `Map { }` (MapKit)
- ⏳ `EnhancedMapView.swift` : Utilise encore `Map { }` (MapKit)
- ⏳ `CityView.swift` : Utilise encore `Map { }` (MapKit)

## 🔄 Prochaines étapes

Une fois que Google Maps fonctionne dans `RideMapView`, nous pouvons migrer les autres vues si nécessaire.

## ⚠️ Note importante

Même si les packages sont installés, ils doivent être **liés au target** pour que `canImport(GoogleMaps)` retourne `true`. C'est la raison la plus courante pour laquelle MapKit est utilisé au lieu de Google Maps.

