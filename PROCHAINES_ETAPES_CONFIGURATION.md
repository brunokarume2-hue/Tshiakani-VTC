# 🎯 Prochaines Étapes - Configuration App Client

## ⚠️ Correction Nécessaire

Il y a une **incohérence** dans la configuration des URLs :

### Problème Identifié

1. **Info.plist** utilise : `/api` ✅
2. **ConfigurationService.swift** (fallback) utilise : `/api/v1` ❌
3. **Backend** expose les routes sous : `/api` ✅

### Solution

Les routes client sont sous `/api` (pas `/api/v1`). Il faut corriger le fallback dans `ConfigurationService.swift`.

---

## ✅ Étape 1: Corriger ConfigurationService.swift

### Correction à Apporter

Dans `Tshiakani VTC/Services/ConfigurationService.swift`, ligne 33 :

**Avant** (incorrect) :
```swift
return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/v1"
```

**Après** (correct) :
```swift
return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api"
```

Et ligne 51 pour WebSocket :

**Avant** (incorrect) :
```swift
return "wss://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
```

**Après** (correct) :
```swift
return "https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app"
```

**Note**: Socket.io utilise `https://` et gère automatiquement la sécurisation WebSocket.

---

## ✅ Étape 2: Vérifier la Configuration CORS sur Cloud Run

Le backend doit accepter les requêtes de l'application iOS.

### Vérifier CORS

```bash
# Vérifier les variables d'environnement du service Cloud Run
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"
```

### Configurer CORS si Nécessaire

Si CORS n'est pas configuré, mettre à jour le service :

```bash
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --set-env-vars "CORS_ORIGIN=*"
```

**Pour la production**, utilisez des origines spécifiques plutôt que `*` :

```bash
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --set-env-vars "CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app"
```

---

## ✅ Étape 3: Tester la Connexion au Backend

### 3.1 Test Health Check

```bash
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
```

**Résultat attendu** : Réponse 200 OK avec statut du backend

### 3.2 Test Authentification

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "role": "client"
  }'
```

**Résultat attendu** : Token JWT retourné

### 3.3 Test Routes Client

```bash
# Test estimation de prix (avec token JWT)
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/rides/estimate-price \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "pickupLocation": {
      "latitude": -4.3276,
      "longitude": 15.3136
    },
    "dropoffLocation": {
      "latitude": -4.3296,
      "longitude": 15.3156
    }
  }'
```

---

## ✅ Étape 4: Tester l'Application iOS

### 4.1 Build en Mode RELEASE

1. Ouvrir Xcode
2. Sélectionner le schéma **Release**
3. Builder l'application
4. Installer sur un appareil ou simulateur

### 4.2 Vérifier la Connexion

1. Lancer l'application
2. Vérifier les logs Xcode pour confirmer la connexion au backend
3. Tester l'authentification
4. Tester la création de course
5. Vérifier les WebSockets

### 4.3 Vérifier les URLs Utilisées

Dans les logs, vérifier que l'application utilise :
- **API URL**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- **WebSocket URL**: `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`

---

## ✅ Étape 5: Vérifier les WebSockets

### 5.1 Configuration WebSocket

Vérifier que :
- ✅ Namespace client : `/ws/client`
- ✅ URL WebSocket : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- ✅ Token JWT passé en query parameter

### 5.2 Tester la Connexion WebSocket

1. Se connecter avec un compte client
2. Créer une course
3. Vérifier que les événements WebSocket sont reçus :
   - `ride:status:changed`
   - `ride:accepted`
   - `driver:location:update`

---

## ✅ Étape 6: Vérifier les Routes API

### Routes Client Disponibles

Vérifier que toutes les routes client fonctionnent :

- ✅ `POST /api/auth/signin` - Authentification
- ✅ `POST /api/auth/verify` - Vérification OTP
- ✅ `GET /api/auth/profile` - Profil utilisateur
- ✅ `POST /api/rides/estimate-price` - Estimation du prix
- ✅ `POST /api/rides/create` - Création de course
- ✅ `GET /api/client/track_driver/{rideId}` - Suivi du chauffeur
- ✅ `GET /api/rides/history/{userId}` - Historique des courses

---

## ✅ Étape 7: Monitoring et Logs

### 7.1 Vérifier les Logs du Backend

```bash
# Voir les logs en temps réel
gcloud run services logs tail tshiakani-driver-backend \
  --region us-central1

# Voir les logs récents
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 50
```

### 7.2 Vérifier les Logs de l'App iOS

Dans Xcode, vérifier les logs de l'application pour :
- Erreurs de connexion
- Erreurs d'authentification
- Erreurs WebSocket
- Erreurs d'API

---

## 🛠️ Dépannage

### Problème: L'app ne se connecte pas

**Solutions**:
1. Vérifier que l'URL dans `Info.plist` est correcte
2. Vérifier que le backend est accessible
3. Vérifier CORS configuration
4. Vérifier les logs du backend

### Problème: Erreurs 404

**Solutions**:
1. Vérifier que l'URL API se termine par `/api` (pas `/api/v1`)
2. Vérifier que les routes sont montées correctement
3. Vérifier les logs du backend

### Problème: Erreurs CORS

**Solutions**:
1. Vérifier que `CORS_ORIGIN` est configuré sur Cloud Run
2. Mettre à jour CORS si nécessaire
3. Vérifier les headers CORS dans la réponse

### Problème: WebSocket ne se connecte pas

**Solutions**:
1. Vérifier que l'URL WebSocket utilise `https://` (pas `wss://`)
2. Vérifier que Socket.io est configuré sur le backend
3. Vérifier les logs du backend
4. Vérifier que le namespace est correct (`/ws/client`)

---

## 📊 Checklist de Vérification

### Configuration
- [ ] Info.plist configuré avec les bonnes URLs
- [ ] ConfigurationService.swift corrigé (fallback sans `/v1`)
- [ ] URLs cohérentes entre Info.plist et ConfigurationService.swift

### Backend
- [ ] Backend déployé sur Cloud Run
- [ ] CORS configuré correctement
- [ ] Routes API disponibles sous `/api`
- [ ] WebSocket configuré correctement

### Tests
- [ ] Health check fonctionne
- [ ] Authentification fonctionne
- [ ] Routes API testées
- [ ] WebSockets testés
- [ ] App iOS testée en mode RELEASE

### Monitoring
- [ ] Logs du backend vérifiés
- [ ] Logs de l'app iOS vérifiés
- [ ] Erreurs identifiées et corrigées

---

## 🎯 Résumé des Actions

1. **Corriger ConfigurationService.swift** - Enlever `/v1` et utiliser `https://` pour WebSocket
2. **Vérifier CORS** - S'assurer que CORS est configuré sur Cloud Run
3. **Tester la connexion** - Tester toutes les routes API
4. **Tester l'app iOS** - Builder en mode RELEASE et tester
5. **Vérifier les WebSockets** - Tester la connexion WebSocket
6. **Monitorer les logs** - Vérifier les logs du backend et de l'app

---

## 📚 Ressources

- [Configuration Client Cloud Run](./CONFIGURATION_CLIENT_CLOUD_RUN.md)
- [Guide de Configuration](./GUIDE_CONFIGURATION_CLIENT_GCLOUD.md)
- [Documentation Backend](./backend/README.md)
- [Routes API](./backend/API_CLIENT_V1.md)

---

**Date**: $(date)  
**Statut**: ⚠️ Correction nécessaire avant tests

