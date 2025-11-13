#!/bin/bash

# Script qui ouvre un terminal pour installer Homebrew
# Ce script crée un script d'installation et l'exécute dans un nouveau terminal

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍺 Préparation de l'installation de Homebrew${NC}"
echo ""

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
else
    HOMEBREW_PREFIX="/usr/local"
fi

echo -e "${BLUE}Architecture: $ARCH${NC}"
echo -e "${BLUE}Emplacement: $HOMEBREW_PREFIX${NC}"
echo ""

# Créer le script d'installation complet
INSTALL_SCRIPT="$HOME/install-homebrew-now.sh"
cat > "$INSTALL_SCRIPT" << 'INSTALL_SCRIPT_CONTENT'
#!/bin/bash

# Script d'installation Homebrew
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Installation de Homebrew            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Détecter l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

echo -e "${BLUE}Architecture: $ARCH${NC}"
echo -e "${BLUE}Emplacement: $HOMEBREW_PREFIX${NC}"
echo ""

# Vérifier si déjà installé
if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo -e "${GREEN}✓ Homebrew est déjà installé${NC}"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    brew --version
    exit 0
fi

echo -e "${YELLOW}⚠️  Cette installation nécessite votre mot de passe administrateur${NC}"
echo ""
echo "Appuyez sur Entrée pour continuer..."
read

# Installer Homebrew
echo ""
echo "📥 Téléchargement et installation de Homebrew..."
echo ""

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Vérifier l'installation
if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo ""
    echo -e "${GREEN}✓ Homebrew installé avec succès!${NC}"
    
    # Charger l'environnement
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    
    # Configurer le PATH dans .zshrc
    SHELL_CONFIG="$HOME/.zshrc"
    if [[ -f "$SHELL_CONFIG" ]]; then
        if ! grep -q "brew shellenv" "$SHELL_CONFIG" 2>/dev/null; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Homebrew" >> "$SHELL_CONFIG"
            echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> "$SHELL_CONFIG"
            echo -e "${GREEN}✓ PATH configuré dans $SHELL_CONFIG${NC}"
        fi
    else
        echo "# Homebrew" > "$SHELL_CONFIG"
        echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> "$SHELL_CONFIG"
        echo -e "${GREEN}✓ $SHELL_CONFIG créé${NC}"
    fi
    
    # Vérifier l'installation
    echo ""
    echo "🔍 Vérification..."
    brew --version
    
    echo ""
    echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
    echo ""
    echo "Homebrew est maintenant disponible. Vous pouvez:"
    echo "  - Utiliser: brew install <package>"
    echo "  - Fermer ce terminal et en ouvrir un nouveau"
    echo ""
    echo "Appuyez sur Entrée pour fermer..."
    read
else
    echo ""
    echo -e "${RED}✗ L'installation a échoué${NC}"
    echo ""
    echo "Appuyez sur Entrée pour fermer..."
    read
    exit 1
fi
INSTALL_SCRIPT_CONTENT

chmod +x "$INSTALL_SCRIPT"

echo -e "${YELLOW} Terminal${NC}"
echo "Un nouveau terminal va s'ouvrir pour l'installation."
echo "Suivez les instructions dans le terminal."
echo ""
echo "Appuyez sur Entrée pour ouvrir le terminal d'installation..."
read

# Ouvrir un nouveau terminal avec le script
if command -v osascript &> /dev/null; then
    # Sur macOS, ouvrir Terminal.app avec le script
    osascript <<APPLESCRIPT
tell application "Terminal"
    activate
    do script "cd ~ && bash '$INSTALL_SCRIPT'"
end tell
APPLESCRIPT
else
    # Fallback: essayer avec open
    open -a Terminal "$INSTALL_SCRIPT"
fi

echo ""
echo "Le terminal d'installation devrait être ouvert."
echo "Si ce n'est pas le cas, exécutez manuellement:"
echo "  bash $INSTALL_SCRIPT"

