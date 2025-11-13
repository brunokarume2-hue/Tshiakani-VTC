#!/bin/bash

# Script simplifié pour pousser sur GitHub

set -e

cd "/Users/admin/Documents/Tshiakani VTC"

echo "🚀 Push vers GitHub - Version Simplifiée"
echo "=========================================="
echo ""

# Vérifier si déjà poussé
if git ls-remote --heads origin main 2>/dev/null | grep -q "main"; then
    echo "✅ Le code est déjà sur GitHub !"
    echo "🔗 https://github.com/brunokarume2-hue/Tshiakani-VTC"
    exit 0
fi

echo "📋 Instructions pour créer un Personal Access Token :"
echo ""
echo "1. 🌐 Ouverture de la page de création de token..."
open "https://github.com/settings/tokens/new" 2>/dev/null || echo "   Ouvrir manuellement : https://github.com/settings/tokens/new"
echo ""
echo "2. 📝 Dans la page qui s'ouvre :"
echo "   - Note : Tshiakani-VTC"
echo "   - Expiration : 90 days (ou No expiration)"
echo "   - Cocher : repo (accès complet)"
echo "   - Cliquer 'Generate token'"
echo "   - ⚠️  COPIER LE TOKEN (affiché une seule fois)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "⏳ Appuyez sur ENTER une fois le token créé et copié... "

echo ""
read -p "Entrez votre nom d'utilisateur GitHub (brunokarume2-hue) : " github_username
github_username=${github_username:-brunokarume2-hue}

echo ""
read -sp "Entrez votre Personal Access Token : " github_token
echo ""

if [ -z "$github_token" ]; then
    echo "❌ Token vide, annulation"
    exit 1
fi

echo ""
echo "📤 Poussée du code vers GitHub..."
echo ""

# Configurer l'URL avec le token
git remote set-url origin https://${github_username}:${github_token}@github.com/brunokarume2-hue/Tshiakani-VTC.git

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
    echo "   2. Le repository existe : https://github.com/brunokarume2-hue/Tshiakani-VTC"
    echo "   3. Vous avez les droits d'écriture sur le repository"
    echo ""
    
    # Remettre l'URL normale
    git remote set-url origin https://github.com/brunokarume2-hue/Tshiakani-VTC.git
fi

