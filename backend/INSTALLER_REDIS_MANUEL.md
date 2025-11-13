# 📦 Installation Manuelle de Redis - Tshiakani VTC

## ⚠️ Installation Requise

Redis n'est pas encore installé sur votre machine. Voici les instructions pour l'installer manuellement.

## 🍎 Installation sur macOS

### Option 1 : Avec Homebrew (Recommandé)

1. **Installer Homebrew** (si pas déjà installé) :
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Installer Redis** :
   ```bash
   brew install redis
   ```

3. **Démarrer Redis** :
   ```bash
   brew services start redis
   ```

4. **Vérifier que Redis fonctionne** :
   ```bash
   redis-cli ping
   # Réponse attendue : PONG
   ```

### Option 2 : Avec MacPorts

1. **Installer MacPorts** (si pas déjà installé) :
   - Télécharger depuis : https://www.macports.org/install.php

2. **Installer Redis** :
   ```bash
   sudo port install redis
   ```

3. **Démarrer Redis** :
   ```bash
   sudo port load redis
   ```

### Option 3 : Avec Docker (Alternative)

1. **Installer Docker Desktop** :
   - Télécharger depuis : https://www.docker.com/products/docker-desktop

2. **Lancer Redis avec Docker** :
   ```bash
   docker run -d -p 6379:6379 --name redis redis:latest
   ```

3. **Vérifier que Redis fonctionne** :
   ```bash
   docker exec -it redis redis-cli ping
   # Réponse attendue : PONG
   ```

## 🐧 Installation sur Linux

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### CentOS/RHEL

```bash
sudo yum install redis
sudo systemctl start redis
sudo systemctl enable redis
```

### Fedora

```bash
sudo dnf install redis
sudo systemctl start redis
sudo systemctl enable redis
```

## ✅ Vérification de l'Installation

Après l'installation, vérifiez que Redis fonctionne :

```bash
# Vérifier que Redis est en cours d'exécution
redis-cli ping

# Réponse attendue : PONG
```

## 🔧 Configuration

Les variables Redis sont déjà configurées dans votre fichier `.env` :

```env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_CONNECT_TIMEOUT=10000
```

## 🧪 Test de Connexion

Après l'installation, testez la connexion Redis depuis le backend :

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

## 🚀 Démarrage du Serveur

Une fois Redis installé et démarré, démarrez le serveur backend :

```bash
cd backend
npm run dev
```

Dans les logs, vous devriez voir :
```
✅ Redis connecté avec succès
Redis client ready
```

## 🔍 Commandes Utiles

```bash
# Vérifier que Redis fonctionne
redis-cli ping

# Voir les clés Redis
redis-cli KEYS "*"

# Voir les codes OTP stockés
redis-cli KEYS "otp:*"

# Voir les inscriptions en attente
redis-cli KEYS "pending:register:*"

# Voir les connexions en attente
redis-cli KEYS "pending:login:*"

# Voir le rate limiting
redis-cli KEYS "otp:rate:*"

# Arrêter Redis (macOS avec Homebrew)
brew services stop redis

# Démarrer Redis (macOS avec Homebrew)
brew services start redis

# Voir les statistiques Redis
redis-cli INFO stats
```

## ⚠️ Dépannage

### Erreur: "Connection refused"

**Problème** : Redis n'est pas démarré.

**Solution** :
```bash
# macOS avec Homebrew
brew services start redis

# Linux
sudo systemctl start redis-server

# Docker
docker start redis
```

### Erreur: "Redis is not connected"

**Problème** : Le serveur backend n'arrive pas à se connecter à Redis.

**Solution** :
1. Vérifier que Redis est en cours d'exécution : `redis-cli ping`
2. Vérifier les variables d'environnement dans `.env`
3. Vérifier que le port Redis (6379) n'est pas bloqué par un firewall

### Erreur: "Command not found: redis-cli"

**Problème** : Redis n'est pas installé ou n'est pas dans le PATH.

**Solution** :
1. Installer Redis (voir les instructions ci-dessus)
2. Vérifier que Redis est dans le PATH : `which redis-cli`

## 📝 Notes

- **Mode dégradé** : Si Redis n'est pas disponible, le backend continue de fonctionner mais avec des limitations (utilise un fallback en mémoire)
- **Production** : Pour la production, utilisez Redis Memorystore sur GCP pour une meilleure disponibilité
- **Sécurité** : En production, configurez un mot de passe Redis

## ✅ Checklist

- [ ] Redis installé
- [ ] Redis démarré
- [ ] Test `redis-cli ping` réussi
- [ ] Variables Redis configurées dans `.env`
- [ ] Test de connexion depuis Node.js réussi
- [ ] Serveur backend démarre sans erreur Redis
- [ ] Logs montrent "Redis connecté avec succès"

---

**Une fois Redis installé, exécutez le script de test pour vérifier la connexion !**

