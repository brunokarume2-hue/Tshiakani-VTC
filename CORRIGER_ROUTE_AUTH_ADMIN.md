# 🔧 Corriger la Route d'Authentification Admin

## ⚠️ Problème

La route `/api/auth/admin/login` n'est **pas disponible** sur le backend Cloud Run déployé.

**Erreur** : `Cannot POST /api/auth/admin/login`

## 🔍 Diagnostic

### Vérification du Code

Le code montre que :
- ✅ La route existe dans `backend/routes.postgres/auth.js` (ligne 115)
- ✅ La route est montée dans `server.postgres.js` (ligne 39: `app.use('/api/auth', require('./routes.postgres/auth'))`)
- ✅ Le Dockerfile utilise `server.postgres.js` (ligne 42)
- ❌ Mais la route ne répond pas sur le backend déployé

### Causes Possibles

1. **Backend non mis à jour** : Le backend déployé utilise une ancienne version
2. **Erreur au démarrage** : Le backend a une erreur qui empêche les routes de se charger
3. **Problème de base de données** : La connexion à PostgreSQL échoue, empêchant les routes de fonctionner
4. **Variables d'environnement manquantes** : JWT_SECRET ou autres variables manquantes

---

## ✅ Solution : Redéployer le Backend

### Option 1: Redéployer avec Google Cloud Build

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que gcloud est installé
gcloud --version

# Vérifier que vous êtes connecté
gcloud auth login

# Configurer le projet
gcloud config set project tshiakani-vtc

# Builder et déployer
gcloud builds submit --config cloudbuild.yaml
```

### Option 2: Redéployer avec le Script

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Exécuter le script de déploiement
./scripts/deploy-cloud-run.sh
```

### Option 3: Redéployer Manuellement

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# 1. Builder l'image Docker
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api

# 2. Déployer sur Cloud Run
gcloud run deploy tshiakani-driver-backend \
  --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "NODE_ENV=production" \
  --update-env-vars "CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
```

---

## 🔍 Vérification Avant Déploiement

### 1. Vérifier que le Code est Correct

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que la route existe
grep -n "admin/login" routes.postgres/auth.js

# Vérifier que la route est montée
grep -n "app.use.*auth" server.postgres.js
```

### 2. Tester Localement

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Démarrer le backend local
npm run dev

# Dans un autre terminal, tester la route
curl -X POST http://localhost:3000/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Admin",
    "phoneNumber": "243900000000",
    "role": "admin"
  }
}
```

### 3. Vérifier les Variables d'Environnement

Le backend Cloud Run doit avoir ces variables :
- `JWT_SECRET` : Clé secrète JWT
- `ADMIN_API_KEY` : Clé API Admin
- `DATABASE_URL` : URL de connexion PostgreSQL
- `CORS_ORIGIN` : URLs autorisées (inclure Firebase)

---

## 🚀 Étapes de Redéploiement

### Étape 1: Vérifier la Configuration

```bash
cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que server.postgres.js existe
ls -la server.postgres.js

# Vérifier que les routes existent
ls -la routes.postgres/auth.js
```

### Étape 2: Vérifier le Dockerfile

```bash
# Vérifier que le Dockerfile utilise server.postgres.js
grep "CMD" Dockerfile
# Doit afficher: CMD ["node", "server.postgres.js"]
```

### Étape 3: Builder l'Image

```bash
# Builder l'image Docker
gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
```

### Étape 4: Déployer sur Cloud Run

```bash
# Déployer avec les variables d'environnement nécessaires
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

### Étape 5: Vérifier le Déploiement

```bash
# Tester la route admin login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** : Token JWT et informations utilisateur

---

## 🔧 Configuration des Variables d'Environnement

### Variables Requises sur Cloud Run

```bash
# JWT Secret
JWT_SECRET=votre_secret_jwt

# Clé API Admin
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8

# Base de données PostgreSQL
DATABASE_URL=postgresql://user:password@host:5432/database

# CORS
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com

# Port
PORT=8080

# Environnement
NODE_ENV=production
```

### Configurer dans Cloud Run

```bash
# Mettre à jour les variables d'environnement
gcloud run services update tshiakani-driver-backend \
  --region us-central1 \
  --update-env-vars "CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
```

---

## ✅ Vérification Post-Déploiement

### 1. Vérifier le Health Check

```bash
curl https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/health
```

**Résultat attendu** : `{"status":"OK","database":"connected",...}`

### 2. Tester la Route Admin Login

```bash
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** : Token JWT et informations utilisateur

### 3. Tester depuis le Dashboard

1. Aller sur `https://tshiakani-vtc-99cea.web.app`
2. Se connecter avec :
   - Numéro : `+243900000000`
   - Mot de passe : (vide)
3. Vérifier que la connexion fonctionne

---

## 🆘 Dépannage

### Erreur: "Cannot POST /api/auth/admin/login"

**Causes** :
1. Backend non déployé avec la dernière version
2. Route non montée dans server.postgres.js
3. Erreur au démarrage du serveur

**Solution** :
1. Vérifier les logs Cloud Run : `gcloud run services logs read tshiakani-driver-backend --region us-central1`
2. Redéployer le backend
3. Vérifier que server.postgres.js est utilisé

### Erreur: "Database connection failed"

**Cause** : Problème de connexion à PostgreSQL

**Solution** :
1. Vérifier que DATABASE_URL est correcte
2. Vérifier que Cloud SQL est accessible
3. Vérifier les permissions

### Erreur: "JWT_SECRET is not defined"

**Cause** : Variable d'environnement manquante

**Solution** :
1. Configurer JWT_SECRET dans Cloud Run
2. Redéployer le backend

---

## 📝 Checklist

- [ ] Code vérifié (route existe dans auth.js)
- [ ] Route montée dans server.postgres.js
- [ ] Dockerfile utilise server.postgres.js
- [ ] Variables d'environnement configurées
- [ ] Backend testé localement
- [ ] Backend redéployé sur Cloud Run
- [ ] Route testée après déploiement
- [ ] Dashboard peut se connecter

---

**Date** : $(date)
**Statut** : ⚠️ Route à redéployer

