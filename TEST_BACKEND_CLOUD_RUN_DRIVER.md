# 🔍 Test Backend Cloud Run - App Driver

## 📋 Résumé

Test de connexion au backend Cloud Run déployé pour vérifier que l'app driver peut se connecter correctement.

---

## ✅ Configuration

### Backend Cloud Run
- **URL Base**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **URL API**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- **URL WebSocket**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`

### Configuration App Driver
- **Info.plist**: URLs configurées pour Cloud Run
- **ConfigurationService.swift**: Utilise les URLs de Cloud Run en mode PRODUCTION
- **Namespace WebSocket**: `/ws/driver`

---

## 🧪 Tests Effectués

### 1. Health Check ✅

```bash
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
```

**Résultat** :
```json
{
  "status": "ok",
  "timestamp": "2025-11-10T00:43:29.506Z",
  "environment": "production"
}
```

✅ **Le backend Cloud Run est accessible et fonctionne**

### 2. Test Authentification

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001", "role": "driver"}'
```

**Note** : Il semble que la route `/api/auth/signin` ne soit pas disponible ou utilise un chemin différent. Il faut vérifier la structure des routes du backend déployé.

---

## 🔍 Vérifications à Effectuer

### 1. Vérifier les Routes Disponibles

Il faut vérifier quelles routes sont disponibles sur le backend Cloud Run :

```bash
# Test health check
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Test routes API
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api

# Test routes auth
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth

# Test routes driver
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/driver
```

### 2. Vérifier la Configuration du Backend

Le backend Cloud Run doit avoir :
- ✅ Routes `/api/auth/*` configurées
- ✅ Routes `/api/driver/*` configurées
- ✅ WebSocket namespace `/ws/driver` configuré
- ✅ CORS configuré pour accepter les requêtes iOS
- ✅ Base de données PostgreSQL connectée

### 3. Vérifier les Logs Cloud Run

```bash
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 50
```

---

## 📱 Configuration App Driver

### Info.plist

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api</string>
<key>WS_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app</string>
```

### ConfigurationService.swift

Le service utilise automatiquement les URLs de `Info.plist` en mode PRODUCTION :

```swift
var apiBaseURL: String {
    #if DEBUG
    return "http://localhost:3000/api"
    #else
    if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String {
        return url
    }
    return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
    #endif
}
```

---

## 🚀 Prochaines Étapes

### 1. Vérifier les Routes du Backend

Il faut vérifier que le backend Cloud Run a les routes suivantes :
- `POST /api/auth/signin` - Authentification
- `GET /api/auth/profile` - Profil utilisateur
- `POST /api/driver/location/update` - Mise à jour position
- `POST /api/driver/accept_ride/:rideId` - Accepter une course
- `POST /api/driver/reject_ride/:rideId` - Rejeter une course
- `POST /api/driver/complete_ride/:rideId` - Compléter une course

### 2. Tester depuis l'App iOS

Une fois les routes vérifiées, tester depuis l'app iOS :
1. Se connecter avec un numéro de téléphone (rôle driver)
2. Vérifier que l'authentification fonctionne
3. Vérifier la mise à jour de position
4. Vérifier la connexion WebSocket

### 3. Vérifier les Logs

Surveiller les logs Cloud Run pour voir les requêtes entrantes :
```bash
gcloud run services logs tail tshiakani-driver-backend \
  --region us-central1
```

---

## 📝 Notes

- Le backend Cloud Run répond au health check ✅
- La configuration de l'app driver est correcte ✅
- Il faut vérifier que les routes API sont correctement déployées
- Il faut vérifier que CORS est configuré pour accepter les requêtes iOS

---

**Date de test** : $(date)
**Statut** : ✅ Backend accessible, routes à vérifier

