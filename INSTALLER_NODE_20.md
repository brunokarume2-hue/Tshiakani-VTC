# 🔧 Installation de Node.js 20 pour Firebase CLI

## ⚠️ Problème

Node.js v24.11.0 n'est pas compatible avec Firebase CLI. Firebase CLI nécessite Node.js 18, 20 ou 22.

## ✅ Solution: Installer Node.js 20 avec nvm

### Étape 1: Installer nvm (si pas déjà installé)

Ouvrez un **nouveau terminal** et exécutez :

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

### Étape 2: Recharger le terminal

```bash
source ~/.zshrc
```

Ou fermez et rouvrez votre terminal.

### Étape 3: Vérifier nvm

```bash
nvm --version
```

Vous devriez voir la version de nvm (ex: `0.39.0`)

### Étape 4: Installer Node.js 20

```bash
nvm install 20
nvm use 20
```

### Étape 5: Vérifier Node.js

```bash
node --version
# Doit afficher: v20.x.x

npm --version
# Doit afficher: 10.x.x
```

### Étape 6: Installer Firebase CLI

```bash
npm install -g firebase-tools
```

### Étape 7: Vérifier Firebase CLI

```bash
firebase --version
```

---

## 🚀 Alternative: Utiliser Homebrew

Si nvm ne fonctionne pas, vous pouvez utiliser Homebrew :

```bash
# Installer Node.js 20 avec Homebrew
brew install node@20

# Lier Node.js 20
brew link node@20 --force --overwrite

# Vérifier
node --version
```

---

## 📝 Après l'installation

Une fois Node.js 20 installé, vous pouvez déployer le dashboard :

```bash
cd "/Users/admin/Documents/Tshiakani VTC"

# Se connecter à Firebase
firebase login

# Sélectionner le projet
firebase use tshiakani-vtc

# Déployer
firebase deploy --only hosting
```

---

## 🔄 Basculer entre les versions de Node.js

Avec nvm, vous pouvez basculer entre les versions :

```bash
# Utiliser Node.js 20
nvm use 20

# Utiliser Node.js 24 (pour le développement)
nvm use 24

# Utiliser la version système
nvm use system
```

---

## ✅ Vérification

Pour vérifier que tout est correct :

```bash
# Node.js version
node --version
# Doit afficher: v20.x.x

# npm version
npm --version
# Doit afficher: 10.x.x

# Firebase CLI
firebase --version
# Doit afficher: 13.x.x ou supérieur
```

---

**Note** : Après avoir installé Node.js 20, exécutez le script `deploy-dashboard.sh` ou les commandes manuelles pour déployer le dashboard.

