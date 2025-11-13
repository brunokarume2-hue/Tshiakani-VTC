# 🔍 Instructions de Vérification des Connexions

Ce document vous guide pour vérifier les connexions entre le backend, l'application driver, et la base de données.

---

## 📋 Résumé de l'État Actuel

### ✅ Configurations Présentes
- ✅ Backend API configuré (`server.postgres.js`)
- ✅ Routes API disponibles (Client, Driver, Admin)
- ✅ Configuration iOS présente (`ConfigurationService.swift`)
- ✅ Fichier `.env` présent dans `backend/`
- ✅ Dashboard Admin configuré

### ⚠️ À Vérifier
- ⚠️ PostgreSQL en cours d'exécution
- ⚠️ Connexion à la base de données
- ⚠️ Extension PostGIS installée
- ⚠️ Backend démarré

---

## 🚀 Étapes de Vérification

### Étape 1: Vérifier PostgreSQL

#### 1.1 Vérifier si PostgreSQL est installé

```bash
# Vérifier si psql est disponible
which psql

# Vérifier la version
psql --version
```

Si PostgreSQL n'est pas installé:
```bash
# Installer PostgreSQL (macOS)
brew install postgresql@14
# ou
brew install postgresql@15
# ou
brew install postgresql@16
```

#### 1.2 Vérifier si PostgreSQL est en cours d'exécution

```bash
# Vérifier le statut
brew services list | grep postgresql

# Démarrer PostgreSQL (si nécessaire)
brew services start postgresql@14
# ou
brew services start postgresql@15
# ou
brew services start postgresql@16
```

#### 1.3 Vérifier la connexion

```bash
# Tester la connexion
psql -h localhost -p 5432 -U postgres -d postgres
```

---

### Étape 2: Vérifier la Configuration de la Base de Données

#### 2.1 Vérifier le fichier .env

```bash
cd backend
cat .env | grep -E "DB_HOST|DB_PORT|DB_USER|DB_NAME|DB_PASSWORD"
```

#### 2.2 Vérifier les valeurs

Les valeurs attendues dans `.env`:
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin  # ou postgres
DB_NAME=tshiakanivtc  # ou tshiakani_vtc
DB_PASSWORD=votre_mot_de_passe
```

#### 2.3 Créer la base de données (si nécessaire)

```bash
# Se connecter à PostgreSQL
psql -h localhost -p 5432 -U postgres

# Créer la base de données
CREATE DATABASE tshiakanivtc;

# Créer l'utilisateur (si nécessaire)
CREATE USER admin WITH PASSWORD 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON DATABASE tshiakanivtc TO admin;

# Quitter
\q
```

---

### Étape 3: Installer PostGIS

#### 3.1 Installer l'extension PostGIS

```bash
# Se connecter à la base de données
psql -h localhost -p 5432 -U admin -d tshiakanivtc

# Installer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# Vérifier l'installation
SELECT PostGIS_version();

# Quitter
\q
```

#### 3.2 Vérifier PostGIS via le script Node.js

```bash
cd backend
node test-database-connection.js
```

---

### Étape 4: Tester la Connexion à la Base de Données

#### 4.1 Utiliser le script Node.js (Recommandé)

```bash
cd backend
node test-database-connection.js
```

Ce script vérifie:
- ✅ Connexion PostgreSQL
- ✅ Extension PostGIS
- ✅ Tables présentes
- ✅ Entités TypeORM

#### 4.2 Utiliser psql directement

```bash
# Se connecter à la base de données
psql -h localhost -p 5432 -U admin -d tshiakanivtc

# Tester une requête
SELECT NOW();

# Vérifier PostGIS
SELECT PostGIS_version();

# Vérifier les tables
\dt

