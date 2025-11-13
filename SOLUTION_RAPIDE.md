# ⚡ Solution Rapide - Déploiement du Dashboard

## 🎯 Problème

Node.js v24.11.0 n'est pas compatible avec Firebase CLI. Il faut Node.js 18, 20 ou 22.

## ✅ Solution la Plus Rapide

### Méthode 1: Utiliser nvm (Recommandé - 5 minutes)

**Ouvrez un NOUVEAU terminal** et exécutez ces commandes une par une :

```bash
# 1. Installer nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 2. Recharger le terminal (ou fermer/rouvrir)
source ~/.zshrc

# 3. Installer Node.js 20
nvm install 20
nvm use 20

# 4. Vérifier
node --version
# Doit afficher: v20.x.x

# 5. Installer Firebase CLI
npm install -g firebase-tools

# 6. Aller dans le projet
cd "/Users/admin/Documents/Tshiakani VTC"

# 7. Se connecter à Firebase
firebase login

# 8. Sélectionner le projet
firebase use tshiakani-vtc

# 9. Déployer
firebase deploy --only hosting
```

**Temps estimé** : 5-10 minutes

---

### Méthode 2: Utiliser Homebrew (Si nvm ne fonctionne pas)

```bash
# 1. Installer Node.js 20
brew install node@20

# 2. Lier Node.js 20
brew link node@20 --force --overwrite

# 3. Vérifier
node --version
# Doit afficher: v20.x.x

# 4. Installer Firebase CLI
npm install -g firebase-tools

# 5. Déployer
cd "/Users/admin/Documents/Tshiakani VTC"
firebase login
firebase use tshiakani-vtc
firebase deploy --only hosting
```

**Temps estimé** : 5-10 minutes

---

## 🚀 Après le Déploiement

Une fois déployé, vérifiez :

```bash
# 1. Vérifier l'accessibilité
curl -I https://tshiakani-vtc.firebaseapp.com

# 2. Ouvrir dans le navigateur
open https://tshiakani-vtc.firebaseapp.com
```

---

## ✅ Checklist

- [ ] Node.js 20 installé (v20.x.x)
- [ ] Firebase CLI installé
- [ ] Connecté à Firebase (`firebase login`)
- [ ] Projet sélectionné (`firebase use tshiakani-vtc`)
- [ ] Dashboard déployé (`firebase deploy --only hosting`)
- [ ] Dashboard accessible (200 OK)
- [ ] Connexion au backend fonctionnelle

---

## 🆘 Si vous avez des problèmes

1. **Vérifier Node.js** : `node --version` doit afficher v20.x.x
2. **Vérifier Firebase CLI** : `firebase --version` doit afficher la version
3. **Vérifier la connexion** : `firebase projects:list` doit lister vos projets
4. **Vérifier le build** : `ls -la admin-dashboard/dist/` doit contenir `index.html`

---

## 📝 Note Importante

Après avoir installé Node.js 20, **utilisez toujours Node.js 20 pour Firebase CLI** :

```bash
# Basculer vers Node.js 20 avant d'utiliser Firebase CLI
nvm use 20

# Vous pouvez toujours utiliser Node.js 24 pour le développement
nvm use 24
```

---

**Temps total estimé** : 10-15 minutes
**Difficulté** : Facile
**Résultat** : Dashboard déployé et accessible
