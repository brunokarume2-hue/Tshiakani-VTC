# 🔧 Guide : Corriger la Configuration Google Maps API

## 📋 Date : 2025-01-15

---

## 🎯 Problème

La clé API Google Maps retourne une erreur `403 PERMISSION_DENIED` avec le message :
```
"API_KEY_IOS_APP_BLOCKED"
"Requests from this iOS client application <empty> are blocked."
```

**Cause** : La clé API est configurée pour iOS uniquement, mais nous l'utilisons depuis le backend (serveur).

---

## ✅ Solution : Créer une Nouvelle Clé API pour le Backend

### Option 1 : Créer une Nouvelle Clé API (Recommandé)

#### Étape 1 : Aller dans Google Cloud Console

1. Ouvrir : https://console.cloud.google.com/apis/credentials?project=tshiakani-vtc-477711
2. Ou naviguer : **APIs & Services** → **Credentials**

#### Étape 2 : Créer une Nouvelle Clé API

1. Cliquer sur **"+ CREATE CREDENTIALS"**
2. Sélectionner **"API key"**
3. Une nouvelle clé sera générée

#### Étape 3 : Configurer les Restrictions

1. Cliquer sur la clé API créée pour l'éditer
2. **Application restrictions** :
   - Sélectionner **"None"** (pour le backend serveur)
   - OU **"IP addresses"** et ajouter les IPs de Cloud Run (optionnel, plus sécurisé)

3. **API restrictions** :
   - Sélectionner **"Restrict key"**
   - Cocher uniquement :
     - ✅ **Routes API**
     - ✅ **Geocoding API** (si utilisé)
     - ✅ **Places API** (si utilisé)

4. Cliquer sur **"SAVE"**

#### Étape 4 : Mettre à Jour Cloud Run

Une fois la nouvelle clé créée, mettre à jour la variable d'environnement dans Cloud Run :

```bash
export GCP_PROJECT_ID=tshiakani-vtc-477711
export NEW_API_KEY="VOTRE_NOUVELLE_CLE_API"

gcloud run services update tshiakani-vtc-backend \
  --region us-central1 \
  --project ${GCP_PROJECT_ID} \
  --update-env-vars="GOOGLE_MAPS_API_KEY=${NEW_API_KEY}"
```

---

### Option 2 : Modifier la Clé API Existante

#### Étape 1 : Trouver la Clé API

1. Aller dans : https://console.cloud.google.com/apis/credentials?project=tshiakani-vtc-477711
2. Trouver la clé : `AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8`
3. Cliquer dessus pour l'éditer

#### Étape 2 : Modifier les Restrictions

1. **Application restrictions** :
   - Changer de **"iOS apps"** à **"None"**
   - OU ajouter **"IP addresses"** avec les IPs de Cloud Run

2. **API restrictions** :
   - S'assurer que **Routes API** est autorisée

3. Cliquer sur **"SAVE"**

---

## 🧪 Test de la Clé API

Après modification, tester avec :

```bash
curl -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: VOTRE_CLE_API" \
  -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters" \
  -d '{
    "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3136}}},
    "destination": {"location": {"latLng": {"latitude": -4.3297, "longitude": 15.3150}}},
    "travelMode": "DRIVE",
    "routingPreference": "TRAFFIC_AWARE"
  }'
```

**Résultat attendu** : Réponse JSON avec `routes[0].legs[0].distanceMeters` et `routes[0].legs[0].duration`

---

## 📝 Notes Importantes

1. **Sécurité** : Pour la production, il est recommandé de :
   - Créer une clé API séparée pour le backend
   - Limiter les restrictions IP si possible
   - Activer les quotas et alertes dans Google Cloud Console

2. **Coûts** : Routes API est payant, mais il y a un crédit gratuit mensuel (200$)

3. **Fallback** : Le système utilise automatiquement Haversine si l'API échoue, donc l'application fonctionnera même si l'API est temporairement indisponible.

---

## ✅ Checklist

- [ ] Clé API créée ou modifiée dans Google Cloud Console
- [ ] Restrictions configurées (Application: None, API: Routes API)
- [ ] Clé API mise à jour dans Cloud Run
- [ ] Test de l'API réussi
- [ ] Backend redéployé (si nécessaire)

---

**Date** : 2025-01-15  
**Statut** : ⏳ **EN ATTENTE DE CONFIGURATION**

