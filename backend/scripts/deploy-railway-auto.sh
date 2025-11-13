#!/bin/bash

# Déploiement automatique complet sur Railway

set -e

echo "🚂 Déploiement Automatique Railway"
echo "=================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "📦 Installation de Railway CLI..."
    npm install -g @railway/cli
fi

echo "✅ Railway CLI installé"
echo ""

# Vérifier la connexion
if ! railway whoami &> /dev/null 2>&1; then
    echo "🔐 Connexion à Railway..."
    echo "   Une fenêtre de navigateur va s'ouvrir pour l'authentification"
    railway login
fi

echo "✅ Connecté à Railway"
railway whoami
echo ""

# Demander la connection string Supabase
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 CONNECTION STRING SUPABASE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Supabase Dashboard :"
echo "   Settings → Database → Connection string → URI"
echo ""

read -p "Entrez la connection string Supabase : " DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    echo "❌ Connection string requise"
    exit 1
fi

echo ""
echo "✅ Connection string configurée"
echo ""

# Créer ou lier le projet Railway
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚂 CONFIGURATION RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ..

# Initialiser Railway si nécessaire
if [ ! -f ".railway" ] && [ ! -d ".railway" ]; then
    echo "📦 Initialisation du projet Railway..."
    railway init --name tshiakani-vtc-backend 2>&1 | head -10
fi

# Lier au repository GitHub
echo ""
echo "🔗 Liaison avec GitHub..."
railway link 2>&1 | head -5 || echo "⚠️  Projet peut-être déjà lié"

# Configurer les variables d'environnement
echo ""
echo "📝 Configuration des variables..."
echo ""

railway variables set DATABASE_URL="$DATABASE_URL" 2>&1
railway variables set NODE_ENV=production 2>&1
railway variables set PORT=3000 2>&1
railway variables set JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab 2>&1
railway variables set ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8 2>&1
railway variables set CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com 2>&1
# Variables Twilio - À configurer manuellement dans Railway Dashboard
# railway variables set TWILIO_ACCOUNT_SID=votre_vraie_valeur 2>&1
# railway variables set TWILIO_AUTH_TOKEN=votre_vraie_valeur 2>&1
railway variables set TWILIO_WHATSAPP_FROM=whatsapp:+14155238886 2>&1
railway variables set TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75 2>&1
railway variables set STRIPE_CURRENCY=cdf 2>&1

echo ""
echo "✅ Variables configurées"
echo ""

# Configurer le service pour utiliser le dossier backend
echo "🔧 Configuration du service..."
cd backend

# Déployer
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📤 Déploiement en cours..."
echo "⏱️  Cela peut prendre 3-5 minutes"
echo ""

railway up 2>&1 | tail -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Récupérer l'URL
echo "🔗 Récupération de l'URL..."
SERVICE_URL=$(railway domain 2>/dev/null || railway status 2>/dev/null | grep -o 'https://[^ ]*' | head -1 || echo "")

if [ ! -z "$SERVICE_URL" ] && [ "$SERVICE_URL" != "" ]; then
    echo ""
    echo "✅ URL du service : $SERVICE_URL"
    echo ""
    echo "🧪 Tester avec :"
    echo "   curl $SERVICE_URL/health"
    echo ""
    echo "📱 Mettre à jour l'app iOS dans Info.plist :"
    echo "   API_BASE_URL = $SERVICE_URL/api"
    echo "   WS_BASE_URL = $SERVICE_URL"
else
    echo ""
    echo "📊 Vérifier l'URL dans Railway Dashboard :"
    echo "   https://railway.app"
    echo ""
    echo "Ou exécuter :"
    echo "   railway status"
fi

echo ""

