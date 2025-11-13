# ⚡ Déploiement Rapide sur Render.com

## 🎯 Checklist Rapide

### ✅ Prérequis
- [ ] Code sur GitHub
- [ ] Compte Render.com créé
- [ ] Connexion GitHub → Render configurée

### 📋 Étapes de Déploiement

#### 1. Créer la Base de Données PostgreSQL

**Dans Render Dashboard** :
1. `New +` → `PostgreSQL`
2. **Name** : `tshiakani-vtc-db`
3. **Database** : `tshiakani_vtc`
4. **User** : `tshiakani_user`
5. **Plan** : Free (ou Starter $7/mois)
6. **Create Database**
7. ⚠️ **Noter l'URL de connexion** (DATABASE_URL)

#### 2. Créer le Service Web

**Dans Render Dashboard** :
1. `New +` → `Web Service`
2. Connecter le repository GitHub
3. Sélectionner : `Tshiakani VTC` (ou votre repo)
4. **Configuration** :
   ```
   Name: tshiakani-vtc-backend
   Environment: Node
   Root Directory: backend
   Build Command: npm ci --only=production
   Start Command: node server.postgres.js
   Plan: Free (ou Starter $7/mois)
   ```

#### 3. Variables d'Environnement

**Copier-coller ces variables dans Render** :

```bash
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

**Variables DB** (ajoutées automatiquement si vous liez la DB) :
- `Link Database` → Sélectionner `tshiakani-vtc-db`
- Render ajoute automatiquement : DATABASE_URL, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME

#### 4. Déployer

1. Cliquer sur **"Create Web Service"**
2. Attendre 5-10 minutes
3. L'URL sera : `https://tshiakani-vtc-backend.onrender.com`

## 🔗 Liens Utiles

- **Render Dashboard** : https://dashboard.render.com
- **Documentation complète** : `backend/DEPLOIEMENT_RENDER.md`
- **Guide détaillé** : `backend/ALTERNATIVES_DEPLOIEMENT.md`

## 🧪 Test Après Déploiement

```bash
# Health check
curl https://tshiakani-vtc-backend.onrender.com/health

# Test admin login
curl -X POST https://tshiakani-vtc-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

## 📱 Mise à Jour App iOS

Après le déploiement, mettre à jour dans `Info.plist` :

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com/api</string>

<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com</string>
```

## ⚠️ Note Importante

**Plan Free** : Le service s'endort après 15 minutes d'inactivité
- **Solution 1** : Utiliser un service de ping gratuit (UptimeRobot, etc.)
- **Solution 2** : Passer au plan Starter ($7/mois) pour éviter le sleep

## ✅ Fichiers Prêts

- ✅ `render.yaml` : Configuration automatique
- ✅ `Dockerfile` : Port 8080 configuré
- ✅ `server.postgres.js` : Utilise process.env.PORT

**Tout est prêt pour le déploiement ! 🚀**

