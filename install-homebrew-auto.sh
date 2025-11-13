#!/bin/bash

# Script qui ouvre automatiquement Terminal.app pour installer Homebrew
# Aucune interaction requise dans ce script

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍺 Préparation de l'installation de Homebrew${NC}"
echo ""

# Vérifier si Homebrew est déjà installé
if command -v brew &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Homebrew est déjà installé${NC}"
    eval "$(brew --env)"
    brew --version
    exit 0
fi

# Vérifier si Homebrew existe dans les emplacements standards
if [[ -f "/opt/homebrew/bin/brew" ]] || [[ -f "/usr/local/bin/brew" ]]; then
    echo -e "${GREEN}✓ Homebrew est installé mais pas dans le PATH${NC}"
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    brew --version
    exit 0
fi

# Détecter l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    BREW_PATH="/opt/homebrew/bin/brew"
else
    HOMEBREW_PREFIX="/usr/local"
    BREW_PATH="/usr/local/bin/brew"
fi

echo -e "${BLUE}Architecture: $ARCH${NC}"
echo -e "${BLUE}Emplacement: $HOMEBREW_PREFIX${NC}"
echo ""

# Créer le script d'installation
INSTALL_SCRIPT="$HOME/install-homebrew-now.sh"
cat > "$INSTALL_SCRIPT" << 'INSTALL_EOF'
#!/bin/bash
clear
echo "╔════════════════════════════════════════╗"
echo "║   Installation de Homebrew            ║"
echo "╚════════════════════════════════════════╝"
echo ""

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo "✓ Homebrew est déjà installé"
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    brew --version
    echo ""
    echo "Appuyez sur Entrée pour fermer..."
    read
    exit 0
fi

echo "Cette installation nécessite votre mot de passe administrateur."
echo ""
echo "Installation en cours..."
echo ""

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo ""
    echo "✓ Homebrew installé avec succès!"
    
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
    
    # Configurer .zshrc
    SHELL_CONFIG="$HOME/.zshrc"
    if ! grep -q "brew shellenv" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Homebrew" >> "$SHELL_CONFIG"
        echo "eval \"\$($HOMEBREW_PREFIX/bin/brew shellenv)\"" >> "$SHELL_CONFIG"
    fi
    
    brew --version
    echo ""
    echo "✅ Installation terminée!"
    echo "Fermez ce terminal et ouvrez-en un nouveau pour utiliser Homebrew."
else
    echo ""
    echo "✗ L'installation a échoué"
fi

echo ""
echo "Appuyez sur Entrée pour fermer..."
read
INSTALL_EOF

chmod +x "$INSTALL_SCRIPT"

echo -e "${YELLOW}Ouverture du terminal pour l'installation...${NC}"
echo ""

# Ouvrir Terminal.app avec le script
osascript <<'APPLESCRIPT'
tell application "Terminal"
    activate
    set newTab to do script "bash ~/install-homebrew-now.sh"
end tell
APPLESCRIPT

echo -e "${GREEN}✓ Terminal ouvert avec le script d'installation${NC}"
echo ""
echo "Suivez les instructions dans le terminal qui vient de s'ouvrir."
echo "Vous devrez entrer votre mot de passe administrateur."

