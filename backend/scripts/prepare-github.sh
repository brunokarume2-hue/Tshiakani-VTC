#!/bin/bash

# Script pour préparer le code pour GitHub et Render

set -e

echo "🔧 Préparation pour GitHub et Render"
echo "===================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier l'état Git
echo "📋 Vérification de l'état Git..."
git status --short | head -10

echo ""
echo "⚠️  IMPORTANT : Le code doit être sur GitHub pour Render"
echo ""
echo "📝 Étapes à suivre :"
echo ""
echo "1. Créer un repository sur GitHub.com :"
echo "   - Aller sur https://github.com/new"
echo "   - Nom : Tshiakani-VTC (ou votre choix)"
echo "   - Visibilité : Public ou Private"
echo "   - NE PAS initialiser avec README"
echo "   - Cliquer 'Create repository'"
echo ""
echo "2. Dans le terminal, exécuter :"
echo ""
echo "   cd \"/Users/admin/Documents/Tshiakani VTC\""
echo "   git add ."
echo "   git commit -m \"Prepare for Render deployment\""
echo "   git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git"
echo "   git push -u origin main"
echo ""
echo "3. Ensuite, dans Render Dashboard :"
echo "   - Connecter GitHub"
echo "   - Sélectionner le repository"
echo "   - Suivre INSTRUCTIONS_RENDER_CHROME.md"
echo ""

# Vérifier si des changements non commités
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Il y a des changements non commités"
    echo "   Voulez-vous les commiter maintenant ? (y/n)"
    read -r response
    if [ "$response" = "y" ]; then
        git add .
        git commit -m "Prepare for Render deployment"
        echo "✅ Changements commités"
    fi
fi

echo ""
echo "✅ Préparation terminée"
echo "   Suivez les étapes ci-dessus pour pousser sur GitHub"

