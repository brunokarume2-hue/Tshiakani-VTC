# 🚀 Guide Complet - Déploiement Render.com

## ⚠️ Important : Je ne peux pas accéder à votre navigateur Chrome

Je ne peux pas me connecter à Render.com à votre place, mais j'ai préparé **TOUT** ce qui peut être automatisé.

## ✅ Ce qui est Prêt (100%)

1. ✅ **render.yaml** : Configuration complète
2. ✅ **Dockerfile** : Port 8080 configuré
3. ✅ **server.postgres.js** : Utilise process.env.PORT
4. ✅ **Variables d'environnement** : Toutes documentées
5. ✅ **Scripts** : Tous créés
6. ✅ **Documentation** : Complète

## 📋 Ce qu'il reste à faire (15-20 minutes)

### Étape 1 : GitHub (5 minutes)

**Le code doit être sur GitHub pour Render**

#### Option A : Si vous avez déjà un repository GitHub
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git add .
git commit -m "Prepare for Render deployment"
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
git push -u origin main
```

#### Option B : Créer un nouveau repository
1. Aller sur https://github.com/new
2. **Repository name** : `Tshiakani-VTC`
3. **Visibility** : Public ou Private
4. **NE PAS** cocher "Add a README file"
5. Cliquer **"Create repository"**
6. Dans le terminal :
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git add .
git commit -m "Prepare for Render deployment"
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
git branch -M main
git push -u origin main
```

### Étape 2 : Render Dashboard (10-15 minutes)

**Ouvrir dans Chrome** : https://dashboard.render.com

#### 2.1 Créer PostgreSQL Database
1. Cliquer **"New +"** (en haut à droite)
2. Sélectionner **"PostgreSQL"**
3. Remplir :
   - **Name** : `tshiakani-vtc-db`
   - **Database** : `tshiakani_vtc`
   - **User** : `tshiakani_user`
   - **PostgreSQL Version** : `15`
   - **Plan** : `Free`
4. Cliquer **"Create Database"**
5. ⚠️ **ATTENDRE** 1-2 minutes
6. ✅ Base créée

#### 2.2 Créer Web Service
1. Cliquer **"New +"** → **"Web Service"**
2. **Connecter GitHub** (si pas déjà fait) :
   - Cliquer **"Connect GitHub"**
   - Autoriser Render
   - Sélectionner repository : **Tshiakani-VTC**
3. **Configuration** :
   ```
   Name: tshiakani-vtc-backend
   Environment: Node
   Region: Oregon (US West)
   Branch: main
   Root Directory: backend ⚠️ IMPORTANT
   Build Command: npm ci --only=production
   Start Command: node server.postgres.js
   Plan: Free
   ```

#### 2.3 Variables d'Environnement
1. Scroller à **"Environment Variables"**
2. Cliquer **"Add Environment Variable"** pour chaque variable
3. **Copier depuis** : `backend/RENDER_ENV_VARS.txt`

```
NODE_ENV = production
PORT = 10000
JWT_SECRET = ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY = aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN = https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID = TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN = TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM = whatsapp:+14155238886
TWILIO_CONTENT_SID = HX229f5a04fd0510ce1b071852155d3e75
```

#### 2.4 Lier Base de Données
1. Scroller à **"Add Database"** ou **"Link Database"**
2. Cliquer **"Link Database"**
3. Sélectionner : `tshiakani-vtc-db`
4. ✅ Variables DB ajoutées automatiquement

#### 2.5 Déployer
1. Cliquer **"Create Web Service"**
2. ⚠️ **ATTENDRE** 5-10 minutes
3. Vérifier les logs de build
4. ✅ Service déployé
5. URL : `https://tshiakani-vtc-backend.onrender.com`

### Étape 3 : Test (1 minute)

```bash
# Health check
curl https://tshiakani-vtc-backend.onrender.com/health

# Test admin login
curl -X POST https://tshiakani-vtc-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

### Étape 4 : Mise à Jour iOS

Dans `Info.plist` :
```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com/api</string>

<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com</string>
```

## 📚 Fichiers de Référence

- **Instructions Chrome** : `INSTRUCTIONS_RENDER_CHROME.md`
- **Checklist** : `CHECKLIST_RENDER.md`
- **Variables** : `RENDER_ENV_VARS.txt`
- **Configuration** : `render.yaml`

## 🆘 Aide

Si vous avez des problèmes :
1. Vérifier les logs dans Render Dashboard
2. Vérifier que `Root Directory` = `backend`
3. Vérifier que toutes les variables sont ajoutées
4. Vérifier que la DB est liée

---

**Temps total** : 15-20 minutes
**Coût** : Gratuit (plan Free)

