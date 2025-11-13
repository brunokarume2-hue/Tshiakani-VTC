# ✅ Checklist Déploiement Render.com

## 🎯 Étapes à Suivre dans Chrome (15-20 minutes)

### ✅ Prérequis
- [x] Compte Render créé
- [ ] Code sur GitHub (vérifier ci-dessous)
- [ ] Repository GitHub connecté à Render

### 📋 Dans Render Dashboard (Chrome)

#### 1. Créer PostgreSQL Database
- [ ] Aller sur https://dashboard.render.com
- [ ] Cliquer **"New +"** → **"PostgreSQL"**
- [ ] **Name** : `tshiakani-vtc-db`
- [ ] **Database** : `tshiakani_vtc`
- [ ] **User** : `tshiakani_user`
- [ ] **Plan** : `Free`
- [ ] Cliquer **"Create Database"**
- [ ] ⚠️ **ATTENDRE** 1-2 minutes
- [ ] ✅ Base créée

#### 2. Créer Web Service
- [ ] Cliquer **"New +"** → **"Web Service"**
- [ ] **Connecter GitHub** (si pas déjà fait)
- [ ] Sélectionner repository : **Tshiakani-VTC**
- [ ] **Configuration** :
  - [ ] **Name** : `tshiakani-vtc-backend`
  - [ ] **Environment** : `Node`
  - [ ] **Root Directory** : `backend` ⚠️ **IMPORTANT**
  - [ ] **Build Command** : `npm ci --only=production`
  - [ ] **Start Command** : `node server.postgres.js`
  - [ ] **Plan** : `Free`

#### 3. Variables d'Environnement
- [ ] Scroller à **"Environment Variables"**
- [ ] Ajouter ces variables (copier depuis `RENDER_ENV_VARS.txt`) :

```
NODE_ENV=production
PORT=10000
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID=TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75
```

#### 4. Lier Base de Données
- [ ] Scroller à **"Add Database"** ou **"Link Database"**
- [ ] Cliquer **"Link Database"**
- [ ] Sélectionner : `tshiakani-vtc-db`
- [ ] ✅ Variables DB ajoutées automatiquement

#### 5. Déployer
- [ ] Cliquer **"Create Web Service"**
- [ ] ⚠️ **ATTENDRE** 5-10 minutes
- [ ] Vérifier les logs de build
- [ ] ✅ Service déployé
- [ ] URL : `https://tshiakani-vtc-backend.onrender.com`

### 🧪 Test
- [ ] Tester : `curl https://tshiakani-vtc-backend.onrender.com/health`
- [ ] Vérifier les logs dans Render Dashboard

### 📱 Mise à Jour iOS
- [ ] Mettre à jour `Info.plist` :
  - `API_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com/api`
  - `WS_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com`

---

## 📚 Fichiers de Référence

- **Instructions détaillées** : `INSTRUCTIONS_RENDER_CHROME.md`
- **Variables d'environnement** : `RENDER_ENV_VARS.txt`
- **Configuration** : `render.yaml`

---

**Temps total** : 15-20 minutes
**Coût** : Gratuit (plan Free)

