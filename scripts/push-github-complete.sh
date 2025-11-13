#!/bin/bash

# Script complet pour pousser sur GitHub - Version améliorée

set -e

cd "/Users/admin/Documents/Tshiakani VTC"

echo "🚀 Configuration GitHub - Version Automatique"
echo "============================================"
echo ""

# Vérifier si remote existe déjà
if git remote get-url origin > /dev/null 2>&1; then
    echo "✅ Remote GitHub déjà configuré :"
    git remote get-url origin
    echo ""
    echo "📤 Poussée du code..."
    if git push -u origin main; then
        echo ""
        echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
        echo ""
        echo "🎉 Le code a été poussé sur GitHub avec succès !"
        echo ""
        echo "🔗 Repository : $(git remote get-url origin)"
        echo ""
        echo "🚀 Prochaine étape :"
        echo "   Aller sur https://dashboard.render.com"
        echo "   Suivre : backend/GUIDE_COMPLET_RENDER.md"
        exit 0
    else
        echo "❌ Erreur lors du push"
        exit 1
    fi
fi

echo "📝 Le repository GitHub n'existe pas encore"
echo ""

# Ouvrir GitHub
echo "🌐 Ouverture de GitHub dans votre navigateur..."
open "https://github.com/new?name=Tshiakani-VTC&description=Backend+et+app+iOS+pour+Tshiakani+VTC&visibility=public" 2>/dev/null || {
    echo "⚠️  Ouvrir manuellement : https://github.com/new"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 INSTRUCTIONS - Suivez ces étapes :"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Dans la page GitHub qui s'est ouverte :"
echo "   ✅ Repository name : Tshiakani-VTC (déjà rempli)"
echo "   ✅ Description : Backend et app iOS pour Tshiakani VTC"
echo "   ✅ Visibility : Public (déjà sélectionné)"
echo "   ❌ NE PAS cocher 'Add a README file'"
echo "   👆 Cliquer sur 'Create repository'"
echo ""
echo "2️⃣  Après la création, GitHub affichera une page"
echo "   📋 Copier l'URL complète du repository"
echo "   (ex: https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git)"
echo ""
echo "3️⃣  Revenir ici et coller l'URL quand demandé"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Attendre que l'utilisateur crée le repository
read -p "⏳ Appuyez sur ENTER une fois le repository créé sur GitHub... " 

echo ""
echo "📝 Entrez l'URL complète du repository GitHub :"
echo "   (ex: https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git)"
read -p "🔗 URL : " repo_url

if [ -z "$repo_url" ]; then
    echo "❌ URL vide, annulation"
    exit 1
fi

# Nettoyer l'URL (enlever les espaces)
repo_url=$(echo "$repo_url" | xargs)

echo ""
echo "🔗 Configuration du remote GitHub..."
git remote add origin "$repo_url" 2>/dev/null || {
    echo "⚠️  Remote existe déjà, mise à jour..."
    git remote set-url origin "$repo_url"
}

echo "✅ Remote configuré : $repo_url"
echo ""

# Renommer la branche en main si nécessaire
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    echo "📝 Renommage de la branche en 'main'..."
    git branch -M main
fi

echo ""
echo "📤 Poussée du code vers GitHub..."
echo "   (Cela peut prendre quelques secondes...)"
echo ""

# Pousser le code
if git push -u origin main; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ ✅ ✅ SUCCÈS ! ✅ ✅ ✅"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🎉 Le code a été poussé sur GitHub avec succès !"
    echo ""
    echo "🔗 Repository : $repo_url"
    echo ""
    echo "📊 Vérification :"
    echo "   Ouvrir : $repo_url"
    echo "   Vérifier que le dossier 'backend/' est présent"
    echo ""
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
    echo "💡 Solutions possibles :"
    echo ""
    echo "1. Vérifier que le repository existe sur GitHub"
    echo "   Ouvrir : $repo_url"
    echo ""
    echo "2. Vérifier votre authentification GitHub"
    echo "   - Utiliser un Personal Access Token"
    echo "   - Aller sur : https://github.com/settings/tokens"
    echo "   - Générer un token avec permission 'repo'"
    echo "   - Utiliser le token comme mot de passe lors du push"
    echo ""
    echo "3. Réessayer manuellement :"
    echo "   git push -u origin main"
    echo ""
fi

