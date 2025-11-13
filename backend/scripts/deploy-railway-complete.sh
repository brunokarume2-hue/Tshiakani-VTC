#!/bin/bash

# Script de déploiement complet sur Railway avec Supabase

set -e

echo "🚂 Déploiement Automatique Railway + Supabase"
echo "=============================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "📦 Installation de Railway CLI..."
    echo ""
    echo "Exécuter :"
    echo "  npm install -g @railway/cli"
    echo "  railway login"
    echo ""
    read -p "Railway CLI est-il installé ? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Installation..."
        npm install -g @railway/cli 2>/dev/null || {
            echo "❌ Erreur d'installation"
            echo "   Installer manuellement : npm install -g @railway/cli"
            exit 1
        }
    fi
fi

echo "✅ Railway CLI installé"
echo ""

# Vérifier la connexion
if ! railway whoami &> /dev/null; then
    echo "🔐 Connexion à Railway..."
    railway login
fi

echo "✅ Connecté à Railway"
echo ""

# Demander les variables Supabase
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 VARIABLES SUPABASE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Ouvrir Supabase Dashboard :"
echo "  Settings → Database → Connection string"
echo ""

read -p "Entrez la connection string Supabase (postgresql://...) : " DATABASE_URL

if [ -z "$DATABASE_URL" ]; then
    echo "❌ Connection string requise"
    exit 1
fi

echo ""
echo "✅ Connection string configurée"
echo ""

# Créer le projet Railway
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚂 CRÉATION DU PROJET RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Initialiser Railway dans le projet
if [ ! -f "railway.json" ]; then
    echo "📦 Initialisation Railway..."
    railway init --name tshiakani-vtc-backend 2>/dev/null || {
        echo "⚠️  Projet Railway peut-être déjà initialisé"
    }
fi

# Lier au repository GitHub
echo ""
echo "🔗 Liaison avec GitHub..."
railway link 2>/dev/null || {
    echo "⚠️  Projet peut-être déjà lié"
}

# Configurer les variables
echo ""
echo "📝 Configuration des variables d'environnement..."
echo ""

railway variables set DATABASE_URL="$DATABASE_URL"
railway variables set NODE_ENV=production
railway variables set PORT=3000
railway variables set JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
railway variables set ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
railway variables set CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
# Variables Twilio - À configurer manuellement dans Railway Dashboard
# railway variables set TWILIO_ACCOUNT_SID=votre_vraie_valeur
# railway variables set TWILIO_AUTH_TOKEN=votre_vraie_valeur
railway variables set TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
railway variables set TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75
railway variables set STRIPE_CURRENCY=cdf

echo ""
echo "✅ Variables configurées"
echo ""

# Configurer le service
echo "🔧 Configuration du service..."
cd backend

# Créer railway.toml si nécessaire
if [ ! -f "railway.toml" ]; then
    cat > railway.toml << 'EOF'
[build]
builder = "NIXPACKS"

[deploy]
startCommand = "node server.postgres.js"
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10
EOF
    echo "✅ railway.toml créé"
fi

# Déployer
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📤 Déploiement en cours..."
echo ""

railway up

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Récupérer l'URL
SERVICE_URL=$(railway domain 2>/dev/null || railway status 2>/dev/null | grep -o 'https://[^ ]*' | head -1)

if [ ! -z "$SERVICE_URL" ]; then
    echo "🔗 URL du service : $SERVICE_URL"
    echo ""
    echo "🧪 Tester avec :"
    echo "   curl $SERVICE_URL/health"
    echo ""
    echo "📱 Mettre à jour l'app iOS dans Info.plist :"
    echo "   API_BASE_URL = $SERVICE_URL/api"
    echo "   WS_BASE_URL = $SERVICE_URL"
else
    echo "📊 Vérifier l'URL dans Railway Dashboard"
    echo "   railway status"
fi

echo ""

