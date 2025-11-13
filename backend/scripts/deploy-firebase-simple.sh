#!/bin/bash

# Script de déploiement simplifié sur Firebase

set -e

echo "🔥 Déploiement sur Firebase"
echo "============================"
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI non installé"
    echo ""
    echo "📦 Installation :"
    echo "   npm install -g firebase-tools"
    echo "   firebase login"
    exit 1
fi

echo "✅ Firebase CLI installé"
echo ""

# Vérifier la connexion
if ! firebase projects:list &> /dev/null; then
    echo "⚠️  Pas connecté à Firebase"
    echo ""
    echo "🔐 Connexion..."
    firebase login
fi

echo "✅ Connecté à Firebase"
echo ""

# Afficher les projets disponibles
echo "📋 Projets Firebase disponibles :"
firebase projects:list

echo ""
read -p "Entrez le Project ID Firebase (ex: tshiakani-vtc-99cea) : " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Project ID requis"
    exit 1
fi

# Sélectionner le projet
echo ""
echo "🔧 Sélection du projet..."
firebase use "$PROJECT_ID"

# Vérifier la configuration
echo ""
echo "📋 Configuration actuelle :"
cat firebase.json | head -20

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 DÉPLOIEMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Firebase va déployer :"
echo "  ✅ Functions (backend)"
echo "  ✅ Hosting (admin dashboard)"
echo ""

read -p "Continuer le déploiement ? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

echo ""
echo "📤 Déploiement en cours..."
echo ""

# Déployer
firebase deploy

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DÉPLOIEMENT TERMINÉ !"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔗 URLs :"
echo "   Backend API : https://$PROJECT_ID.cloudfunctions.net/api"
echo "   Dashboard : https://$PROJECT_ID.web.app"
echo ""

