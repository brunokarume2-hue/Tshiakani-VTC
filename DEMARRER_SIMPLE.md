# 🚀 Démarrage Simple - Dashboard Admin

## Instructions étape par étape

### 1. Ouvrir 2 terminaux

**Terminal 1** - Pour le backend
**Terminal 2** - Pour le dashboard

### 2. Terminal 1 - Backend

```bash
cd "/Users/admin/Documents/wewa taxi/backend"
npm install
npm run dev
```

Vous devriez voir : `🚀 Serveur démarré sur le port 3000`

### 3. Terminal 2 - Dashboard

```bash
cd "/Users/admin/Documents/wewa taxi/admin-dashboard"
npm install
npm run dev
```

Vous devriez voir : `Local: http://localhost:3001`

### 4. Ouvrir le navigateur

Allez à : **http://localhost:3001**

### 5. Se connecter

- **Numéro** : `+243900000000`
- **Mot de passe** : (vide)

## ⚠️ Si ça ne marche pas

### Vérifier Node.js
```bash
node --version
npm --version
```
Si erreur, installez Node.js : https://nodejs.org

### Vérifier MongoDB
```bash
mongod --version
```
Si erreur, installez MongoDB : https://www.mongodb.com/try/download/community

### Vérifier les ports
```bash
# Vérifier le port 3000
lsof -i:3000

# Vérifier le port 3001
lsof -i:3001
```

### Réinstaller les dépendances
```bash
# Backend
cd "/Users/admin/Documents/wewa taxi/backend"
rm -rf node_modules
npm install

# Dashboard
cd "/Users/admin/Documents/wewa taxi/admin-dashboard"
rm -rf node_modules
npm install
```

## 📞 Message d'erreur spécifique ?

Dites-moi exactement quel message d'erreur vous voyez et je vous aiderai à le résoudre !

