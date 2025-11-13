# 🚀 Action Immédiate : Installation PostgreSQL

## 📋 Situation Actuelle

**Problème** : PostgreSQL n'est pas installé sur le système.

**Solution** : Installer PostgreSQL et configurer la base de données.

---

## 🎯 Action Immédiate : Installer PostgreSQL

### Option 1 : Utiliser le Script d'Installation (Recommandé)

```bash
cd "/Users/admin/Documents/Tshiakani VTC"
./installer-postgresql.sh
```

Le script vous demandera de choisir entre :
1. **Homebrew** (Recommandé pour macOS)
2. **Docker** (Alternative)

---

### Option 2 : Installation Manuelle via Homebrew

```bash
# Installer Homebrew (si non installé)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer PostgreSQL 15
brew install postgresql@15 postgis

# Ajouter au PATH
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Démarrer PostgreSQL
brew services start postgresql@15

# Créer la base de données
psql postgres -c "CREATE USER admin WITH PASSWORD 'Nyota9090_postgres';"
psql postgres -c "ALTER USER admin WITH SUPERUSER;"
psql postgres -c "CREATE DATABASE tshiakanivtc OWNER admin;"
psql -U admin -d tshiakanivtc -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

### Option 3 : Installation via Postgres.app (Plus Simple)

1. **Télécharger Postgres.app**
   - https://postgresapp.com/
   - Ou : `brew install --cask postgres-unofficial`

2. **Lancer Postgres.app**
   - Ouvrir l'application
   - Cliquer sur "Initialize" si c'est la première fois
   - Cliquer sur "Start"

3. **Créer la base de données**
   ```bash
   psql postgres -c "CREATE USER admin WITH PASSWORD 'Nyota9090_postgres';"
   psql postgres -c "ALTER USER admin WITH SUPERUSER;"
   psql postgres -c "CREATE DATABASE tshiakanivtc OWNER admin;"
   psql -U admin -d tshiakanivtc -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   ```

---

### Option 4 : Installation via Docker

```bash
# Créer un conteneur PostgreSQL avec PostGIS
docker run --name tshiakani-postgres \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=Nyota9090_postgres \
  -e POSTGRES_DB=tshiakanivtc \
  -p 5432:5432 \
  -d postgis/postgis:15-3.4

# Activer PostGIS
docker exec -it tshiakani-postgres psql -U admin -d tshiakanivtc -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

## ✅ Vérification de l'Installation

### Test 1 : Vérifier que PostgreSQL est Démarré

```bash
pg_isready
```

**Résultat attendu** :
```
/var/run/postgresql:5432 - accepting connections
```

### Test 2 : Vérifier la Connexion

```bash
psql -h localhost -p 5432 -U admin -d tshiakanivtc -c "SELECT version();"
```

### Test 3 : Vérifier PostGIS

```bash
psql -h localhost -p 5432 -U admin -d tshiakanivtc -c "SELECT PostGIS_version();"
```

---

## 🚀 Prochaines Étapes

Une fois PostgreSQL installé :

1. **Vérifier les préconditions**
   ```bash
   ./verifier-preconditions-backend.sh
   ```

2. **Démarrer le backend**
   ```bash
   ./demarrer-backend.sh
   ```

3. **Tester la connexion**
   ```bash
   ./test-backend-connection.sh
   ```

---

## 📝 Configuration du Backend

Le fichier `.env` est déjà configuré avec :
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Nyota9090_postgres
DB_NAME=tshiakanivtc
```

Aucune modification n'est nécessaire une fois PostgreSQL installé.

---

## 🆘 Support

### Problèmes Courants

1. **PostgreSQL ne démarre pas**
   - Vérifier les logs : `brew services list`
   - Réinitialiser : `brew services restart postgresql@15`

2. **PostGIS non disponible**
   - Installer PostGIS : `brew install postgis`

3. **Erreur de connexion**
   - Vérifier les identifiants dans `.env`
   - Vérifier que la base de données existe

### Documentation

- `INSTALLATION_POSTGRESQL_COMPLETE.md` - Guide complet
- `RESOLUTION_PROBLEMES_BACKEND.md` - Guide de résolution
- `DEMARRAGE_BACKEND_GUIDE.md` - Guide de démarrage

---

**Date de création** : $(date)
**Statut** : ✅ Prêt à être exécuté

**Recommandation** : Utiliser **Postgres.app** (Option 3) pour la méthode la plus simple.

