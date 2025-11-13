#!/bin/bash

# Script de déploiement simplifié - Ouvre tout et guide

set -e

echo "🚀 Déploiement Simplifié sur Render"
echo "===================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Ouvrir toutes les pages nécessaires
echo "🌐 Ouverture des pages Render..."
open "https://dashboard.render.com" 2>/dev/null
open "https://dashboard.render.com/new/postgres" 2>/dev/null
open "https://dashboard.render.com/new/web-service" 2>/dev/null
open "https://dashboard.render.com/account/api-keys" 2>/dev/null

echo "✅ Pages ouvertes dans votre navigateur"
echo ""

# Afficher un guide ultra-simplifié
cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 GUIDE ULTRA-SIMPLIFIÉ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ÉTAPE 1 : Créer PostgreSQL (page 1 ouverte)
─────────────────────────────────────────────
✅ Remplir :
   Name: tshiakani-vtc-db
   Database: tshiakani_vtc
   User: tshiakani_user
   Version: 15
   Plan: Free
✅ Cliquer "Create Database"
⏳ Attendre 1-2 minutes

ÉTAPE 2 : Créer Web Service (page 2 ouverte)
─────────────────────────────────────────────
✅ Connecter GitHub → brunokarume2-hue/Tshiakani-VTC
✅ Remplir :
   Name: tshiakani-vtc-backend
   Environment: Node
   Branch: main
   Root Directory: backend ⚠️
   Build: npm ci --only=production
   Start: node server.postgres.js
   Plan: Free

ÉTAPE 3 : Variables (dans la même page)
─────────────────────────────────────────
✅ Scroller à "Environment Variables"
✅ Cliquer "Add" pour chaque ligne ci-dessous :

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

ÉTAPE 4 : Lier Database
────────────────────────
✅ Scroller à "Link Database"
✅ Sélectionner: tshiakani-vtc-db

ÉTAPE 5 : Déployer
──────────────────
✅ Cliquer "Create Web Service"
⏳ Attendre 5-10 minutes
✅ URL: https://tshiakani-vtc-backend.onrender.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ TOUT EST OUVERT - SUIVEZ LES ÉTAPES CI-DESSUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

echo ""
echo "📄 Toutes les pages sont ouvertes dans votre navigateur"
echo "   Suivez simplement les étapes ci-dessus"
echo ""

