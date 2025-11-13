#!/bin/bash

# Script final pour configurer Railway

set -e

echo "🚀 Configuration Railway"
echo "======================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "📦 Installation Railway CLI..."
    npm install -g @railway/cli
fi

echo "✅ Railway CLI installé"
echo ""

# Connexion
if ! railway whoami &> /dev/null 2>&1; then
    echo "🔐 Connexion à Railway..."
    echo ""
    echo "📋 Actions :"
    echo "   1. Railway va s'ouvrir dans votre navigateur"
    echo "   2. Connectez-vous"
    echo "   3. Revenez ici et appuyez ENTER"
    echo ""
    open "https://railway.app/login" 2>/dev/null
    read -p "⏳ Appuyez ENTER une fois connecté... "
    
    railway login
fi

echo "✅ Connecté à Railway"
railway whoami
echo ""

# Lier le projet
echo "🔗 Liaison avec le projet Railway..."
railway link -p 62642a48-f2d2-4818-a18b-b147812afff7
echo "✅ Projet lié"
echo ""

# Configurer les variables Twilio (nouvelle syntaxe)
echo "📝 Configuration des variables Twilio..."
echo ""

railway variables --set "TWILIO_ACCOUNT_SID=AC80018f519898d589fc4e9f07f79e0327" 2>&1 || true
railway variables --set "TWILIO_AUTH_TOKEN=PF6AMX1753UD629JDFF1D7GE" 2>&1 || true
railway variables --set "TWILIO_WHATSAPP_FROM=whatsapp:+14155238886" 2>&1 || true
railway variables --set "TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75" 2>&1 || true

echo ""
echo "✅ Variables Twilio configurées !"
echo ""
echo "🔄 Railway va redéployer automatiquement"
echo ""
echo "✅ Tout est prêt !"

