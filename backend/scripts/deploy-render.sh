#!/bin/bash

# Script de déploiement sur Render.com
# Usage: ./scripts/deploy-render.sh

set -e

echo "🚀 Guide de Déploiement sur Render.com"
echo "========================================"
echo ""

# Vérifier que le code est sur GitHub
echo "📋 Étape 1 : Vérification GitHub"
echo "   Assurez-vous que votre code est sur GitHub"
echo "   Repository : Votre repository GitHub"
echo ""

# Afficher les instructions
echo "📋 Étape 2 : Créer un compte Render"
echo "   1. Aller sur https://render.com"
echo "   2. Cliquer sur 'Get Started for Free'"
echo "   3. S'inscrire avec GitHub (recommandé)"
echo ""

echo "📋 Étape 3 : Créer la Base de Données PostgreSQL"
echo "   1. Dans Render Dashboard, cliquer sur 'New +' > 'PostgreSQL'"
echo "   2. Configurer :"
echo "      - Name: tshiakani-vtc-db"
echo "      - Database: tshiakani_vtc"
echo "      - User: tshiakani_user"
echo "      - Plan: Free (ou Starter pour \$7/mois)"
echo "   3. Cliquer sur 'Create Database'"
echo "   4. Noter l'URL de connexion (DATABASE_URL)"
echo ""

echo "📋 Étape 4 : Créer le Service Web"
echo "   1. Dans Render Dashboard, cliquer sur 'New +' > 'Web Service'"
echo "   2. Connecter votre repository GitHub"
echo "   3. Sélectionner le repository 'Tshiakani VTC'"
echo "   4. Sélectionner la branche 'main' (ou 'master')"
echo "   5. Configurer :"
echo "      - Name: tshiakani-vtc-backend"
echo "      - Environment: Node"
echo "      - Root Directory: backend (si backend est dans un sous-dossier)"
echo "      - Build Command: npm ci --only=production"
echo "      - Start Command: node server.postgres.js"
echo "      - Plan: Free (ou Starter pour \$7/mois)"
echo ""

echo "📋 Étape 5 : Configurer les Variables d'Environnement"
echo ""
echo "   Variables à ajouter dans Render :"
echo ""
echo "   NODE_ENV=production"
echo "   PORT=10000"
echo "   JWT_SECRET=ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"
echo "   ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
echo "   CORS_ORIGIN=https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"
echo "   TWILIO_ACCOUNT_SID=TWILIO_ACCOUNT_SID"
echo "   TWILIO_AUTH_TOKEN=TWILIO_AUTH_TOKEN"
echo "   TWILIO_WHATSAPP_FROM=whatsapp:+14155238886"
echo "   TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75"
echo ""
echo "   Variables de base de données (ajoutées automatiquement si vous liez la DB) :"
echo "   - DATABASE_URL (automatique)"
echo "   - DB_HOST (automatique)"
echo "   - DB_PORT (automatique)"
echo "   - DB_USER (automatique)"
echo "   - DB_PASSWORD (automatique)"
echo "   - DB_NAME (automatique)"
echo ""

echo "📋 Étape 6 : Lier la Base de Données"
echo "   1. Dans la configuration du service web, aller dans 'Environment'"
echo "   2. Cliquer sur 'Link Database'"
echo "   3. Sélectionner 'tshiakani-vtc-db'"
echo ""

echo "📋 Étape 7 : Déployer"
echo "   1. Cliquer sur 'Create Web Service'"
echo "   2. Attendre la fin du déploiement (5-10 minutes)"
echo "   3. L'URL sera disponible dans le dashboard"
echo ""

echo "✅ Après le déploiement :"
echo ""
echo "   1. Tester la route health :"
echo "      curl https://tshiakani-vtc-backend.onrender.com/health"
echo ""
echo "   2. Mettre à jour l'URL de l'API dans l'app iOS (Info.plist) :"
echo "      API_BASE_URL = https://tshiakani-vtc-backend.onrender.com/api"
echo "      WS_BASE_URL = https://tshiakani-vtc-backend.onrender.com"
echo ""

echo "📚 Documentation complète : backend/DEPLOIEMENT_RENDER.md"
echo ""
echo "🌐 Lien direct : https://dashboard.render.com"

