# 🔍 Vérification Backend Cloud Run

## ⚠️ Problème Identifié

Le backend est accessible (health check OK), mais la route `/api/auth/signin` retourne une erreur 404.

**Erreur**: `Cannot POST /api/auth/signin`

---

## 🔍 Diagnostic

### 1. Health Check ✅

```bash
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
```

**Résultat**: ✅ Backend accessible et fonctionnel

### 2. Route Auth ❌

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber": "+243900000001", "role": "client"}'
```

**Résultat**: ❌ `Cannot POST /api/auth/signin`

---

## 🔧 Causes Possibles

### 1. Backend Déployé avec une Configuration Différente

Le backend déployé sur Cloud Run pourrait :
- Utiliser un fichier serveur différent (`server.js` au lieu de `server.postgres.js`)
- Avoir des routes montées différemment
- Ne pas avoir les routes auth montées

### 2. Problème de Déploiement

Le déploiement pourrait :
- Ne pas inclure tous les fichiers nécessaires
- Avoir une configuration différente
- Utiliser une ancienne version du code

### 3. Configuration des Routes

Les routes pourraient être :
- Montées sous un chemin différent
- Non montées du tout
- Montées mais avec un problème de middleware

---

## ✅ Solutions

### Solution 1: Vérifier la Configuration du Backend Déployé

```bash
# Vérifier les logs du backend
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 100

# Vérifier les variables d'environnement
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"
```

### Solution 2: Vérifier le Fichier Serveur Utilisé

Vérifier quel fichier serveur est utilisé dans le déploiement :

```bash
# Vérifier le Dockerfile
cat backend/Dockerfile

# Vérifier package.json
cat backend/package.json | grep "start\|main"
```

### Solution 3: Redéployer le Backend

Si le backend n'utilise pas `server.postgres.js`, redéployer avec la bonne configuration :

```bash
cd backend
./scripts/deploy-cloud-run.sh
```

### Solution 4: Vérifier les Routes Disponibles

Tester d'autres routes pour voir lesquelles fonctionnent :

```bash
# Tester différentes routes
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/rides
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/client
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/driver
```

---

## 🎯 Actions Immédiates

### Étape 1: Vérifier les Logs du Backend

```bash
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 50
```

**Chercher**:
- Messages de démarrage du serveur
- Routes montées
- Erreurs de connexion à la base de données
- Erreurs de configuration

### Étape 2: Vérifier le Fichier Serveur

```bash
# Vérifier package.json
cat backend/package.json | grep -A 5 "scripts"

# Vérifier Dockerfile
cat backend/Dockerfile | grep -A 5 "CMD\|ENTRYPOINT"
```

### Étape 3: Vérifier la Configuration

```bash
# Vérifier server.postgres.js
grep -n "app.use('/api/auth" backend/server.postgres.js

# Vérifier que les routes sont montées
grep -n "require('./routes.postgres/auth')" backend/server.postgres.js
```

### Étape 4: Tester Autres Routes

```bash
# Tester la route health (devrait fonctionner)
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health

# Tester d'autres routes
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/rides/estimate-price
```

---

## 🔍 Vérifications Détaillées

### Vérification 1: Fichier Serveur

Le backend doit utiliser `server.postgres.js` et non `server.js` :

```json
// package.json
{
  "scripts": {
    "start": "node server.postgres.js"
  }
}
```

### Vérification 2: Routes Montées

Dans `server.postgres.js`, vérifier que les routes sont montées :

```javascript
app.use('/api/auth', require('./routes.postgres/auth'));
```

### Vérification 3: Base de Données

Vérifier que la connexion à la base de données fonctionne :

```bash
# Vérifier les logs pour les erreurs de connexion
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 100 | grep -i "database\|postgres\|error"
```

---

## 🛠️ Solution Recommandée

### Option 1: Redéployer le Backend (Recommandé)

Si le backend déployé n'utilise pas la bonne configuration, redéployer :

```bash
cd backend
./scripts/deploy-cloud-run.sh
```

### Option 2: Vérifier et Corriger la Configuration

1. Vérifier le Dockerfile
2. Vérifier package.json
3. Vérifier server.postgres.js
4. Redéployer si nécessaire

### Option 3: Utiliser une URL Différente

Si le backend déployé est une version différente, vérifier s'il y a une autre URL disponible ou un autre service déployé.

---

## 📊 Checklist de Vérification

- [ ] Logs du backend vérifiés
- [ ] Fichier serveur vérifié (server.postgres.js)
- [ ] Routes montées vérifiées
- [ ] Configuration vérifiée
- [ ] Base de données accessible
- [ ] Backend redéployé si nécessaire
- [ ] Routes testées après redéploiement

---

## 🎯 Prochaines Étapes

1. **Vérifier les logs** du backend pour identifier le problème
2. **Vérifier la configuration** du backend déployé
3. **Redéployer** le backend si nécessaire
4. **Tester les routes** après redéploiement
5. **Configurer l'app client** une fois le backend fonctionnel

---

## 📚 Ressources

- [Script de Déploiement](./backend/scripts/deploy-cloud-run.sh)
- [Configuration Backend](./backend/server.postgres.js)
- [Routes Auth](./backend/routes.postgres/auth.js)
- [Documentation Cloud Run](https://cloud.google.com/run/docs)

---

**Date**: $(date)  
**Statut**: ⚠️ Vérification nécessaire  
**Prochaine étape**: Vérifier les logs et la configuration du backend déployé

