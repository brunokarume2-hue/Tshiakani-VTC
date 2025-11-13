# 🔍 Rapport de Vérification - Connexion Backend et App Driver

## 📋 Date : $(date)
**Objectif** : Vérifier que l'application driver iOS est correctement connectée au backend

---

## ✅ Configuration Actuelle

### 1. URLs Configurées dans l'Application iOS

**Fichier** : `Tshiakani VTC/Services/ConfigurationService.swift`

#### API Base URL
- **Mode DEBUG** : `http://localhost:3000/api`
- **Mode PRODUCTION** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- **Personnalisé** : Peut être défini dans `UserDefaults` avec la clé `api_base_url`

#### WebSocket Base URL
- **Mode DEBUG** : `http://localhost:3000`
- **Mode PRODUCTION** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **Personnalisé** : Peut être défini dans `UserDefaults` avec la clé `socket_base_url`

#### Namespace WebSocket Driver
- **Namespace** : `/ws/driver`

---

## ✅ Routes Driver Disponibles

### Routes REST API

| Méthode | Endpoint | Description | Authentification |
|---------|----------|-------------|------------------|
| POST | `/api/driver/location/update` | Mettre à jour la position GPS | ✅ JWT (rôle driver) |
| POST | `/api/driver/accept_ride/:rideId` | Accepter une course | ✅ JWT (rôle driver) |
| POST | `/api/driver/reject_ride/:rideId` | Rejeter une course | ✅ JWT (rôle driver) |
| POST | `/api/driver/complete_ride/:rideId` | Compléter une course | ✅ JWT (rôle driver) |

### WebSocket Events

| Événement | Direction | Description |
|-----------|-----------|-------------|
| `ride:new` | Backend → Driver | Nouvelle course disponible |
| `ride:update` | Backend → Driver | Mise à jour d'une course |
| `ride:accepted` | Backend → Driver/Client | Course acceptée |
| `ride:rejected` | Backend → Driver/Client | Course rejetée |
| `ride:completed` | Backend → Driver/Client | Course complétée |
| `driver:location:update` | Driver → Backend | Mise à jour position (via REST) |

---

## 🔧 Vérification de la Connexion

### Étape 1 : Vérifier que le Backend est Démarré

```bash
cd backend
npm start

# Vérifier les logs :
# 🚀 Serveur démarré sur le port 3000
# 📡 WebSocket namespace /ws/driver disponible
# 🌐 API disponible sur http://0.0.0.0:3000/api
```

### Étape 2 : Tester la Connexion avec le Script de Vérification

#### Option A : Script Bash

```bash
./verifier-connexion-backend-driver.sh
```

Ce script vérifie :
- ✅ Health check du backend
- ✅ Authentification driver
- ✅ Routes driver disponibles
- ✅ Configuration iOS
- ✅ Fichiers backend

#### Option B : Script Node.js

```bash
cd backend
node test-driver-connection.js
```

Ce script teste :
- ✅ Health check
- ✅ Authentification driver
- ✅ Profil driver
- ✅ Mise à jour position
- ✅ Connexion WebSocket
- ✅ Protection des routes
- ✅ Vérification du rôle

### Étape 3 : Tester depuis l'Application iOS

#### 3.1 Test d'Authentification
1. Ouvrir l'application driver iOS
2. Se connecter avec un numéro de téléphone (rôle: driver)
3. Vérifier que l'authentification fonctionne
4. Vérifier les logs du backend pour voir la requête

#### 3.2 Test de Mise à Jour de Position
1. Se connecter en tant que driver
2. Activer la géolocalisation
3. Vérifier que la position est mise à jour dans la base de données
4. Vérifier les logs du backend

#### 3.3 Test de Connexion WebSocket
1. Se connecter à l'application driver
2. Vérifier que la connexion WebSocket est établie
3. Vérifier les logs du backend (devrait voir "Driver connecté")
4. Créer une course depuis l'app client
5. Vérifier que le driver reçoit la notification

---

