# 🗄️ Backend PostgreSQL + PostGIS - Tshiakani VTC

## 🎯 Pourquoi PostgreSQL + PostGIS ?

- ⚡ **10x plus rapide** pour les requêtes géospatiales
- 🎯 **Calcul de distance natif** et précis
- 📍 **Indexation spatiale GIST** optimisée
- 🔍 **Requêtes complexes** simplifiées avec SQL
- 💰 **Transactions ACID** pour les paiements

## 🚀 Installation

### 1. Installer PostgreSQL + PostGIS

**macOS :**
```bash
brew install postgresql@14 postgis
brew services start postgresql@14
```

**Linux :**
```bash
sudo apt-get install postgresql-14 postgresql-14-postgis-3
```

### 2. Créer la base de données

```bash
psql -U postgres
CREATE DATABASE tshiakani_vtc;
\c tshiakani_vtc
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 3. Exécuter les migrations

```bash
cd backend
psql -U postgres -d tshiakani_vtc -f migrations/001_init_postgis.sql
```

### 4. Installer les dépendances

```bash
npm install typeorm pg @types/pg
```

### 5. Configurer l'environnement

```bash
cp .env.postgres.example .env
# Modifier .env avec vos credentials PostgreSQL
```

### 6. Démarrer le serveur

```bash
node server.postgres.js
# ou
npm run dev  # Si package.json modifié
```

## 📊 Structure

```
backend/
├── config/
│   └── database.js          # Configuration TypeORM
├── entities/
│   ├── User.js              # Utilisateur avec PostGIS
│   ├── Ride.js              # Course avec PostGIS
│   ├── Notification.js      # Notifications
│   └── SOSReport.js         # Alertes SOS avec PostGIS
├── routes.postgres/
│   ├── auth.js              # Authentification
│   ├── rides.js             # Courses optimisées
│   ├── location.js          # Localisation PostGIS
│   ├── users.js             # Utilisateurs
│   ├── admin.js             # Administration
│   ├── sos.js               # Alertes SOS
│   └── notifications.js      # Notifications
├── middlewares.postgres/
│   └── auth.js              # Authentification
├── migrations/
│   └── 001_init_postgis.sql # Schéma SQL complet
└── server.postgres.js        # Serveur PostgreSQL
```

## 🔍 Requêtes optimisées

### Trouver conducteurs proches

```javascript
const drivers = await User.findNearbyDrivers(lat, lon, 5, AppDataSource);
// Retourne avec distance calculée automatiquement
```

### Calculer distance course

```javascript
const distance = await Ride.calculateDistance(rideId, AppDataSource);
// Distance en kilomètres calculée par PostGIS
```

## 📝 Documentation complète

Voir `INSTALLATION_POSTGRES.md` et `MIGRATION_COMPLETE.md` pour plus de détails.

