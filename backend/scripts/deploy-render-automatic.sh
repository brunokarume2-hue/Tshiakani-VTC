#!/bin/bash

# Script de déploiement automatisé sur Render.com
# Ce script prépare tout et guide l'utilisateur étape par étape

set -e

echo "🚀 Déploiement Automatique sur Render.com"
echo "=========================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier que le code est sur GitHub
echo "📋 Vérification GitHub..."
if git remote get-url origin > /dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
    echo "✅ Repository GitHub : $REPO_URL"
    
    # Vérifier que le code est poussé
    if git ls-remote --heads origin main > /dev/null 2>&1; then
        echo "✅ Code présent sur GitHub"
    else
        echo "⚠️  Code pas encore poussé sur GitHub"
        echo "   Exécuter : git push -u origin main"
        exit 1
    fi
else
    echo "❌ Pas de remote GitHub configuré"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 ÉTAPES DE DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ouvrir Render Dashboard
echo "🌐 Ouverture de Render Dashboard..."
open "https://dashboard.render.com" 2>/dev/null || echo "   Ouvrir manuellement : https://dashboard.render.com"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1 : Créer PostgreSQL Database"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Dans Render Dashboard, cliquer 'New +' → 'PostgreSQL'"
echo "2. Configuration :"
echo "   - Name: tshiakani-vtc-db"
echo "   - Database: tshiakani_vtc"
echo "   - User: tshiakani_user"
echo "   - PostgreSQL Version: 15"
echo "   - Plan: Free"
echo "3. Cliquer 'Create Database'"
echo "4. ⚠️  ATTENDRE 1-2 minutes"
echo ""

read -p "⏳ Appuyez sur ENTER une fois la base de données créée... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2 : Créer Web Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Cliquer 'New +' → 'Web Service'"
echo "2. Connecter GitHub (si pas déjà fait)"
echo "3. Sélectionner repository : brunokarume2-hue/Tshiakani-VTC"
echo "4. Configuration :"
echo "   - Name: tshiakani-vtc-backend"
echo "   - Environment: Node"
echo "   - Branch: main"
echo "   - Root Directory: backend ⚠️ IMPORTANT"
echo "   - Build Command: npm ci --only=production"
echo "   - Start Command: node server.postgres.js"
echo "   - Plan: Free"
echo ""

# Afficher les variables d'environnement
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3 : Variables d'Environnement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans la section 'Environment Variables', ajouter :"
echo ""

cat << 'EOF'
NODE_ENV = production
PORT = 10000
JWT_SECRET = ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY = aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN = https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID = YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN = YOUR_TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM = whatsapp:+14155238886
TWILIO_CONTENT_SID = HX229f5a04fd0510ce1b071852155d3e75
STRIPE_CURRENCY = cdf
EOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4 : Lier Base de Données"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Scroller à 'Add Database' ou 'Link Database'"
echo "2. Cliquer 'Link Database'"
echo "3. Sélectionner : tshiakani-vtc-db"
echo "4. ✅ Variables DB ajoutées automatiquement"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 5 : Déployer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Cliquer 'Create Web Service'"
echo "2. ⚠️  ATTENDRE 5-10 minutes"
echo "3. Vérifier les logs de build"
echo "4. URL finale : https://tshiakani-vtc-backend.onrender.com"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le service créé et le déploiement lancé... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT EN COURS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Surveiller le déploiement dans Render Dashboard"
echo "   Les logs s'affichent en temps réel"
echo ""
echo "⏱️  Temps estimé : 5-10 minutes"
echo ""
echo "🧪 Une fois terminé, tester avec :"
echo "   curl https://tshiakani-vtc-backend.onrender.com/health"
echo ""
echo "📱 Mettre à jour l'app iOS dans Info.plist :"
echo "   API_BASE_URL = https://tshiakani-vtc-backend.onrender.com/api"
echo "   WS_BASE_URL = https://tshiakani-vtc-backend.onrender.com"
echo ""

