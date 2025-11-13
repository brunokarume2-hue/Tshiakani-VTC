#!/bin/bash

# Script de déploiement automatique via API Render
# Nécessite un API Key Render

set -e

echo "🚀 Déploiement Automatique via API Render"
echo "=========================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC/backend"

# Vérifier si API Key existe
if [ -z "$RENDER_API_KEY" ]; then
    echo "📝 Pour utiliser l'API Render, vous avez besoin d'un API Key"
    echo ""
    echo "1. Aller sur : https://dashboard.render.com/account/api-keys"
    echo "2. Cliquer 'New API Key'"
    echo "3. Copier le key"
    echo "4. Exécuter : export RENDER_API_KEY='votre_key'"
    echo "5. Relancer ce script"
    echo ""
    read -p "Avez-vous un API Key Render ? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "💡 Alternative : Utiliser le script interactif"
        echo "   ./scripts/deploy-render-automatic.sh"
        exit 0
    fi
    
    echo ""
    read -sp "Entrez votre Render API Key : " RENDER_API_KEY
    echo ""
    export RENDER_API_KEY
fi

echo "✅ API Key configuré"
echo ""

# Vérifier GitHub
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|https://github.com/||')
echo "📋 Repository GitHub : $REPO_URL"

# Créer la base de données PostgreSQL
echo ""
echo "📦 Création de la base de données PostgreSQL..."
echo ""

DB_RESPONSE=$(curl -s -X POST "https://api.render.com/v1/databases" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tshiakani-vtc-db",
    "database": "tshiakani_vtc",
    "user": "tshiakani_user",
    "plan": "free",
    "postgresMajorVersion": 15
  }')

if echo "$DB_RESPONSE" | grep -q "database"; then
    echo "✅ Base de données créée"
    DB_ID=$(echo "$DB_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   ID: $DB_ID"
else
    echo "⚠️  Erreur ou base déjà existante"
    echo "   Réponse: $DB_RESPONSE"
fi

# Créer le service web
echo ""
echo "🌐 Création du service web..."
echo ""

SERVICE_RESPONSE=$(curl -s -X POST "https://api.render.com/v1/services" \
  -H "Authorization: Bearer $RENDER_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"tshiakani-vtc-backend\",
    \"type\": \"web_service\",
    \"repo\": \"https://github.com/$REPO_URL\",
    \"branch\": \"main\",
    \"rootDir\": \"backend\",
    \"buildCommand\": \"npm ci --only=production\",
    \"startCommand\": \"node server.postgres.js\",
    \"plan\": \"free\",
    \"envVars\": [
      {\"key\": \"NODE_ENV\", \"value\": \"production\"},
      {\"key\": \"PORT\", \"value\": \"10000\"},
      {\"key\": \"JWT_SECRET\", \"value\": \"ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab\"},
      {\"key\": \"ADMIN_API_KEY\", \"value\": \"aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8\"},
      {\"key\": \"CORS_ORIGIN\", \"value\": \"https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com\"},
      {\"key\": \"TWILIO_ACCOUNT_SID\", \"value\": \"YOUR_TWILIO_ACCOUNT_SID\"},
      {\"key\": \"TWILIO_AUTH_TOKEN\", \"value\": \"YOUR_TWILIO_AUTH_TOKEN\"},
      {\"key\": \"TWILIO_WHATSAPP_FROM\", \"value\": \"whatsapp:+14155238886\"},
      {\"key\": \"TWILIO_CONTENT_SID\", \"value\": \"HX229f5a04fd0510ce1b071852155d3e75\"},
      {\"key\": \"STRIPE_CURRENCY\", \"value\": \"cdf\"}
    ]
  }")

if echo "$SERVICE_RESPONSE" | grep -q "service"; then
    echo "✅ Service web créé"
    SERVICE_ID=$(echo "$SERVICE_RESPONSE" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   ID: $SERVICE_ID"
    echo ""
    echo "🔗 URL: https://tshiakani-vtc-backend.onrender.com"
else
    echo "❌ Erreur lors de la création du service"
    echo "   Réponse: $SERVICE_RESPONSE"
    echo ""
    echo "💡 Vérifier :"
    echo "   1. L'API Key est valide"
    echo "   2. Le repository GitHub est accessible"
    echo "   3. Vous avez les permissions nécessaires"
fi

echo ""
echo "✅ Déploiement lancé !"
echo "   Surveiller dans Render Dashboard : https://dashboard.render.com"

