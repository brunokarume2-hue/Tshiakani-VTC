# 🚂 Déploiement Railway via Interface Web - Mode Simple

## ✅ Configuration Prête

- ✅ Connection string Supabase : `postgresql://postgres:Nyota9090@db.ecayztndohyyjaynrkaz.supabase.co:5432/postgres`
- ✅ Code sur GitHub : `brunokarume2-hue/Tshiakani-VTC`
- ✅ Variables d'environnement : Toutes prêtes

## 🚀 Déploiement en 3 Étapes (5 minutes)

### Étape 1 : Créer le Projet Railway (1 min)

1. Aller sur : https://railway.app/new
2. Cliquer **"Deploy from GitHub repo"**
3. Autoriser Railway (si première fois)
4. Sélectionner : **brunokarume2-hue/Tshiakani-VTC**
5. Railway détectera automatiquement le backend

### Étape 2 : Configurer les Variables (2 min)

Dans Railway Dashboard, section **Variables**, ajouter :

```
DATABASE_URL = postgresql://postgres:Nyota9090@db.ecayztndohyyjaynrkaz.supabase.co:5432/postgres
NODE_ENV = production
PORT = 3000
JWT_SECRET = ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY = aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN = https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID = YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN = YOUR_TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM = whatsapp:+14155238886
TWILIO_CONTENT_SID = HX229f5a04fd0510ce1b071852155d3e75
STRIPE_CURRENCY = cdf
SUPABASE_URL = https://mbbcjcltvmfbfrbgfhmv.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYmNqY2x0dm1mYmZyYmdmaG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTQ2MDcsImV4cCI6MjA3ODU5MDYwN30.KZN1OYaOXmVdSUkZxsN9sIwe5_g11l2cZVuC0ESDL08
```

### Étape 3 : Configurer le Service (1 min)

Dans les **Settings** du service :
- **Root Directory** : `backend`
- **Start Command** : `node server.postgres.js`

Railway déploiera automatiquement ! ⏱️ 3-5 minutes

## 🧪 Test

```bash
curl https://votre-app.railway.app/health
```

## 📱 Mise à Jour iOS

Dans `Info.plist` :
- `API_BASE_URL` = `https://votre-app.railway.app/api`
- `WS_BASE_URL` = `https://votre-app.railway.app`

---

**Temps total** : 5 minutes
**Coût** : Gratuit

