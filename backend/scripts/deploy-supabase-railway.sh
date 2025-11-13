#!/bin/bash

# Script de déploiement : Supabase (DB) + Railway (Backend)

set -e

echo "🚀 Déploiement Supabase + Railway"
echo "=================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 1 : Créer Projet Supabase"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ouvrir Supabase
echo "🌐 Ouverture de Supabase..."
open "https://supabase.com/dashboard" 2>/dev/null || echo "   Ouvrir : https://supabase.com/dashboard"
open "https://supabase.com/dashboard/new" 2>/dev/null || echo "   Ouvrir : https://supabase.com/dashboard/new"

echo ""
echo "📋 Dans Supabase Dashboard :"
echo "   1. Cliquer 'New Project'"
echo "   2. Name : tshiakani-vtc"
echo "   3. Database Password : (choisir un mot de passe fort)"
echo "   4. Region : West US (ou le plus proche)"
echo "   5. Plan : Free"
echo "   6. Cliquer 'Create new project'"
echo "   7. ⚠️  ATTENDRE 2-3 minutes"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le projet Supabase créé... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2 : Récupérer les Variables Supabase"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Supabase Dashboard :"
echo "   1. Settings → API"
echo "   2. Noter :"
echo "      - Project URL"
echo "      - anon public key"
echo "      - service_role key"
echo "   3. Settings → Database"
echo "   4. Noter : Connection string"
echo ""

read -p "⏳ Appuyez sur ENTER une fois les variables notées... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3 : Créer Projet Railway"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ouvrir Railway
echo "🌐 Ouverture de Railway..."
open "https://railway.app" 2>/dev/null || echo "   Ouvrir : https://railway.app"
open "https://railway.app/new" 2>/dev/null || echo "   Ouvrir : https://railway.app/new"

echo ""
echo "📋 Dans Railway Dashboard :"
echo "   1. Cliquer 'New Project'"
echo "   2. Cliquer 'Deploy from GitHub repo'"
echo "   3. Sélectionner : brunokarume2-hue/Tshiakani-VTC"
echo "   4. Railway détectera automatiquement le backend"
echo ""

read -p "⏳ Appuyez sur ENTER une fois Railway configuré... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4 : Configurer les Variables Railway"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Railway, section Variables, ajouter :"
echo ""

cat << 'EOF'
DATABASE_URL = (Connection string de Supabase)
NODE_ENV = production
PORT = 3000
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
echo "ÉTAPE 5 : Déployer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Railway déploiera automatiquement depuis GitHub"
echo "⏱️  Temps estimé : 3-5 minutes"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le déploiement lancé... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT EN COURS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Surveiller dans Railway Dashboard"
echo "   L'URL sera disponible après le déploiement"
echo ""
echo "🧪 Tester avec :"
echo "   curl https://votre-app.railway.app/health"
echo ""

