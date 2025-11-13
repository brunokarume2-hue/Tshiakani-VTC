# 🚀 Guide de Démarrage Complet - Tshiakani VTC

## ✅ État Actuel

### Dashboard Admin
- ✅ **Démarré et fonctionnel**
- 🌐 URL: http://localhost:3001
- 📝 Port: 3001 (5173 était occupé)

### Backend
- ⚠️ **En attente de PostgreSQL**
- 🔧 Code corrigé et prêt
- 📦 Dépendances installées

## 📋 Étapes pour Démarrer Complètement

### Étape 1 : Installer PostgreSQL + PostGIS

**Option A : Script automatique (Recommandé)**
```bash
./installer-postgresql.sh
```

**Option B : Installation manuelle avec Homebrew**
```bash
# Installer Homebrew (si pas déjà installé)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer PostgreSQL + PostGIS
brew install postgresql@14 postgis

# Démarrer PostgreSQL
brew services start postgresql@14
```

**Option C : Postgres.app (Interface graphique)**
1. Télécharger depuis : https://postgresapp.com/
2. Installer et lancer l'application
3. PostGIS doit être installé séparément via Homebrew

### Étape 2 : Configurer la Base de Données

**Option A : Script automatique**
```bash
./SCRIPT_SETUP_BDD.sh
```

**Option B : Configuration manuelle**
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

# Vérifier PostGIS
SELECT PostGIS_version();
```

### Étape 3 : Vérifier et Démarrer

**Script de vérification complet :**
```bash
./verifier-et-demarrer.sh
```

**Ou démarrage manuel :**
```bash
./demarrer-serveurs.sh
```

## 🔍 Vérification

### Backend
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

### Dashboard
Ouvrir dans le navigateur : http://localhost:3001

## 🛠️ Corrections Effectuées

1. ✅ **Dépendances backend réinstallées** (typeorm installé)
2. ✅ **Correction de `utils/notifications.js`** - Migration de Mongoose vers TypeORM
3. ✅ **Dashboard démarré avec succès**
4. ✅ **Scripts d'installation créés**

## 📝 Fichiers Créés

- `installer-postgresql.sh` - Installation automatique de PostgreSQL
- `verifier-et-demarrer.sh` - Vérification complète et démarrage
- `DEMARRAGE_COMPLET.md` - Ce guide

## 🐛 Dépannage

### PostgreSQL ne démarre pas
```bash
# Vérifier le statut
brew services list

# Démarrer manuellement
brew services start postgresql@14
```

### Erreur de connexion à la base de données
1. Vérifier que PostgreSQL est démarré
2. Vérifier les credentials dans `backend/.env`
3. Vérifier que la base de données existe

### Port déjà utilisé
```bash
# Trouver le processus utilisant le port
lsof -i:3000
lsof -i:5432

# Arrêter le processus
kill -9 <PID>
```

## ✅ Prochaines Étapes

1. Installer PostgreSQL (voir Étape 1)
2. Configurer la base de données (voir Étape 2)
3. Démarrer les serveurs (voir Étape 3)
4. Accéder au dashboard : http://localhost:3001

