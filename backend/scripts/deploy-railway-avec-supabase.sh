#!/bin/bash

# Déploiement automatique avec les infos Supabase fournies

set -e

echo "🚂 Déploiement Automatique Railway + Supabase"
echo "=============================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Variables Supabase fournies
SUPABASE_URL="https://mbbcjcltvmfbfrbgfhmv.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1iYmNqY2x0dm1mYmZyYmdmaG12Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTQ2MDcsImV4cCI6MjA3ODU5MDYwN30.KZN1OYaOXmVdSUkZxsN9sIwe5_g11l2cZVuC0ESDL08"
PROJECT_REF="mbbcjcltvmfbfrbgfhmv"

echo "✅ Informations Supabase reçues"
echo "   URL: $SUPABASE_URL"
echo ""

# Demander le mot de passe de la base de données
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔐 MOT DE PASSE BASE DE DONNÉES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Entrez le mot de passe de la base de données Supabase"
echo "(Le mot de passe que vous avez défini lors de la création du projet)"
echo ""

read -sp "Mot de passe : " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Mot de passe requis"
    exit 1
fi

# Construire la connection string
DATABASE_URL="postgresql://postgres:${DB_PASSWORD}@db.${PROJECT_REF}.supabase.co:5432/postgres"

echo "✅ Connection string générée"
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
    echo "🔐 CONNEXION RAILWAY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Une fenêtre de navigateur va s'ouvrir"
    echo "Connectez-vous avec votre compte Railway"
    echo ""
    read -p "Appuyez sur ENTER pour ouvrir la page de connexion... "
    
    railway login
    
    echo ""
    echo "✅ Connecté à Railway"
else
    echo "✅ Déjà connecté à Railway"
    railway whoami
fi

echo ""

# Créer ou lier le projet Railway
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚂 CONFIGURATION RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier si déjà initialisé
if [ ! -f ".railway" ] && [ ! -d ".railway" ]; then
    echo "📦 Création du projet Railway..."
    railway init --name tshiakani-vtc-backend
    echo ""
    echo "🔗 Liaison avec GitHub..."
    railway link
else
    echo "✅ Projet Railway déjà configuré"
fi

echo ""

# Configurer les variables d'environnement
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
railway variables set SUPABASE_URL="$SUPABASE_URL"
railway variables set SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo ""
echo "✅ Variables configurées"
echo ""

# Configurer le service
echo "🔧 Configuration du service..."
cd backend

# Vérifier railway.toml
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
    echo "✅ URL du service : $SERVICE_URL"
    echo ""
    echo "🧪 Tester avec :"
    echo "   curl $SERVICE_URL/health"
    echo ""
    echo "📱 Mettre à jour l'app iOS dans Info.plist :"
    echo "   API_BASE_URL = $SERVICE_URL/api"
    echo "   WS_BASE_URL = $SERVICE_URL"
    
    # Sauvegarder l'URL
    echo "$SERVICE_URL" > ../RAILWAY_URL.txt
    echo ""
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

