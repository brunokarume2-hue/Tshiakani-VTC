# 🔍 Vérification de la Connexion Backend - Tshiakani VTC

## 📋 Date : $(date)
**Objectif** : Vérifier que l'application iOS est correctement connectée au backend

---

## 🔍 Configuration Actuelle

### 1. ✅ URLs Configurées dans l'Application iOS

**Fichier** : `Tshiakani VTC/Services/ConfigurationService.swift`

#### API Base URL
- **Mode DEBUG** : `http://localhost:3000/api`
- **Mode PRODUCTION** : `https://api.tshiakani-vtc.com/api`
- **Personnalisé** : Peut être défini dans `UserDefaults` avec la clé `api_base_url`

#### WebSocket Base URL
- **Mode DEBUG** : `http://localhost:3000`
- **Mode PRODUCTION** : `https://api.tshiakani-vtc.com`
- **Personnalisé** : Peut être défini dans `UserDefaults` avec la clé `socket_base_url`

#### Namespace WebSocket Client
- **Namespace** : `/ws/client`

---

## ✅ Endpoints Utilisés par l'Application iOS

### Authentification
- ✅ `POST /api/auth/signin` - Connexion/Inscription
- ✅ `POST /api/auth/verify` - Vérification OTP
- ✅ `PUT /api/auth/profile` - Mise à jour profil
- ✅ `GET /api/auth/profile` - Profil utilisateur

### Courses
- ✅ `POST /api/rides/estimate-price` - Estimation du prix
- ✅ `POST /api/rides/create` - Création de course
- ✅ `GET /api/rides/history/{userId}` - Historique
- ✅ `PATCH /api/rides/{rideId}/status` - Mise à jour statut
- ✅ `POST /api/rides/{rideId}/rate` - Évaluation
- ✅ `GET /api/rides/{rideId}` - Détails d'une course

### Client
- ✅ `GET /api/client/track_driver/{rideId}` - Suivi du chauffeur

### Location
- ✅ `GET /api/location/drivers/nearby` - Chauffeurs à proximité
- ✅ `POST /api/location/update` - Mise à jour position

### Paiements
- ✅ `POST /api/paiements/preauthorize` - Préautorisation
- ✅ `POST /api/paiements/confirm` - Confirmation

---

## 🔧 Vérification de la Connexion

### Étape 1 : Vérifier la Configuration

#### 1.1 Vérifier l'URL du Backend
```swift
// Dans l'application iOS
let config = ConfigurationService.shared
print("API Base URL: \(config.apiBaseURL)")
print("Socket Base URL: \(config.socketBaseURL)")
```

#### 1.2 Vérifier le Mode (DEBUG/PRODUCTION)
- **DEBUG** : Utilise `http://localhost:3000/api`
- **PRODUCTION** : Utilise `https://api.tshiakani-vtc.com/api`

---

### Étape 2 : Tester la Connexion HTTP

#### 2.1 Test de Health Check
```bash
# Tester le endpoint health
curl http://localhost:3000/health

# Réponse attendue :
# {
#   "status": "OK",
#   "database": "connected",
#   "timestamp": "2025-01-XX..."
# }
```

#### 2.2 Test d'Authentification
```bash
# Tester l'authentification
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "role": "client"
  }'

# Réponse attendue :
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {
#     "id": 1,
#     "name": "Utilisateur",
#     "phoneNumber": "+243900000000",
#     "role": "client"
#   }
# }
```

---

### Étape 3 : Tester la Connexion WebSocket

#### 3.1 Test de Connexion WebSocket
```javascript
// Dans le backend, vérifier les logs
// Lors de la connexion, vous devriez voir :
// ✅ Client X connecté via WebSocket
```

#### 3.2 Test du Namespace Client
```javascript
// Le client doit se connecter à : /ws/client
// Avec le token JWT en paramètre : ?token=...
```

---

## 🧪 Tests à Effectuer

### Test 1 : Vérifier que le Backend est Démarré

```bash
cd backend
npm start

# Vérifier les logs :
# 🚀 Serveur démarré sur le port 3000
# 📡 WebSocket namespace /ws/driver disponible
# 📡 WebSocket namespace /ws/client disponible
# 🌐 API disponible sur http://0.0.0.0:3000/api
# ⚡ Service temps réel des courses activé
```

### Test 2 : Tester depuis l'Application iOS

#### 2.1 Test d'Authentification
1. Ouvrir l'application iOS
2. Se connecter avec un numéro de téléphone
3. Vérifier que l'authentification fonctionne
4. Vérifier les logs du backend pour voir la requête

