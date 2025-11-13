# Résolution des Erreurs "Missing package product 'GoogleMaps'" et "Missing package product 'GooglePlaces'"

## Problème

Les erreurs "Missing package product 'GoogleMaps'" et "Missing package product 'GooglePlaces'" indiquent que les packages Swift ne sont pas correctement résolus ou liés au target dans Xcode.

## Analyse de la Configuration

### Configuration Actuelle

La configuration dans `project.pbxproj` est **correcte** :

- ✅ **Package References** : Les packages sont référencés dans `packageReferences` (lignes 212-213)
  - `ios-places-sdk` (Google Places)
  - `ios-maps-sdk` (Google Maps)

- ✅ **Product Dependencies** : Les produits sont dans `packageProductDependencies` (lignes 121-124)
  - `GooglePlaces`
  - `GoogleMaps`

- ✅ **Frameworks Build Phase** : Les frameworks sont dans `PBXFrameworksBuildPhase` (lignes 60-61)
  - `GoogleMaps in Frameworks`
  - `GooglePlaces in Frameworks`

- ✅ **Product References** : Les références de produits sont définies (lignes 665-673)
  - `GooglePlaces` → `ios-places-sdk`
  - `GoogleMaps` → `ios-maps-sdk`

- ✅ **Package.resolved** : Les packages sont présents dans `Package.resolved`
  - `ios-maps-sdk` version 10.4.0
  - `ios-places-sdk` version 10.4.0

### Cause Probable

Le problème est que les packages ne sont **pas résolus dans Xcode**, même s'ils sont correctement référencés dans `project.pbxproj`. Cela peut être dû à :

1. **Cache corrompu** : Le cache Swift Package Manager est corrompu
2. **Packages non résolus** : Les packages n'ont pas été résolus dans Xcode
3. **Frameworks non liés** : Les frameworks ne sont pas correctement liés au target dans l'interface Xcode

## Solution Automatique

### Script de Résolution

Un script a été créé pour forcer la résolution des packages :

```bash
./forcer-resolution-packages.sh
```

Ce script :
- Sauvegarde `Package.resolved`
- Supprime `Package.resolved` pour forcer la résolution
- Nettoie les caches Swift Package Manager
- Nettoie le DerivedData
- Vérifie la configuration des packages

## Solution Manuelle dans Xcode

### Étape 1 : Nettoyer les Caches

1. **Ouvrir Xcode** et le projet `Tshiakani VTC.xcodeproj`

2. **File > Packages > Reset Package Caches**
   - Cela supprime les caches des packages
   - Attendre que l'opération se termine

3. **Fermer Xcode complètement**

4. **Supprimer le DerivedData** (optionnel mais recommandé) :
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
   ```

5. **Rouvrir Xcode**

### Étape 2 : Résoudre les Packages

1. **File > Packages > Resolve Package Versions**
   - Cela résout toutes les versions des packages
   - Attendre que tous les packages soient résolus (barre de progression en bas)
   - Cela peut prendre plusieurs minutes

2. **Vérifier que les packages sont résolus** :
   - Dans le **Project Navigator**, développer **Package Dependencies**
   - Vous devriez voir :
     - ✅ `ios-maps-sdk` (Google Maps)
     - ✅ `ios-places-sdk` (Google Places)

### Étape 3 : Vérifier les Frameworks Liés

1. **Sélectionner le target "Tshiakani VTC"** dans la liste des targets

2. **Aller dans l'onglet "General"**

3. **Scroller jusqu'à "Frameworks, Libraries, and Embedded Content"**

4. **Vérifier que vous voyez :**
   - ✅ `GoogleMaps` (statut : "Do Not Embed" ou "Embed & Sign")
   - ✅ `GooglePlaces` (statut : "Do Not Embed" ou "Embed & Sign")

5. **Si les frameworks ne sont PAS présents :**
   - Cliquer sur le bouton **"+"** en bas de la liste
   - Dans la fenêtre, aller dans l'onglet **"Package Dependencies"**
   - Sélectionner **GoogleMaps** et cliquer sur **"Add"**
   - Répéter pour **GooglePlaces**

### Étape 4 : Nettoyer et Recompiler

1. **Product > Clean Build Folder** (⇧⌘K)
   - Cela nettoie le build folder

2. **Product > Build** (⌘B)
   - Cela compile le projet
   - Vérifier que les erreurs "Missing package product" ont disparu

## Vérification Finale

Après avoir suivi les étapes ci-dessus, vérifier que :

- ✅ Les packages sont résolus dans Package Dependencies
- ✅ Les frameworks GoogleMaps et GooglePlaces sont liés au target
- ✅ Le build réussit sans erreurs "Missing package product"
- ✅ Les imports `import GoogleMaps` et `import GooglePlaces` fonctionnent dans le code

## Dépannage

### Si les erreurs persistent après la résolution

1. **Vérifier la connexion internet** :
   - Les packages doivent être téléchargés depuis GitHub
   - Vérifier que la connexion internet fonctionne

2. **Vérifier les versions des packages** :
   - Les packages doivent être en version 10.4.0 ou supérieure
   - Vérifier dans `Package.resolved` que les versions sont correctes

3. **Réinstaller les packages** :
   - Supprimer les packages dans Xcode (Project > Package Dependencies)
   - Réajouter les packages :
     - `https://github.com/googlemaps/ios-maps-sdk`
     - `https://github.com/googlemaps/ios-places-sdk`
   - Sélectionner les produits GoogleMaps et GooglePlaces

4. **Vérifier les Build Settings** :
   - Vérifier que `SWIFT_PACKAGE_MANAGER_RESOLUTION_MODE` est défini correctement
   - Vérifier que les frameworks sont dans les search paths

### Si les frameworks ne peuvent pas être ajoutés

1. **Vérifier que les packages sont résolus** :
   - Les packages doivent être résolus avant de pouvoir ajouter les frameworks
   - Réessayer après avoir résolu les packages

2. **Vérifier les permissions** :
   - Vérifier que vous avez les permissions pour modifier le projet
   - Vérifier que le projet n'est pas verrouillé

## Fichiers Créés

1. ✅ `forcer-resolution-packages.sh` - Script pour forcer la résolution des packages
2. ✅ `RESOLUTION_PACKAGES_GOOGLE_MAPS.md` - Ce document

## Résumé

Les erreurs "Missing package product" sont généralement causées par des packages non résolus dans Xcode. La solution consiste à :

1. Nettoyer les caches
2. Résoudre les packages dans Xcode
3. Vérifier que les frameworks sont liés au target
4. Nettoyer et recompiler

---

**Statut :** ✅ Configuration vérifiée, script créé, documentation fournie
