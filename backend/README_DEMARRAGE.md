# 🚀 Guide de démarrage - Backend PostgreSQL

## 📋 Prérequis

1. **PostgreSQL 14+** avec **PostGIS** installé
2. **Node.js 18+** et **npm**

## 🔧 Installation

### 1. Installer les dépendances

```bash
cd backend
npm install
```

### 2. Configurer la base de données

Créer un fichier `.env` à partir de `.env.example` :

```bash
cp .env.example .env
```

Modifier les variables dans `.env` selon votre configuration PostgreSQL.

### 3. Créer la base de données et activer PostGIS

```bash
# Se connecter à PostgreSQL
psql -U postgres

# Créer la base de données
CREATE DATABASE TshiakaniVTC;

# Se connecter à la base
\c TshiakaniVTC

# Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 4. Exécuter les migrations

```bash
npm run migrate
# ou manuellement :
psql -U postgres -d TshiakaniVTC -f migrations/001_init_postgis.sql
```

## ▶️ Démarrer le serveur

### Mode développement (avec rechargement automatique)

```bash
npm run dev
```

### Mode production

```bash
npm start
```

Le serveur démarre sur `http://localhost:3000` par défaut.

## ✅ Vérification

Vérifier que le serveur fonctionne :

```bash
curl http://localhost:3000/health
```

Réponse attendue :
```json
{
  "status": "OK",
  "database": "connected",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

## 📡 Endpoints principaux

- `POST /api/auth/signin` - Connexion/Inscription
- `POST /api/auth/admin/login` - Connexion admin
- `GET /api/auth/verify` - Vérifier le token
- `POST /api/rides/create` - Créer une course
- `GET /api/admin/stats` - Statistiques (admin)
- `GET /api/admin/rides` - Liste des courses (admin)
- `GET /api/admin/sos` - Alertes SOS (admin)

## 🔐 Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `DB_HOST` | Hôte PostgreSQL | `localhost` |
| `DB_PORT` | Port PostgreSQL | `5432` |
| `DB_USER` | Utilisateur PostgreSQL | `postgres` |
| `DB_PASSWORD` | Mot de passe PostgreSQL | `postgres` |
| `DB_NAME` | Nom de la base de données | `TshiakaniVTC` |
| `JWT_SECRET` | Clé secrète JWT | (requis) |
| `PORT` | Port du serveur | `3000` |
| `CORS_ORIGIN` | Origine CORS autorisée | `http://localhost:5173` |

## 🐛 Dépannage

### Erreur "extension postgis does not exist"

```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Erreur de connexion PostgreSQL

Vérifier :
- PostgreSQL est démarré : `brew services list` (macOS) ou `sudo systemctl status postgresql` (Linux)
- Les credentials dans `.env` sont corrects
- Le port 5432 est accessible

### Erreur "relation does not exist"

Exécuter les migrations :
```bash
npm run migrate
```

