#!/bin/bash

# Déploiement simple - demande juste le mot de passe

set -e

echo "🚂 Déploiement Railway + Supabase"
echo "=================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Variables Supabase
SUPABASE_URL="https://mbbcjcltvmfbfrbgfhmv.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYmNqY2x0dm1mYmZyYmdmaG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTQ2MDcsImV4cCI6MjA3ODU5MDYwN30.KZN1OYaOXmVdSUkZxsN9sIwe5_g11l2cZVuC0ESDL08"
DB_HOST="db.ecayztndohyyjaynrkaz.supabase.co"

echo "✅ Supabase configuré"
echo "   URL: $SUPABASE_URL"
echo ""

# Demander juste le mot de passe
read -sp "Entrez le mot de passe de la base de données Supabase : " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Mot de passe requis"
    exit 1
fi

# Construire la connection string
DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@${DB_HOST}:5432/postgres"

echo ""
echo "✅ Connection string générée"
echo ""

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    npm install -g @railway/cli
fi

# Vérifier la connexion
if ! railway whoami &> /dev/null 2>&1; then
    echo "🔐 Connexion à Railway..."
    open "https://railway.app/login" 2>/dev/null
    railway login
fi

echo "✅ Connecté à Railway"
echo ""

# Initialiser le projet si nécessaire
if [ ! -f ".railway" ] && [ ! -d ".railway" ]; then
    railway init --name tshiakani-vtc-backend
    railway link
fi

echo "📝 Configuration des variables..."
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

echo "✅ Variables configurées"
echo ""

# Déployer
cd backend
echo "🚀 Déploiement..."
echo ""

railway up

echo ""
echo "✅ Déploiement terminé !"
echo ""

SERVICE_URL=$(railway domain 2>/dev/null || railway status 2>/dev/null | grep -o 'https://[^ ]*\.railway\.app' | head -1 || echo "")

if [ ! -z "$SERVICE_URL" ]; then
    echo "🔗 URL : $SERVICE_URL"
    echo "$SERVICE_URL" > ../RAILWAY_URL.txt
    echo ""
    echo "📱 Mettre à jour Info.plist :"
    echo "   API_BASE_URL = $SERVICE_URL/api"
    echo "   WS_BASE_URL = $SERVICE_URL"
else
    echo "📊 Vérifier l'URL dans Railway Dashboard"
fi

echo ""

