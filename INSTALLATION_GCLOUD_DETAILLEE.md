# 🔧 Installation Détaillée de Google Cloud CLI

## 📋 Prérequis

- macOS (Darwin)
- Connexion Internet
- Compte Google Cloud (avec projet `tshiakani-vtc`)

---

## 🚀 Option 1: Installation via Homebrew (Recommandé)

### Étape 1: Installer Homebrew (si pas déjà installé)

```bash
# Installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Suivre les instructions à l'écran
# Ajouter Homebrew au PATH si demandé
```

### Étape 2: Installer Google Cloud SDK

```bash
# Installer Google Cloud SDK
brew install --cask google-cloud-sdk
```

### Étape 3: Initialiser gcloud

```bash
# Initialiser gcloud
gcloud init

# Ou se connecter seulement
gcloud auth login
gcloud config set project tshiakani-vtc
```

---

## 🚀 Option 2: Installation via le Script Officiel

### Étape 1: Télécharger et Installer

```bash
# Télécharger et exécuter le script d'installation
curl https://sdk.cloud.google.com | bash

# Le script va :
# - Télécharger Google Cloud SDK
# - L'installer dans ~/google-cloud-sdk
# - Vous demander si vous voulez modifier votre shell
```

### Étape 2: Ajouter au PATH

Le script vous demandera si vous voulez modifier votre shell. Répondez **"y"** (yes).

Si vous préférez le faire manuellement :

```bash
# Pour zsh (macOS par défaut)
echo 'source ~/google-cloud-sdk/path.zsh.inc' >> ~/.zshrc
echo 'source ~/google-cloud-sdk/completion.zsh.inc' >> ~/.zshrc

# Pour bash
echo 'source ~/google-cloud-sdk/path.bash.inc' >> ~/.bash_profile
echo 'source ~/google-cloud-sdk/completion.bash.inc' >> ~/.bash_profile

# Recharger le shell
source ~/.zshrc  # ou source ~/.bash_profile
```

### Étape 3: Initialiser gcloud

```bash
# Initialiser gcloud
gcloud init

# Ou se connecter seulement
gcloud auth login
gcloud config set project tshiakani-vtc
```

---

## 🚀 Option 3: Installation Manuelle

### Étape 1: Télécharger

1. Allez sur https://cloud.google.com/sdk/docs/install
2. Cliquez sur **"Download the macOS 64-bit (x86_64) archive"** ou **"Download the macOS 64-bit (ARM64) archive"** selon votre Mac
3. Téléchargez le fichier `.tar.gz`

### Étape 2: Extraire

```bash
# Aller dans le répertoire de téléchargement
cd ~/Downloads

# Extraire l'archive
tar -xzf google-cloud-sdk-*.tar.gz

# Déplacer dans le répertoire home
mv google-cloud-sdk ~/
```

### Étape 3: Installer

```bash
# Exécuter l'installer
~/google-cloud-sdk/install.sh

# Répondre "y" aux questions
# - Modifier le shell : y
# - Back up existing configuration : y (si demandé)
```

### Étape 4: Ajouter au PATH

```bash
# Pour zsh
echo 'source ~/google-cloud-sdk/path.zsh.inc' >> ~/.zshrc
echo 'source ~/google-cloud-sdk/completion.zsh.inc' >> ~/.zshrc
source ~/.zshrc

# Pour bash
echo 'source ~/google-cloud-sdk/path.bash.inc' >> ~/.bash_profile
echo 'source ~/google-cloud-sdk/completion.bash.inc' >> ~/.bash_profile
source ~/.bash_profile
```

### Étape 5: Initialiser gcloud

```bash
# Initialiser gcloud
gcloud init
```

---

## ✅ Vérification de l'Installation

### Vérifier que gcloud est installé

```bash
# Vérifier la version
gcloud --version

# Résultat attendu :
# Google Cloud SDK 450.0.0
# ...
```

### Vérifier la configuration

```bash
# Vérifier la configuration actuelle
gcloud config list

# Vérifier l'authentification
gcloud auth list
```

---

## 🔐 Configuration Initiale

### Étape 1: Se Connecter

```bash
# Se connecter à Google Cloud
gcloud auth login

# Une fenêtre du navigateur s'ouvrira
# Connectez-vous avec votre compte Google Cloud
```

### Étape 2: Configurer le Projet

```bash
# Configurer le projet
gcloud config set project tshiakani-vtc

# Vérifier la configuration
gcloud config list
```

### Étape 3: Vérifier les Permissions

```bash
# Vérifier les permissions
gcloud projects get-iam-policy tshiakani-vtc

# Vous devez avoir les rôles suivants :
# - Cloud Run Admin
# - Service Account User
# - Cloud Build Service Account
```

---

## 🧪 Test de l'Installation

### Tester gcloud

```bash
# Tester une commande simple
gcloud projects list

# Devrait afficher la liste de vos projets
```

### Tester l'authentification

```bash
# Vérifier que vous êtes connecté
gcloud auth list

# Devrait afficher votre compte
```

---

## 🆘 Dépannage

### Erreur: "gcloud: command not found"

**Solution** :
```bash
# Vérifier que gcloud est dans le PATH
which gcloud

# Si non trouvé, ajouter au PATH
export PATH=$PATH:~/google-cloud-sdk/bin

# Ajouter de façon permanente
echo 'export PATH=$PATH:~/google-cloud-sdk/bin' >> ~/.zshrc
source ~/.zshrc
```

### Erreur: "Permission denied"

**Solution** :
```bash
# Vérifier les permissions
ls -la ~/google-cloud-sdk

# Si nécessaire, corriger les permissions
chmod +x ~/google-cloud-sdk/bin/gcloud
```

### Erreur: "Project not found"

**Solution** :
```bash
# Vérifier que le projet existe
gcloud projects list

# Configurer le bon projet
gcloud config set project tshiakani-vtc
```

---

## 📝 Utilisation du Script d'Installation

Vous pouvez utiliser le script d'installation automatique :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"

# Exécuter le script
./installer-gcloud.sh
```

Le script va :
1. ✅ Vérifier si Homebrew est installé
2. ✅ Installer gcloud via Homebrew si disponible
3. ✅ Sinon, proposer l'installation via le script officiel
4. ✅ Configurer le PATH automatiquement

---

## 🎯 Prochaines Étapes

Une fois gcloud installé :

1. **Se connecter** :
   ```bash
   gcloud auth login
   ```

2. **Configurer le projet** :
   ```bash
   gcloud config set project tshiakani-vtc
   ```

3. **Déployer le backend** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   ./scripts/deploy-cloud-run.sh
   ```

---

**Date** : $(date)

