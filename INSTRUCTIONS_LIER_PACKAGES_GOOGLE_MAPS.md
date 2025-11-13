# 🔗 Instructions : Lier les Packages Google Maps au Target

## 🎯 Problème

Les packages Google Maps sont installés mais **pas liés au target**. C'est pour cela que `canImport(GoogleMaps)` retourne `false` et que l'application utilise MapKit au lieu de Google Maps.

## ✅ Solution : Lier les packages via Xcode

### Étape 1 : Ouvrir Xcode

1. Ouvrez le projet dans Xcode
2. Sélectionnez le projet **Tshiakani VTC** dans le Project Navigator (icône bleue en haut)

### Étape 2 : Sélectionner le target

1. Dans la liste des targets, sélectionnez **Tshiakani VTC** (pas les tests)
2. Allez dans l'onglet **General**

### Étape 3 : Vérifier les Frameworks

1. Scrollez jusqu'à la section **Frameworks, Libraries, and Embedded Content**
2. Si vous ne voyez **PAS** `GoogleMaps.xcframework` et `GooglePlaces.xcframework`, continuez avec l'étape 4

### Étape 4 : Ajouter les packages

1. Cliquez sur le bouton **+** en bas de la liste des frameworks
2. Dans la fenêtre qui s'ouvre, allez dans l'onglet **Package Dependencies**
3. Vous devriez voir :
   - `GoogleMaps` (de `ios-maps-sdk`)
   - `GooglePlaces` (de `ios-places-sdk`)
4. Sélectionnez **GoogleMaps** et cliquez sur **Add**
5. Répétez pour **GooglePlaces**

### Étape 5 : Configurer les frameworks

1. Pour chaque framework (`GoogleMaps` et `GooglePlaces`), assurez-vous que :
   - Le status est **"Do Not Embed"** (pour les frameworks système)
   - Ou **"Embed & Sign"** si nécessaire

### Étape 6 : Nettoyer et reconstruire

1. **Product** > **Clean Build Folder** (⇧⌘K)
2. **Product** > **Build** (⌘B)

### Étape 7 : Vérifier

1. Lancez l'application
2. Vérifiez la console Xcode
3. Vous devriez voir :
   ```
   ✅ Google Maps SDK initialisé avec succès - Clé API: AIzaSyBBSO...
   ✅ GoogleMapView: Utilisation de Google Maps (GMSMapView)
   ```

## 🔍 Vérification Alternative : Via Build Phases

Si la méthode ci-dessus ne fonctionne pas :

1. Sélectionnez le target **Tshiakani VTC**
2. Allez dans l'onglet **Build Phases**
3. Développez **Link Binary With Libraries**
4. Vérifiez que vous voyez :
   - `GoogleMaps.xcframework`
   - `GooglePlaces.xcframework`
5. Si absents, cliquez sur **+** et ajoutez-les

## 🎯 Résultat attendu

Une fois les packages liés :

- ✅ `canImport(GoogleMaps)` retournera `true`
- ✅ `GoogleMapView` utilisera `GMSMapView` (Google Maps) au lieu de `MKMapView` (MapKit)
- ✅ La carte Google Maps s'affichera dans l'application

## ⚠️ Si le problème persiste

1. Vérifiez que les packages sont bien dans **Package Dependencies** (onglet Package Dependencies du projet)
2. Vérifiez que la version des packages est correcte (10.4.0)
3. Nettoyez les DerivedData :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```
4. Rouvrez Xcode et reconstruisez

## 📝 Note

Cette étape est **cruciale** : même si les packages sont installés, ils doivent être **liés au target** pour être utilisables dans le code. C'est la raison la plus courante pour laquelle MapKit est utilisé au lieu de Google Maps.

