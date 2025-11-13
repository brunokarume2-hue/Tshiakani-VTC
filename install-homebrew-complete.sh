#!/bin/bash

# Script complet d'installation de Homebrew utilisant AppleScript
# Ce script utilise osascript pour demander le mot de passe via l'interface système

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍺 Installation de Homebrew${NC}"
echo ""

# Vérifier si Homebrew est déjà installé
if command -v brew &> /dev/null; then
    echo -e "${GREEN}✓ Homebrew est déjà installé${NC}"
    brew --version
    exit 0
fi

# Vérifier si on est sur macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}✗ Ce script est conçu pour macOS uniquement${NC}"
    exit 1
fi

# Détecter l'architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    BREW_BIN="$HOMEBREW_PREFIX/bin/brew"
else
    HOMEBREW_PREFIX="/usr/local"
    BREW_BIN="$HOMEBREW_PREFIX/bin/brew"
fi

echo -e "${BLUE}Architecture détectée: $ARCH${NC}"
echo -e "${BLUE}Emplacement: $HOMEBREW_PREFIX${NC}"
echo ""

# Créer un script temporaire pour l'installation
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'INSTALL_SCRIPT'
#!/bin/bash
set -e

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

# Installer Homebrew
echo "Téléchargement et installation de Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Vérifier l'installation
if [[ -f "$HOMEBREW_PREFIX/bin/brew" ]]; then
    echo "SUCCESS: Homebrew installé dans $HOMEBREW_PREFIX"
else
    echo "ERROR: Échec de l'installation"
    exit 1
fi
INSTALL_SCRIPT

chmod +x "$TEMP_SCRIPT"

echo -e "${YELLOW}⚠️  Installation nécessitant des privilèges administrateur${NC}"
echo -e "${YELLOW}→ Une boîte de dialogue va apparaître pour demander votre mot de passe${NC}"
echo ""

# Exécuter avec osascript et privilèges administrateur
# Cela affichera une boîte de dialogue système macOS
INSTALL_OUTPUT=$(osascript <<APPLESCRIPT
try
    set scriptPath to "$TEMP_SCRIPT"
    do shell script "bash " & quoted form of scriptPath with administrator privileges
    return "SUCCESS"
on error errorMessage
    return "ERROR: " & errorMessage
end try
APPLESCRIPT
)

# Nettoyer le script temporaire
rm -f "$TEMP_SCRIPT"

# Vérifier le résultat
if [[ "$INSTALL_OUTPUT" == *"SUCCESS"* ]] || [[ -f "$BREW_BIN" ]]; then
    echo ""
    echo -e "${GREEN}✓ Homebrew installé avec succès!${NC}"
    
    # Configurer le PATH
    echo ""
    echo "🔧 Configuration de l'environnement..."
    
    SHELL_CONFIG=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
        if [[ -f "$HOME/.bash_profile" ]]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        else
            SHELL_CONFIG="$HOME/.bashrc"
        fi
    fi
    
    if [[ -n "$SHELL_CONFIG" ]]; then
        # Charger brew dans le shell actuel
        eval "$($BREW_BIN shellenv 2>/dev/null || true)"
        
        # Ajouter au fichier de configuration
        if [[ -f "$SHELL_CONFIG" ]]; then
            if ! grep -q "brew shellenv" "$SHELL_CONFIG" 2>/dev/null; then
                echo "" >> "$SHELL_CONFIG"
                echo "# Homebrew" >> "$SHELL_CONFIG"
                echo "eval \"\$($BREW_BIN shellenv)\"" >> "$SHELL_CONFIG"
                echo -e "${GREEN}✓ PATH configuré dans $SHELL_CONFIG${NC}"
            fi
        else
            echo "# Homebrew" > "$SHELL_CONFIG"
            echo "eval \"\$($BREW_BIN shellenv)\"" >> "$SHELL_CONFIG"
            echo -e "${GREEN}✓ $SHELL_CONFIG créé et configuré${NC}"
        fi
    fi
    
    # Vérifier l'installation
    echo ""
    echo "🔍 Vérification..."
    if eval "$($BREW_BIN shellenv)" && brew --version > /dev/null 2>&1; then
        brew --version
        echo ""
        echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
        echo ""
        echo "Homebrew est maintenant disponible. Vous pouvez l'utiliser avec:"
        echo "  brew install <package>"
        echo ""
        echo "Pour charger Homebrew dans ce terminal:"
        echo "  eval \"\$($BREW_BIN shellenv)\""
    else
        echo -e "${YELLOW}⚠️  Homebrew installé mais nécessite un rechargement du shell${NC}"
        echo "Exécutez: eval \"\$($BREW_BIN shellenv)\""
        echo "Ou fermez et rouvrez votre terminal."
    fi
else
    echo ""
    echo -e "${RED}✗ L'installation a échoué${NC}"
    echo "Message: $INSTALL_OUTPUT"
    echo ""
    echo "Essayez d'installer manuellement en exécutant:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

