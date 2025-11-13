# 🔒 Sécurité Admin et Suivi en Temps Réel - Documentation

## Date: 08/11/2025

### ✅ Implémentations Complétées

---

## I. 🔒 Sécurité du Dashboard Admin

### Middleware de Sécurité API Key

**Fichier:** `/backend/middlewares.postgres/adminApiKey.js`

**Fonctionnalité:**
- Vérifie la présence de l'en-tête `X-ADMIN-API-KEY` dans toutes les requêtes vers `/api/admin/*`
- Compare la clé avec la variable d'environnement `ADMIN_API_KEY`
- Retourne `403 Forbidden` si la clé est manquante ou incorrecte

**Application:**
- Le middleware est appliqué automatiquement à toutes les routes dans `/backend/routes.postgres/admin.js`
- Toutes les routes `/api/admin/*` sont maintenant protégées

### Configuration Requise

**Variable d'environnement à ajouter dans Render:**

```bash
ADMIN_API_KEY=votre_cle_secrete_tres_longue_et_aleatoire_123456789
```

**Génération d'une clé sécurisée:**
```bash
# Sur Linux/Mac
openssl rand -hex 32

# Ou utiliser un générateur de clé en ligne
# Exemple de clé générée: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6
```

### Utilisation dans le Dashboard

**Dans le code du dashboard (React/Vite), ajouter l'en-tête:**

```javascript
// Exemple avec axios
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api',
  headers: {
    'Content-Type': 'application/json',
    'X-ADMIN-API-KEY': import.meta.env.VITE_ADMIN_API_KEY // À configurer dans .env
  }
});
```

**Fichier `.env` du dashboard:**
```env
VITE_API_URL=http://localhost:3000/api
VITE_ADMIN_API_KEY=votre_cle_secrete_tres_longue_et_aleatoire_123456789
```

### Réponses d'Erreur

**Clé manquante:**
```json
{
  "error": "Accès refusé",
  "message": "Clé API admin manquante. Veuillez inclure X-ADMIN-API-KEY dans les headers."
}
```
**Status:** `403 Forbidden`

**Clé incorrecte:**
```json
{
  "error": "Accès refusé",
  "message": "Clé API admin invalide"
}
```
**Status:** `403 Forbidden`

---

## II. 📡 Suivi du Chauffeur en Temps Réel

### Endpoint Backend

**Route:** `GET /api/client/track_driver/:rideId`

**Fichier:** `/backend/routes.postgres/client.js`

**Authentification:** Requis (JWT token dans header `Authorization`)

**Paramètres:**
- `rideId` (URL): ID de la course

**Réponse:**
```json
{
  "success": true,
  "rideId": 123,
  "driver": {
    "id": 456,
    "name": "Jean Dupont",
    "phoneNumber": "+243900000000",
    "status": "en_route_to_pickup",
    "isOnline": true
  },
  "location": {
    "latitude": -4.3276,
    "longitude": 15.3136,
    "timestamp": "2025-11-08T10:30:00Z"
  },
  "estimatedArrivalMinutes": 5,
  "rideStatus": "accepted",
  "timestamp": "2025-11-08T10:30:00Z"
}
```

**Fonctionnalités:**
- ✅ Récupère les coordonnées géospatiales du chauffeur depuis PostGIS
- ✅ Retourne le statut du chauffeur (en_route_to_pickup, on_trip, etc.)
- ✅ Calcule l'ETA (temps d'arrivée estimé) en utilisant PostGIS pour la distance réelle
- ✅ Vérifie les permissions (seul le client de la course peut suivre)

### Implémentation Client (iOS)

**Fichier:** `/Tshiakani VTC/Services/APIService.swift`

**Méthode ajoutée:**
```swift
func trackDriver(rideId: String) async throws -> (
    driverId: String, 
    driverName: String, 
    location: Location, 
    status: String, 
    estimatedArrivalMinutes: Int?
)
```

**Fichier:** `/Tshiakani VTC/Views/Client/RideMapView.swift`

**Modifications:**
1. ✅ Requêtes périodiques toutes les **3 secondes** (au lieu de 4)
2. ✅ Animation fluide du mouvement du chauffeur avec `withAnimation(.easeInOut(duration: 0.5))`
3. ✅ Affichage de l'ETA (temps d'arrivée estimé) avec icône horloge
4. ✅ Affichage du statut du chauffeur (En route vers vous, En course, etc.)

**Code d'animation:**
```swift
await MainActor.run {
    // Animation fluide du mouvement du chauffeur sur la carte
    withAnimation(.easeInOut(duration: 0.5)) {
        driverLocation = result.location
        driverName = result.driverName
        driverStatus = result.status
    }
    
    // Utiliser l'ETA calculé par le backend (plus précis)
    if let eta = result.estimatedArrivalMinutes {
        estimatedArrivalTime = eta
    }
}
```

