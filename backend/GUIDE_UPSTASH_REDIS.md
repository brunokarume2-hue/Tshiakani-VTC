# 🚀 Guide de Configuration Upstash Redis - Tshiakani VTC

## 📋 Introduction

Upstash Redis est une alternative **GRATUITE** à Redis Memorystore. Il offre :
- **10 000 commandes/jour** gratuitement
- **256 MB de stockage** gratuitement
- **Hébergé** (pas besoin d'installer/maintenir Redis)
- **Compatible Redis** (pas de changement de code)

## ✅ Avantages d'Upstash Redis

1. **Gratuit** : 0 $/mois au lieu de 30 $/mois (Redis Memorystore)
2. **Suffisant** : 10 000 commandes/jour suffisent pour < 3000 clients
3. **Compatible** : Compatible avec Redis (pas de changement de code)
4. **Hébergé** : Pas besoin d'installer/maintenir Redis
5. **Scalable** : Peut être mis à niveau plus tard si nécessaire

## 🔧 Étape 1 : Créer un Compte Upstash

1. Aller sur [https://upstash.com/](https://upstash.com/)
2. Cliquer sur **"Sign Up"** ou **"Get Started"**
3. Créer un compte (email, Google, ou GitHub)
4. Vérifier votre email si nécessaire

## 🗄️ Étape 2 : Créer une Base de Données Redis

1. Une fois connecté, aller dans le **Dashboard**
2. Cliquer sur **"Create Database"** ou **"New Database"**
3. Choisir **"Redis"** comme type de base de données
4. Sélectionner le **tier gratuit** (Free)
5. Choisir une **région** proche de vos utilisateurs (ex: `us-east-1`, `eu-west-1`)
6. Donner un nom à la base de données (ex: `tshiakani-redis`)
7. Cliquer sur **"Create"**

## 📝 Étape 3 : Récupérer l'URL de Connexion

1. Une fois la base de données créée, aller dans les **détails**
2. Trouver la section **"Redis URL"** ou **"REST API"**
3. **Important** : Utilisez l'**URL Redis** (pas l'URL REST) pour le package `redis` standard
4. Récupérer l'**URL de connexion Redis** qui ressemble à :
   - `redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379`
   - ou `rediss://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379`
5. **Copier l'URL complète** (elle contient le token d'authentification)

### Format de l'URL Upstash Redis

Upstash Redis fournit deux types d'URLs :
1. **Redis URL** (pour le package `redis` standard) : `redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379`
2. **REST URL** (pour le package `@upstash/redis`) : `https://YOUR_ENDPOINT.upstash.io`

**Note** : Pour notre backend, nous utilisons le package `redis` standard, donc nous avons besoin de l'**URL Redis** (format `redis://` ou `rediss://`).

**Note TLS** : Upstash Redis utilise TLS par défaut. L'URL peut être `redis://` (sans TLS explicite) ou `rediss://` (avec TLS explicite). Le client Redis détecte automatiquement TLS depuis l'URL.

## ⚙️ Étape 4 : Configurer les Variables d'Environnement

### Pour le Développement Local

1. Éditer le fichier `backend/.env`
2. Ajouter la variable `REDIS_URL` :

```env
REDIS_URL=redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379
```

**Important** : Remplacez `YOUR_TOKEN` et `YOUR_ENDPOINT` par les valeurs réelles de votre base de données Upstash.

### Pour la Production (Cloud Run)

1. Éditer le fichier `backend/scripts/deploy-cloud-run.sh`
2. Configurer la variable `REDIS_URL` :

```bash
REDIS_URL="redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379"
```

**Ou** utiliser Secret Manager (recommandé pour la production) :

```bash
# Créer un secret pour REDIS_URL
gcloud secrets create redis-url \
  --project=tshiakani-vtc-99cea \
  --data-file=- <<< "redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379"

# Donner accès au secret au service Cloud Run
gcloud secrets add-iam-policy-binding redis-url \
  --project=tshiakani-vtc-99cea \
  --member="serviceAccount:tshiakani-driver-backend@tshiakani-vtc-99cea.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## 🧪 Étape 5 : Tester la Connexion

### Test Local

```bash
cd backend
node test-redis-connection.js
```

Vous devriez voir :
```
✅ Redis connecté avec succès (Upstash)
✅ Test de connexion Redis: OK
```

### Test depuis le Backend

```bash
cd backend
node -e "
require('dotenv').config();
const { getRedisService } = require('./services/RedisService');
const redisService = getRedisService();
redisService.connect()
  .then(() => {
    console.log('✅ Redis connecté avec succès');
    return redisService.testConnection();
  })
  .then((result) => {
    console.log('✅ Test de connexion:', result ? 'OK' : 'ÉCHEC');
    process.exit(result ? 0 : 1);
  })
  .catch((error) => {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  });
"
```

## 🔍 Vérification

### Vérifier les Logs

Dans les logs du serveur backend, vous devriez voir :
```
Using Upstash Redis (REDIS_URL)
Redis client connecting...
Redis client ready
Redis connected successfully (Upstash)
```

### Vérifier le Stockage

```bash
# Tester le stockage d'une valeur
node -e "
require('dotenv').config();
const { getRedisService } = require('./services/RedisService');
const redisService = getRedisService();
redisService.connect()
  .then(() => {
    return redisService.client.set('test:key', 'test:value', { EX: 10 });
  })
  .then(() => {
    return redisService.client.get('test:key');
  })
  .then((value) => {
    console.log('✅ Valeur stockée:', value);
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Erreur:', error.message);
    process.exit(1);
  });
