# 🚀 Guide de Déploiement sur Render.com

## ✅ Pourquoi Render.com ?

- ✅ **Gratuit** avec limitations acceptables pour le développement
- ✅ **Configuration simple** : Déploiement automatique depuis GitHub
- ✅ **Support complet** : Node.js, PostgreSQL, Redis, WebSockets
- ✅ **SSL automatique** : HTTPS inclus
- ✅ **Pas de compte de facturation requis** pour commencer

## 📋 Prérequis

1. Compte GitHub avec le code du backend
2. Compte Render.com (gratuit)
3. Base de données PostgreSQL (peut être créée sur Render)

## 🚀 Déploiement en 5 Étapes

### Étape 1 : Créer un Compte Render

1. Aller sur [Render.com](https://render.com)
2. Cliquer sur "Get Started for Free"
3. S'inscrire avec GitHub (recommandé pour déploiement automatique)

### Étape 2 : Créer la Base de Données PostgreSQL

1. Dans le Dashboard Render, cliquer sur "New +"
2. Sélectionner "PostgreSQL"
3. Configurer :
   - **Name** : `tshiakani-vtc-db`
   - **Database** : `tshiakani_vtc`
   - **User** : `tshiakani_user`
   - **Plan** : Free (ou Starter pour $7/mois)
   - **Region** : Choisir la région la plus proche
4. Cliquer sur "Create Database"
5. **Important** : Noter l'URL de connexion (DATABASE_URL) qui sera affichée

### Étape 3 : Créer le Service Web

1. Dans le Dashboard Render, cliquer sur "New +"
2. Sélectionner "Web Service"
3. Connecter votre repository GitHub
4. Sélectionner le repository `Tshiakani VTC`
5. Sélectionner la branche `main` (ou `master`)
6. Configurer :
   - **Name** : `tshiakani-vtc-backend`
   - **Environment** : `Node`
   - **Root Directory** : `backend` (si le backend est dans un sous-dossier)
   - **Build Command** : `npm ci --only=production`
   - **Start Command** : `node server.postgres.js`
   - **Plan** : Free (ou Starter pour $7/mois - recommandé pour éviter le sleep)

### Étape 4 : Configurer les Variables d'Environnement

Dans la section "Environment", ajouter les variables suivantes :

#### Variables Requises

```
NODE_ENV=production
PORT=10000
```

#### Variables de Base de Données

Render va automatiquement créer ces variables si vous liez la base de données :
- `DATABASE_URL` (automatique si vous liez la DB)
- `DB_HOST` (automatique)
- `DB_PORT` (automatique)
- `DB_USER` (automatique)
- `DB_PASSWORD` (automatique)
- `DB_NAME` (automatique)

#### Variables de Sécurité

```
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

#### Variables CORS

```
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
```

#### Variables Twilio (OTP)

```
TWILIO_ACCOUNT_SID=TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75
```

#### Variables Redis (Optionnel)

Si vous utilisez Redis (Upstash recommandé) :
```
REDIS_URL=redis://default:token@endpoint.upstash.io:6379
REDIS_CONNECT_TIMEOUT=10000
```

#### Variables Stripe (Optionnel)

```
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_CURRENCY=cdf
```

### Étape 5 : Lier la Base de Données

1. Dans la configuration du service web, aller dans "Environment"
2. Cliquer sur "Link Database"
3. Sélectionner `tshiakani-vtc-db`
4. Render ajoutera automatiquement les variables de connexion

### Étape 6 : Déployer

1. Cliquer sur "Create Web Service"
2. Render va :
   - Cloner le repository
   - Installer les dépendances (`npm ci --only=production`)
   - Builder l'application
   - Démarrer le service
3. Attendre la fin du déploiement (5-10 minutes)
4. L'URL sera disponible dans le dashboard (ex: `https://tshiakani-vtc-backend.onrender.com`)

## 🔧 Configuration Alternative avec render.yaml

Si vous préférez utiliser le fichier `render.yaml` :

1. Assurez-vous que `render.yaml` est à la racine du repository (ou dans le dossier backend)
2. Dans Render, lors de la création du service, sélectionner "Apply Render YAML"
3. Render utilisera automatiquement la configuration du fichier

## 📝 Mise à Jour de l'URL dans l'App iOS

Après le déploiement, mettre à jour l'URL de l'API dans `Info.plist` :

```xml
<key>API_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com/api</string>

<key>WS_BASE_URL</key>
<string>https://tshiakani-vtc-backend.onrender.com</string>
```

## 🧪 Tester le Déploiement

```bash
# Tester la route health
curl https://tshiakani-vtc-backend.onrender.com/health

# Tester la route admin login
curl -X POST https://tshiakani-vtc-backend.onrender.com/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

## ⚠️ Limitations du Plan Gratuit

- **Sleep Mode** : Le service s'endort après 15 minutes d'inactivité
  - Solution : Utiliser un service de "ping" gratuit (UptimeRobot, etc.)
  - Ou : Passer au plan Starter ($7/mois) pour éviter le sleep
  
- **750 heures gratuites/mois** : Suffisant pour le développement

- **512 MB RAM** : Suffisant pour un backend Node.js

## 🔄 Déploiement Automatique

Render déploie automatiquement à chaque push sur la branche principale (main/master).

Pour désactiver :
- Aller dans Settings > Build & Deploy
- Désactiver "Auto-Deploy"

## 📊 Monitoring

Render fournit :
- Logs en temps réel
- Métriques de performance
- Alertes par email

## 💰 Coûts

- **Plan Free** : Gratuit (avec limitations)
- **Plan Starter** : $7/mois (recommandé pour production)
  - Pas de sleep mode
  - Plus de ressources
  - Support prioritaire

## 🔗 Liens Utiles

- [Documentation Render](https://render.com/docs)
- [Dashboard Render](https://dashboard.render.com)
- [Support Render](https://render.com/docs/support)

---

**Prochaine Étape** : Une fois déployé, mettre à jour l'URL de l'API dans l'app iOS et tester la connexion.

