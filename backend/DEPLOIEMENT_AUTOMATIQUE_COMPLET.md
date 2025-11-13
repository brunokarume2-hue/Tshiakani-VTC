# 🚀 Déploiement Automatique Complet - Railway + Supabase

## ✅ Ce qui est Prêt

- ✅ Railway CLI installé
- ✅ Scripts de déploiement créés
- ✅ Configuration Railway prête (`railway.toml`)
- ✅ Projet Supabase créé

## 🚀 Déploiement en 2 Étapes

### Étape 1 : Se Connecter à Railway (1 min)

1. **Page Railway ouverte** dans votre navigateur
2. **Se connecter** avec votre compte Railway (ou créer un compte)
3. **Dans le terminal**, appuyer sur **ENTER** pour continuer

### Étape 2 : Entrer la Connection String Supabase (30 sec)

Le script va demander la connection string Supabase :

1. **Aller sur** : https://supabase.com/dashboard
2. **Sélectionner** votre projet
3. **Settings** → **Database**
4. **Connection string** → **URI**
5. **Copier** la connection string
6. **Coller** dans le terminal quand demandé

Le script fera **automatiquement** :
- ✅ Créer le projet Railway
- ✅ Lier avec GitHub
- ✅ Configurer toutes les variables
- ✅ Déployer le backend

## 📋 Variables Configurées Automatiquement

Le script configure ces variables :
- `DATABASE_URL` (Supabase)
- `NODE_ENV=production`
- `PORT=3000`
- `JWT_SECRET`
- `ADMIN_API_KEY`
- `CORS_ORIGIN`
- `TWILIO_*` (toutes les variables Twilio)
- `STRIPE_CURRENCY`

## 🧪 Après le Déploiement

Le script affichera l'URL du service. Tester avec :

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

