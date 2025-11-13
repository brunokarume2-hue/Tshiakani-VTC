#!/bin/bash

# Script d'installation de Homebrew avec demande de mot de passe graphique
# Ce script demande le mot de passe via une interface graphique macOS

set -e

echo "🍺 Installation de Homebrew avec interface graphique..."
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction pour demander le mot de passe via AppleScript
ask_password() {
    osascript -e 'Tell application "System Events" to display dialog "Homebrew nécessite votre mot de passe administrateur pour l''installation." & return & return & "Entrez votre mot de passe dans le terminal qui va s''ouvrir." buttons {"OK"} default button "OK" with title "Installation Homebrew" with icon note'
}

# Vérifier si Homebrew est déjà installé
if command -v brew &> /dev/null; then
    echo -e "${GREEN}✓ Homebrew est déjà installé${NC}"
    brew --version
    exit 0
fi

# Détecter l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    echo -e "${BLUE}Architecture: Apple Silicon (ARM64)${NC}"
else
    HOMEBREW_PREFIX="/usr/local"
    echo -e "${BLUE}Architecture: Intel${NC}"
fi

echo ""
echo -e "${YELLOW}⚠️  Cette installation nécessite des privilèges administrateur${NC}"
echo ""

# Afficher la notification
ask_password

echo ""
echo "📥 Téléchargement du script d'installation Homebrew..."
echo ""

# Télécharger le script d'installation
INSTALL_SCRIPT=$(mktemp)
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$INSTALL_SCRIPT"
chmod +x "$INSTALL_SCRIPT"

echo "🚀 Lancement de l'installation..."
echo -e "${YELLOW}→ Vous devrez entrer votre mot de passe dans le terminal${NC}"
echo ""

# Exécuter l'installation
bash "$INSTALL_SCRIPT"

# Nettoyer
rm -f "$INSTALL_SCRIPT"

# Vérifier si l'installation a réussi
if command -v brew &> /dev/null || [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo ""
    echo -e "${GREEN}✓ Homebrew installé avec succès!${NC}"
    
    # Configurer le PATH
    SHELL_CONFIG=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
    fi
    
    if [[ -n "$SHELL_CONFIG" ]]; then
        echo ""
        echo "🔧 Configuration du PATH..."
        
        # Créer le fichier s'il n'existe pas
        touch "$SHELL_CONFIG"
        
        # Ajouter Homebrew au PATH si nécessaire
        if ! grep -q "brew shellenv" "$SHELL_CONFIG" 2>/dev/null; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Homebrew" >> "$SHELL_CONFIG"
            echo 'eval "$('"$HOMEBREW_PREFIX"'/bin/brew shellenv)"' >> "$SHELL_CONFIG"
            echo -e "${GREEN}✓ PATH configuré dans $SHELL_CONFIG${NC}"
        fi
        
        # Charger l'environnement
        eval "$($HOMEBREW_PREFIX/bin/brew shellenv 2>/dev/null || true)"
    fi
    
    # Vérifier l'installation
    echo ""
    echo "🔍 Vérification..."
    if command -v brew &> /dev/null; then
        brew --version
        echo ""
        echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
        echo ""
        echo "Pour utiliser Homebrew maintenant, exécutez:"
        echo "  eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
        echo ""
        echo "Ou fermez et rouvrez votre terminal."
    else
        echo -e "${YELLOW}⚠️  Homebrew installé mais pas encore dans le PATH${NC}"
        echo "Exécutez: eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\""
    fi
    
else
    echo ""
    echo -e "${RED}✗ L'installation semble avoir échoué${NC}"
    echo "Vérifiez les messages d'erreur ci-dessus."
    exit 1
fi