"
```

## 📊 Limites du Tier Gratuit

- **Commandes** : 10 000 commandes/jour
- **Stockage** : 256 MB
- **Connexions** : Illimitées
- **Régions** : 1 région gratuite

### Estimation pour Votre Projet

Pour < 3000 clients :
- **Codes OTP** : ~3 000 commandes/jour (1 OTP par client/jour)
- **Inscriptions** : ~100 commandes/jour (nouvelles inscriptions)
- **Connexions** : ~500 commandes/jour (connexions)
- **Rate limiting** : ~500 commandes/jour
- **Positions conducteurs** : ~2 000 commandes/jour (mises à jour)
- **Total** : ~6 100 commandes/jour (bien en dessous de 10 000)

## ⚠️ Dépannage

### Erreur: "Connection refused"

**Problème** : L'URL de connexion est incorrecte.

**Solution** :
1. Vérifier que `REDIS_URL` est correctement configuré
2. Vérifier que l'URL contient le token d'authentification
3. Vérifier que l'endpoint Upstash est correct

### Erreur: "Authentication failed"

**Problème** : Le token d'authentification est incorrect.

**Solution** :
1. Vérifier que le token dans `REDIS_URL` est correct
2. Récupérer un nouveau token depuis le dashboard Upstash
3. Mettre à jour `REDIS_URL` avec le nouveau token

### Erreur: "TLS handshake failed"

**Problème** : Upstash Redis utilise TLS par défaut.

**Solution** :
1. Utiliser `rediss://` (avec deux 's') au lieu de `redis://`
2. Ou utiliser l'URL REST API d'Upstash (si disponible)

### Erreur: "Rate limit exceeded"

**Problème** : Vous avez dépassé la limite de 10 000 commandes/jour.

**Solution** :
1. Surveiller l'utilisation dans le dashboard Upstash
2. Optimiser les commandes Redis (réduire les opérations inutiles)
3. Mettre à niveau vers un plan payant si nécessaire

## 📝 Migration depuis Redis Memorystore

Si vous utilisez actuellement Redis Memorystore :

1. **Créer une base de données Upstash Redis** (voir Étape 2)
2. **Configurer REDIS_URL** dans `.env` et `deploy-cloud-run.sh`
3. **Tester la connexion** (voir Étape 5)
4. **Déployer le backend** avec Upstash Redis
5. **Vérifier les logs** pour confirmer la connexion
6. **Désactiver Redis Memorystore** (économie de 30 $/mois)

## 🚀 Déploiement sur Cloud Run

### Méthode 1 : Variables d'Environnement Directes

1. Éditer `backend/scripts/deploy-cloud-run.sh`
2. Configurer `REDIS_URL` :

```bash
REDIS_URL="redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379"
```

3. Déployer :

```bash
cd backend
./scripts/deploy-cloud-run.sh
```

### Méthode 2 : Secret Manager (Recommandé)

1. Créer un secret pour `REDIS_URL` :

```bash
gcloud secrets create redis-url \
  --project=tshiakani-vtc-99cea \
  --data-file=- <<< "redis://default:YOUR_TOKEN@YOUR_ENDPOINT.upstash.io:6379"
```

2. Donner accès au secret :

```bash
gcloud secrets add-iam-policy-binding redis-url \
  --project=tshiakani-vtc-99cea \
  --member="serviceAccount:tshiakani-driver-backend@tshiakani-vtc-99cea.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

3. Modifier le script de déploiement pour utiliser le secret :

```bash
gcloud run deploy tshiakani-driver-backend \
  --set-secrets "REDIS_URL=redis-url:latest" \
  ...
```

## ✅ Checklist

- [ ] Compte Upstash créé
- [ ] Base de données Redis créée (tier gratuit)
- [ ] URL de connexion récupérée
- [ ] Variable `REDIS_URL` configurée dans `.env`
- [ ] Variable `REDIS_URL` configurée dans `deploy-cloud-run.sh`
- [ ] Test de connexion réussi localement
- [ ] Backend déployé avec Upstash Redis
- [ ] Logs vérifiés pour confirmer la connexion
- [ ] Test d'inscription avec OTP réussi
- [ ] Test de connexion avec OTP réussi

## 📚 Documentation

- [Upstash Documentation](https://docs.upstash.com/redis)
- [Upstash Pricing](https://upstash.com/pricing)
- [Upstash Dashboard](https://console.upstash.com/)

## 🎉 Résumé

Upstash Redis est une excellente alternative **GRATUITE** à Redis Memorystore pour votre projet. Avec 10 000 commandes/jour gratuites, vous pouvez facilement supporter < 3000 clients sans coûts supplémentaires.

**Économies** : 30 $/mois (Redis Memorystore) → 0 $/mois (Upstash Redis)

---

**Date** : 2025-11-12  
**Statut** : ✅ **GUIDE CRÉÉ**

