# ✅ Google Maps API - Configuré

## 🔑 Clé API Configurée

**Date de configuration** : 2025-01-15

### Configuration Effectuée

1. ✅ **Clé API stockée dans Secret Manager**
   - Secret : `google-maps-api-key`
   - Projet : `tshiakani-vtc-477711`

2. ✅ **Permissions IAM configurées**
   - Service account : `418102154417-compute@developer.gserviceaccount.com`
   - Rôle : `roles/secretmanager.secretAccessor`

3. ✅ **Variable d'environnement Cloud Run mise à jour**
   - Service : `tshiakani-vtc-backend`
   - Variable : `GOOGLE_MAPS_API_KEY`
   - Région : `us-central1`

---

## 📝 Informations

### Clé API
- **Clé** : `AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8`
- **Stockage** : Secret Manager + Variable d'environnement Cloud Run

### APIs Utilisées
- Routes API (pour calculer les distances et itinéraires)
- Places API (pour la recherche de lieux)
- Geocoding API (pour convertir adresses en coordonnées)

---

## 🔒 Sécurité

### Recommandations

1. **Restreindre la clé API** :
   - Aller sur : https://console.cloud.google.com/apis/credentials?project=tshiakani-vtc-477711
   - Cliquer sur la clé API
   - Sous "Restrictions d'application", sélectionner "Applications HTTP"
   - Ajouter l'URL : `https://tshiakani-vtc-backend-418102154417.us-central1.run.app`
   - Sous "Restrictions d'API", sélectionner uniquement :
     - Routes API
     - Places API
     - Geocoding API

2. **Configurer des quotas** :
   - Aller sur : https://console.cloud.google.com/apis/api/routes-backend.googleapis.com/quotas?project=tshiakani-vtc-477711
   - Configurer des quotas pour éviter les dépassements de coûts

3. **Activer les alertes de facturation** :
   - Aller sur : https://console.cloud.google.com/billing?project=tshiakani-vtc-477711
   - Configurer des alertes pour être notifié en cas de dépassement

---

## 🧪 Test

### Tester l'API Google Maps

```bash
# Test de l'API Routes
curl "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8" \
  -d '{
    "origin": {"location": {"latLng": {"latitude": -4.3276, "longitude": 15.3363}}},
    "destination": {"location": {"latLng": {"latitude": -4.3376, "longitude": 15.3463}}},
    "travelMode": "DRIVE"
  }'
```

### Vérifier dans le Backend

```bash
# Tester via le service Cloud Run
curl https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/ride/estimate \
  -H "Content-Type: application/json" \
  -d '{
    "pickupLocation": {"latitude": -4.3276, "longitude": 15.3363},
    "dropoffLocation": {"latitude": -4.3376, "longitude": 15.3463}
  }'
```

---

## 📊 Coûts

### Tarification Google Maps (approximative)

- **Routes API** : 
  - $5.00 par 1000 requêtes (Basic)
  - $10.00 par 1000 requêtes (Advanced)
- **Places API** :
  - $17.00 par 1000 requêtes (Text Search)
  - $32.00 par 1000 requêtes (Nearby Search)
- **Geocoding API** :
  - $5.00 par 1000 requêtes

### Quota Gratuit

- $200 de crédit gratuit par mois
- Environ 40 000 requêtes Routes API (Basic) par mois

---

## 🔧 Commandes Utiles

### Mettre à jour la clé API

```bash
# Mettre à jour dans Secret Manager
echo -n 'NOUVELLE_CLE_API' | gcloud secrets versions add google-maps-api-key \
  --data-file=- \
  --project=tshiakani-vtc-477711

# Mettre à jour dans Cloud Run
gcloud run services update tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --update-env-vars="GOOGLE_MAPS_API_KEY=NOUVELLE_CLE_API"
```

### Vérifier la configuration

```bash
# Vérifier Secret Manager
gcloud secrets describe google-maps-api-key --project=tshiakani-vtc-477711

# Vérifier Cloud Run
gcloud run services describe tshiakani-vtc-backend \
  --region=us-central1 \
  --project=tshiakani-vtc-477711 \
  --format="value(spec.template.spec.containers[0].env)"
```

---

## 📚 Documentation

- **Console GCP** : https://console.cloud.google.com/apis/credentials?project=tshiakani-vtc-477711
- **Documentation Routes API** : https://developers.google.com/maps/documentation/routes
- **Documentation Places API** : https://developers.google.com/maps/documentation/places
- **Tarification** : https://developers.google.com/maps/billing-and-pricing/pricing

---

**Date de configuration** : 2025-01-15  
**Statut** : ✅ Configuré et opérationnel

