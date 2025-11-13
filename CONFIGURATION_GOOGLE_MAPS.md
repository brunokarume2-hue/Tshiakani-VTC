# Configuration Google Maps - Guide Complet

## 🔑 Étape 1 : Obtenir et Configurer la Clé API

### 1.1 Créer une Clé API dans Google Cloud Console

1. **Accédez à Google Cloud Console**
   - Allez sur [https://console.cloud.google.com/](https://console.cloud.google.com/)

2. **Créez ou sélectionnez un projet**
   - Cliquez sur le sélecteur de projet en haut
   - Créez un nouveau projet ou sélectionnez un projet existant
   - Nom suggéré : "Tshiakani VTC"

3. **Activez les APIs requises**
   - Allez dans **APIs & Services** > **Library**
   - Recherchez et activez les APIs suivantes :
     - ✅ **Maps SDK for iOS**
     - ✅ **Places API**
     - ✅ **Directions API**
     - ✅ **Geocoding API** (optionnel mais recommandé)

4. **Créez une clé API**
   - Allez dans **APIs & Services** > **Credentials**
   - Cliquez sur **+ CREATE CREDENTIALS** > **API Key**
   - Copiez la clé API générée (elle commence par `AIza...`)

5. **Configurez les restrictions de la clé API** (Recommandé pour la sécurité)
   - Cliquez sur la clé API que vous venez de créer
   - Dans **Application restrictions**, sélectionnez **iOS apps**
   - Ajoutez votre Bundle ID : `com.bruno.tshiakaniVTC`
   - Dans **API restrictions**, sélectionnez **Restrict key**
   - Cochez uniquement :
     - Maps SDK for iOS
     - Places API
     - Directions API
   - Cliquez sur **Save**

### 1.2 Configurer la Clé API dans Xcode

#### Option A : Via Build Settings (Recommandé pour Xcode moderne)

1. Ouvrez le projet dans Xcode
2. Sélectionnez le target **Tshiakani VTC** dans le Project Navigator
3. Allez dans l'onglet **Build Settings**
4. Recherchez `INFOPLIST_KEY` dans la barre de recherche
5. Cliquez sur le **+** à côté de "Info.plist Values"
6. Ajoutez :
   - **Key**: `GOOGLE_MAPS_API_KEY`
   - **Type**: String
   - **Value**: Votre clé API (ex: `AIzaSy...`)

#### Option B : Créer un fichier Info.plist manuel

1. Dans Xcode, faites un clic droit sur le dossier **Tshiakani VTC**
2. Sélectionnez **New File...**
3. Choisissez **Property List**
4. Nommez-le `Info.plist`
5. Ajoutez la clé suivante :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GOOGLE_MAPS_API_KEY</key>
    <string>VOTRE_CLE_API_ICI</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Nous avons besoin de votre localisation pour trouver les chauffeurs à proximité et calculer les trajets.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Nous avons besoin de votre localisation pour suivre votre course en temps réel.</string>
</dict>
</plist>
```

6. Dans **Build Settings**, recherchez `INFOPLIST_FILE` et pointez vers votre nouveau fichier `Info.plist`

#### Option C : Via Variables d'Environnement (Pour le développement)

1. Dans Xcode, allez dans **Product** > **Scheme** > **Edit Scheme...**
2. Sélectionnez **Run** dans le menu de gauche
3. Allez dans l'onglet **Arguments**
4. Dans **Environment Variables**, cliquez sur **+**
5. Ajoutez :
   - **Name**: `GOOGLE_MAPS_API_KEY`
   - **Value**: Votre clé API

## 📦 Étape 2 : Installer les Packages Swift

### 2.1 Ajouter Google Maps SDK

1. Dans Xcode, allez dans **File** > **Add Package Dependencies...**
2. Collez l'URL suivante :
   ```
   https://github.com/googlemaps/ios-maps-sdk
   ```
3. Cliquez sur **Add Package**
4. Sélectionnez la version la plus récente (ex: `7.4.0` ou supérieure)
5. Cochez **GoogleMaps** dans la liste des produits
6. Cliquez sur **Add Package**

### 2.2 Ajouter Google Places SDK

1. Répétez les étapes ci-dessus avec l'URL :
   ```
   https://github.com/googlemaps/ios-places-sdk
   ```
2. Cochez **GooglePlaces** dans la liste des produits

### 2.3 Vérifier l'installation

1. Ouvrez `TshiakaniVTCApp.swift`
2. Vérifiez que les imports fonctionnent :
   ```swift
   import GoogleMaps
   import GooglePlaces
   ```
3. Si Xcode ne trouve pas les modules, nettoyez le build :
   - **Product** > **Clean Build Folder** (⇧⌘K)
   - Rebuild le projet (⌘B)

## ✅ Étape 3 : Vérifier la Configuration

### 3.1 Vérifier que la clé API est chargée

1. Ajoutez un point d'arrêt dans `TshiakaniVTCApp.init()`
2. Lancez l'application en mode Debug
3. Vérifiez dans la console qu'il n'y a pas de message d'erreur :
   - ✅ `"✅ Google Maps SDK initialisé avec succès"`
   - ❌ `"⚠️ GOOGLE_MAPS_API_KEY non trouvée"`

### 3.2 Tester l'autocomplétion

1. Lancez l'application
2. Allez dans **Nouvelle course** (RideRequestView)
3. Tapez dans le champ **Destination** : "Kinshasa"
4. Vérifiez que des suggestions d'adresses apparaissent
5. Sélectionnez une adresse
6. Vérifiez que l'adresse et les coordonnées sont correctement remplies

### 3.3 Tester le calcul d'itinéraire

1. Remplissez les champs **Départ** et **Destination**
2. Attendez quelques secondes
3. Vérifiez que :
   - La **Distance** s'affiche (ex: "5.2 km")
   - Le **Temps d'attente** s'affiche (ex: "12 min")
   - Le **Prix estimé** s'affiche (ex: "2500 FC")

### 3.4 Vérifier les logs

Dans la console Xcode, vous devriez voir :
- ✅ Requêtes réussies vers Google Places API
- ✅ Requêtes réussies vers Google Directions API
- ❌ Pas d'erreurs "API key not valid" ou "Quota exceeded"

## 🧪 Étape 4 : Tests Complets

### Test 1 : Autocomplétion d'Adresses

```swift
// Test dans RideRequestView
1. Ouvrir l'application
2. Aller dans "Nouvelle course"
3. Taper "123 Avenue" dans le champ Destination
4. Vérifier que des suggestions apparaissent
5. Sélectionner une suggestion
6. Vérifier que l'adresse est remplie
```

### Test 2 : Calcul de Prix avec Trafic

```swift
// Test dans RideRequestView
1. Remplir Départ : "Aéroport de Kinshasa"
2. Remplir Destination : "Place de l'Indépendance, Kinshasa"
3. Attendre le calcul automatique
4. Vérifier :
   - Distance affichée (doit être > 0)
   - Temps estimé affiché (doit être > 0)
   - Prix estimé affiché (doit être > 0)
```

### Test 3 : Affichage de la Carte

```swift
// Test dans RideMapView (après avoir remplacé MapKit)
1. Créer une course avec départ et destination
2. Vérifier que la carte Google Maps s'affiche
3. Vérifier que les marqueurs de départ/destination sont visibles
4. Vérifier que la route est tracée (si implémenté)
```

## 🔧 Dépannage

### Erreur : "API key not valid"

**Solutions :**
1. Vérifiez que la clé API est correctement copiée (sans espaces)
2. Vérifiez que les APIs sont activées dans Google Cloud Console
3. Vérifiez que la clé API n'a pas de restrictions trop strictes
4. Vérifiez que le Bundle ID correspond à celui configuré dans les restrictions

### Erreur : "Quota exceeded"

**Solutions :**
1. Vérifiez vos quotas dans Google Cloud Console
2. Attendez la réinitialisation mensuelle (généralement le 1er du mois)
3. Vérifiez que vous n'avez pas dépassé les $200 USD de crédit gratuit

### Erreur : "SDK not initialized"

**Solutions :**
1. Vérifiez que `GoogleMapsService.shared.initialize()` est appelé dans `TshiakaniVTCApp.init()`
2. Vérifiez que la clé API n'est pas vide
3. Vérifiez les logs de la console pour plus de détails

### La carte ne s'affiche pas

**Solutions :**
1. Vérifiez que les frameworks sont bien liés dans Build Phases
2. Vérifiez que les packages Swift sont bien installés
3. Nettoyez le build folder et rebuild
4. Vérifiez que la clé API a les bonnes restrictions (Bundle ID)

### L'autocomplétion ne fonctionne pas

**Solutions :**
1. Vérifiez que Places API est activée dans Google Cloud Console
2. Vérifiez les quotas et limites de l'API
3. Vérifiez les logs pour les erreurs de requête
4. Vérifiez que le filtre de région (Kinshasa) n'est pas trop restrictif

## 📊 Monitoring et Coûts

### Configurer les Alertes de Quota

1. Allez dans Google Cloud Console > **APIs & Services** > **Dashboard**
2. Cliquez sur **Quotas**
3. Configurez des alertes pour :
   - Places API : 80% du quota mensuel
   - Directions API : 80% du quota mensuel
   - Maps SDK : 80% du quota mensuel

### Vérifier l'Utilisation

1. Allez dans **APIs & Services** > **Dashboard**
2. Consultez les graphiques d'utilisation
3. Vérifiez les coûts dans **Billing**

### Crédit Gratuit

Google Maps Platform offre **$200 USD de crédit gratuit par mois**, ce qui couvre généralement :
- ~28,000 chargements de carte (Maps SDK)
- ~17,000 requêtes Places API
- ~40,000 requêtes Directions API

## ✅ Checklist de Configuration

- [ ] Projet créé dans Google Cloud Console
- [ ] APIs activées (Maps SDK, Places API, Directions API)
- [ ] Clé API créée et copiée
- [ ] Restrictions configurées (Bundle ID, APIs)
- [ ] Clé API ajoutée dans Xcode (Build Settings ou Info.plist)
- [ ] Packages Swift installés (GoogleMaps, GooglePlaces)
- [ ] Application compile sans erreurs
- [ ] Autocomplétion fonctionne dans RideRequestView
- [ ] Calcul de prix fonctionne avec Google Directions
- [ ] Alertes de quota configurées dans Google Cloud Console
- [ ] Tests effectués et validés

## 🎯 Prochaines Étapes

Une fois la configuration terminée :

1. ✅ Tester l'autocomplétion avec différentes adresses
2. ✅ Tester le calcul de prix avec différents trajets
3. ✅ Remplacer progressivement MapKit par Google Maps dans les autres vues
4. ✅ Implémenter le tracé de route sur la carte
5. ✅ Optimiser les performances et réduire les appels API

---

**Support** : En cas de problème, consultez :
- [Documentation Google Maps SDK iOS](https://developers.google.com/maps/documentation/ios-sdk)
- [Documentation Google Places SDK iOS](https://developers.google.com/maps/documentation/places/ios-sdk)
- [Documentation Google Directions API](https://developers.google.com/maps/documentation/directions)

