# 🚀 Instructions pour Déployer sur Render (Chrome)

## ✅ Vous avez déjà créé le compte Render - Parfait !

## 📋 Étapes à Suivre dans Chrome

### Étape 1 : Vérifier GitHub (2 minutes)

**Dans le terminal** :
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git status
```

**Si le code n'est pas sur GitHub** :
1. Aller sur https://github.com
2. Créer un nouveau repository : `Tshiakani-VTC`
3. Dans le terminal :
```bash
git add .
git commit -m "Prepare for Render deployment"
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
git push -u origin main
```

### Étape 2 : Créer la Base de Données PostgreSQL (2 minutes)

**Dans Render Dashboard (Chrome)** :
1. Aller sur : https://dashboard.render.com
2. Cliquer sur **"New +"** (en haut à droite)
3. Sélectionner **"PostgreSQL"**
4. Remplir :
   - **Name** : `tshiakani-vtc-db`
   - **Database** : `tshiakani_vtc`
   - **User** : `tshiakani_user`
   - **PostgreSQL Version** : `15`
   - **Plan** : `Free` (ou `Starter` pour $7/mois)
5. Cliquer sur **"Create Database"**
6. ⚠️ **ATTENDRE** que la base soit créée (1-2 minutes)
7. ⚠️ **NOTER** l'URL de connexion (DATABASE_URL) - vous en aurez besoin

### Étape 3 : Créer le Service Web (3 minutes)

**Dans Render Dashboard** :
1. Cliquer sur **"New +"** → **"Web Service"**
2. **Connecter GitHub** (si pas déjà fait) :
   - Cliquer sur **"Connect GitHub"**
   - Autoriser Render à accéder à vos repositories
   - Sélectionner le repository : **Tshiakani-VTC** (ou votre nom de repo)
3. **Configuration du service** :
   - **Name** : `tshiakani-vtc-backend`
   - **Environment** : `Node`
   - **Region** : `Oregon (US West)` (ou le plus proche)
   - **Branch** : `main` (ou `master`)
   - **Root Directory** : `backend` ⚠️ **IMPORTANT**
   - **Build Command** : `npm ci --only=production`
   - **Start Command** : `node server.postgres.js`
   - **Plan** : `Free` (ou `Starter` pour $7/mois)

### Étape 4 : Variables d'Environnement (3 minutes)

**Dans la configuration du service web** :
1. Scroller jusqu'à **"Environment Variables"**
2. Cliquer sur **"Add Environment Variable"**
3. **Copier-coller ces variables une par une** :

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

**OU** copier depuis le fichier : `backend/RENDER_ENV_VARS.txt`

### Étape 5 : Lier la Base de Données (1 minute)

**Dans la même page de configuration** :
1. Scroller jusqu'à **"Add Database"** ou **"Link Database"**
2. Cliquer sur **"Link Database"**
3. Sélectionner : `tshiakani-vtc-db`
4. Render ajoutera automatiquement :
   - `DATABASE_URL`
   - `DB_HOST`
   - `DB_PORT`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_NAME`

### Étape 6 : Déployer (5-10 minutes)

1. Cliquer sur **"Create Web Service"** (en bas de la page)
2. **ATTENDRE** le déploiement (5-10 minutes)
3. Vous verrez les logs de build en temps réel
4. Une fois terminé, l'URL sera : `https://tshiakani-vtc-backend.onrender.com`

### Étape 7 : Tester (1 minute)

**Dans le terminal** :
```bash
# Test health check
curl https://tshiakani-vtc-backend.onrender.com/health

# Test admin login
curl -X POST https://tshiakani-vtc-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

## 🎯 Résumé Rapide

1. ✅ Compte Render créé (FAIT)
2. ⏳ Créer PostgreSQL : `tshiakani-vtc-db`
3. ⏳ Créer Web Service depuis GitHub
4. ⏳ Ajouter variables d'environnement
5. ⏳ Lier la base de données
6. ⏳ Déployer et attendre

## ⚠️ Notes Importantes

- **Root Directory** : Doit être `backend` (pas la racine)
- **Plan Free** : Le service s'endort après 15 min d'inactivité
- **Premier déploiement** : Peut prendre 10-15 minutes
- **Variables DB** : Sont ajoutées automatiquement quand vous liez la DB

## 📱 Après le Déploiement

Mettre à jour dans `Info.plist` de l'app iOS :
```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com/api</string>

<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com</string>
```

## 🆘 En Cas de Problème

- **Build échoue** : Vérifier les logs dans Render Dashboard
- **Service ne démarre pas** : Vérifier que `PORT=10000` est défini
- **Erreur DB** : Vérifier que la DB est liée et que `DATABASE_URL` existe

---

**Temps total estimé** : 15-20 minutes
**Coût** : Gratuit (plan Free)

