#!/bin/bash

# Script de déploiement sur Google App Engine
# Usage: ./scripts/deploy-app-engine.sh

set -e

echo "🚀 Déploiement sur Google App Engine..."

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI n'est pas installé. Installez-le depuis https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Variables
PROJECT_ID="tshiakani-vtc"

# Vérifier que le projet est configuré
echo "📋 Vérification du projet GCP..."
gcloud config set project ${PROJECT_ID}

# Déployer sur App Engine
echo "🚀 Déploiement sur App Engine..."
gcloud app deploy app.yaml

echo "✅ Déploiement terminé!"
echo "🌐 URL du service: https://${PROJECT_ID}.appspot.com"

