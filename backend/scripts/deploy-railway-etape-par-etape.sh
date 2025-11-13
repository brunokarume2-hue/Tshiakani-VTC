#!/bin/bash

# Déploiement étape par étape avec guide

set -e

echo "🚂 Déploiement Railway + Supabase"
echo "=================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Variables configurées
DATABASE_URL="postgresql://postgres:Nyota9090@db.ecayztndohyyjaynrkaz.supabase.co:5432/postgres"
SUPABASE_URL="https://mbbcjcltvmfbfrbgfhmv.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYmNqY2x0dm1mYmZyYmdmaG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTQ2MDcsImV4cCI6MjA3ODU5MDYwN30.KZN1OYaOXmVdSUkZxsN9sIwe5_g11l2cZVuC0ESDL08"

echo "✅ Connection string Supabase configurée"
echo ""

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "📦 Installation de Railway CLI..."
    npm install -g @railway/cli
fi

echo "✅ Railway CLI installé"
echo ""

# Vérifier la connexion
if ! railway whoami &> /dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 ÉTAPE 1 : CONNEXION RAILWAY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🌐 Ouverture de Railway dans votre navigateur..."
    open "https://railway.app/login" 2>/dev/null || echo "   Ouvrir : https://railway.app/login"
    echo ""
    echo "📋 Actions :"
    echo "   1. Se connecter avec votre compte Railway"
    echo "   2. Revenir ici et appuyer ENTER"
    echo ""
    read -p "⏳ Appuyez sur ENTER une fois connecté à Railway... "
    
    echo ""
    echo "🔐 Connexion via CLI..."
    railway login
    
    echo ""
    echo "✅ Connecté à Railway"
    railway whoami
else
    echo "✅ Déjà connecté à Railway"
    railway whoami
fi

echo ""

# Initialiser le projet
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚂 ÉTAPE 2 : CONFIGURATION RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ ! -f ".railway" ] && [ ! -d ".railway" ]; then
    echo "📦 Création du projet Railway..."
    railway init --name tshiakani-vtc-backend
    echo ""
    echo "🔗 Liaison avec GitHub..."
    railway link
    echo ""
    echo "✅ Projet créé et lié"
else
    echo "✅ Projet Railway déjà configuré"
fi

echo ""

# Configurer les variables
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 ÉTAPE 3 : VARIABLES D'ENVIRONNEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configuration des variables..."
echo ""

railway variables set DATABASE_URL="$DATABASE_URL" 2>&1 | grep -v "already exists" || true
railway variables set NODE_ENV=production 2>&1 | grep -v "already exists" || true
railway variables set PORT=3000 2>&1 | grep -v "already exists" || true
railway variables set JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab 2>&1 | grep -v "already exists" || true
railway variables set ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8 2>&1 | grep -v "already exists" || true
railway variables set CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_WHATSAPP_FROM=whatsapp:+14155238886 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75 2>&1 | grep -v "already exists" || true
railway variables set STRIPE_CURRENCY=cdf 2>&1 | grep -v "already exists" || true
railway variables set SUPABASE_URL="$SUPABASE_URL" 2>&1 | grep -v "already exists" || true
railway variables set SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" 2>&1 | grep -v "already exists" || true

echo ""
echo "✅ Variables configurées"
echo ""

# Configurer le service
cd backend

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
echo "🚀 ÉTAPE 4 : DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📤 Déploiement en cours..."
echo "⏱️  Cela peut prendre 3-5 minutes"
echo ""

railway up

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Récupérer l'URL
echo "🔗 Récupération de l'URL..."
SERVICE_URL=$(railway domain 2>/dev/null || railway status 2>/dev/null | grep -o 'https://[^ ]*\.railway\.app' | head -1 || echo "")

if [ ! -z "$SERVICE_URL" ] && [ "$SERVICE_URL" != "" ]; then
    echo ""
    echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
    echo ""
    echo "🔗 URL du service : $SERVICE_URL"
    echo ""
    echo "🧪 Tester avec :"
    echo "   curl $SERVICE_URL/health"
    echo ""
    echo "📱 Mettre à jour l'app iOS dans Info.plist :"
    echo "   API_BASE_URL = $SERVICE_URL/api"
    echo "   WS_BASE_URL = $SERVICE_URL"
    echo ""
    
    # Sauvegarder l'URL
    echo "$SERVICE_URL" > ../RAILWAY_URL.txt
    echo "✅ URL sauvegardée dans : RAILWAY_URL.txt"
else
    echo ""
    echo "📊 Vérifier l'URL dans Railway Dashboard :"
    echo "   https://railway.app"
    echo ""
    echo "Ou exécuter :"
    echo "   railway status"
    echo "   railway domain"
fi

echo ""

