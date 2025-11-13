# 🚂 Déploiement Railway + Supabase - Mode Simple

## ✅ Ce qui est Prêt

- ✅ Projet Supabase créé
- ✅ Code sur GitHub : `brunokarume2-hue/Tshiakani-VTC`
- ✅ Configuration Railway prête

## 🚀 Déploiement en 3 Étapes

### Étape 1 : Récupérer la Connection String Supabase (1 min)

1. Aller sur : https://supabase.com/dashboard
2. Sélectionner votre projet
3. **Settings** → **Database**
4. Scroller à **"Connection string"**
5. Sélectionner **"URI"**
6. **Copier** la connection string (ex: `postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres`)

### Étape 2 : Créer le Projet Railway (2 min)

1. Aller sur : https://railway.app/new
2. Cliquer **"Deploy from GitHub repo"**
3. Autoriser Railway
4. Sélectionner : **brunokarume2-hue/Tshiakani-VTC**
5. Railway détectera automatiquement le backend

### Étape 3 : Configurer les Variables (3 min)

Dans Railway, section **Variables**, ajouter :

```
DATABASE_URL = (coller la connection string Supabase)
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

**Temps total** : 6 minutes
**Coût** : Gratuit (plan Free)