# Quitter
\q
```

---

### Étape 5: Démarrer le Backend

#### 5.1 Installer les dépendances (si nécessaire)

```bash
cd backend
npm install
```

#### 5.2 Démarrer le backend

```bash
cd backend
npm run dev
```

Vous devriez voir:
```
✅ Connecté à PostgreSQL avec PostGIS
✅ PostGIS version: ...
🚀 Serveur démarré sur le port 3000
📡 WebSocket namespace /ws/driver disponible
📡 WebSocket namespace /ws/client disponible
🌐 API disponible sur http://0.0.0.0:3000/api
⚡ Service temps réel des courses activé
```

---

### Étape 6: Vérifier les Connexions

#### 6.1 Exécuter le script de vérification complet

```bash
./verifier-connexions.sh
```

Ce script vérifie:
- ✅ Fichier .env
- ✅ PostgreSQL
- ✅ Backend
- ✅ Routes API
- ✅ Configuration iOS

#### 6.2 Consulter le rapport

Le script génère un rapport dans:
```
rapport-verification-connexions-YYYYMMDD-HHMMSS.txt
```

---

### Étape 7: Tester les Routes API

#### 7.1 Tester le health check

```bash
curl http://localhost:3000/health
```

#### 7.2 Tester l'authentification

```bash
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243900000000",
    "role": "client"
  }'
```

#### 7.3 Tester les routes driver

```bash
# Avec un token JWT valide
curl -X POST http://localhost:3000/api/driver/location/update \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "latitude": -4.3276,
    "longitude": 15.3136
  }'
```

---

## 🔧 Résolution des Problèmes

### Problème 1: PostgreSQL n'est pas accessible

**Solution**:
```bash
# Vérifier si PostgreSQL est en cours d'exécution
brew services list | grep postgresql

# Démarrer PostgreSQL
brew services start postgresql@14
```

### Problème 2: Erreur de connexion à la base de données

**Solutions**:
1. Vérifier que PostgreSQL est en cours d'exécution
2. Vérifier les credentials dans `.env`
3. Vérifier que la base de données existe
4. Vérifier que l'utilisateur a les permissions nécessaires

### Problème 3: PostGIS n'est pas installé

**Solution**:
```bash
# Installer PostGIS
psql -h localhost -p 5432 -U admin -d tshiakanivtc -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

### Problème 4: Backend ne démarre pas

**Solutions**:
1. Vérifier que PostgreSQL est accessible
2. Vérifier que le fichier `.env` est correctement configuré
3. Vérifier que les dépendances sont installées (`npm install`)
4. Vérifier les logs d'erreur

### Problème 5: Routes API non accessibles

**Solutions**:
1. Vérifier que le backend est démarré
2. Vérifier que le port 3000 est disponible
3. Vérifier les logs du backend
4. Tester avec curl ou Postman

---

## 📊 Routes API Disponibles

### Routes Client
- `POST /api/auth/signin` - Authentification
- `POST /api/auth/verify` - Vérification OTP
- `GET /api/auth/profile` - Profil utilisateur
- `POST /api/rides/create` - Création de course
- `POST /api/rides/estimate-price` - Estimation du prix
- `GET /api/client/track_driver/:rideId` - Suivi du chauffeur
- `GET /api/rides/history/:userId` - Historique des courses

### Routes Driver
- `POST /api/driver/location/update` - Mise à jour position
- `POST /api/driver/accept_ride/:rideId` - Accepter une course
- `POST /api/driver/reject_ride/:rideId` - Rejeter une course
- `POST /api/driver/complete_ride/:rideId` - Compléter une course

### Routes Admin
- `GET /api/admin/available_drivers` - Chauffeurs disponibles
- `GET /api/admin/active_rides` - Courses actives
- `GET /api/admin/stats` - Statistiques

---

## 🔍 Scripts de Vérification

### 1. Script de Vérification Complète
```bash
./verifier-connexions.sh
```

### 2. Test de Connexion à la Base de Données
```bash
cd backend
node test-database-connection.js
```

### 3. Test de Connexion Backend
```bash
./test-backend-connection.sh
```

---

## ✅ Checklist de Vérification

- [ ] PostgreSQL installé
- [ ] PostgreSQL en cours d'exécution
- [ ] Base de données créée
- [ ] Extension PostGIS installée
- [ ] Fichier `.env` configuré
- [ ] Connexion à la base de données réussie
- [ ] Backend démarré
- [ ] Routes API accessibles
- [ ] WebSocket fonctionnel
- [ ] Configuration iOS vérifiée

---

## 📝 Notes

- Les URLs backend sont différentes selon le mode (DEBUG vs PRODUCTION)
- Toutes les routes API (sauf `/api/auth/signin`) nécessitent un token JWT
- Les connexions WebSocket nécessitent également un token JWT
- L'extension PostGIS est requise pour les fonctionnalités de géolocalisation

---

**Dernière mise à jour**: $(date)