#### 2.2 Test de Création de Course
1. Créer une course depuis l'application
2. Vérifier que la course est créée dans la base de données
3. Vérifier les logs du backend

#### 2.3 Test de WebSocket
1. Se connecter à l'application
2. Vérifier que la connexion WebSocket est établie
3. Vérifier les logs du backend

---

## 🔍 Diagnostic des Problèmes

### Problème 1 : L'application ne peut pas se connecter au backend

#### Symptômes
- Erreur "URL invalide"
- Erreur "Connection refused"
- Timeout des requêtes

#### Solutions
1. **Vérifier que le backend est démarré**
   ```bash
   cd backend
   npm start
   ```

2. **Vérifier l'URL dans l'application**
   - Mode DEBUG : `http://localhost:3000/api`
   - Mode PRODUCTION : Vérifier l'URL de production

3. **Vérifier les variables d'environnement**
   ```bash
   # Dans le backend
   cat .env
   ```

4. **Vérifier le firewall**
   - Port 3000 doit être ouvert
   - CORS doit être configuré correctement

---

### Problème 2 : L'authentification échoue

#### Symptômes
- Erreur 401 (Unauthorized)
- Erreur 403 (Forbidden)
- Token JWT invalide

#### Solutions
1. **Vérifier le JWT_SECRET**
   ```bash
   # Dans le backend .env
   JWT_SECRET=your_secret_here
   ```

2. **Vérifier que le token est envoyé**
   ```swift
   // Dans l'application iOS
   let token = config.getAuthToken()
   print("Token: \(token ?? "Aucun token")")
   ```

3. **Vérifier l'expiration du token**
   - Par défaut : 7 jours
   - Vérifier dans le backend : `JWT_EXPIRES_IN`

---

### Problème 3 : WebSocket ne se connecte pas

#### Symptômes
- Connexion WebSocket échoue
- Erreur "Connection refused"
- Timeout de connexion

#### Solutions
1. **Vérifier que Socket.io est configuré**
   ```javascript
   // Dans server.postgres.js
   // Vérifier que les namespaces sont configurés
   ```

2. **Vérifier l'URL WebSocket**
   ```swift
   // Dans l'application iOS
   let socketURL = config.buildSocketURL(namespace: "/ws/client")
   print("Socket URL: \(socketURL)")
   ```

3. **Vérifier le token JWT**
   - Le token doit être passé en paramètre : `?token=...`
   - Le token doit être valide

4. **Vérifier CORS**
   ```javascript
   // Dans server.postgres.js
   // Vérifier que CORS est configuré pour WebSocket
   ```

---

## 📊 Checklist de Vérification

### Configuration
- [ ] Backend démarré et accessible
- [ ] URL du backend correcte dans l'application
- [ ] Variables d'environnement configurées
- [ ] CORS configuré correctement

### Authentification
- [ ] Endpoint `/api/auth/signin` fonctionne
- [ ] Token JWT généré correctement
- [ ] Token JWT stocké dans UserDefaults
- [ ] Token JWT envoyé dans les requêtes

### API REST
- [ ] Endpoint `/api/rides/create` fonctionne
- [ ] Endpoint `/api/rides/history` fonctionne
- [ ] Endpoint `/api/location/drivers/nearby` fonctionne
- [ ] Endpoint `/api/client/track_driver` fonctionne

### WebSocket
- [ ] Connexion WebSocket établie
- [ ] Namespace `/ws/client` accessible
- [ ] Authentification WebSocket fonctionne
- [ ] Mises à jour en temps réel fonctionnent

---

## 🧪 Script de Test

### Test Backend (Health Check)
```bash
#!/bin/bash
# test-backend-connection.sh

echo "🔍 Test de connexion au backend..."

# Test 1: Health Check
echo "1. Test Health Check..."
curl -s http://localhost:3000/health | jq .

# Test 2: Authentification
echo "2. Test Authentification..."
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "role": "client"
  }' | jq .

echo "✅ Tests terminés"
```

---

## 📝 Notes

### Mode Développement
- L'application utilise `http://localhost:3000/api` en mode DEBUG
- Le backend doit être démarré localement
- Le simulateur iOS peut accéder à `localhost` sur la machine hôte

### Mode Production
- L'application utilise `https://api.tshiakani-vtc.com/api` en mode PRODUCTION
- Le backend doit être déployé et accessible
- L'URL peut être personnalisée via UserDefaults

### Configuration Personnalisée
- L'URL du backend peut être modifiée via UserDefaults
- Clé : `api_base_url`
- Clé : `socket_base_url`

---

**Date de création** : $(date)
**Statut** : ✅ Guide de vérification créé

