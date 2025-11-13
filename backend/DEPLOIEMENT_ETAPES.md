# 🚀 Déploiement Render - Étapes Détaillées

## 📋 Checklist Complète

### ✅ Préparation (FAIT)
- [x] render.yaml configuré
- [x] Dockerfile mis à jour
- [x] server.postgres.js configuré
- [x] Variables d'environnement documentées

### 🔴 Actions Manuelles Requises

#### 1. GitHub (si pas déjà fait)
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git add .
git commit -m "Prepare for Render deployment"
git push
```

#### 2. Créer Compte Render
- Aller sur : https://render.com
- Cliquer : "Get Started for Free"
- S'inscrire avec GitHub

#### 3. Créer Base de Données PostgreSQL
Dans Render Dashboard :
1. **New +** → **PostgreSQL**
2. **Name** : `tshiakani-vtc-db`
3. **Database** : `tshiakani_vtc`
4. **User** : `tshiakani_user`
5. **Plan** : Free
6. **Create Database**

#### 4. Créer Service Web
Dans Render Dashboard :
1. **New +** → **Web Service**
2. Connecter repository GitHub
3. Sélectionner : **Tshiakani VTC**
4. Configuration :
   - **Name** : `tshiakani-vtc-backend`
   - **Environment** : `Node`
   - **Root Directory** : `backend`
   - **Build Command** : `npm ci --only=production`
   - **Start Command** : `node server.postgres.js`
   - **Plan** : Free

#### 5. Variables d'Environnement
Copier depuis `RENDER_ENV_VARS.txt` dans Render Dashboard > Environment

#### 6. Lier Base de Données
Dans la configuration du service :
- **Environment** → **Link Database**
- Sélectionner : `tshiakani-vtc-db`

#### 7. Déployer
- Cliquer : **"Create Web Service"**
- Attendre : 5-10 minutes
- URL : `https://tshiakani-vtc-backend.onrender.com`

## 🧪 Test

```bash
curl https://tshiakani-vtc-backend.onrender.com/health
```

## 📱 Mise à Jour iOS

Dans `Info.plist` :
- `API_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com/api`
- `WS_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com`
