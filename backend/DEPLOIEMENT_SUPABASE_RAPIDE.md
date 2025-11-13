# ⚡ Déploiement Rapide : Supabase + Railway

## 🎯 Pourquoi cette combinaison ?

- ✅ **Supabase** : Base de données PostgreSQL gratuite et simple
- ✅ **Railway** : Déploiement backend automatique depuis GitHub
- ✅ **Total** : 10 minutes, 100% gratuit

## 🚀 Déploiement en 5 Étapes

### 1️⃣ Créer Supabase (2 min)

1. Aller sur : https://supabase.com/dashboard/new
2. **Name** : `tshiakani-vtc`
3. **Password** : (choisir un mot de passe)
4. **Region** : `West US`
5. **Plan** : `Free`
6. Cliquer **"Create new project"**
7. ⏳ Attendre 2-3 minutes

### 2️⃣ Récupérer les Variables Supabase (1 min)

Dans Supabase Dashboard :

**Settings → API** :
- Project URL : `https://xxxxx.supabase.co`
- anon key : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- service_role key : `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**Settings → Database** :
- Connection string : `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`

### 3️⃣ Créer Railway (2 min)

1. Aller sur : https://railway.app/new
2. Cliquer **"Deploy from GitHub repo"**
3. Autoriser Railway
4. Sélectionner : `brunokarume2-hue/Tshiakani-VTC`
5. Railway détecte automatiquement le backend

### 4️⃣ Configurer Variables Railway (3 min)

Dans Railway, section **Variables**, ajouter :

```
DATABASE_URL = (Connection string de Supabase)
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
```

### 5️⃣ Déployer (2 min)

Railway déploie automatiquement !
- ⏳ Attendre 3-5 minutes
- ✅ URL disponible dans Railway Dashboard

## 🧪 Test

```bash
curl https://votre-app.railway.app/health
```

## 📱 Mise à Jour iOS

Dans `Info.plist` :
- `API_BASE_URL` = `https://votre-app.railway.app/api`
- `WS_BASE_URL` = `https://votre-app.railway.app`

---

**Temps total** : 10 minutes
**Coût** : Gratuit (plan Free)

