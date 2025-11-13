#!/bin/bash

# Script de déploiement sur Firebase Hosting
# Usage: ./scripts/deploy-firebase.sh

set -e

echo "🚀 Déploiement sur Firebase Hosting..."

# Vérifier que firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI n'est pas installé. Installez-le avec: npm install -g firebase-tools"
    exit 1
fi

# Vérifier que l'utilisateur est connecté
if ! firebase projects:list &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Firebase. Connectez-vous avec: firebase login"
    exit 1
fi

# Aller dans le dossier admin-dashboard
cd admin-dashboard

# Installer les dépendances
echo "📦 Installation des dépendances..."
npm install

# Build du dashboard
echo "🔨 Build du dashboard..."
npm run build

# Revenir à la racine
cd ..

# Déployer sur Firebase Hosting
echo "🚀 Déploiement sur Firebase Hosting..."
firebase deploy --only hosting

echo "✅ Déploiement terminé!"
echo "🌐 URL du dashboard: https://tshiakani-vtc.firebaseapp.com"

