#!/bin/bash

# Script pour pousser avec token GitHub

set -e

cd "/Users/admin/Documents/Tshiakani VTC"

echo "🔐 Push vers GitHub avec Token"
echo "=============================="
echo ""

# Demander le token
echo "📝 Entrez votre Personal Access Token GitHub"
echo "   (Si vous n'en avez pas, créez-en un : https://github.com/settings/tokens/new)"
echo ""
read -sp "Token : " github_token
echo ""

if [ -z "$github_token" ]; then
    echo "❌ Token vide, annulation"
    exit 1
fi

# Configurer l'URL avec le token
echo "🔗 Configuration du remote avec authentification..."
git remote set-url origin https://brunokarume2-hue:${github_token}@github.com/brunokarume2-hue/Tshiakani-VTC.git

echo ""
echo "📤 Poussée du code vers GitHub..."
echo ""

# Pousser
if git push -u origin main; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🎉 Le code a été poussé sur GitHub avec succès !"
    echo ""
    echo "🔗 Repository : https://github.com/brunokarume2-hue/Tshiakani-VTC"
    echo ""
    echo "📊 Vérification :"
    echo "   Ouvrir : https://github.com/brunokarume2-hue/Tshiakani-VTC"
    echo "   Vérifier que le dossier 'backend/' est présent"
    echo ""
    
    # Remettre l'URL normale (sans token)
    git remote set-url origin https://github.com/brunokarume2-hue/Tshiakani-VTC.git
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 PROCHAINE ÉTAPE : Déploiement sur Render"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Aller sur : https://dashboard.render.com"
    echo "2. Suivre le guide : backend/GUIDE_COMPLET_RENDER.md"
    echo "3. Créer PostgreSQL database : tshiakani-vtc-db"
    echo "4. Créer Web Service depuis GitHub"
    echo "5. Déployer !"
    echo ""
else
    echo ""
    echo "❌ Erreur lors du push"
    echo ""
    echo "💡 Vérifications :"
    echo "   1. Le token a la permission 'repo'"
    echo "   2. Le token est valide et non expiré"
    echo "   3. Vous avez les droits d'écriture sur le repository"
    echo ""
    
    # Remettre l'URL normale
    git remote set-url origin https://github.com/brunokarume2-hue/Tshiakani-VTC.git
fi

