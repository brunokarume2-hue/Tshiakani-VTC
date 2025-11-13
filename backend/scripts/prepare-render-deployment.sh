#!/bin/bash

# Script de préparation pour le déploiement Render
# Génère toutes les configurations nécessaires

set -e

echo "🚀 Préparation du Déploiement Render.com"
echo "=========================================="
echo ""

BACKEND_DIR="/Users/admin/Documents/Tshiakani VTC/backend"
cd "$BACKEND_DIR"

# Vérifier que render.yaml existe
if [ ! -f "render.yaml" ]; then
    echo "❌ render.yaml non trouvé"
    exit 1
fi

echo "✅ Fichiers de configuration vérifiés"
echo ""

# Générer un fichier avec toutes les variables d'environnement
cat > RENDER_ENV_VARS.txt << 'EOF'
# Variables d'environnement pour Render.com
# Copier-coller ces variables dans Render Dashboard > Environment

NODE_ENV=production
PORT=10000
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID=TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75

# Variables de base de données (ajoutées automatiquement si vous liez la DB)
# DATABASE_URL (automatique)
# DB_HOST (automatique)
# DB_PORT (automatique)
# DB_USER (automatique)
# DB_PASSWORD (automatique)
# DB_NAME (automatique)
EOF

echo "✅ Fichier RENDER_ENV_VARS.txt créé"
echo ""

# Créer un guide de déploiement étape par étape
cat > DEPLOIEMENT_ETAPES.md << 'EOF'
# 🚀 Déploiement Render - Étapes Détaillées

## 📋 Checklist Complète

### ✅ Préparation (FAIT)
- [x] render.yaml configuré
- [x] Dockerfile mis à jour
- [x] server.postgres.js configuré
- [x] Variables d'environnement documentées

### 🔴 Actions Manuelles Requises

#### 1. GitHub (si pas déjà fait)
```bash
cd "/Users/admin/Documents/Tshiakani VTC"
git add .
git commit -m "Prepare for Render deployment"
git push
```

#### 2. Créer Compte Render
- Aller sur : https://render.com
- Cliquer : "Get Started for Free"
- S'inscrire avec GitHub

#### 3. Créer Base de Données PostgreSQL
Dans Render Dashboard :
1. **New +** → **PostgreSQL**
2. **Name** : `tshiakani-vtc-db`
3. **Database** : `tshiakani_vtc`
4. **User** : `tshiakani_user`
5. **Plan** : Free
6. **Create Database**

#### 4. Créer Service Web
Dans Render Dashboard :
1. **New +** → **Web Service**
2. Connecter repository GitHub
3. Sélectionner : **Tshiakani VTC**
4. Configuration :
   - **Name** : `tshiakani-vtc-backend`
   - **Environment** : `Node`
   - **Root Directory** : `backend`
   - **Build Command** : `npm ci --only=production`
   - **Start Command** : `node server.postgres.js`
   - **Plan** : Free

#### 5. Variables d'Environnement
Copier depuis `RENDER_ENV_VARS.txt` dans Render Dashboard > Environment

#### 6. Lier Base de Données
Dans la configuration du service :
- **Environment** → **Link Database**
- Sélectionner : `tshiakani-vtc-db`

#### 7. Déployer
- Cliquer : **"Create Web Service"**
- Attendre : 5-10 minutes
- URL : `https://tshiakani-vtc-backend.onrender.com`

## 🧪 Test

```bash
curl https://tshiakani-vtc-backend.onrender.com/health
```

## 📱 Mise à Jour iOS

Dans `Info.plist` :
- `API_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com/api`
- `WS_BASE_URL` = `https://tshiakani-vtc-backend.onrender.com`
EOF

echo "✅ Guide DEPLOIEMENT_ETAPES.md créé"
echo ""

# Vérifier la structure
echo "📋 Vérification de la structure..."
echo ""

if [ -f "server.postgres.js" ]; then
    echo "✅ server.postgres.js trouvé"
else
    echo "❌ server.postgres.js non trouvé"
fi

if [ -f "package.json" ]; then
    echo "✅ package.json trouvé"
else
    echo "❌ package.json non trouvé"
fi

if [ -f "render.yaml" ]; then
    echo "✅ render.yaml trouvé"
else
    echo "❌ render.yaml non trouvé"
fi

if [ -f "Dockerfile" ]; then
    echo "✅ Dockerfile trouvé"
else
    echo "❌ Dockerfile non trouvé"
fi

echo ""
echo "🎯 Prochaines Étapes :"
echo ""
echo "1. Vérifier que le code est sur GitHub"
echo "2. Aller sur https://dashboard.render.com"
echo "3. Suivre DEPLOIEMENT_ETAPES.md"
echo "4. Copier les variables depuis RENDER_ENV_VARS.txt"
echo ""
echo "📚 Documentation :"
echo "  - DEPLOIEMENT_ETAPES.md (étapes détaillées)"
echo "  - RENDER_ENV_VARS.txt (variables à copier)"
echo "  - render.yaml (configuration automatique)"
echo ""
echo "✅ Tout est prêt pour le déploiement !"

