# 🎨 Guide de démarrage - Dashboard Admin

## 📋 Prérequis

- **Node.js 18+** et **npm**

## 🔧 Installation

### 1. Installer les dépendances

```bash
cd admin-dashboard
npm install
```

### 2. Configurer l'URL de l'API

Créer un fichier `.env` à la racine du dossier `admin-dashboard` :

```bash
VITE_API_URL=http://localhost:3000/api
```

## ▶️ Démarrer le dashboard

### Mode développement

```bash
npm run dev
```

Le dashboard sera accessible sur `http://localhost:5173`

### Build pour production

```bash
npm run build
```

Les fichiers seront générés dans le dossier `dist/`.

## 🔐 Connexion

1. Ouvrir `http://localhost:5173`
2. Utiliser un numéro de téléphone pour se connecter en tant qu'admin
3. Le système créera automatiquement un compte admin si nécessaire

## 📊 Fonctionnalités

- **Dashboard** : Vue d'ensemble avec statistiques
- **Courses** : Gestion et historique des courses
- **Utilisateurs** : Liste et gestion des utilisateurs
- **Carte** : Visualisation en temps réel des conducteurs
- **Alertes SOS** : Gestion des alertes d'urgence

## 🔧 Configuration

### Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `VITE_API_URL` | URL de l'API backend | `http://localhost:3000/api` |

## 🐛 Dépannage

### Erreur de connexion à l'API

Vérifier que :
- Le backend est démarré sur le port 3000
- L'URL dans `.env` est correcte
- CORS est configuré correctement dans le backend

### Erreur "Cannot find module"

Réinstaller les dépendances :
```bash
rm -rf node_modules package-lock.json
npm install
```

