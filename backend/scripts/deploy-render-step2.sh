#!/bin/bash

# Script pour les étapes 2-5 du déploiement Render

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 2 : Créer Web Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Dans Render Dashboard, cliquer 'New +' → 'Web Service'"
echo "2. Connecter GitHub (si pas déjà fait) :"
echo "   - Cliquer 'Connect GitHub'"
echo "   - Autoriser Render"
echo "   - Sélectionner repository : brunokarume2-hue/Tshiakani-VTC"
echo ""
echo "3. Configuration du service :"
echo "   - Name: tshiakani-vtc-backend"
echo "   - Environment: Node"
echo "   - Region: Oregon (US West) ou le plus proche"
echo "   - Branch: main"
echo "   - Root Directory: backend ⚠️ IMPORTANT"
echo "   - Build Command: npm ci --only=production"
echo "   - Start Command: node server.postgres.js"
echo "   - Plan: Free"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le service configuré (mais pas encore créé)... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 3 : Variables d'Environnement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans la section 'Environment Variables', ajouter ces variables :"
echo ""

# Afficher les variables avec formatage clair
cat << 'EOF'
┌─────────────────────┬─────────────────────────────────────────────────────────────────────────┐
│ Key                 │ Value                                                                   │
├─────────────────────┼─────────────────────────────────────────────────────────────────────────┤
│ NODE_ENV            │ production                                                              │
│ PORT                │ 10000                                                                   │
│ JWT_SECRET          │ ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6│
│                     │ e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab                 │
│ ADMIN_API_KEY       │ aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8        │
│ CORS_ORIGIN         │ https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebas│
│                     │ eapp.com                                                                │
│ TWILIO_ACCOUNT_SID  │ YOUR_TWILIO_ACCOUNT_SID                                      │
│ TWILIO_AUTH_TOKEN   │ YOUR_TWILIO_AUTH_TOKEN                                                │
│ TWILIO_WHATSAPP_FROM│ whatsapp:+14155238886                                                  │
│ TWILIO_CONTENT_SID  │ HX229f5a04fd0510ce1b071852155d3e75                                      │
│ STRIPE_CURRENCY     │ cdf                                                                     │
└─────────────────────┴─────────────────────────────────────────────────────────────────────────┘
EOF

echo ""
echo "💡 Pour chaque variable :"
echo "   1. Cliquer 'Add Environment Variable'"
echo "   2. Entrer le Key (nom)"
echo "   3. Entrer le Value (valeur)"
echo "   4. Cliquer 'Save'"
echo ""

read -p "⏳ Appuyez sur ENTER une fois toutes les variables ajoutées... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 4 : Lier Base de Données"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Scroller jusqu'à 'Add Database' ou 'Link Database'"
echo "2. Cliquer 'Link Database'"
echo "3. Sélectionner : tshiakani-vtc-db"
echo "4. ✅ Les variables DB seront ajoutées automatiquement :"
echo "   - DATABASE_URL"
echo "   - DB_HOST"
echo "   - DB_PORT"
echo "   - DB_USER"
echo "   - DB_PASSWORD"
echo "   - DB_NAME"
echo ""

read -p "⏳ Appuyez sur ENTER une fois la base de données liée... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ÉTAPE 5 : Déployer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Cliquer 'Create Web Service' (en bas de la page)"
echo "2. ⚠️  ATTENDRE 5-10 minutes"
echo "3. Surveiller les logs de build en temps réel"
echo "4. Une fois terminé, l'URL sera :"
echo "   https://tshiakani-vtc-backend.onrender.com"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le déploiement lancé... "

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT EN COURS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Surveiller le déploiement dans Render Dashboard"
echo "   - Les logs s'affichent en temps réel"
echo "   - Vérifier qu'il n'y a pas d'erreurs"
echo ""
echo "⏱️  Temps estimé : 5-10 minutes"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TEST APRÈS DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Une fois le déploiement terminé, tester avec :"
echo ""
echo "curl https://tshiakani-vtc-backend.onrender.com/health"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 MISE À JOUR APP iOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Dans Info.plist, mettre à jour :"
echo ""
echo "API_BASE_URL = https://tshiakani-vtc-backend.onrender.com/api"
echo "WS_BASE_URL = https://tshiakani-vtc-backend.onrender.com"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

