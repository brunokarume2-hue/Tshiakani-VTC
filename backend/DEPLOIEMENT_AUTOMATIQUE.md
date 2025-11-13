# 🤖 Déploiement Automatique sur Render.com

## ⚠️ Limitations

Je ne peux pas créer de compte Render ou me connecter à leur interface, mais j'ai préparé **TOUT** ce qui peut être automatisé.

## ✅ Ce qui est Prêt

1. ✅ **render.yaml** : Configuration complète
2. ✅ **Dockerfile** : Port 8080 configuré
3. ✅ **server.postgres.js** : Utilise process.env.PORT
4. ✅ **.gitignore** : Fichiers ignorés configurés
5. ✅ **Variables d'environnement** : Toutes listées

## 🚀 Étapes Manuelles (5 minutes)

### Étape 1 : Vérifier GitHub

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git status
```

Si le code n'est pas sur GitHub :
```bash
# Initialiser Git (si pas déjà fait)
git init

# Ajouter tous les fichiers
git add .

# Commit
git commit -m "Prepare for Render deployment"

# Créer un repository sur GitHub.com
# Puis :
git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git
git push -u origin main
```

### Étape 2 : Créer le Compte Render

1. Aller sur : **https://render.com**
2. Cliquer sur **"Get Started for Free"**
3. S'inscrire avec **GitHub** (recommandé)
4. Autoriser Render à accéder à vos repositories

### Étape 3 : Créer la Base de Données

1. Dans Render Dashboard : **New +** → **PostgreSQL**
2. Configuration :
   - **Name** : `tshiakani-vtc-db`
   - **Database** : `tshiakani_vtc`
   - **User** : `tshiakani_user`
   - **Plan** : Free
3. **Create Database**
4. ⚠️ **Noter l'URL** (DATABASE_URL)

### Étape 4 : Créer le Service Web

1. **New +** → **Web Service**
2. Connecter le repository GitHub
3. Sélectionner : **Tshiakani VTC** (votre repo)
4. Configuration :
   ```
   Name: tshiakani-vtc-backend
   Environment: Node
   Root Directory: backend
   Build Command: npm ci --only=production
   Start Command: node server.postgres.js
   Plan: Free
   ```

### Étape 5 : Variables d'Environnement

**Copier-coller dans Render** (section Environment) :

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

**Lier la base de données** :
- Cliquer sur **"Link Database"**
- Sélectionner **tshiakani-vtc-db**
- Render ajoutera automatiquement : DATABASE_URL, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME

### Étape 6 : Déployer

1. Cliquer sur **"Create Web Service"**
2. Attendre 5-10 minutes
3. L'URL sera : `https://tshiakani-vtc-backend.onrender.com`

## 🧪 Test

```bash
# Health check
curl https://tshiakani-vtc-backend.onrender.com/health

# Test admin login
curl -X POST https://tshiakani-vtc-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

## 📱 Mise à Jour App iOS

Dans `Info.plist` :

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com/api</string>

<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com</string>
```

## 🎯 Alternative : Utiliser render.yaml

Si vous préférez, Render peut utiliser directement le fichier `render.yaml` :

1. Créer le service web
2. Dans "Apply Render YAML", sélectionner le fichier `render.yaml`
3. Render configurera tout automatiquement

---

**Temps estimé** : 10-15 minutes
**Coût** : Gratuit (plan Free)

