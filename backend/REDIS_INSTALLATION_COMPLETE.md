# ✅ Installation Redis Complète - Tshiakani VTC

## 🎉 Statut : INSTALLATION RÉUSSIE

Redis a été installé et configuré avec succès !

## ✅ Ce qui a été fait

### 1. Installation de Redis

- ✅ **Redis installé** : Version 8.2.3 via Homebrew
- ✅ **Redis démarré** : Service démarré avec `brew services start redis`
- ✅ **Redis fonctionne** : Test `redis-cli ping` retourne `PONG`

### 2. Configuration

- ✅ **Variables Redis** : Configurées dans `backend/.env`
  ```env
  REDIS_HOST=localhost
  REDIS_PORT=6379
  REDIS_PASSWORD=
  REDIS_CONNECT_TIMEOUT=10000
  ```

### 3. Tests de Connexion

- ✅ **Test de connexion** : Réussi
- ✅ **Test de stockage** : Réussi
- ✅ **Test des méthodes OTP** : Réussi
  - `storePendingRegistration` : OK
  - `getPendingRegistration` : OK
  - `deletePendingRegistration` : OK
- ✅ **Test du rate limiting** : Réussi
  - `checkOTPRateLimit` : OK
  - `resetOTPRateLimit` : OK

## 🔍 Vérification

### Vérifier que Redis fonctionne

```bash
# Vérifier que Redis est en cours d'exécution
redis-cli ping
# Réponse attendue : PONG

# Vérifier le statut du service Redis
brew services list | grep redis
# Réponse attendue : redis started
```

### Tester la connexion depuis Node.js

```bash
cd backend
node test-redis-connection.js
```

Vous devriez voir :
```
✅ Redis connecté avec succès
✅ Test de connexion Redis: OK
🎉 Tous les tests sont réussis !
```

## 🚀 Démarrage du Serveur

Démarrez le serveur backend :

```bash
cd backend
npm run dev
```

Dans les logs, vous devriez voir :
```
✅ Redis connecté avec succès
Redis client ready
```

## 📊 Utilisation de Redis

### 1. Stockage des Codes OTP

- **Clé** : `otp:{phoneNumber}`
- **Format** : Hash Redis avec `code`, `attempts`, `createdAt`
- **TTL** : 600 secondes (10 minutes)
- **Service** : `OTPService.js`

### 2. Stockage des Inscriptions en Attente

- **Clé** : `pending:register:{phoneNumber}`
- **Format** : Hash Redis avec `name`, `phoneNumber`, `role`, `createdAt`
- **TTL** : 600 secondes (10 minutes)
- **Service** : `RedisService.js`

### 3. Stockage des Connexions en Attente

- **Clé** : `pending:login:{phoneNumber}`
- **Format** : Hash Redis avec `phoneNumber`, `createdAt`
- **TTL** : 600 secondes (10 minutes)
- **Service** : `RedisService.js`

### 4. Rate Limiting pour OTP

- **Clé** : `otp:rate:{phoneNumber}`
- **Format** : Compteur Redis
- **TTL** : 3600 secondes (1 heure)
- **Limite** : 3 tentatives par heure
- **Service** : `RedisService.js`

## 🔍 Commandes Redis Utiles

```bash
# Vérifier que Redis fonctionne
redis-cli ping

# Voir les clés Redis
redis-cli KEYS "*"

# Voir les codes OTP stockés
redis-cli KEYS "otp:*"

# Voir une clé OTP spécifique
redis-cli HGETALL "otp:+243900000000"

# Voir les inscriptions en attente
redis-cli KEYS "pending:register:*"

# Voir les connexions en attente
redis-cli KEYS "pending:login:*"

# Voir le rate limiting
redis-cli KEYS "otp:rate:*"

# Vérifier le TTL d'une clé
redis-cli TTL "otp:+243900000000"

# Supprimer une clé
redis-cli DEL "otp:+243900000000"

# Statistiques Redis
redis-cli INFO stats
redis-cli INFO memory
```

## 🎯 Test de l'Authentification OTP

### Test d'Inscription

```bash
# 1. Demander un code OTP
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "name": "Test User",
    "role": "client"
  }'

# Réponse attendue :
# {
#   "success": true,
#   "message": "Code de vérification envoyé par SMS/WhatsApp",
#   "phoneNumber": "+243900000000",
#   "remainingAttempts": 2
# }
```

### Vérifier dans Redis

```bash
# Voir le code OTP stocké
redis-cli HGETALL "otp:+243900000000"

# Voir les données d'inscription en attente
redis-cli HGETALL "pending:register:+243900000000"
```

### Test de Vérification OTP

```bash
# 2. Vérifier le code OTP (remplacez CODE par le code reçu)
curl -X POST http://localhost:3000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "code": "123456",
    "type": "register"
  }'

# Réponse attendue :
# {
#   "success": true,
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": {
#     "id": 1,
#     "name": "Test User",
#     "phoneNumber": "243900000000",
#     "role": "client",
#     "isVerified": true
#   }
# }
```

## 🔧 Gestion du Service Redis

### Démarrer Redis

```bash
brew services start redis
```

### Arrêter Redis

```bash
brew services stop redis
```

### Redémarrer Redis

```bash
brew services restart redis
```

### Vérifier le statut

```bash
brew services list | grep redis
```

## ⚠️ Dépannage

### Erreur: "Connection refused"

**Problème** : Redis n'est pas démarré.

**Solution** :
```bash
brew services start redis
```

### Erreur: "Redis is not connected"

**Problème** : Le serveur backend n'arrive pas à se connecter à Redis.

**Solution** :
1. Vérifier que Redis est en cours d'exécution : `redis-cli ping`
2. Vérifier les variables d'environnement dans `.env`
3. Vérifier que le port Redis (6379) n'est pas bloqué par un firewall

### Erreur: "Command not found: redis-cli"

**Problème** : `redis-cli` n'est pas dans le PATH.

**Solution** :
```bash
# Utiliser le chemin complet
/opt/homebrew/bin/redis-cli ping

# Ou ajouter au PATH
export PATH="/opt/homebrew/bin:$PATH"
```

## ✅ Checklist

- [x] Redis installé (version 8.2.3)
- [x] Redis démarré
- [x] Test `redis-cli ping` réussi
- [x] Variables Redis configurées dans `.env`
- [x] Test de connexion depuis Node.js réussi
- [x] Test des méthodes OTP réussi
- [x] Test du rate limiting réussi
- [ ] Serveur backend démarré avec Redis
- [ ] Test d'inscription avec OTP réussi
- [ ] Test de connexion avec OTP réussi

## 📝 Prochaines Étapes

1. ✅ Redis installé et configuré
2. ⏳ Démarrer le serveur backend : `npm run dev`
3. ⏳ Tester l'inscription avec OTP
4. ⏳ Tester la connexion avec OTP
5. ⏳ Vérifier les logs pour confirmer la connexion Redis

## 🎉 Résumé

Redis est maintenant **entièrement installé et configuré** ! 

- ✅ Redis installé et démarré
- ✅ Variables Redis configurées dans `.env`
- ✅ Tests de connexion réussis
- ✅ Méthodes OTP testées et fonctionnelles
- ✅ Rate limiting testé et fonctionnel

**Le système d'authentification OTP est maintenant prêt à être utilisé !**

---

**Date** : 2025-11-12  
**Statut** : ✅ **INSTALLATION ET CONFIGURATION COMPLÈTES**

