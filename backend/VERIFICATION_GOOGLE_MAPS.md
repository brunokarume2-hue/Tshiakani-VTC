# ✅ Vérification Intégration Google Maps Routes API

## 📋 Date : 2025-01-15

---

## 🎯 Objectif

Vérifier que Google Maps Routes API est correctement intégrée pour calculer l'ETA et le prix **AVANT** de proposer la course au chauffeur.

---

## ✅ Vérifications Effectuées

### 1. **Configuration de la Clé API**

✅ **Clé API configurée dans Cloud Run** :
```
GOOGLE_MAPS_API_KEY=AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8
```

⚠️ **Problème détecté** : La clé API retourne une erreur `403 PERMISSION_DENIED` avec le message :
```
"Requests from this iOS client application <empty> are blocked."
"API_KEY_IOS_APP_BLOCKED"
```

**Cause** : La clé API est probablement configurée pour iOS uniquement dans Google Cloud Console, mais nous l'utilisons depuis le backend (serveur).

**Solution** : Il faut configurer la clé API pour autoriser les requêtes depuis le serveur (IP restrictions ou aucune restriction pour le backend).

---

### 2. **Intégration dans le Code**

#### ✅ **BackendAgentPrincipal.createRide()** (Lignes 73-93)

Le flux est **correct** :

```javascript
// 1. Calculer la distance et le temps AVANT de créer la course
const routeData = await GoogleMapsService.calculateRoute(
  rideData.pickupLocation,
  rideData.dropoffLocation,
  {
    travelMode: 'DRIVE',
    routingPreference: 'TRAFFIC_AWARE',  // Prend en compte le trafic
    language: 'fr'
  }
);

const distance = routeData.distance.kilometers;
const duration = routeData.duration;

// 2. Calculer le prix avec distance et temps réels
const pricing = await PricingService.calculateDynamicPrice(
  distance,
  new Date(),
  rideData.pickupLocation,
  rideData.dropoffLocation
);

// 3. Créer la course avec prix et ETA calculés
const ride = rideRepository.create({
  // ...
  estimatedPrice: pricing.price,
  distance: distance,
  estimatedDuration: duration.minutes,
  // ...
});

// 4. Trouver le meilleur chauffeur (matching)
const bestMatch = await DriverMatchingService.findBestDriver(
  rideData.pickupLocation,
  rideData.dropoffLocation,
  savedRide.id
);

// 5. Proposer la course au chauffeur avec prix et ETA
```

**✅ Confirmation** : Le prix et l'ETA sont calculés **AVANT** la création de la course et la proposition au chauffeur.

#### ✅ **PricingService.calculateDynamicPrice()** (Lignes 122-240)

Le service utilise Google Maps Routes API pour calculer la distance et le temps :

```javascript
// Si dropoffLocation est fourni, utiliser Google Maps Routes API
if (dropoffLocation && pickupLocation) {
  try {
    const routeData = await GoogleMapsService.calculateRoute(
      pickupLocation,
      dropoffLocation,
      {
        travelMode: 'DRIVE',
        routingPreference: 'TRAFFIC_AWARE',  // Trafic en temps réel
        language: 'fr'
      }
    );

    calculatedDistance = routeData.distance.kilometers;
    duration = routeData.duration;
  } catch (error) {
    // Fallback vers Haversine si l'API échoue
    const haversineResult = GoogleMapsService.calculateDistanceHaversine(
      pickupLocation,
      dropoffLocation
    );
    calculatedDistance = haversineResult.distance.kilometers;
  }
}
```

**✅ Fallback** : Si Google Maps API échoue, le système utilise la formule de Haversine comme fallback.

---

### 3. **Service GoogleMapsService**

#### ✅ **Routes API v2** (Lignes 43-199)

- ✅ Utilise `routes.googleapis.com/directions/v2:computeRoutes`
- ✅ Prend en compte le trafic (`routingPreference: 'TRAFFIC_AWARE'`)
- ✅ Retourne distance en kilomètres et durée en minutes
- ✅ Gère les erreurs avec fallback Haversine

