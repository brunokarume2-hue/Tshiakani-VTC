#!/bin/bash

# Script de configuration initiale pour Google Cloud Platform
# Usage: ./scripts/setup-gcp.sh

set -e

echo "🔧 Configuration Google Cloud Platform..."

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI n'est pas installé. Installez-le depuis https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Variables
PROJECT_ID="tshiakani-vtc"
REGION="us-central1"
DB_INSTANCE_NAME="tshiakani-vtc-db"
DB_NAME="tshiakani_vtc"
DB_USER="tshiakani_user"

# Vérifier que le projet est configuré
echo "📋 Configuration du projet GCP..."
gcloud config set project ${PROJECT_ID}

# Activer les APIs nécessaires
echo "🔌 Activation des APIs nécessaires..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  sqladmin.googleapis.com \
  containerregistry.googleapis.com \
  secretmanager.googleapis.com

# Demander le mot de passe de la base de données
read -sp "🔐 Entrez le mot de passe pour la base de données: " DB_PASSWORD
echo ""

# Créer l'instance Cloud SQL
echo "🗄️ Création de l'instance Cloud SQL..."
gcloud sql instances create ${DB_INSTANCE_NAME} \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=${REGION} \
  --root-password=${DB_PASSWORD} \
  --storage-type=SSD \
  --storage-size=10GB \
  --backup-start-time=03:00

# Créer la base de données
echo "📊 Création de la base de données..."
gcloud sql databases create ${DB_NAME} \
  --instance=${DB_INSTANCE_NAME}

# Créer un utilisateur
echo "👤 Création de l'utilisateur de la base de données..."
gcloud sql users create ${DB_USER} \
  --instance=${DB_INSTANCE_NAME} \
  --password=${DB_PASSWORD}

# Générer un JWT secret
echo "🔑 Génération du JWT secret..."
JWT_SECRET=$(openssl rand -hex 32)

# Créer les secrets dans Secret Manager
echo "🔐 Création des secrets dans Secret Manager..."
echo -n "${JWT_SECRET}" | gcloud secrets create jwt-secret --data-file=-

# Demander les autres secrets
read -sp "🔐 Entrez la clé API admin: " ADMIN_API_KEY
echo ""
echo -n "${ADMIN_API_KEY}" | gcloud secrets create admin-api-key --data-file=-

read -sp "🔐 Entrez la clé secrète Stripe: " STRIPE_SECRET_KEY
echo ""
echo -n "${STRIPE_SECRET_KEY}" | gcloud secrets create stripe-secret-key --data-file=-

echo -n "${DB_PASSWORD}" | gcloud secrets create database-password --data-file=-

echo "✅ Configuration terminée!"
echo ""
echo "📝 Informations importantes:"
echo "   - Instance Cloud SQL: ${DB_INSTANCE_NAME}"
echo "   - Base de données: ${DB_NAME}"
echo "   - Utilisateur: ${DB_USER}"
echo "   - Région: ${REGION}"
echo ""
echo "🔗 Connexion à la base de données:"
echo "   postgresql://${DB_USER}:${DB_PASSWORD}@/cloudsql/${PROJECT_ID}:${REGION}:${DB_INSTANCE_NAME}/${DB_NAME}"

