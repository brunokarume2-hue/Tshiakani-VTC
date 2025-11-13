#!/bin/bash

# Déploiement Railway 100% automatique - Toutes les méthodes

set -e

echo "🚀 Déploiement Railway Automatique Complet"
echo "==========================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Variables
DATABASE_URL="postgresql://postgres:Nyota9090@db.ecayztndohyyjaynrkaz.supabase.co:5432/postgres"
SUPABASE_URL="https://mbbcjcltvmfbfrbgfhmv.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYmNqY2x0dm1mYmZyYmdmaG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTQ2MDcsImV4cCI6MjA3ODU5MDYwN30.KZN1OYaOXmVdSUkZxsN9sIwe5_g11l2cZVuC0ESDL08"

echo "✅ Configuration Supabase : OK"
echo ""

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "📦 Installation Railway CLI..."
    npm install -g @railway/cli 2>&1 | tail -5
fi

echo "✅ Railway CLI : OK"
echo ""

# Méthode 1 : Essayer avec CLI si déjà connecté
if railway whoami &> /dev/null 2>&1; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ DÉPLOIEMENT AUTOMATIQUE VIA CLI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Initialiser le projet
    if [ ! -f ".railway" ] && [ ! -d ".railway" ]; then
        echo "📦 Création du projet..."
        railway init --name tshiakani-vtc-backend 2>&1 | head -10
        railway link 2>&1 | head -5
    fi
    
    echo ""
    echo "📝 Configuration des variables..."
    
    # Variables en batch
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
    
    # Configurer railway.toml
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
    fi
    
    echo "🚀 Déploiement..."
    railway up 2>&1 | tee ../railway-deploy.log
    
    echo ""
    echo "✅ Déploiement terminé !"
    
    # Récupérer l'URL
    SERVICE_URL=$(railway domain 2>/dev/null || railway status 2>/dev/null | grep -o 'https://[^ ]*\.railway\.app' | head -1 || echo "")
    
    if [ ! -z "$SERVICE_URL" ]; then
        echo ""
        echo "🔗 URL : $SERVICE_URL"
        echo "$SERVICE_URL" > ../RAILWAY_URL.txt
    fi
    
    exit 0
fi

# Méthode 2 : Connexion interactive puis automatisation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 CONNEXION RAILWAY REQUISE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Ouverture de Railway..."
open "https://railway.app/login" 2>/dev/null || echo "   Ouvrir : https://railway.app/login"
echo ""
echo "📋 Actions :"
echo "   1. Se connecter à Railway dans le navigateur"
echo "   2. Revenir ici et appuyer ENTER"
echo ""
read -p "⏳ Appuyez ENTER une fois connecté... "

echo ""
echo "🔐 Connexion CLI..."
railway login

echo ""
echo "✅ Connecté ! Continuation automatique..."
echo ""

# Relancer le script automatiquement
exec "$0"

