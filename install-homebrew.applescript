-- Script AppleScript pour installer Homebrew avec privilèges administrateur
-- Ce script demande le mot de passe via une boîte de dialogue système macOS

set brewScript to "#!/bin/bash
set -e

# Détecter l'architecture
ARCH=$(uname -m)
if [[ \"$ARCH\" == \"arm64\" ]]; then
    HOMEBREW_PREFIX=\"/opt/homebrew\"
else
    HOMEBREW_PREFIX=\"/usr/local\"
fi

# Vérifier si Homebrew est déjà installé
if command -v brew &> /dev/null || [[ -f \"$HOMEBREW_PREFIX/bin/brew\" ]]; then
    echo \"Homebrew est déjà installé\"
    exit 0
fi

# Télécharger et installer Homebrew
/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"

# Vérifier l'installation
if [[ -f \"$HOMEBREW_PREFIX/bin/brew\" ]]; then
    echo \"Homebrew installé avec succès dans $HOMEBREW_PREFIX\"
    exit 0
else
    echo \"Erreur: Homebrew n'a pas été installé correctement\"
    exit 1
fi"

try
    -- Exécuter le script avec les privilèges administrateur
    -- Cela affichera une boîte de dialogue système pour demander le mot de passe
    do shell script brewScript with administrator privileges
    
    -- Si on arrive ici, l'installation a réussi
    display dialog "✅ Homebrew a été installé avec succès!" & return & return & "Le script va maintenant configurer votre environnement." buttons {"OK"} default button "OK" with title "Installation Homebrew" with icon note
    
    -- Configurer le PATH dans .zshrc
    set shellConfig to (path to home folder as string) & ".zshrc"
    set brewEnv to "eval \"$(/opt/homebrew/bin/brew shellenv)\""
    
    try
        set configContent to (read file shellConfig)
        if configContent does not contain "brew shellenv" then
            set fileHandle to open for access file shellConfig with write permission
            write (return & "# Homebrew" & return & brewEnv & return) to fileHandle
            close access fileHandle
        end if
    on error
        -- Le fichier n'existe pas, le créer
        try
            set fileHandle to open for access file shellConfig with write permission
            write ("# Homebrew" & return & brewEnv & return) to fileHandle
            close access fileHandle
        end try
    end try
    
    display dialog "✅ Configuration terminée!" & return & return & "Homebrew est maintenant installé et configuré." & return & return & "Fermez et rouvrez votre terminal, ou exécutez:" & return & "eval \"$(/opt/homebrew/bin/brew shellenv)\"" buttons {"OK"} default button "OK" with title "Installation Homebrew" with icon note
    
on error errorMessage
    display dialog "❌ Erreur lors de l'installation:" & return & return & errorMessage buttons {"OK"} default button "OK" with title "Erreur Installation Homebrew" with icon stop
end try

