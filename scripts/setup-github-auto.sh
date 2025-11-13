#!/bin/bash

# Script pour automatiser la création du repository GitHub

set -e

echo "🚀 Configuration GitHub Automatique"
echo "===================================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier l'état Git
echo "📋 Vérification de l'état Git..."
git status --short | head -5
echo ""

# Vérifier si remote existe déjà
if git remote get-url origin > /dev/null 2>&1; then
    echo "✅ Remote GitHub déjà configuré :"
    git remote get-url origin
    echo ""
    read -p "Pousser le code maintenant ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin main && echo "✅ Code poussé avec succès !" || echo "❌ Erreur lors du push"
    fi
    exit 0
fi

echo "📝 Le repository GitHub n'existe pas encore"
echo ""
echo "🌐 Ouverture de GitHub dans votre navigateur..."
echo ""

# Ouvrir GitHub dans le navigateur
open "https://github.com/new?name=Tshiakani-VTC&description=Backend+et+app+iOS+pour+Tshiakani+VTC&visibility=public" 2>/dev/null || {
    echo "⚠️  Impossible d'ouvrir le navigateur automatiquement"
    echo "   Ouvrir manuellement : https://github.com/new"
}

echo ""
echo "⏳ En attendant que vous créiez le repository..."
echo ""
echo "📋 Instructions :"
echo "   1. Dans la page GitHub qui s'est ouverte :"
echo "      - Repository name : Tshiakani-VTC (déjà rempli)"
echo "      - Description : Backend et app iOS pour Tshiakani VTC (déjà rempli)"
echo "      - Visibility : Public (déjà sélectionné)"
echo "      - NE PAS cocher 'Add a README file'"
echo "      - Cliquer 'Create repository'"
echo ""
echo "   2. Après la création, copier l'URL du repository"
echo "      (ex: https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git)"
echo ""

# Attendre que l'utilisateur crée le repository
read -p "Appuyez sur ENTER une fois le repository créé sur GitHub... " 

echo ""
echo "📝 Entrez l'URL du repository GitHub :"
read -p "URL (ex: https://github.com/USERNAME/Tshiakani-VTC.git): " repo_url

if [ -z "$repo_url" ]; then
    echo "❌ URL vide, annulation"
    exit 1
fi

echo ""
echo "🔗 Configuration du remote..."
git remote add origin "$repo_url" 2>/dev/null || {
    echo "⚠️  Remote existe déjà, mise à jour..."
    git remote set-url origin "$repo_url"
}

echo "✅ Remote configuré"
echo ""

# Renommer la branche en main si nécessaire
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "📝 Renommage de la branche en 'main'..."
    git branch -M main
fi

echo ""
echo "📤 Poussée du code vers GitHub..."
echo ""

# Pousser le code
if git push -u origin main; then
    echo ""
    echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
    echo ""
    echo "🎉 Le code a été poussé sur GitHub avec succès !"
    echo ""
    echo "🔗 Repository : $repo_url"
    echo ""
    echo "🚀 Prochaine étape :"
    echo "   Aller sur https://dashboard.render.com"
    echo "   Suivre : backend/GUIDE_COMPLET_RENDER.md"
else
    echo ""
    echo "❌ Erreur lors du push"
    echo ""
    echo "💡 Solutions possibles :"
    echo "   1. Vérifier que le repository existe sur GitHub"
    echo "   2. Vérifier votre authentification GitHub"
    echo "   3. Utiliser un Personal Access Token :"
    echo "      - Aller sur https://github.com/settings/tokens"
    echo "      - Générer un token avec permission 'repo'"
    echo "      - Utiliser le token comme mot de passe"
    echo ""
    echo "📝 Commandes manuelles :"
    echo "   git push -u origin main"
fi

