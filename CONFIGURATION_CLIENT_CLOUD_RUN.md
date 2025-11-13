# ✅ Configuration App Client vers Backend Cloud Run

## 📋 Résumé

L'application client iOS est maintenant configurée pour se connecter au backend déployé sur Google Cloud Run.

---

## ✅ Configuration Effectuée

### 1. Info.plist Mis à Jour

Le fichier `Tshiakani VTC/Info.plist` a été mis à jour avec les URLs du backend Cloud Run:

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api</string>
<key>WS_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app</string>
```

### 2. ConfigurationService.swift

Le fichier `Tshiakani VTC/Services/ConfigurationService.swift` est déjà configuré pour:
- ✅ Lire les URLs depuis `Info.plist` en priorité
- ✅ Utiliser `localhost:3000` en mode DEBUG
- ✅ Utiliser les URLs de production en mode RELEASE

### 3. Corrections Apportées

- ✅ **URL API**: Corrigée de `/api/v1` vers `/api` (routes correctes)
- ✅ **URL WebSocket**: Corrigée de `wss://` vers `https://` (Socket.io gère automatiquement)

---

## 🔍 URLs Configurées

### Backend Cloud Run
- **URL Base**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **URL API**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- **URL WebSocket**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`

### Mode DEBUG
- **URL API**: `http://localhost:3000/api`
- **URL WebSocket**: `http://localhost:3000`

---

## 📱 Routes API Utilisées par l'App Client

### Authentification
- `POST /api/auth/signin` - Connexion/Inscription
- `POST /api/auth/verify` - Vérification OTP
- `GET /api/auth/profile` - Profil utilisateur
- `PUT /api/auth/profile` - Mise à jour profil

### Courses
- `POST /api/rides/estimate-price` - Estimation du prix
- `POST /api/rides/create` - Création de course
- `GET /api/rides/history/{userId}` - Historique des courses
- `GET /api/rides/{rideId}` - Détails d'une course
- `PATCH /api/rides/{rideId}/status` - Mise à jour statut
- `POST /api/rides/{rideId}/rate` - Évaluation

### Client
- `GET /api/client/track_driver/{rideId}` - Suivi du chauffeur

### Location
- `GET /api/location/drivers/nearby` - Chauffeurs à proximité
- `POST /api/location/update` - Mise à jour position

### Paiements
- `POST /api/paiements/preauthorize` - Préautorisation
- `POST /api/paiements/confirm` - Confirmation

---

## 🔌 WebSocket

### Namespace Client
- **Namespace**: `/ws/client`
- **URL Complète**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/ws/client`

### Événements Reçus
- `ride:status:changed` - Changement de statut de course
- `ride:accepted` - Course acceptée
- `driver:location:update` - Mise à jour de position du driver

---

## 🧪 Tests

### Tester la Connexion API

```bash
# Health check
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Test d'authentification
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "role": "client"
  }'
```

### Tester depuis l'App iOS

1. **Build en mode RELEASE** pour utiliser les URLs de production
2. **Lancer l'app** et vérifier les logs
3. **Tester l'authentification**
4. **Tester la création de course**
5. **Tester les WebSockets**

---

## ⚙️ Configuration CORS

Le backend doit accepter les requêtes de l'application iOS. Vérifiez que CORS est configuré sur Cloud Run:

```bash
# Vérifier la configuration CORS
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"
```

Pour une configuration sécurisée, CORS doit accepter:
- Les requêtes depuis l'application iOS (origine peut être `*` ou spécifique)
- Les headers `Authorization`, `Content-Type`
- Les méthodes `GET`, `POST`, `PUT`, `PATCH`, `DELETE`

---

## 🔐 Sécurité

### Authentification
- ✅ JWT Token requis pour toutes les routes (sauf `/api/auth/signin`)
- ✅ Token stocké dans `UserDefaults` via `ConfigurationService`
- ✅ Token passé dans le header `Authorization: Bearer <token>`

### WebSocket
- ✅ Token JWT passé en query parameter lors de la connexion
- ✅ Vérification du token côté serveur
- ✅ Connexion sécurisée via HTTPS/WSS

---

## 🛠️ Dépannage

### Problème: L'app ne se connecte pas au backend

**Solutions**:
1. Vérifier que l'URL dans `Info.plist` est correcte
2. Vérifier que le backend est accessible: `curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health`
3. Vérifier les logs du backend: `gcloud run services logs read tshiakani-driver-backend --region us-central1`
4. Vérifier CORS configuration

### Problème: Erreurs CORS

**Solutions**:
1. Vérifier que `CORS_ORIGIN` est configuré sur Cloud Run
2. Vérifier que l'origine de la requête est autorisée
3. Vérifier les headers CORS dans la réponse

### Problème: WebSocket ne se connecte pas

**Solutions**:
1. Vérifier que l'URL WebSocket est correcte (utilisez `https://` pas `wss://`)
2. Vérifier que Socket.io est configuré sur le backend
3. Vérifier les logs du backend pour les erreurs de connexion
4. Vérifier que le namespace est correct (`/ws/client`)

### Problème: Routes API non trouvées (404)

**Solutions**:
1. Vérifier que l'URL API se termine par `/api` (pas `/api/v1`)
2. Vérifier que les routes sont montées correctement dans `server.postgres.js`
3. Vérifier les logs du backend pour les erreurs 404

---

## 📊 État de la Configuration

- ✅ **Info.plist**: URLs configurées
- ✅ **ConfigurationService.swift**: Configuration correcte
- ✅ **Routes API**: Toutes les routes client disponibles
- ✅ **WebSocket**: Namespace `/ws/client` configuré
- ✅ **Authentification**: JWT configuré
- ✅ **Mode DEBUG**: Backend local (`localhost:3000`)
- ✅ **Mode RELEASE**: Backend Cloud Run

---

## 🎯 Prochaines Étapes

1. **Tester l'application en mode RELEASE**
2. **Vérifier que toutes les fonctionnalités fonctionnent**
3. **Vérifier les WebSockets**
4. **Vérifier les notifications push**
5. **Monitorer les logs du backend**

---

## 📚 Ressources

- [Guide de Configuration](./GUIDE_CONFIGURATION_CLIENT_GCLOUD.md)
- [Documentation Backend](./backend/README.md)
- [Routes API](./backend/API_CLIENT_V1.md)
- [Configuration WebSocket](./backend/server.postgres.js)

---

## ✅ Checklist

- [x] Info.plist mis à jour avec les URLs Cloud Run
- [x] URL API corrigée (sans `/v1`)
- [x] URL WebSocket corrigée (`https://` au lieu de `wss://`)
- [x] ConfigurationService.swift vérifié
- [ ] Tests de connexion effectués
- [ ] App iOS testée en mode RELEASE
- [ ] WebSockets testés
- [ ] CORS vérifié sur Cloud Run

---

**Date de configuration**: $(date)  
**Backend URL**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`  
**Statut**: ✅ Configuré

