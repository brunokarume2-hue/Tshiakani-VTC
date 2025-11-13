# 🎨 Guide de Connexion Dashboard Admin

Guide complet pour connecter le dashboard admin au backend.

## 🎯 Configuration Rapide

### 1. Configuration Automatique

Le dashboard est **déjà configuré** pour se connecter au backend local.

**Fichier:** `admin-dashboard/src/services/api.js`

```javascript
const API_URL = import.meta.env.VITE_API_URL || 
  (import.meta.env.DEV ? '/api' : 'http://localhost:3000/api')
```

### 2. Variables d'Environnement

**Créer le fichier:** `admin-dashboard/.env.local`

```env
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
```

### 3. Démarrer le Dashboard

```bash
cd admin-dashboard
npm install
npm run dev
```

**Le dashboard sera accessible sur:** `http://localhost:5173`

## 🔧 Configuration Détaillée

### Fichier .env.local

**Créer:** `admin-dashboard/.env.local`

```env
# URL de l'API backend
VITE_API_URL=http://localhost:3000/api

# URL du serveur WebSocket
VITE_SOCKET_URL=http://localhost:3000

# Clé API Admin (optionnel)
VITE_ADMIN_API_KEY=votre_admin_api_key
```

### Configuration CORS dans le Backend

**Vérifier:** `backend/server.postgres.js`

```javascript
app.use(cors({
  origin: process.env.CORS_ORIGIN || [
    "http://localhost:3001",
    "http://localhost:5173"  // ✅ Port Vite par défaut
  ],
  credentials: true
}));
```

**Mettre à jour .env:**
```env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173
```

## 🧪 Tests

### 1. Test de Connexion

**Ouvrir:** `http://localhost:5173`

**Vérifier la console du navigateur (F12):**
```
🔧 Configuration API: { API_URL: 'http://localhost:3000/api', ... }
```

### 2. Test d'Authentification

1. **Aller sur la page de connexion**
2. **Se connecter** avec un numéro de téléphone admin
3. **Vérifier** que la connexion réussit

### 3. Test des Données

1. **Aller sur le dashboard**
2. **Vérifier** que les statistiques s'affichent
3. **Vérifier** que les courses s'affichent
4. **Vérifier** que les utilisateurs s'affichent

## ✅ Checklist

- [ ] Variables d'environnement configurées (`.env.local`)
- [ ] Dépendances installées (`npm install`)
- [ ] Dashboard démarré (`npm run dev`)
- [ ] Backend démarré sur le port 3000
- [ ] CORS configuré dans le backend
- [ ] Connexion réussie
- [ ] Authentification fonctionnelle
- [ ] Données affichées correctement

## 🐛 Dépannage

### Erreur: "Cannot connect to API"

**Solutions:**
1. Vérifier que le backend est démarré
2. Vérifier l'URL dans `.env.local`
3. Vérifier les logs du backend
4. Vérifier la console du navigateur (F12)

### Erreur: "CORS policy"

**Solution:**
```bash
# Mettre à jour CORS dans backend/.env
CORS_ORIGIN=http://localhost:3001,http://localhost:5173
```

### Erreur: "401 Unauthorized"

**Solutions:**
1. Vérifier que vous êtes connecté
2. Vérifier que le token est valide
3. Vérifier les identifiants admin

## 📚 Documentation

- **API Service:** `admin-dashboard/src/services/api.js`
- **Auth Context:** `admin-dashboard/src/services/AuthContext.jsx`
- **Configuration:** `admin-dashboard/.env.local`

---

**Date:** Novembre 2025  
**Version:** 1.0.0

