# 🚀 Guide de Déploiement - Wewa Taxi

Guide complet pour déployer l'application Wewa Taxi en production.

## 📋 Prérequis

- Node.js 18+ installé
- MongoDB 6+ installé et configuré
- Compte Firebase (pour les notifications push - optionnel)
- Serveur avec accès SSH (pour le déploiement)

## 🔧 Configuration Backend

### 1. Installation

```bash
cd backend
npm install
```

### 2. Configuration MongoDB

Créer une base de données MongoDB :
```bash
mongosh
use wewa_taxi
```

### 3. Variables d'environnement

Créer un fichier `.env` :
```bash
cp .env.example .env
```

Configurer les variables :
- `MONGODB_URI` : URL de connexion MongoDB
- `JWT_SECRET` : Clé secrète pour JWT (générer une clé forte)
- `CORS_ORIGIN` : URL du dashboard admin
- `FIREBASE_*` : Credentials Firebase (optionnel)

### 4. Démarrer le serveur

```bash
# Développement
npm run dev

# Production
npm start
```

## 🖥️ Configuration Dashboard Admin

### 1. Installation

```bash
cd admin-dashboard
npm install
```

### 2. Configuration

Créer un fichier `.env` :
```
VITE_API_URL=http://localhost:3000/api
```

### 3. Build pour production

```bash
npm run build
```

Les fichiers seront dans le dossier `dist/`

### 4. Servir les fichiers

Vous pouvez utiliser :
- Nginx
- Apache
- Serveur statique (serve, etc.)

## 📱 Configuration iOS

### 1. Permissions Info.plist

Ajouter dans `Info.plist` :
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Wewa Taxi a besoin de votre localisation pour trouver les conducteurs disponibles.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Wewa Taxi a besoin de votre localisation en arrière-plan pour suivre votre trajet.</string>
```

### 2. Configuration API

Modifier `APIService.swift` avec l'URL de votre backend :
```swift
private let baseURL = "https://api.wewataxi.com"
```

### 3. Build et déploiement

1. Ouvrir le projet dans Xcode
2. Configurer les certificats de signature
3. Archiver le projet
4. Uploader vers App Store Connect

## 🌐 Déploiement Production

### Backend (Node.js)

#### Option 1: PM2

```bash
npm install -g pm2
pm2 start server.js --name wewa-taxi-api
pm2 save
pm2 startup
```

#### Option 2: Docker

Créer un `Dockerfile` :
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### Dashboard Admin

Déployer le dossier `dist/` sur un serveur web (Nginx, etc.)

## 🔐 Sécurité Production

1. **JWT Secret** : Utiliser une clé forte et unique
2. **HTTPS** : Configurer SSL/TLS
3. **Rate Limiting** : Ajuster selon vos besoins
4. **CORS** : Limiter aux domaines autorisés
5. **MongoDB** : Activer l'authentification
6. **Firewall** : Restreindre l'accès aux ports nécessaires

## 📊 Monitoring

- Utiliser PM2 pour le monitoring Node.js
- Configurer des logs (Winston, etc.)
- Surveiller MongoDB avec MongoDB Compass
- Utiliser des outils comme New Relic ou Datadog

## 🧪 Tests

```bash
# Backend
cd backend
npm test

# Dashboard (à implémenter)
cd admin-dashboard
npm test
```

## 📝 Checklist Déploiement

- [ ] MongoDB configuré et accessible
- [ ] Variables d'environnement configurées
- [ ] JWT secret généré et sécurisé
- [ ] HTTPS configuré
- [ ] CORS configuré correctement
- [ ] Rate limiting activé
- [ ] Logs configurés
- [ ] Monitoring en place
- [ ] Backup MongoDB configuré
- [ ] Tests effectués

## 🆘 Support

En cas de problème :
1. Vérifier les logs du serveur
2. Vérifier la connexion MongoDB
3. Vérifier les variables d'environnement
4. Vérifier les permissions de fichiers

