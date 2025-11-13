# 🚀 Déploiement Manuel du Dashboard

## 📋 Étapes à Suivre

### Prérequis

1. **Node.js 20** installé (voir `INSTALLER_NODE_20.md`)
2. **Firebase CLI** installé
3. **Compte Firebase** avec accès au projet `tshiakani-vtc`

---

## 🔧 Étape 1: Vérifier Node.js 20

```bash
# Vérifier la version de Node.js
node --version
# Doit afficher: v20.x.x

# Si ce n'est pas Node.js 20, utiliser nvm
nvm use 20
```

---

## 🔧 Étape 2: Installer Firebase CLI

```bash
# Installer Firebase CLI globalement
npm install -g firebase-tools

# Vérifier l'installation
firebase --version
```

---

## 🔧 Étape 3: Se Connecter à Firebase

```bash
# Se connecter à Firebase
firebase login

# Suivre les instructions dans le navigateur:
# 1. Ouvrir le lien affiché
# 2. Se connecter avec votre compte Google
# 3. Autoriser l'accès à Firebase
```

**Résultat attendu** : `Success! Logged in as [votre-email]`

---

## 🔧 Étape 4: Sélectionner le Projet Firebase

```bash
# Lister les projets disponibles
firebase projects:list

# Sélectionner le projet tshiakani-vtc
firebase use tshiakani-vtc

# Vérifier le projet actuel
firebase use
```

**Résultat attendu** : `Using project tshiakani-vtc`

---

## 🔧 Étape 5: Vérifier le Build

```bash
# Aller dans le répertoire du projet
cd "/Users/admin/Documents/Tshiakani VTC"

# Vérifier que le dossier dist existe
ls -la admin-dashboard/dist/

# Si le dossier dist n'existe pas, builder le dashboard
cd admin-dashboard
npm install
npm run build
cd ..
```

**Résultat attendu** : Le dossier `admin-dashboard/dist/` contient `index.html` et `assets/`

---

## 🔧 Étape 6: Vérifier la Configuration Firebase

```bash
# Vérifier le fichier firebase.json
cat firebase.json
```

**Résultat attendu** : Le fichier doit contenir :
```json
{
  "hosting": {
    "public": "admin-dashboard/dist",
    ...
  }
}
```

---

## 🚀 Étape 7: Déployer

```bash
# Déployer uniquement le hosting
firebase deploy --only hosting
```

**Résultat attendu** :
```
✔ Deploy complete!

Hosting URL: https://tshiakani-vtc.firebaseapp.com
```

---

## ✅ Étape 8: Vérifier le Déploiement

```bash
# Vérifier l'accessibilité
curl -I https://tshiakani-vtc.firebaseapp.com

# Ou ouvrir dans le navigateur
open https://tshiakani-vtc.firebaseapp.com
```

**Résultat attendu** :
- Code HTTP 200 (au lieu de 404)
- Dashboard s'affiche dans le navigateur

---

## 🔍 Étape 9: Vérifier la Connexion au Backend

1. **Ouvrir le dashboard** dans le navigateur
2. **Ouvrir la console développeur** (F12)
3. **Aller dans l'onglet "Network"**
4. **Se connecter au dashboard**
5. **Vérifier les requêtes** :
   - Requêtes vers `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/admin/*`
   - Réponses avec statut 200 (OK)
   - Pas d'erreurs CORS

---

## 🎯 Résultat Final

Après le déploiement, vous devriez avoir :

- ✅ Dashboard accessible sur `https://tshiakani-vtc.firebaseapp.com`
- ✅ Communication avec le backend Cloud Run fonctionnelle
- ✅ Toutes les fonctionnalités opérationnelles

---

## 🆘 Dépannage

### Erreur: "firebase: command not found"

**Solution** :
```bash
# Vérifier que Node.js 20 est utilisé
nvm use 20

# Réinstaller Firebase CLI
npm install -g firebase-tools
```

### Erreur: "Error: EACCES: permission denied"

**Solution** :
```bash
# Configurer npm pour utiliser un répertoire global personnalisé
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g firebase-tools
```

### Erreur: "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solution** :
1. Vérifier que `CORS_ORIGIN` dans le backend contient l'URL Firebase
2. Redéployer le backend si nécessaire

### Erreur: "403 Forbidden" sur les routes `/api/admin/*`

**Solution** :
1. Vérifier que la clé API Admin est correcte dans `.env.production`
2. Vérifier que le backend a la même clé dans `ADMIN_API_KEY`

---

## 📝 Commandes Complètes

```bash
# 1. Vérifier Node.js 20
nvm use 20
node --version

# 2. Installer Firebase CLI
npm install -g firebase-tools

# 3. Se connecter à Firebase
firebase login

# 4. Sélectionner le projet
firebase use tshiakani-vtc

# 5. Aller dans le répertoire du projet
cd "/Users/admin/Documents/Tshiakani VTC"

# 6. Vérifier le build
ls -la admin-dashboard/dist/

# 7. Déployer
firebase deploy --only hosting

# 8. Vérifier
curl -I https://tshiakani-vtc.firebaseapp.com
```

---

**Date** : $(date)
**Statut** : ✅ Guide prêt pour déploiement manuel

