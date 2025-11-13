#!/bin/bash

# Script d'installation de Google Cloud CLI pour macOS
# Usage: ./installer-gcloud.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Installation de Google Cloud CLI...${NC}"
echo ""

# Vérifier le système
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ Ce script est conçu pour macOS${NC}"
    exit 1
fi

# Option 1: Installer via Homebrew (si disponible)
if command -v brew &> /dev/null; then
    echo -e "${BLUE}📦 Option 1: Installation via Homebrew...${NC}"
    echo -e "${YELLOW}⏳ Installation en cours...${NC}"
    
    brew install --cask google-cloud-sdk
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Installation réussie via Homebrew${NC}"
        echo ""
        echo -e "${BLUE}📋 Initialisation...${NC}"
        gcloud init
        exit 0
    else
        echo -e "${YELLOW}⚠️  Installation via Homebrew échouée, essai de l'installation manuelle...${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️  Homebrew n'est pas installé${NC}"
    echo -e "${BLUE}📋 Options d'installation:${NC}"
    echo ""
    echo -e "${GREEN}Option A: Installer Homebrew puis gcloud (Recommandé)${NC}"
    echo "  1. Installer Homebrew:"
    echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    echo ""
    echo "  2. Installer gcloud:"
    echo "     brew install --cask google-cloud-sdk"
    echo ""
    echo -e "${GREEN}Option B: Installation manuelle de gcloud${NC}"
    echo "  1. Télécharger depuis: https://cloud.google.com/sdk/docs/install"
    echo "  2. Extraire et exécuter l'installer"
    echo ""
    echo -e "${GREEN}Option C: Installation via le script officiel (Recommandé si Homebrew n'est pas disponible)${NC}"
    echo ""
    
    read -p "Voulez-vous installer via le script officiel? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📥 Téléchargement et installation via le script officiel...${NC}"
        
        # Télécharger et exécuter le script d'installation
        curl https://sdk.cloud.google.com | bash
        
        # Ajouter au PATH
        echo -e "${BLUE}📋 Ajout au PATH...${NC}"
        
        # Détecter le shell
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_RC="$HOME/.bash_profile"
        else
            SHELL_RC="$HOME/.zshrc"
            touch "$SHELL_RC"
        fi
        
        # Ajouter les lignes si elles n'existent pas
        if ! grep -q "google-cloud-sdk/path.bash.inc" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# Google Cloud SDK" >> "$SHELL_RC"
            echo "source '$HOME/google-cloud-sdk/path.bash.inc'" >> "$SHELL_RC"
            echo "source '$HOME/google-cloud-sdk/completion.bash.inc'" >> "$SHELL_RC"
        fi
        
        echo -e "${GREEN}✅ Installation terminée${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Vous devez redémarrer votre terminal ou exécuter:${NC}"
        echo "   source $SHELL_RC"
        echo ""
        echo -e "${BLUE}📋 Ensuite, initialisez gcloud:${NC}"
        echo "   gcloud init"
        echo ""
    else
        echo -e "${YELLOW}ℹ️  Installation annulée${NC}"
        echo ""
        echo -e "${BLUE}📋 Pour installer manuellement:${NC}"
        echo "  1. Allez sur: https://cloud.google.com/sdk/docs/install"
        echo "  2. Téléchargez l'installer pour macOS"
        echo "  3. Suivez les instructions d'installation"
        exit 0
    fi
fi

