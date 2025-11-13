# 🚀 Redéployer le Backend sur Cloud Run

## ⚠️ Problème

Le backend déployé sur Cloud Run ne répond pas aux routes `/api/auth/*` et `/api/admin/*`.

**Erreurs** :
- `Cannot POST /api/auth/admin/login`
- `Cannot GET /api/auth/verify`
- `Cannot GET /api/admin/stats`

## 🔍 Diagnostic

### Vérification

```bash
# Health check fonctionne
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
# ✅ Retourne: {"status":"ok",...}

# Routes API ne fonctionnent pas
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login
# ❌ Retourne: Cannot POST /api/auth/admin/login
```

### Causes Possibles

1. **Backend déployé utilise une ancienne version** sans les routes
2. **Problème de configuration** dans le déploiement
3. **Erreur au démarrage** qui empêche les routes de se charger
4. **Base de données non accessible** depuis Cloud Run

---

## ✅ Solution : Redéployer le Backend

### Étape 1: Vérifier le Code Local

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que la route existe
grep -n "admin/login" routes.postgres/auth.js

# Vérifier que la route est montée
grep -n "app.use.*auth" server.postgres.js
```

### Étape 2: Vérifier le Dockerfile

```bash
# Vérifier que le Dockerfile utilise server.postgres.js
grep "CMD" Dockerfile
# Doit afficher: CMD ["node", "server.postgres.js"]
```

### Étape 3: Builder l'Image Docker

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Builder l'image
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
```

### Étape 4: Déployer sur Cloud Run

```bash
# Déployer le service
gcloud run deploy tshiakani-driver-backend \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production" \
  --update-env-vars "CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
```

### Étape 5: Configurer les Variables d'Environnement

Les variables d'environnement doivent être configurées dans Cloud Run :

```bash
# Mettre à jour les variables d'environnement
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --update-env-vars "JWT_SECRET=votre_secret_jwt,ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8,CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
```

### Étape 6: Vérifier le Déploiement

```bash
# Tester la route admin login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** : Token JWT et informations utilisateur

---

## 🔧 Configuration Requise

### Variables d'Environnement sur Cloud Run

- `NODE_ENV=production`
- `PORT=8080`
- `JWT_SECRET` : Clé secrète JWT
- `ADMIN_API_KEY` : Clé API Admin
- `DATABASE_URL` : URL de connexion PostgreSQL
- `CORS_ORIGIN` : URLs autorisées (Firebase)

---

## 📝 Checklist

- [ ] Code vérifié (route existe)
- [ ] Dockerfile vérifié (utilise server.postgres.js)
- [ ] Image Docker builder
- [ ] Backend déployé sur Cloud Run
- [ ] Variables d'environnement configurées
- [ ] Route testée après déploiement
- [ ] Dashboard peut se connecter

---

**Date** : $(date)

