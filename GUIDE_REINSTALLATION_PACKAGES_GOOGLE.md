# Guide de Réinstallation des Packages GoogleMaps et GooglePlaces

## ✅ Actions Automatiques Effectuées

Le script `reinstaller-packages-google.sh` a effectué les actions suivantes :

1. ✅ Nettoyage des caches Swift Package Manager
2. ✅ Suppression de Package.resolved
3. ✅ Nettoyage du projet Xcode
4. ✅ Vérification de la configuration des packages

## 📋 Actions Manuelles Requises dans Xcode

Les packages doivent maintenant être résolus manuellement dans Xcode :

### Étape 1 : Ouvrir le Projet
1. Ouvrez Xcode
2. Ouvrez le projet `Tshiakani VTC.xcodeproj`

### Étape 2 : Résoudre les Packages
1. Dans le menu Xcode, allez dans **File > Packages > Resolve Package Versions**
2. Attendez que Xcode télécharge et résolve tous les packages
   - Cela peut prendre quelques minutes
   - Vous verrez une barre de progression en bas de Xcode

### Étape 3 : Vérifier la Résolution
1. Vérifiez que les packages apparaissent dans le navigateur de projet (panneau de gauche)
2. Les packages devraient être sous "Package Dependencies" ou dans le dossier "Swift Package Dependencies"

### Étape 4 : Si les Packages ne se Résolvent Pas
Si les packages ne se résolvent pas automatiquement :

1. **Réinitialiser les caches de packages** :
   - File > Packages > Reset Package Caches
   - Puis File > Packages > Resolve Package Versions

2. **Vérifier la connexion Internet** :
   - Les packages sont téléchargés depuis GitHub
   - Assurez-vous d'avoir une connexion Internet active

3. **Vérifier les URLs des packages** :
   - GoogleMaps: `https://github.com/googlemaps/ios-maps-sdk`
   - GooglePlaces: `https://github.com/googlemaps/ios-places-sdk`

### Étape 5 : Compiler le Projet
1. Une fois les packages résolus, compilez le projet :
   - **Product > Build** (ou Cmd+B)
2. Vérifiez qu'il n'y a plus d'erreurs "Missing package product"

## 🔍 Vérification de la Configuration

Les packages sont correctement configurés dans le projet :

- ✅ **GoogleMaps** : Référencé depuis `ios-maps-sdk` (version 10.4.0+)
- ✅ **GooglePlaces** : Référencé depuis `ios-places-sdk` (version 10.4.0+)
- ✅ Les frameworks sont liés au target "Tshiakani VTC"
- ✅ Les dépendances sont déclarées dans `packageProductDependencies`

## 🛠️ En Cas de Problème Persistant

Si les erreurs persistent après avoir suivi ces étapes :

1. **Fermer et rouvrir Xcode**
2. **Nettoyer le build folder** :
   - Product > Clean Build Folder (Shift+Cmd+K)
3. **Supprimer DerivedData** :
   - Xcode > Settings > Locations
   - Cliquez sur la flèche à côté du chemin DerivedData
   - Supprimez le dossier du projet
4. **Réessayer la résolution des packages**

## 📝 Notes Techniques

- Les packages utilisent Swift Package Manager (SPM)
- Les versions minimales requises sont :
  - GoogleMaps: 10.4.0
  - GooglePlaces: 10.4.0
- Le fichier `Package.resolved` sera recréé automatiquement après la résolution

