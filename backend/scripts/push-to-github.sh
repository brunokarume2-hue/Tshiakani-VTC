#!/bin/bash

# Script pour pousser le backend sur GitHub

set -e

echo "🚀 Préparation pour GitHub"
echo "=========================="
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier l'état Git
echo "📋 Vérification de l'état Git..."
echo ""

# Afficher les changements
echo "📝 Fichiers modifiés/nouveaux :"
git status --short | head -20
echo ""

# Vérifier si on est dans un repo Git
if [ ! -d ".git" ]; then
    echo "⚠️  Pas de repository Git initialisé"
    echo "   Initialisation..."
    git init
    echo "✅ Repository initialisé"
fi

# Ajouter tous les fichiers
echo "📦 Ajout des fichiers..."
git add .
echo "✅ Fichiers ajoutés"
echo ""

# Commit
echo "💾 Création du commit..."
git commit -m "Prepare backend for Render deployment" || echo "⚠️  Pas de changements à commiter"
echo ""

# Vérifier si remote existe
if git remote get-url origin > /dev/null 2>&1; then
    echo "✅ Remote GitHub déjà configuré :"
    git remote get-url origin
    echo ""
    echo "📤 Pousser vers GitHub..."
    echo ""
    echo "⚠️  Si vous n'avez pas encore créé le repository sur GitHub :"
    echo "   1. Aller sur https://github.com/new"
    echo "   2. Créer un repository : Tshiakani-VTC"
    echo "   3. NE PAS initialiser avec README"
    echo "   4. Puis exécuter : git push -u origin main"
    echo ""
    read -p "Voulez-vous pousser maintenant ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push -u origin main || echo "⚠️  Erreur lors du push. Vérifiez que le repository existe sur GitHub."
    fi
else
    echo "⚠️  Pas de remote GitHub configuré"
    echo ""
    echo "📝 Étapes à suivre :"
    echo ""
    echo "1. Créer un repository sur GitHub :"
    echo "   - Aller sur https://github.com/new"
    echo "   - Nom : Tshiakani-VTC"
    echo "   - Visibilité : Public ou Private"
    echo "   - NE PAS cocher 'Add a README file'"
    echo "   - Cliquer 'Create repository'"
    echo ""
    echo "2. Copier l'URL du repository (ex: https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git)"
    echo ""
    echo "3. Exécuter cette commande :"
    echo "   git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
    read -p "Avez-vous créé le repository sur GitHub ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Entrez l'URL du repository GitHub : " repo_url
        if [ ! -z "$repo_url" ]; then
            git remote add origin "$repo_url"
            git branch -M main 2>/dev/null || echo "⚠️  Branche déjà 'main'"
            echo ""
            echo "📤 Pousser vers GitHub..."
            git push -u origin main || echo "⚠️  Erreur. Vérifiez l'URL."
        fi
    fi
fi

echo ""
echo "✅ Préparation terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Vérifier que le code est sur GitHub"
echo "   2. Aller sur https://dashboard.render.com"
echo "   3. Suivre GUIDE_COMPLET_RENDER.md"

