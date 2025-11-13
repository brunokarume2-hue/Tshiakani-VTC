# ✅ Guide de Configuration Redis - Tshiakani VTC

## 📋 État de la Configuration

### ✅ Configuration Complète

Redis est maintenant **entièrement configuré** dans le backend :

1. ✅ **Package installé** : `redis: ^4.6.12` dans `package.json`
2. ✅ **Variables d'environnement** : Configurées dans `ENV.example`
3. ✅ **Service Redis** : `RedisService.js` implémenté avec toutes les méthodes nécessaires
4. ✅ **Initialisation** : Redis est initialisé dans `server.postgres.js`
5. ✅ **Routes d'authentification** : Utilisent Redis pour stocker les données temporaires
6. ✅ **OTP Service** : Utilise Redis pour stocker les codes OTP
7. ✅ **Rate Limiting** : Utilise Redis pour limiter les tentatives OTP
8. ✅ **Support Upstash Redis** : Compatible avec Upstash Redis (gratuit)

## 🚀 Options de Configuration Redis

### Option 1 : Upstash Redis (RECOMMANDÉ - GRATUIT)

**Upstash Redis** est une alternative **GRATUITE** à Redis Memorystore :
- **10 000 commandes/jour** gratuitement
- **256 MB de stockage** gratuitement
- **Hébergé** (pas besoin d'installer/maintenir Redis)
- **Compatible Redis** (pas de changement de code)
- **Coût** : 0 $/mois

**Pour configurer Upstash Redis**, consultez le guide : [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)

### Option 2 : Redis Local (Développement)

**Redis Local** pour le développement local :
- **Gratuit** (installé localement)
- **Pas de limites** (sauf ressources système)
- **Coût** : 0 $/mois

### Option 3 : Redis Memorystore (Production GCP)

**Redis Memorystore** pour la production sur GCP :
- **Hébergé** par Google Cloud
- **Haute disponibilité** (99,9%)
- **Coût** : ~30 $/mois (tier basic, 1 GB)

## 🔧 Configuration Requise

### 1. Choisir une Option Redis

**Pour un MVP avec < 3000 clients** : **Upstash Redis (GRATUIT)** est recommandé.

**Pour le développement local** : **Redis Local** est recommandé.

**Pour la production GCP** : **Redis Memorystore** ou **Upstash Redis** (selon le budget).

### 2. Configurer Upstash Redis (Recommandé)

Consultez le guide complet : [GUIDE_UPSTASH_REDIS.md](GUIDE_UPSTASH_REDIS.md)

**Résumé** :
1. Créer un compte sur [https://upstash.com/](https://upstash.com/)
2. Créer une base de données Redis (tier gratuit)
3. Récupérer l'URL de connexion (REDIS_URL)
4. Configurer `REDIS_URL` dans `.env` et `deploy-cloud-run.sh`

### 3. Installer Redis Local (Alternative)

#### Sur macOS (Homebrew)
```bash
brew install redis
brew services start redis
```

#### Sur Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

#### Sur Windows
Télécharger Redis depuis : https://github.com/microsoftarchive/redis/releases
Ou utiliser WSL (Windows Subsystem for Linux)

#### Vérifier que Redis fonctionne
```bash
redis-cli ping
# Réponse attendue : PONG
```

### 4. Configurer les Variables d'Environnement

Créez un fichier `.env` dans le dossier `backend` (s'il n'existe pas) :

```bash
cd backend
cp ENV.example .env
```

Éditez le fichier `.env` et configurez les variables Redis :

#### Option 1 : Upstash Redis (Recommandé)

```env
# ===========================================
# Redis (Upstash Redis - GRATUIT)
# ===========================================
# URL de connexion Upstash Redis
REDIS_URL=redis://default:your_token@endpoint.upstash.io:6379

# Timeout de connexion (millisecondes)
REDIS_CONNECT_TIMEOUT=10000
```

#### Option 2 : Redis Local (Développement)

```env
# ===========================================
# Redis (Local)
# ===========================================
# Host Redis (localhost pour développement)
REDIS_HOST=localhost

# Port Redis (6379 par défaut)
REDIS_PORT=6379

# Mot de passe Redis (optionnel, laisser vide si pas de mot de passe)
REDIS_PASSWORD=

# Timeout de connexion (millisecondes)
REDIS_CONNECT_TIMEOUT=10000
```

#### Option 3 : Redis Memorystore (Production GCP)

```env
# ===========================================
# Redis (Memorystore)
# ===========================================
# Host Redis (adresse IP du Memorystore)
REDIS_HOST=10.x.x.x  # IP de votre instance Memorystore

# Port Redis (6379 par défaut)
REDIS_PORT=6379

# Mot de passe Redis (optionnel, selon votre configuration Memorystore)
REDIS_PASSWORD=

# Timeout de connexion (millisecondes)
REDIS_CONNECT_TIMEOUT=10000
```

**Note** : Si `REDIS_URL` est défini, il sera utilisé en priorité (Upstash Redis). Sinon, `REDIS_HOST` sera utilisé (Redis local ou Memorystore).

## 🧪 Vérification de la Configuration

### 1. Vérifier que Redis fonctionne

```bash
# Vérifier que Redis est en cours d'exécution
redis-cli ping

# Réponse attendue : PONG
```

### 2. Vérifier les Variables d'Environnement

```bash
cd backend
node -e "require('dotenv').config(); console.log('REDIS_HOST:', process.env.REDIS_HOST); console.log('REDIS_PORT:', process.env.REDIS_PORT);"
```

### 3. Tester la Connexion Redis depuis le Backend

Créez un script de test :

```bash
cd backend
node -e "
require('dotenv').config();
const { getRedisService } = require('./services/RedisService');
const redisService = getRedisService();
redisService.connect()
  .then(() => {
    console.log('✅ Redis connecté avec succès');
    redisService.testConnection()
      .then((result) => {
        console.log('✅ Test de connexion Redis:', result ? 'OK' : 'ÉCHEC');
        process.exit(0);
      });
  })
  .catch((error) => {
    console.error('❌ Erreur de connexion Redis:', error.message);
    process.exit(1);
  });
"
```

### 4. Démarrer le Serveur et Vérifier les Logs

```bash
cd backend
npm run dev
```

Dans les logs, vous devriez voir :
```
✅ Redis connecté avec succès
Redis client ready
```

## 📊 Utilisation de Redis dans le Backend

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

### 5. Positions des Conducteurs

- **Clé** : `driver:{driverId}`
- **Format** : Hash Redis avec `lat`, `lon`, `status`, `last_update`, etc.
- **TTL** : 300 secondes (5 minutes)
- **Service** : `RedisService.js`

## 🔍 Commandes Redis Utiles

### Se connecter à Redis
```bash
redis-cli -h localhost -p 6379
```

### Vérifier les clés OTP
```bash
redis-cli KEYS "otp:*"
```

### Vérifier une clé OTP spécifique
```bash
redis-cli HGETALL "otp:+243900000000"
```

### Vérifier les inscriptions en attente
```bash
redis-cli KEYS "pending:register:*"
```

### Vérifier les connexions en attente
```bash
redis-cli KEYS "pending:login:*"
```

### Vérifier le rate limiting
```bash
redis-cli KEYS "otp:rate:*"
```

### Vérifier les positions des conducteurs
```bash
redis-cli KEYS "driver:*"
```

### Vérifier le TTL d'une clé
```bash
redis-cli TTL "otp:+243900000000"
```

### Supprimer une clé
```bash
redis-cli DEL "otp:+243900000000"
```

### Statistiques Redis
```bash
redis-cli INFO stats
redis-cli INFO memory
```

## ⚠️ Dépannage

### Erreur: "Connection refused"

**Problème** : Redis n'est pas démarré ou n'écoute pas sur le port configuré.

**Solution** :
```bash
# Vérifier que Redis est en cours d'exécution
redis-cli ping

# Si Redis n'est pas démarré, le démarrer
brew services start redis  # macOS
sudo systemctl start redis-server  # Linux
```

### Erreur: "Redis is not connected"

**Problème** : Le serveur backend n'arrive pas à se connecter à Redis.

**Solution** :
1. Vérifier que Redis est en cours d'exécution
2. Vérifier les variables d'environnement (`REDIS_HOST`, `REDIS_PORT`)
3. Vérifier que le port Redis n'est pas bloqué par un firewall
4. Vérifier les logs du serveur backend

### Erreur: "Service temporairement indisponible"

**Problème** : Redis n'est pas disponible, mais le serveur backend continue de fonctionner.

**Solution** :
1. Vérifier que Redis est en cours d'exécution
2. Vérifier les variables d'environnement
3. Redémarrer Redis si nécessaire
4. Redémarrer le serveur backend

### Mode Dégradé

Si Redis n'est pas disponible, le backend continue de fonctionner mais :
- ❌ Les codes OTP ne peuvent pas être stockés (utilisation d'un fallback en mémoire)
- ❌ Les inscriptions/connexions en attente ne peuvent pas être stockées
- ❌ Le rate limiting ne fonctionne pas
- ❌ Les positions des conducteurs ne sont pas mises en cache

**Important** : Pour une utilisation en production, Redis est **requis**.

## ✅ Checklist de Configuration

- [ ] Redis installé et démarré
- [ ] Variables d'environnement Redis configurées dans `.env`
- [ ] Test de connexion Redis réussi (`redis-cli ping`)
- [ ] Serveur backend démarre sans erreur Redis
- [ ] Logs montrent "Redis connecté avec succès"
- [ ] Test d'inscription avec OTP fonctionne
- [ ] Test de connexion avec OTP fonctionne
- [ ] Codes OTP stockés dans Redis (vérifier avec `redis-cli`)

## 📝 Notes Importantes

1. **Redis est requis** pour le fonctionnement complet de l'authentification OTP
2. **Mode dégradé** : Si Redis n'est pas disponible, le backend continue de fonctionner mais avec des limitations
3. **Production** : Pour la production, utilisez Redis Memorystore sur GCP pour une meilleure disponibilité
4. **Sécurité** : Configurez un mot de passe Redis en production
5. **Backup** : Les données Redis sont temporaires (TTL), pas besoin de backup

## 🚀 Prochaines Étapes

1. ✅ Redis est configuré dans le code
2. ⏳ Installer Redis sur votre machine de développement
3. ⏳ Configurer les variables d'environnement dans `.env`
4. ⏳ Tester la connexion Redis
5. ⏳ Tester l'inscription/connexion avec OTP
6. ⏳ Configurer Redis Memorystore pour la production (GCP)

---

**Date** : 2025-01-15  
**Statut** : ✅ **CONFIGURATION COMPLÈTE**