#### ✅ **Fonctionnalités**

1. **calculateRoute()** : Calcul d'itinéraire avec trafic
2. **calculateDistanceHaversine()** : Fallback si API échoue
3. **geocodeAddress()** : Géocodage d'adresses
4. **reverseGeocode()** : Géocodage inversé
5. **searchPlaces()** : Recherche de places

---

## ⚠️ Problème à Corriger

### **Configuration de la Clé API**

La clé API doit être configurée pour autoriser les requêtes depuis le serveur backend.

#### **Étapes de Correction**

1. **Aller dans Google Cloud Console** :
   - APIs & Services → Credentials
   - Trouver la clé : `AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8`

2. **Modifier les restrictions** :
   - **Option 1** : Supprimer les restrictions iOS
   - **Option 2** : Ajouter une restriction "IP addresses" avec les IPs de Cloud Run
   - **Option 3** : Créer une nouvelle clé API pour le backend (recommandé)

3. **Restrictions recommandées** :
   - **Application restrictions** : "None" (pour le backend)
   - **API restrictions** : Limiter à "Routes API" uniquement

---

## 📊 Flux Complet de Création de Course

```
1. Client demande une course
   ↓
2. BackendAgentPrincipal.createRide()
   ↓
3. Google Maps Routes API
   ├─ Calcul distance réelle (avec trafic)
   ├─ Calcul durée réelle (avec trafic)
   └─ Si échec → Fallback Haversine
   ↓
4. PricingService.calculateDynamicPrice()
   ├─ Utilise distance réelle de Google Maps
   ├─ Applique multiplicateurs (heure, jour, demande)
   └─ Calcule prix final
   ↓
5. Création de la course
   ├─ estimatedPrice (prix calculé)
   ├─ distance (distance réelle)
   └─ estimatedDuration (durée réelle)
   ↓
6. DriverMatchingService.findBestDriver()
   ├─ Trouve chauffeurs disponibles (Redis)
   └─ Sélectionne le meilleur
   ↓
7. Proposition au chauffeur
   ├─ Prix fixe (déjà calculé)
   ├─ ETA (déjà calculé)
   └─ Distance (déjà calculée)
```

**✅ Confirmation** : Le prix et l'ETA sont calculés **AVANT** la proposition au chauffeur.

---

## 🧪 Tests à Effectuer

### Test 1 : Vérifier que l'API fonctionne
```bash
# Après correction de la clé API
curl -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8" \
  -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters" \
  -d '{
    "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3136}}},
    "destination": {"location": {"latLng": {"latitude": -4.3297, "longitude": 15.3150}}},
    "travelMode": "DRIVE",
    "routingPreference": "TRAFFIC_AWARE"
  }'
```

### Test 2 : Vérifier le fallback Haversine
Si l'API échoue, le système doit utiliser Haversine automatiquement.

### Test 3 : Vérifier dans les logs
Les logs doivent montrer :
- ✅ `Distance et temps calculés via Google Maps Routes API` (succès)
- ⚠️ `Erreur calcul Google Maps Routes API, tentative avec Haversine` (fallback)

---

## ✅ Résumé

### ✅ **Intégration Code**
- ✅ Google Maps Routes API utilisée dans `BackendAgentPrincipal`
- ✅ Google Maps Routes API utilisée dans `PricingService`
- ✅ Calcul de distance et ETA **AVANT** création de course
- ✅ Fallback Haversine si API échoue
- ✅ Clé API configurée dans Cloud Run

### ⚠️ **Action Requise**
- ⚠️ Corriger la configuration de la clé API dans Google Cloud Console
- ⚠️ Autoriser les requêtes depuis le serveur backend

---

**Date** : 2025-01-15  
**Statut** : ✅ **INTÉGRATION CORRECTE** (configuration clé API à corriger)