### Calcul de l'ETA

Le backend calcule l'ETA en utilisant:
1. **PostGIS** pour calculer la distance réelle entre la position du chauffeur et le point de départ
2. **Estimation de vitesse:** 30 km/h en moyenne (2 minutes par km)
3. **Formule:** `ETA = distance_km * 2` (arrondi à la minute supérieure)

**Exemple:**
- Distance: 2.5 km
- ETA: `ceil(2.5 * 2) = 5 minutes`

---

## 📊 Architecture

```
┌─────────────────┐
│  Dashboard      │
│  Admin          │
└────────┬────────┘
         │
         │ X-ADMIN-API-KEY
         ▼
┌─────────────────┐
│  Middleware     │
│  adminApiKeyAuth│ ✅ Vérifie la clé
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Routes Admin   │
│  /api/admin/*   │
└─────────────────┘

┌─────────────────┐
│  App Client     │
│  (iOS)          │
└────────┬────────┘
         │
         │ GET /api/client/track_driver/:rideId
         │ (toutes les 3 secondes)
         ▼
┌─────────────────┐
│  Backend        │
│  PostgreSQL     │
│  + PostGIS      │ ✅ Calcule ETA
└─────────────────┘
```

---

## 🧪 Tests

### Test Sécurité Admin

**1. Test sans clé API:**
```bash
curl -X GET http://localhost:3000/api/admin/stats
# Réponse: 403 Forbidden
```

**2. Test avec clé incorrecte:**
```bash
curl -X GET http://localhost:3000/api/admin/stats \
  -H "X-ADMIN-API-KEY: mauvaise_cle"
# Réponse: 403 Forbidden
```

**3. Test avec clé correcte:**
```bash
curl -X GET http://localhost:3000/api/admin/stats \
  -H "X-ADMIN-API-KEY: votre_cle_secrete"
# Réponse: 200 OK avec les statistiques
```

### Test Suivi Chauffeur

**1. Test de l'endpoint:**
```bash
curl -X GET http://localhost:3000/api/client/track_driver/123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
# Réponse: JSON avec position, statut et ETA
```

**2. Test dans l'app iOS:**
- Créer une course
- Attendre qu'un chauffeur accepte
- Observer la carte: le chauffeur doit bouger toutes les 3 secondes avec animation
- Vérifier l'affichage de l'ETA

---

## 🚀 Déploiement

### Variables d'Environnement à Configurer dans Render

**Backend:**
```env
ADMIN_API_KEY=votre_cle_secrete_tres_longue_et_aleatoire_123456789
DB_HOST=...
DB_PORT=...
DB_USER=...
DB_PASSWORD=...
DB_NAME=...
JWT_SECRET=...
```

**Dashboard (Vercel ou autre):**
```env
VITE_API_URL=https://votre-backend.onrender.com/api
VITE_ADMIN_API_KEY=votre_cle_secrete_tres_longue_et_aleatoire_123456789
```

---

## ✅ Checklist de Déploiement

- [ ] Générer une clé API sécurisée pour `ADMIN_API_KEY`
- [ ] Configurer `ADMIN_API_KEY` dans Render (Backend)
- [ ] Configurer `VITE_ADMIN_API_KEY` dans Vercel (Dashboard)
- [ ] Tester les routes admin avec la clé API
- [ ] Vérifier que le suivi du chauffeur fonctionne dans l'app iOS
- [ ] Vérifier l'animation fluide du mouvement sur la carte
- [ ] Vérifier l'affichage de l'ETA

---

## 📝 Notes

- **Sécurité:** La clé API admin doit être stockée de manière sécurisée et jamais commitée dans le code
- **Performance:** Les requêtes de suivi toutes les 3 secondes sont optimisées avec PostGIS
- **Animation:** L'animation de 0.5 secondes assure un mouvement fluide sans surcharger l'UI
- **ETA:** Le calcul utilise PostGIS pour une précision maximale, basé sur la distance réelle

---

## 🔗 Fichiers Modifiés

1. ✅ `/backend/middlewares.postgres/adminApiKey.js` (NOUVEAU)
2. ✅ `/backend/routes.postgres/admin.js` (MODIFIÉ - ajout middleware)
3. ✅ `/backend/routes.postgres/client.js` (NOUVEAU)
4. ✅ `/backend/server.postgres.js` (MODIFIÉ - ajout route /api/client)
5. ✅ `/Tshiakani VTC/Services/APIService.swift` (MODIFIÉ - ajout trackDriver)
6. ✅ `/Tshiakani VTC/Views/Client/RideMapView.swift` (MODIFIÉ - animation et ETA)

---

**Toutes les fonctionnalités sont implémentées et prêtes pour le déploiement !** 🎉

