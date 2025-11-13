#!/bin/bash

# Script pour pousser avec authentification GitHub

set -e

cd "/Users/admin/Documents/Tshiakani VTC"

echo "🔐 Authentification GitHub"
echo "=========================="
echo ""
echo "GitHub nécessite une authentification pour pousser le code."
echo ""
echo "📋 Option 1 : Personal Access Token (Recommandé)"
echo "   1. Aller sur : https://github.com/settings/tokens"
echo "   2. Cliquer 'Generate new token (classic)'"
echo "   3. Nom : Tshiakani-VTC"
echo "   4. Cocher : repo (accès complet)"
echo "   5. Cliquer 'Generate token'"
echo "   6. COPIER LE TOKEN (il ne sera affiché qu'une fois)"
echo ""
echo "📋 Option 2 : Utiliser GitHub CLI"
echo "   gh auth login"
echo ""
read -p "Avez-vous un Personal Access Token ? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Entrez votre nom d'utilisateur GitHub : " github_username
    read -sp "Entrez votre Personal Access Token : " github_token
    echo ""
    echo ""
    echo "📤 Poussée du code..."
    
    # Utiliser le token dans l'URL
    git remote set-url origin https://${github_username}:${github_token}@github.com/brunokarume2-hue/Tshiakani-VTC.git
    
    if git push -u origin main; then
        echo ""
        echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
        echo ""
        echo "🎉 Le code a été poussé sur GitHub avec succès !"
        echo ""
        echo "🔗 Repository : https://github.com/brunokarume2-hue/Tshiakani-VTC"
        echo ""
        echo "🚀 Prochaine étape :"
        echo "   Aller sur https://dashboard.render.com"
        echo "   Suivre : backend/GUIDE_COMPLET_RENDER.md"
        
        # Remettre l'URL normale (sans token)
        git remote set-url origin https://github.com/brunokarume2-hue/Tshiakani-VTC.git
    else
        echo ""
        echo "❌ Erreur lors du push"
        echo "   Vérifiez que le token a la permission 'repo'"
    fi
else
    echo ""
    echo "📝 Créer un token d'abord :"
    echo "   1. Aller sur : https://github.com/settings/tokens"
    echo "   2. Générer un nouveau token (classic)"
    echo "   3. Cocher 'repo'"
    echo "   4. Relancer ce script"
    echo ""
    echo "💡 Ou utiliser GitHub CLI :"
    echo "   brew install gh"
    echo "   gh auth login"
    echo "   git push -u origin main"
fi

