# 🚀 Guide de Déploiement du Dashboard - Tshiakani VTC

## ✅ État Actuel

### Configuration Prête

- ✅ **Fichier `.env.production` créé** avec l'URL du backend Cloud Run
- ✅ **Dashboard builder** dans `admin-dashboard/dist/`
- ✅ **Configuration Firebase** présente dans `firebase.json`
- ✅ **Backend déployé** et accessible sur Cloud Run

### Problème Rencontré

- ⚠️ **Firebase CLI** nécessite Node.js 18, 20 ou 22
- ⚠️ **Version actuelle** : Node.js v24.11.0 (non compatible)

---

## 📋 Étapes de Déploiement

### Option A: Utiliser Node Version Manager (nvm) - Recommandé

#### 1. Installer nvm (si pas déjà installé)

```bash
# Sur macOS/Linux
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Recharger le terminal
source ~/.zshrc  # ou ~/.bashrc
```

#### 2. Installer Node.js 20 (LTS)

```bash
nvm install 20
nvm use 20
```

#### 3. Vérifier la version

```bash
node --version
# Doit afficher v20.x.x
```

#### 4. Installer Firebase CLI

```bash
npm install -g firebase-tools
```

#### 5. Se connecter à Firebase

```bash
firebase login
```

#### 6. Vérifier le projet Firebase

```bash
firebase use tshiakani-vtc
# ou
firebase projects:list
```

#### 7. Déployer le dashboard

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
firebase deploy --only hosting
```

---

### Option B: Utiliser Docker (Alternative)

#### 1. Créer un conteneur Docker avec Node.js 20

```bash
docker run -it --rm \
  -v "$(pwd):/workspace" \
  -w /workspace \
  node:20-alpine \
  sh -c "npm install -g firebase-tools && firebase deploy --only hosting"
```

---

### Option C: Déployer manuellement sur Firebase Console

#### 1. Aller sur Firebase Console

- URL : https://console.firebase.google.com/
- Projet : `tshiakani-vtc`

#### 2. Aller dans Hosting

- Cliquez sur "Hosting" dans le menu de gauche
- Cliquez sur "Get started" si c'est la première fois

#### 3. Uploader les fichiers

- Le dossier `admin-dashboard/dist/` contient les fichiers à déployer
- Utilisez l'interface Firebase Console pour uploader les fichiers

#### 4. Configurer les règles de réécriture

Dans Firebase Console > Hosting > Configuration, ajoutez :

```json
{
  "hosting": {
    "public": "admin-dashboard/dist",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 🔧 Configuration Post-Déploiement

### 1. Vérifier CORS dans le Backend

Le backend doit autoriser les requêtes depuis le dashboard Firebase :

**Dans Cloud Run (variables d'environnement)** :
```env
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app
```

**Ou dans le backend local (`.env`)** :
```env
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app,http://localhost:5173,http://localhost:3001
```

### 2. Vérifier la Clé API Admin

La clé API Admin doit être la même dans :
- **Backend** (variable d'environnement `ADMIN_API_KEY`)
- **Dashboard** (fichier `.env.production` : `VITE_ADMIN_API_KEY`)

**Clé actuelle configurée** :
```
aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### 3. Tester le Dashboard

Une fois déployé, testez :

1. **Accéder au dashboard** :
   - URL : `https://tshiakani-vtc.firebaseapp.com`
   - URL alternative : `https://tshiakani-vtc.web.app`

2. **Vérifier la connexion au backend** :
   - Ouvrez la console du navigateur (F12)
   - Vérifiez les requêtes vers `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/admin/*`
   - Vérifiez qu'il n'y a pas d'erreurs CORS

3. **Tester l'authentification** :
   - Connectez-vous au dashboard
   - Vérifiez que les données s'affichent correctement

---

## 📝 Fichiers de Configuration

### Fichier `.env.production`

**Emplacement** : `admin-dashboard/.env.production`

**Contenu** :
```env
# URL de l'API backend (Cloud Run)
VITE_API_URL=https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api

# Clé API Admin
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8

# URL du serveur WebSocket
VITE_SOCKET_URL=https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app
```

### Fichier `firebase.json`

**Emplacement** : `firebase.json`

**Contenu** :
```json
{
  "hosting": {
    "public": "admin-dashboard/dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
```

---

## ✅ Checklist de Déploiement

### Avant le Déploiement

- [x] Fichier `.env.production` créé
- [x] Dashboard builder (`admin-dashboard/dist/`)
- [x] Configuration Firebase (`firebase.json`)
- [ ] Firebase CLI installé (nécessite Node.js 18/20/22)
- [ ] Connecté à Firebase (`firebase login`)
- [ ] Projet Firebase sélectionné (`firebase use tshiakani-vtc`)

### Déploiement

- [ ] Déployer sur Firebase Hosting (`firebase deploy --only hosting`)
- [ ] Vérifier l'URL du dashboard déployé
- [ ] Vérifier la connexion au backend
- [ ] Tester l'authentification
- [ ] Vérifier les données affichées

### Après le Déploiement

- [ ] Vérifier CORS dans le backend
- [ ] Tester toutes les fonctionnalités du dashboard
- [ ] Vérifier les logs Firebase
- [ ] Documenter l'URL du dashboard

---

## 🔍 Vérification Post-Déploiement

### 1. Vérifier l'Accessibilité

```bash
curl https://tshiakani-vtc.firebaseapp.com
# Doit retourner 200 OK (au lieu de 404)
```

### 2. Vérifier la Connexion au Backend

Dans le navigateur (console F12), vérifier :
- ✅ Requêtes vers `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/admin/*`
- ✅ Réponses avec statut 200
- ❌ Pas d'erreurs CORS
- ❌ Pas d'erreurs 401 (authentification)

### 3. Tester les Fonctionnalités

- ✅ Se connecter au dashboard
- ✅ Voir les statistiques
- ✅ Voir la liste des conducteurs
- ✅ Voir la liste des courses
- ✅ Voir la carte avec les conducteurs disponibles

---

## 🆘 Dépannage

### Erreur : "Firebase CLI requires Node.js 18, 20 or 22"

**Solution** : Utiliser nvm pour installer Node.js 20

```bash
nvm install 20
nvm use 20
npm install -g firebase-tools
```

### Erreur : "CORS policy"

**Solution** : Vérifier que CORS est configuré dans le backend pour autoriser Firebase

```env
CORS_ORIGIN=https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app
```

### Erreur : "403 Forbidden" sur les routes `/api/admin/*`

**Solution** : Vérifier que la clé API Admin est correcte dans `.env.production`

```env
VITE_ADMIN_API_KEY=aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8
```

### Erreur : "404 Not Found" sur le dashboard

**Solution** : Vérifier que le dossier `admin-dashboard/dist/` existe et contient les fichiers

```bash
ls -la admin-dashboard/dist/
# Doit contenir index.html et assets/
```

---

## 📊 Résumé

### État Actuel

- ✅ **Configuration** : Prête
- ✅ **Build** : Terminé
- ⚠️ **Déploiement** : En attente (nécessite Node.js 18/20/22)

### Prochaines Étapes

1. Installer Node.js 20 avec nvm
2. Installer Firebase CLI
3. Se connecter à Firebase
4. Déployer le dashboard
5. Vérifier la connexion au backend
6. Tester les fonctionnalités

### URLs

- **Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app`
- **Dashboard (attendu)** : `https://tshiakani-vtc.firebaseapp.com`
- **Dashboard (alternatif)** : `https://tshiakani-vtc.web.app`

---

**Date de création** : $(date)
**Dernière mise à jour** : $(date)

