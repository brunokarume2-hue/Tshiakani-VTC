#!/bin/bash

# Script d'installation de Homebrew pour macOS
# Ce script installe Homebrew et configure l'environnement

set -e

echo "🍺 Installation de Homebrew..."
echo ""

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
    echo "Architecture détectée: Apple Silicon (ARM64)"
else
    HOMEBREW_PREFIX="/usr/local"
    echo "Architecture détectée: Intel"
fi

# Vérifier si le répertoire existe déjà
if [[ -d "$HOMEBREW_PREFIX" ]]; then
    echo -e "${YELLOW}⚠ Le répertoire $HOMEBREW_PREFIX existe déjà${NC}"
fi

echo ""
echo "📥 Téléchargement et installation de Homebrew..."
echo "⚠️  Vous devrez entrer votre mot de passe administrateur"
echo ""

# Installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Vérifier si l'installation a réussi
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Homebrew installé avec succès!${NC}"
    
    # Ajouter Homebrew au PATH si nécessaire
    SHELL_CONFIG=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
    
    if [[ -n "$SHELL_CONFIG" ]]; then
        echo ""
        echo "🔧 Configuration du PATH dans $SHELL_CONFIG..."
        
        # Vérifier si Homebrew est déjà dans le PATH
        if ! grep -q "$HOMEBREW_PREFIX/bin" "$SHELL_CONFIG" 2>/dev/null; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Homebrew" >> "$SHELL_CONFIG"
            if [[ "$ARCH" == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$SHELL_CONFIG"
            else
                echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "$SHELL_CONFIG"
            fi
            echo -e "${GREEN}✓ PATH ajouté à $SHELL_CONFIG${NC}"
        else
            echo -e "${YELLOW}⚠ PATH déjà configuré dans $SHELL_CONFIG${NC}"
        fi
        
        # Charger le nouvel environnement
        if [[ "$ARCH" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Vérifier l'installation
    echo ""
    echo "🔍 Vérification de l'installation..."
    brew --version
    
    echo ""
    echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
    echo ""
    echo "Pour utiliser Homebrew dans ce terminal, exécutez:"
    if [[ "$ARCH" == "arm64" ]]; then
        echo "  eval \"\$(/opt/homebrew/bin/brew shellenv)\""
    else
        echo "  eval \"\$(/usr/local/bin/brew shellenv)\""
    fi
    echo ""
    echo "Ou fermez et rouvrez votre terminal."
    
else
    echo ""
    echo -e "${RED}✗ L'installation de Homebrew a échoué${NC}"
    exit 1
fi

