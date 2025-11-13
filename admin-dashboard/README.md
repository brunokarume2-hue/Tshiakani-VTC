# 📊 Wewa Taxi - Dashboard Admin

Dashboard administrateur React.js pour gérer l'application Wewa Taxi.

## 🚀 Installation

1. Installer les dépendances :
```bash
npm install
```

2. Configurer l'URL de l'API dans `.env` :
```
VITE_API_URL=http://localhost:3000/api
```

3. Démarrer le serveur de développement :
```bash
npm run dev
```

4. Ouvrir http://localhost:3001

## 📋 Fonctionnalités

- **Tableau de bord** : Statistiques générales, graphiques
- **Gestion des courses** : Historique avec filtres
- **Gestion des utilisateurs** : Liste, bannissement
- **Carte en temps réel** : Conducteurs en ligne, courses actives

## 🎨 Technologies

- React 18
- React Router
- Tailwind CSS
- Chart.js
- Axios
- Socket.io Client

## 🔐 Authentification

L'authentification se fait via JWT. Le token est stocké dans `localStorage`.

## 📝 Licence

Propriétaire - Wewa Taxi

