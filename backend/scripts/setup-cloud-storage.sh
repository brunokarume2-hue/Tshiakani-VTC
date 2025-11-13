#!/bin/bash

# Script pour configurer Google Cloud Storage pour Tshiakani VTC
# Ce script crée le bucket et configure les permissions

set -e

echo "🚀 Configuration de Google Cloud Storage pour Tshiakani VTC..."

# Variables
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
BUCKET_NAME="${GCS_BUCKET_NAME:-tshiakani-vtc-documents}"
REGION="${GCS_REGION:-us-central1}"

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI n'est pas installé. Installez-le depuis https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Vérifier que le projet est configuré
echo "📋 Vérification du projet GCP..."
gcloud config set project ${PROJECT_ID}

# Activer l'API Cloud Storage
echo "🔧 Activation de l'API Cloud Storage..."
gcloud services enable storage.googleapis.com

# Créer le bucket (s'il n'existe pas)
echo "📦 Création du bucket Cloud Storage..."
if gsutil ls -b gs://${BUCKET_NAME} &> /dev/null; then
    echo "✅ Le bucket ${BUCKET_NAME} existe déjà"
else
    echo "📦 Création du bucket ${BUCKET_NAME}..."
    gsutil mb -p ${PROJECT_ID} -l ${REGION} -c STANDARD gs://${BUCKET_NAME}
    echo "✅ Bucket créé avec succès"
fi

# Configurer les permissions du bucket
echo "🔐 Configuration des permissions..."
# Rendre le bucket privé (pas d'accès public)
gsutil iam ch allUsers:objectViewer gs://${BUCKET_NAME} 2>/dev/null || echo "⚠️ Permissions déjà configurées"

# Configurer CORS (si le fichier existe)
if [ -f "backend/config/cors-storage.json" ]; then
    echo "🌐 Configuration CORS..."
    gsutil cors set backend/config/cors-storage.json gs://${BUCKET_NAME}
    echo "✅ CORS configuré"
else
    echo "⚠️ Fichier CORS non trouvé, création d'un fichier par défaut..."
    mkdir -p backend/config
    cat > backend/config/cors-storage.json << EOF
[
  {
    "origin": ["https://tshiakani-vtc.firebaseapp.com", "https://tshiakani-vtc.web.app"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "responseHeader": ["Content-Type", "Authorization", "Content-Length"],
    "maxAgeSeconds": 3600
  }
]
EOF
    gsutil cors set backend/config/cors-storage.json gs://${BUCKET_NAME}
    echo "✅ CORS configuré avec les paramètres par défaut"
fi

# Configurer la versioning (optionnel mais recommandé)
echo "📝 Configuration de la versioning..."
gsutil versioning set on gs://${BUCKET_NAME}

# Configurer la lifecycle (supprimer les anciennes versions après 90 jours)
echo "🔄 Configuration de la lifecycle..."
cat > /tmp/lifecycle.json << EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {
          "numNewerVersions": 1,
          "age": 90
        }
      }
    ]
  }
}
EOF
gsutil lifecycle set /tmp/lifecycle.json gs://${BUCKET_NAME}
rm /tmp/lifecycle.json

# Afficher les informations du bucket
echo ""
echo "✅ Configuration terminée!"
echo ""
echo "📋 Informations du bucket:"
echo "   Nom: ${BUCKET_NAME}"
echo "   Région: ${REGION}"
echo "   URL: gs://${BUCKET_NAME}"
echo ""
echo "🔧 Variables d'environnement à configurer:"
echo "   GCS_BUCKET_NAME=${BUCKET_NAME}"
echo "   GCP_PROJECT_ID=${PROJECT_ID}"
echo ""
echo "📝 Pour utiliser ce bucket dans votre application:"
echo "   1. Configurez les variables d'environnement dans Cloud Run"
echo "   2. Donnez les permissions IAM nécessaires au service account"
echo "   3. Utilisez StorageService dans votre code backend"
echo ""