## 📱 Configuration iOS

### Fichier Info.plist

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api</string>
<key>WS_BASE_URL</key>
<string>https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app</string>
```

### ConfigurationService.swift

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

var driverSocketNamespace: String {
    return "/ws/driver"
}
```

---

## 🔐 Authentification

### JWT Token

1. **Authentification** : `POST /api/auth/signin`
   ```json
   {
     "phoneNumber": "+243900000001",
     "role": "driver"
   }
   ```

2. **Réponse** :
   ```json
   {
     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
     "user": {
       "id": 1,
       "name": "Driver Name",
       "phoneNumber": "+243900000001",
       "role": "driver"
     }
   }
   ```

3. **Utilisation du Token** :
   - Header : `Authorization: Bearer <token>`
   - WebSocket : `?token=<token>` dans l'URL

### Vérification du Rôle

Toutes les routes driver vérifient que l'utilisateur a le rôle `driver` :
```javascript
if (req.user.role !== 'driver') {
  return res.status(403).json({ 
    error: 'Seuls les conducteurs peuvent accéder à cette route' 
  });
}
```

---

## 🧪 Tests à Effectuer

### Test 1 : Vérifier que le Backend est Démarré

```bash
curl http://localhost:3000/health

# Réponse attendue :
# {
#   "status": "OK",
#   "database": "connected",
#   "timestamp": "2025-01-XX..."
# }
```

### Test 2 : Authentification Driver

```bash
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000001",
    "role": "driver"
  }'

# Réponse attendue :
# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {
#     "id": 1,
#     "name": "Driver Name",
#     "phoneNumber": "+243900000001",
#     "role": "driver"
#   }
# }
```

### Test 3 : Mise à Jour de Position

```bash
curl -X POST http://localhost:3000/api/driver/location/update \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3136,
    "address": "Kinshasa, RD Congo"
  }'

# Réponse attendue :
# {
#   "success": true,
#   "location": {
#     "latitude": -4.3276,
#     "longitude": 15.3136,
#     "address": "Kinshasa, RD Congo"
#   }
# }
```

### Test 4 : Connexion WebSocket

