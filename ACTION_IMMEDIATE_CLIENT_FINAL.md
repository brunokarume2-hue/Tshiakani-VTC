# 🚀 Actions Immédiates - Configuration App Client (MISE À JOUR)

## ⚠️ Problème Identifié

Le backend Cloud Run est accessible, mais la route `/api/auth/signin` retourne une erreur 404.

**Statut**:
- ✅ Backend accessible (health check OK)
- ❌ Route `/api/auth/signin` non disponible
- ⚠️ Vérification de la configuration nécessaire

---

## 🎯 Actions Immédiates

### 1. Vérifier les Logs du Backend (5 minutes)

```bash
# Voir les logs récents
gcloud run services logs read tshiakani-driver-backend \
  --region us-central1 \
  --limit 100

# Voir les logs en temps réel
gcloud run services logs tail tshiakani-driver-backend \
  --region us-central1
```

**Chercher**:
- Fichier serveur utilisé au démarrage
- Routes montées
- Erreurs de configuration
- Erreurs de connexion à la base de données

---

### 2. Vérifier la Configuration du Backend (10 minutes)

#### 2.1 Vérifier le Fichier Serveur

```bash
# Vérifier package.json
cat backend/package.json | grep -A 3 "scripts"

# Vérifier Dockerfile
cat backend/Dockerfile | grep -A 5 "CMD\|ENTRYPOINT"
```

**Vérifier que**:
- `package.json` utilise `server.postgres.js` dans le script `start`
- `Dockerfile` utilise la bonne commande de démarrage

#### 2.2 Vérifier les Routes

```bash
# Vérifier que les routes auth sont montées
grep -n "app.use('/api/auth" backend/server.postgres.js

# Vérifier que le fichier auth.js existe
ls -la backend/routes.postgres/auth.js
```

---

### 3. Vérifier les Variables d'Environnement (5 minutes)

```bash
# Vérifier les variables d'environnement
gcloud run services describe tshiakani-driver-backend \
  --region us-central1 \
  --format "value(spec.template.spec.containers[0].env)"
```

**Vérifier**:
- `NODE_ENV=production`
- `PORT=8080` (ou le port configuré)
- Variables de base de données
- `CORS_ORIGIN` configuré

---

### 4. Tester Autres Routes (5 minutes)

```bash
# Tester différentes routes pour voir lesquelles fonctionnent
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/rides
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/client
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/driver
```

**Objectif**: Identifier quelles routes sont disponibles

---

### 5. Redéployer le Backend si Nécessaire (15 minutes)

Si le backend n'utilise pas la bonne configuration, redéployer :

```bash
cd backend

# Vérifier la configuration
cat package.json | grep "start"
cat Dockerfile

# Redéployer
./scripts/deploy-cloud-run.sh
```

**Après le déploiement**:
1. Attendre que le déploiement soit terminé
2. Tester à nouveau les routes
3. Vérifier les logs

---

## 🔍 Diagnostic Détaillé

### Scénario 1: Backend Utilise server.js au lieu de server.postgres.js

**Symptômes**:
- Health check fonctionne
- Routes `/api/*` ne fonctionnent pas
- Logs montrent `server.js` au démarrage

**Solution**:
1. Modifier `package.json` pour utiliser `server.postgres.js`
2. Redéployer le backend

### Scénario 2: Routes Non Montées

**Symptômes**:
- Backend démarre correctement
- Routes `/api/*` retournent 404
- Logs ne montrent pas les routes montées

**Solution**:
1. Vérifier `server.postgres.js`
2. Vérifier que les fichiers de routes existent
3. Redéployer le backend

### Scénario 3: Problème de Base de Données

**Symptômes**:
- Backend démarre
- Erreurs de connexion à la base de données dans les logs
- Routes retournent des erreurs 500

**Solution**:
1. Vérifier les variables d'environnement de la base de données
2. Vérifier la connexion Cloud SQL
3. Vérifier les secrets

---

## ✅ Checklist de Vérification

### Backend
- [ ] Logs vérifiés
- [ ] Fichier serveur vérifié (server.postgres.js)
- [ ] Routes montées vérifiées
- [ ] Variables d'environnement vérifiées
- [ ] Base de données accessible
- [ ] Backend redéployé si nécessaire

### Configuration
- [ ] package.json utilise server.postgres.js
- [ ] Dockerfile utilise la bonne commande
- [ ] Routes auth montées dans server.postgres.js
- [ ] Fichiers de routes présents

### Tests
- [ ] Health check fonctionne
- [ ] Routes API testées
- [ ] Authentification testée
- [ ] App iOS testée

---

## 🎯 Prochaines Étapes Après Correction

Une fois le backend corrigé :

1. **Tester les Routes API**
   ```bash
   ./scripts/test-backend-cloud-run.sh
   ```

2. **Configurer CORS**
   ```bash
   gcloud run services update tshiakani-driver-backend \
     --region us-central1 \
     --update-env-vars "CORS_ORIGIN=*"
   ```

3. **Tester l'App iOS**
   - Builder en mode RELEASE
   - Tester l'authentification
   - Tester la création de course
   - Tester les WebSockets

---

## 📚 Ressources

- [Vérification Backend Cloud Run](./VERIFICATION_BACKEND_CLOUD_RUN.md)
- [Script de Déploiement](./backend/scripts/deploy-cloud-run.sh)
- [Configuration Backend](./backend/server.postgres.js)
- [Routes Auth](./backend/routes.postgres/auth.js)

---

## 📊 Résumé

**Problème**: Route `/api/auth/signin` non disponible sur Cloud Run  
**Cause**: À déterminer (configuration, déploiement, ou version différente)  
**Solution**: Vérifier les logs et la configuration, redéployer si nécessaire  
**Statut**: ⚠️ Vérification en cours

**Actions immédiates**:
1. Vérifier les logs (5 min)
2. Vérifier la configuration (10 min)
3. Vérifier les variables d'environnement (5 min)
4. Tester autres routes (5 min)
5. Redéployer si nécessaire (15 min)

**Total estimé**: ~40 minutes

---

**Date**: $(date)  
**Prochaine étape**: Vérifier les logs du backend pour identifier le problème

