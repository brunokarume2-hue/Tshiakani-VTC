# 🍺 Installation de Homebrew

Ce guide vous aide à installer Homebrew sur votre Mac.

## Méthode 1 : Installation Automatique (Recommandée)

Exécutez simplement cette commande dans votre terminal :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
./install-homebrew-terminal.sh
```

Ce script ouvrira un nouveau terminal avec le processus d'installation.

## Méthode 2 : Installation Manuelle Directe

Ouvrez Terminal.app et exécutez :

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Suivez les instructions à l'écran. Vous devrez :
1. Entrer votre mot de passe administrateur
2. Appuyer sur Entrée pour continuer
3. Attendre la fin de l'installation

## Après l'Installation

### Pour Apple Silicon (M1/M2/M3) :

Ajoutez Homebrew à votre PATH en exécutant :

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Pour Intel :

```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/usr/local/bin/brew shellenv)"
```

## Vérification

Vérifiez que Homebrew est installé :

```bash
brew --version
```

## Utilisation

Une fois installé, vous pouvez utiliser Homebrew pour installer des packages :

```bash
brew install <package-name>
```

## Scripts Disponibles

- `install-homebrew-terminal.sh` - Ouvre un terminal pour l'installation
- `install-homebrew-complete.sh` - Tentative d'installation automatique (peut nécessiter interaction)
- `install-homebrew-gui.sh` - Version avec interface graphique

## Support

Pour plus d'informations, visitez : https://brew.sh

