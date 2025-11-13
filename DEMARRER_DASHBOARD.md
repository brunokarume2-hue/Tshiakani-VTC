# 🚀 Guide de Démarrage Rapide - Dashboard Admin

## Méthode 1 : Script automatique (Recommandé)

Exécutez simplement :
```bash
./DEMARRER_DASHBOARD.sh
```

## Méthode 2 : Démarrage manuel

### Étape 1 : Installer les dépendances (première fois seulement)

**Backend :**
```bash
cd backend
npm install
```

**Dashboard :**
```bash
cd admin-dashboard
npm install
```

### Étape 2 : Démarrer le backend

Ouvrez un terminal et exécutez :
```bash
cd backend
npm run dev
```

Le backend sera accessible sur **http://localhost:3000**

### Étape 3 : Démarrer le dashboard

Ouvrez un **nouveau terminal** et exécutez :
```bash
cd admin-dashboard
npm run dev
```

Le dashboard sera accessible sur **http://localhost:3001**

### Étape 4 : Accéder au dashboard

1. Ouvrez votre navigateur
2. Allez à : **http://localhost:3001**
3. Connectez-vous avec :
   - **Numéro de téléphone** : `+243900000000` (ou n'importe quel numéro)
   - **Mot de passe** : (laissez vide)

## ⚠️ Prérequis

- **Node.js** installé (version 18+)
  - Vérifier : `node --version`
  - Télécharger : https://nodejs.org

- **MongoDB** en cours d'exécution
  - Vérifier : `mongod --version`
  - Démarrer : `mongod`

## 🔍 Vérification

### Vérifier que le backend fonctionne :
```bash
curl http://localhost:3000/health
```
Devrait retourner : `{"status":"OK",...}`

### Vérifier que le dashboard fonctionne :
Ouvrez http://localhost:3001 dans votre navigateur

## 🐛 Dépannage

### Erreur "npm: command not found"
- Installez Node.js depuis https://nodejs.org
- Redémarrez votre terminal

### Erreur "Port 3000 already in use"
- Arrêtez le processus utilisant le port 3000
- Ou changez le port dans `backend/.env`

### Erreur "Port 3001 already in use"
- Arrêtez le processus utilisant le port 3001
- Ou changez le port dans `admin-dashboard/vite.config.js`

### Erreur de connexion MongoDB
- Vérifiez que MongoDB est démarré : `mongod`
- Vérifiez la connexion dans `backend/.env`

