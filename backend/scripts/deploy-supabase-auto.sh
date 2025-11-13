#!/bin/bash

# Script de déploiement automatique Supabase + Railway

set -e

echo "🚀 Déploiement Automatique Supabase + Railway"
echo "=============================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

echo "✅ Projet Supabase déjà créé"
echo ""

# Ouvrir les pages nécessaires
echo "🌐 Ouverture des pages..."
open "https://supabase.com/dashboard/project/_/settings/api" 2>/dev/null || echo "   Ouvrir : https://supabase.com/dashboard/project/_/settings/api"
open "https://supabase.com/dashboard/project/_/settings/database" 2>/dev/null || echo "   Ouvrir : https://supabase.com/dashboard/project/_/settings/database"
open "https://railway.app/new" 2>/dev/null || echo "   Ouvrir : https://railway.app/new"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 RÉCUPÉRATION DES VARIABLES SUPABASE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Supabase Dashboard (pages ouvertes) :"
echo ""
echo "1. Page 'Settings → API' :"
echo "   - Project URL : https://xxxxx.supabase.co"
echo "   - anon public key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
echo "   - service_role key : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
echo ""
echo "2. Page 'Settings → Database' :"
echo "   - Connection string : postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres"
echo ""

read -p "Entrez votre Project URL Supabase (ex: https://xxxxx.supabase.co) : " SUPABASE_URL
read -p "Entrez votre Database Password Supabase : " -s SUPABASE_PASSWORD
echo ""

# Construire la connection string
if [[ $SUPABASE_URL =~ https://([^.]+)\.supabase\.co ]]; then
    PROJECT_REF="${BASH_REMATCH[1]}"
    DATABASE_URL="postgresql://postgres:${SUPABASE_PASSWORD}@db.${PROJECT_REF}.supabase.co:5432/postgres"
    echo "✅ Connection string générée"
else
    echo "⚠️  Format URL invalide, vous devrez entrer la connection string manuellement"
    read -p "Entrez la connection string complète : " DATABASE_URL
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚂 CONFIGURATION RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Railway (page ouverte) :"
echo "   1. Cliquer 'Deploy from GitHub repo'"
echo "   2. Autoriser Railway"
echo "   3. Sélectionner : brunokarume2-hue/Tshiakani-VTC"
echo "   4. Railway détectera automatiquement le backend"
echo ""

read -p "⏳ Appuyez sur ENTER une fois Railway configuré avec GitHub... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 VARIABLES À AJOUTER DANS RAILWAY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Railway, section Variables, ajouter :"
echo ""

cat << EOF
DATABASE_URL = ${DATABASE_URL}
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
echo "💾 SAUVEGARDE DES VARIABLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Sauvegarder les variables dans un fichier
cat > ../RAILWAY_VARS.txt << EOF
# Variables d'environnement pour Railway
# Copier-coller dans Railway Dashboard > Variables

DATABASE_URL=${DATABASE_URL}
NODE_ENV=production
PORT=3000
JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab
ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com
TWILIO_ACCOUNT_SID=YOUR_TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN=YOUR_TWILIO_AUTH_TOKEN
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75
STRIPE_CURRENCY=cdf
EOF

echo "✅ Variables sauvegardées dans : RAILWAY_VARS.txt"
echo ""

read -p "⏳ Appuyez sur ENTER une fois toutes les variables ajoutées dans Railway... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Railway déploiera automatiquement depuis GitHub"
echo "⏱️  Temps estimé : 3-5 minutes"
echo ""
echo "📊 Surveiller dans Railway Dashboard"
echo "   Les logs s'affichent en temps réel"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le déploiement terminé... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 L'URL de votre backend est disponible dans Railway Dashboard"
echo ""
echo "🧪 Tester avec :"
echo "   curl https://votre-app.railway.app/health"
echo ""
echo "📱 Mettre à jour l'app iOS dans Info.plist :"
echo "   API_BASE_URL = https://votre-app.railway.app/api"
echo "   WS_BASE_URL = https://votre-app.railway.app"
echo ""