```javascript
const io = require('socket.io-client');
const socket = io('http://localhost:3000/ws/driver', {
  query: {
    token: '<token>'
  }
});

socket.on('connect', () => {
  console.log('✅ Connecté au namespace /ws/driver');
});

socket.on('ride:new', (data) => {
  console.log('Nouvelle course:', data);
});
```

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
   - Mode PRODUCTION : Vérifier l'URL de production dans Info.plist

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
   const driverNamespace = io.of('/ws/driver');
   ```

2. **Vérifier l'URL WebSocket**
   ```swift
   // Dans l'application iOS
   let socketURL = config.buildSocketURL(namespace: "/ws/driver")
   print("Socket URL: \(socketURL)")
   ```

3. **Vérifier le token JWT**
   - Le token doit être passé en paramètre : `?token=...`
   - Le token doit être valide
   - Le token doit correspondre à un utilisateur avec le rôle `driver`

4. **Vérifier CORS**
   ```javascript
   // Dans server.postgres.js
   // Vérifier que CORS est configuré pour WebSocket
   const io = socketIo(server, {
     cors: {
       origin: process.env.CORS_ORIGIN || ["http://localhost:3001"],
       methods: ["GET", "POST"]
     }
   });
   ```

---

### Problème 4 : Les routes driver ne sont pas accessibles

#### Symptômes
- Erreur 404 (Not Found)
- Erreur 403 (Forbidden) même avec un token valide
- Routes non trouvées

#### Solutions
1. **Vérifier que les routes sont enregistrées**
   ```javascript
   // Dans server.postgres.js
   app.use('/api/driver', require('./routes.postgres/driver'));
   ```

2. **Vérifier que le fichier de routes existe**
   ```bash
   ls backend/routes.postgres/driver.js
   ```

3. **Vérifier le rôle de l'utilisateur**
   - L'utilisateur doit avoir le rôle `driver`
   - Vérifier dans la base de données : `SELECT role FROM users WHERE id = ?`

---

## 📊 Checklist de Vérification

### Configuration
- [ ] Backend démarré et accessible
- [ ] URL du backend correcte dans l'application
- [ ] Variables d'environnement configurées
- [ ] CORS configuré correctement
- [ ] Base de données PostgreSQL connectée

### Authentification
- [ ] Endpoint `/api/auth/signin` fonctionne
- [ ] Token JWT généré correctement
- [ ] Token JWT stocké dans UserDefaults
- [ ] Token JWT envoyé dans les requêtes
- [ ] Vérification du rôle `driver` fonctionne

### API REST
- [ ] Endpoint `/api/driver/location/update` fonctionne
- [ ] Endpoint `/api/driver/accept_ride/:rideId` fonctionne
- [ ] Endpoint `/api/driver/reject_ride/:rideId` fonctionne
- [ ] Endpoint `/api/driver/complete_ride/:rideId` fonctionne

### WebSocket
- [ ] Connexion WebSocket établie
- [ ] Namespace `/ws/driver` accessible
- [ ] Authentification WebSocket fonctionne
- [ ] Réception des événements `ride:new`
- [ ] Réception des événements `ride:update`
- [ ] Mises à jour en temps réel fonctionnent

### Application iOS
- [ ] ConfigurationService.swift présent
- [ ] Info.plist configuré avec les URLs
- [ ] Namespace WebSocket configuré
- [ ] Authentification fonctionne
- [ ] Mise à jour position fonctionne
- [ ] Connexion WebSocket fonctionne

---

## 🧪 Scripts de Test Disponibles

### 1. Script Bash de Vérification

```bash
./verifier-connexion-backend-driver.sh
```

**Fonctionnalités** :
- ✅ Vérification health check
- ✅ Test authentification driver
- ✅ Vérification routes disponibles
- ✅ Vérification configuration iOS
- ✅ Vérification fichiers backend
- ✅ Génération rapport détaillé

### 2. Script Node.js de Test

```bash
cd backend
node test-driver-connection.js
```

**Fonctionnalités** :
- ✅ Test health check
- ✅ Test authentification
- ✅ Test profil driver
- ✅ Test mise à jour position
- ✅ Test connexion WebSocket
- ✅ Test protection des routes
- ✅ Test vérification du rôle

### 3. Script de Test Client-Driver

```bash
cd backend
node test-client-driver-communication.js
```

**Fonctionnalités** :
- ✅ Simulation client qui crée une course
- ✅ Simulation driver qui reçoit la notification
- ✅ Test acceptation de course
- ✅ Test communication WebSocket

---

## 📝 Notes

### Mode Développement
- L'application utilise `http://localhost:3000/api` en mode DEBUG
- Le backend doit être démarré localement
- Le simulateur iOS peut accéder à `localhost` sur la machine hôte

### Mode Production
- L'application utilise `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api` en mode PRODUCTION
- Le backend doit être déployé et accessible
- L'URL peut être personnalisée via UserDefaults

### Configuration Personnalisée
- L'URL du backend peut être modifiée via UserDefaults
- Clé : `api_base_url`
- Clé : `socket_base_url`

---

## 🚀 Prochaines Étapes

1. **Tester la connexion WebSocket depuis l'app iOS**
   - Vérifier que la connexion s'établit correctement
   - Vérifier la réception des événements

2. **Tester l'acceptation de course depuis l'app driver**
   - Créer une course depuis l'app client
   - Vérifier que le driver reçoit la notification
   - Vérifier que l'acceptation fonctionne

3. **Vérifier les notifications en temps réel**
   - Vérifier que les mises à jour de position sont diffusées
   - Vérifier que les changements de statut sont notifiés

4. **Tester le flux complet**
   - Création de course
   - Acceptation par le driver
   - Mise à jour de position
   - Complétion de course

---

**Date de création** : $(date)
**Statut** : ✅ Guide de vérification créé

