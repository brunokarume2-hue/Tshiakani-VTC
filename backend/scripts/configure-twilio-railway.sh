#!/bin/bash

# Script pour configurer les variables Twilio dans Railway
# Usage: ./scripts/configure-twilio-railway.sh

set -e

echo "🔐 Configuration des Variables Twilio dans Railway"
echo "=================================================="
echo ""

# Vérifier Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI n'est pas installé"
    echo "   Installer avec: npm install -g @railway/cli"
    exit 1
fi

# Vérifier la connexion
if ! railway whoami &> /dev/null 2>&1; then
    echo "❌ Non connecté à Railway"
    echo ""
    echo "🌐 Connexion nécessaire..."
    open "https://railway.app/login" 2>/dev/null
    echo ""
    read -p "⏳ Appuyez ENTER après vous être connecté... "
    railway login
fi

echo "✅ Connecté à Railway"
railway whoami
echo ""

# Demander les valeurs Twilio
echo "📋 Entrez vos credentials Twilio :"
echo ""

read -p "TWILIO_ACCOUNT_SID: " TWILIO_ACCOUNT_SID
read -p "TWILIO_AUTH_TOKEN: " TWILIO_AUTH_TOKEN
read -p "TWILIO_WHATSAPP_FROM [whatsapp:+14155238886]: " TWILIO_WHATSAPP_FROM
TWILIO_WHATSAPP_FROM=${TWILIO_WHATSAPP_FROM:-whatsapp:+14155238886}
read -p "TWILIO_CONTENT_SID [HX229f5a04fd0510ce1b071852155d3e75]: " TWILIO_CONTENT_SID
TWILIO_CONTENT_SID=${TWILIO_CONTENT_SID:-HX229f5a04fd0510ce1b071852155d3e75}

echo ""
echo "📝 Configuration des variables dans Railway..."
echo ""

railway variables set TWILIO_ACCOUNT_SID="$TWILIO_ACCOUNT_SID" 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_AUTH_TOKEN="$TWILIO_AUTH_TOKEN" 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_WHATSAPP_FROM="$TWILIO_WHATSAPP_FROM" 2>&1 | grep -v "already exists" || true
railway variables set TWILIO_CONTENT_SID="$TWILIO_CONTENT_SID" 2>&1 | grep -v "already exists" || true

echo ""
echo "✅ Variables Twilio configurées !"
echo ""
echo "🔄 Railway va redéployer automatiquement le service"
echo ""

