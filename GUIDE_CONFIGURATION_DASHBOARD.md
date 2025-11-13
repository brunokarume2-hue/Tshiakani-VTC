# 🎨 Guide de Configuration Dashboard Admin - Tshiakani VTC

## ✅ Configuration Complète

Le dashboard admin est déjà configuré pour se connecter au backend local !

---

## 📋 Configuration Actuelle

### Variables d'Environnement

**Fichier:** `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
```

### Proxy Vite

**Fichier:** `admin-dashboard/vite.config.js`

Le dashboard utilise un proxy Vite qui redirige `/api` vers `http://localhost:3000` :
- **Port du dashboard:** `3001` (ou `5173` si 3001 est occupé)
- **Proxy:** `/api` → `http://localhost:3000/api`
- **Socket:** `http://localhost:3000`

---

## 🚀 Démarrage du Dashboard

### 1. Installer les Dépendances

```bash
cd admin-dashboard
npm install
```

### 2. Démarrer le Dashboard

```bash
npm run dev
```

**Le dashboard sera accessible sur:** `http://localhost:5173` (ou `http://localhost:3001`)

### 3. Vérifier la Connexion

1. Ouvrir `http://localhost:5173` dans votre navigateur
2. Vérifier dans la console du navigateur (F12) :
   - ✅ Configuration API affichée
   - ✅ Pas d'erreurs CORS
   - ✅ Connexion réussie

---

## 🔐 Connexion au Dashboard

### 1. Page de Connexion

1. Ouvrir `http://localhost:5173`
2. Vous serez redirigé vers la page de connexion
3. Entrer un numéro de téléphone admin

### 2. Authentification

Le dashboard utilise JWT pour l'authentification :
- Le token est stocké dans `localStorage` sous la clé `admin_token`
- Le token est automatiquement ajouté aux requêtes
- En cas d'erreur 401, redirection vers la page de connexion

### 3. Création d'un Compte Admin

Si le numéro de téléphone n'existe pas, le système créera automatiquement un compte admin.

---

## 📊 Fonctionnalités Disponibles

### Dashboard
- ✅ Statistiques générales (utilisateurs, courses, revenus)
- ✅ Graphiques et visualisations
- ✅ Vue d'ensemble en temps réel

### Courses
- ✅ Liste des courses (avec filtres)
- ✅ Détails des courses
- ✅ Historique des courses
- ✅ Filtres par statut et dates

### Utilisateurs
- ✅ Liste des utilisateurs
- ✅ Gestion des utilisateurs
- ✅ Bannir/débannir des utilisateurs
- ✅ Filtres par rôle

### Conducteurs
- ✅ Liste des conducteurs en ligne
- ✅ Filtres par localisation
- ✅ Statut des conducteurs

### Carte
- ✅ Visualisation en temps réel des conducteurs
- ✅ Visualisation des courses actives
- ✅ Géolocalisation

### Alertes SOS
- ✅ Liste des alertes SOS
- ✅ Filtres par statut
- ✅ Résolution des alertes

---

## 🔧 Configuration Avancée

### Variables d'Environnement

**Fichier:** `admin-dashboard/.env.local`

```env
# URL de l'API backend
VITE_API_URL=http://localhost:3000/api

# URL du serveur WebSocket/Socket.io
VITE_SOCKET_URL=http://localhost:3000

# Clé API admin (optionnel, a une valeur par défaut)
VITE_ADMIN_API_KEY=your-admin-api-key
```

### Proxy Vite

Le proxy Vite redirige automatiquement les requêtes `/api` vers le backend :

```javascript
// vite.config.js
server: {
  port: 3001,
  proxy: {
    '/api': {
      target: 'http://localhost:3000',
      changeOrigin: true
    }
  }
}
```

---

## ✅ Checklist de Configuration

### Prérequis
- [x] Backend démarré sur le port 3000
- [x] CORS configuré dans le backend
- [x] `.env.local` créé avec les bonnes URLs
- [x] Dépendances installées (`npm install`)

### Démarrage
- [ ] Dashboard démarré (`npm run dev`)
- [ ] Dashboard accessible sur `http://localhost:5173`
- [ ] Console du navigateur sans erreurs
- [ ] Connexion réussie

### Tests
- [ ] Authentification testée
- [ ] Dashboard affiché
- [ ] Statistiques affichées
- [ ] Liste des courses affichée
- [ ] Liste des utilisateurs affichée
- [ ] Carte fonctionnelle
- [ ] WebSocket fonctionnel

---

## 🧪 Test de la Connexion

### 1. Vérifier que le Backend est Démarré

```bash
curl http://localhost:3000/health
```

**Résultat attendu:**
```json
{"status":"OK","database":"connected","timestamp":"..."}
```

### 2. Vérifier CORS

Le backend doit autoriser les requêtes depuis `http://localhost:5173` (ou `http://localhost:3001`).

Vérifier dans `backend/.env` :
```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173,...
```

### 3. Tester depuis le Dashboard

1. Ouvrir `http://localhost:5173`
2. Ouvrir la console du navigateur (F12)
3. Vérifier les logs :
   - ✅ Configuration API affichée
   - ✅ Pas d'erreurs CORS
   - ✅ Connexion réussie

---

## 🐛 Dépannage

### Erreur: "Cannot connect to server"

**Solutions:**
1. Vérifier que le backend est démarré : `curl http://localhost:3000/health`
2. Vérifier l'URL dans `.env.local` : `VITE_API_URL=http://localhost:3000/api`
3. Vérifier que le proxy Vite est configuré correctement

### Erreur: "CORS policy"

**Solution:**
```bash
# Vérifier CORS dans backend/.env
cat backend/.env | grep CORS_ORIGIN

# Si le port n'est pas présent, l'ajouter
# Le port 5173 (Vite) devrait être dans CORS_ORIGIN
```

### Erreur: "Cannot find module"

**Solution:**
```bash
cd admin-dashboard
rm -rf node_modules package-lock.json
npm install
```

### Le dashboard ne se charge pas

**Solutions:**
1. Vérifier que le port 5173 (ou 3001) est disponible
2. Vérifier les erreurs dans la console du navigateur
3. Vérifier que le backend est démarré
4. Vérifier CORS dans le backend

---

## 📚 Documentation

- **README_DEMARRAGE.md** - Guide de démarrage
- **INTEGRATION.md** - Guide d'intégration
- **ACCES_DASHBOARD.md** - Guide d'accès
- **api.js** - Service API
- **AuthContext.jsx** - Contexte d'authentification

---

## 🎉 Résultat

Une fois configuré et démarré :

- ✅ Dashboard accessible sur `http://localhost:5173`
- ✅ Connexion au backend réussie
- ✅ Authentification fonctionnelle
- ✅ Toutes les fonctionnalités disponibles
- ✅ WebSocket fonctionnel pour les mises à jour temps réel

---

**Date:** Novembre 2025  
**Version:** 1.0.0  
**Backend:** `http://localhost:3000`  
**Dashboard:** `http://localhost:5173`

