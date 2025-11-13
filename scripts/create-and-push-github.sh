#!/bin/bash

# Script pour créer le repository GitHub et pousser le code automatiquement

set -e

echo "🚀 Création du Repository GitHub"
echo "================================"
echo ""

cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier si GitHub CLI est installé
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI trouvé"
    echo ""
    
    # Vérifier l'authentification
    if gh auth status &> /dev/null; then
        echo "✅ Authentifié sur GitHub CLI"
        echo ""
        
        # Créer le repository
        echo "📦 Création du repository GitHub..."
        echo ""
        
        # Demander confirmation
        read -p "Créer le repository 'Tshiakani-VTC' sur GitHub ? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Créer le repository (public par défaut pour Render gratuit)
            gh repo create Tshiakani-VTC --public --source=. --remote=origin --push 2>&1 || {
                echo ""
                echo "⚠️  Le repository existe peut-être déjà ou erreur de connexion"
                echo ""
                echo "📝 Tentative de push manuel..."
                git remote get-url origin > /dev/null 2>&1 && {
                    git push -u origin main
                } || {
                    echo "❌ Pas de remote configuré. Créer le repository manuellement sur GitHub.com"
                }
            }
        else
            echo "❌ Annulé"
        fi
    else
        echo "⚠️  Pas authentifié sur GitHub CLI"
        echo ""
        echo "📝 Authentification GitHub CLI..."
        echo "   Exécuter : gh auth login"
        echo ""
        read -p "Voulez-vous vous authentifier maintenant ? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
            # Réessayer après authentification
            if gh auth status &> /dev/null; then
                read -p "Créer le repository 'Tshiakani-VTC' ? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    gh repo create Tshiakani-VTC --public --source=. --remote=origin --push
                fi
            fi
        else
            echo ""
            echo "📝 Instructions manuelles :"
            echo "   1. Aller sur https://github.com/new"
            echo "   2. Créer repository : Tshiakani-VTC"
            echo "   3. Exécuter : git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git"
            echo "   4. Exécuter : git push -u origin main"
        fi
    fi
else
    echo "⚠️  GitHub CLI non installé"
    echo ""
    echo "📦 Installation de GitHub CLI..."
    echo ""
    read -p "Installer GitHub CLI ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Installer GitHub CLI sur macOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install gh
                echo ""
                echo "✅ GitHub CLI installé"
                echo "   Exécuter : gh auth login"
                echo "   Puis relancer ce script"
            else
                echo "❌ Homebrew non trouvé"
                echo "   Installer Homebrew d'abord : /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            fi
        else
            echo "❌ Installation automatique non supportée sur ce système"
        fi
    else
        echo ""
        echo "📝 Instructions manuelles :"
        echo "   1. Aller sur https://github.com/new"
        echo "   2. Créer repository : Tshiakani-VTC"
        echo "   3. Exécuter : git remote add origin https://github.com/VOTRE_USERNAME/Tshiakani-VTC.git"
        echo "   4. Exécuter : git push -u origin main"
    fi
fi

echo ""
echo "✅ Script terminé"

