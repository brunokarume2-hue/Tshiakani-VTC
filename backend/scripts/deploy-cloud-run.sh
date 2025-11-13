#!/bin/bash

# Script de déploiement sur Google Cloud Run
# Usage: ./scripts/deploy-cloud-run.sh

set -e

echo "🚀 Déploiement sur Google Cloud Run..."

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI n'est pas installé. Installez-le depuis https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
SERVICE_NAME="tshiakani-driver-backend"
REGION="us-central1"
IMAGE_NAME="gcr.io/${PROJECT_ID}/tshiakani-vtc-api"

# Variables d'environnement
JWT_SECRET="ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"
ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"
CORS_ORIGIN="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com"

# Variables Redis (Upstash Redis - GRATUIT ou Redis Local/Memorystore)
# Option 1: Upstash Redis (RECOMMANDÉ - GRATUIT, 10k commandes/jour)
# Créer un compte sur https://upstash.com/ et récupérer l'URL de connexion
REDIS_URL=""  # Exemple: "redis://default:token@endpoint.upstash.io:6379"

# Option 2: Redis Local ou Memorystore (alternative)
# Décommentez ces variables si vous utilisez Redis local ou Memorystore
# REDIS_HOST=""  # Exemple: "10.x.x.x" (adresse IP interne de Memorystore)
# REDIS_PORT="6379"
# REDIS_PASSWORD=""  # Laissez vide si pas de mot de passe, sinon utilisez Secret Manager
REDIS_CONNECT_TIMEOUT="10000"

# Variables Twilio (pour l'envoi de codes OTP)
# IMPORTANT: Utilisez Secret Manager pour stocker ces valeurs sensibles en production
TWILIO_ACCOUNT_SID="TWILIO_ACCOUNT_SID"  # Depuis .env
TWILIO_AUTH_TOKEN="TWILIO_AUTH_TOKEN"   # Depuis .env
TWILIO_WHATSAPP_FROM="whatsapp:+14155238886"  # Sandbox pour les tests
TWILIO_PHONE_NUMBER=""  # Optionnel
TWILIO_CONTENT_SID="HX229f5a04fd0510ce1b071852155d3e75"  # Template WhatsApp OTP

# Vérifier que le projet est configuré
echo "📋 Vérification du projet GCP..."
gcloud config set project ${PROJECT_ID}

# Builder l'image Docker
echo "🔨 Build de l'image Docker..."
echo "⏳ Cela peut prendre plusieurs minutes..."
gcloud builds submit --tag ${IMAGE_NAME} --timeout=1200s

# Vérifier que les variables Redis sont configurées
if [ -z "$REDIS_URL" ] && [ -z "$REDIS_HOST" ]; then
    echo "⚠️  ATTENTION: Redis n'est pas configuré!"
    echo "   Le backend fonctionnera en mode dégradé (sans Redis)"
    echo "   Les codes OTP seront stockés en mémoire (perdus au redémarrage)"
    echo ""
    echo "   Pour activer Upstash Redis (GRATUIT, recommandé):"
    echo "   1. Créer un compte sur https://upstash.com/"
    echo "   2. Créer une base de données Redis (tier gratuit)"
    echo "   3. Récupérer l'URL de connexion (REDIS_URL)"
    echo "   4. Configurer REDIS_URL dans ce script"
    echo "   Exemple: REDIS_URL=\"redis://default:token@endpoint.upstash.io:6379\""
    echo ""
    echo "   Alternative: Redis Memorystore (payant, ~30 $/mois):"
    echo "   gcloud redis instances create INSTANCE_NAME --region=${REGION} --tier=basic --size=1"
    echo "   Configurer REDIS_HOST avec l'adresse IP de l'instance"
    echo ""
    echo "⏳ Continuation du déploiement sans Redis (mode dégradé)..."
    echo ""
fi

# Déployer sur Cloud Run
echo "🚀 Déploiement sur Cloud Run..."
echo "📋 Configuration des variables d'environnement..."

# Construire la liste des variables d'environnement
ENV_VARS="NODE_ENV=production,PORT=8080,JWT_SECRET=${JWT_SECRET},ADMIN_API_KEY=${ADMIN_API_KEY},CORS_ORIGIN=${CORS_ORIGIN}"

# Ajouter les variables Redis si configurées
# Priorité 1: Upstash Redis (REDIS_URL)
if [ ! -z "$REDIS_URL" ]; then
    ENV_VARS="${ENV_VARS},REDIS_URL=${REDIS_URL},REDIS_CONNECT_TIMEOUT=${REDIS_CONNECT_TIMEOUT}"
    echo "✅ Upstash Redis configuré (REDIS_URL)"
# Priorité 2: Redis Local ou Memorystore (REDIS_HOST)
elif [ ! -z "$REDIS_HOST" ]; then
    ENV_VARS="${ENV_VARS},REDIS_HOST=${REDIS_HOST},REDIS_PORT=${REDIS_PORT},REDIS_CONNECT_TIMEOUT=${REDIS_CONNECT_TIMEOUT}"
    if [ ! -z "$REDIS_PASSWORD" ]; then
        ENV_VARS="${ENV_VARS},REDIS_PASSWORD=${REDIS_PASSWORD}"
    fi
    echo "✅ Redis Local/Memorystore configuré (REDIS_HOST)"
else
    echo "⚠️  Redis non configuré - mode dégradé activé"
fi

# Ajouter les variables Twilio si configurées
if [ ! -z "$TWILIO_ACCOUNT_SID" ]; then
    ENV_VARS="${ENV_VARS},TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID},TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN},TWILIO_WHATSAPP_FROM=${TWILIO_WHATSAPP_FROM},TWILIO_CONTENT_SID=${TWILIO_CONTENT_SID}"
    if [ ! -z "$TWILIO_PHONE_NUMBER" ]; then
        ENV_VARS="${ENV_VARS},TWILIO_PHONE_NUMBER=${TWILIO_PHONE_NUMBER}"
    fi
fi

gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 10 \
  --port 8080 \
  --set-env-vars "${ENV_VARS}"

# Obtenir l'URL du service
echo "📋 Récupération de l'URL du service..."
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --region ${REGION} \
  --format "value(status.url)")

echo "✅ Déploiement terminé!"
echo "🌐 URL du service: ${SERVICE_URL}"
echo ""
echo "🧪 Test de la route admin/login..."
sleep 5
curl -X POST ${SERVICE_URL}/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}' || echo "⚠️  Route non disponible (peut prendre quelques minutes)"

