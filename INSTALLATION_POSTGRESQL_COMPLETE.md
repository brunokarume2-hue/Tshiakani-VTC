# 🐘 Installation PostgreSQL - Guide Complet

## 📋 Situation Actuelle

**Problème** : PostgreSQL n'est pas installé sur le système.

**Solution** : Installer PostgreSQL et configurer la base de données pour le backend.

---

## 🚀 Option 1 : Installation via Homebrew (Recommandé)

### Étape 1 : Installer Homebrew (si non installé)

```bash
# Vérifier si Homebrew est installé
which brew

# Si non installé, installer Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Étape 2 : Installer PostgreSQL

```bash
# Installer PostgreSQL 15
brew install postgresql@15

# Ajouter PostgreSQL au PATH (ajouter à ~/.zshrc ou ~/.bash_profile)
echo 'export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Ou pour les Macs Intel
echo 'export PATH="/usr/local/opt/postgresql@15/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Étape 3 : Démarrer PostgreSQL

```bash
# Démarrer PostgreSQL
brew services start postgresql@15

# Vérifier que PostgreSQL est démarré
pg_isready
```

### Étape 4 : Créer l'Utilisateur et la Base de Données

```bash
# Se connecter à PostgreSQL
psql postgres

# Créer l'utilisateur admin (si n'existe pas)
CREATE USER admin WITH PASSWORD 'Nyota9090_postgres';

# Donner les permissions
ALTER USER admin WITH SUPERUSER;

# Créer la base de données
CREATE DATABASE tshiakanivtc OWNER admin;

# Activer PostGIS
\c tshiakanivtc
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# Vérifier PostGIS
SELECT PostGIS_version();

# Quitter
\q
```

---

## 🐳 Option 2 : Installation via Docker (Alternative)

### Étape 1 : Installer Docker

```bash
# Installer Docker Desktop pour macOS
# Télécharger depuis : https://www.docker.com/products/docker-desktop
```

### Étape 2 : Créer un Conteneur PostgreSQL

```bash
# Créer un conteneur PostgreSQL avec PostGIS
docker run --name tshiakani-postgres \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=Nyota9090_postgres \
  -e POSTGRES_DB=tshiakanivtc \
  -p 5432:5432 \
  -d postgis/postgis:15-3.4

# Vérifier que le conteneur est en cours d'exécution
docker ps
```

### Étape 3 : Activer PostGIS

```bash
# Se connecter au conteneur
docker exec -it tshiakani-postgres psql -U admin -d tshiakanivtc

# Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# Vérifier PostGIS
SELECT PostGIS_version();

# Quitter
\q
```

---

## 📱 Option 3 : Installation via Postgres.app (macOS - Plus Simple)

### Étape 1 : Télécharger Postgres.app

```bash
# Télécharger depuis : https://postgresapp.com/
# Ou via Homebrew Cask
brew install --cask postgres-unofficial
```

### Étape 2 : Lancer Postgres.app

1. Ouvrir Postgres.app
2. Cliquer sur "Initialize" si c'est la première fois
3. Cliquer sur "Start" pour démarrer PostgreSQL

### Étape 3 : Créer l'Utilisateur et la Base de Données

```bash
# Se connecter via Postgres.app
# Utiliser le terminal intégré ou :
psql postgres

# Créer l'utilisateur admin
CREATE USER admin WITH PASSWORD 'Nyota9090_postgres';

# Donner les permissions
ALTER USER admin WITH SUPERUSER;

# Créer la base de données
CREATE DATABASE tshiakanivtc OWNER admin;

# Activer PostGIS
\c tshiakanivtc
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# Quitter
\q
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

**Résultat attendu** :
```
PostgreSQL 15.x on ...
```

### Test 3 : Vérifier PostGIS

```bash
psql -h localhost -p 5432 -U admin -d tshiakanivtc -c "SELECT PostGIS_version();"
```

**Résultat attendu** :
```
3.x.x
```

---

## 🔧 Configuration du Backend

### Vérifier le fichier .env

```bash
cd backend
cat .env | grep -E "^DB_|^DATABASE_URL"
```

### Variables Requises

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Nyota9090_postgres
DB_NAME=tshiakanivtc
```

### Créer DATABASE_URL (optionnel)

```env
DATABASE_URL=postgresql://admin:Nyota9090_postgres@localhost:5432/tshiakanivtc
```

---

## 🧪 Test du Backend

### Étape 1 : Vérifier les Préconditions

```bash
./verifier-preconditions-backend.sh
```

### Étape 2 : Démarrer le Backend

```bash
./demarrer-backend.sh
```

### Étape 3 : Tester la Connexion

```bash
./test-backend-connection.sh
```

---

## 🆘 Résolution des Problèmes

### Problème 1 : PostgreSQL ne démarre pas

**Solution** :
```bash
# Vérifier les logs
brew services list
tail -f /usr/local/var/log/postgresql@15.log

# Réinitialiser PostgreSQL (⚠️ ATTENTION : Supprime les données)
brew services stop postgresql@15
rm -rf /usr/local/var/postgresql@15
initdb /usr/local/var/postgresql@15
brew services start postgresql@15
```

### Problème 2 : PostGIS n'est pas disponible

**Solution** :
```bash
# Installer PostGIS via Homebrew
brew install postgis

# Ou pour PostgreSQL 15
brew install postgresql@15/postgis
```

### Problème 3 : Erreur de connexion

**Solution** :
```bash
# Vérifier que PostgreSQL écoute sur le bon port
lsof -i :5432

# Vérifier les permissions
psql -h localhost -p 5432 -U admin -d postgres -c "SELECT 1;"
```

---

## 📚 Ressources

### Documentation
- PostgreSQL : https://www.postgresql.org/docs/
- PostGIS : https://postgis.net/documentation/
- Homebrew : https://brew.sh/
- Postgres.app : https://postgresapp.com/
- Docker : https://www.docker.com/

### Guides
- `RESOLUTION_PROBLEMES_BACKEND.md` - Guide de résolution
- `DEMARRAGE_BACKEND_GUIDE.md` - Guide de démarrage
- `VERIFICATION_CONNEXION_BACKEND.md` - Guide de vérification

---

## 🎯 Recommandation

**Pour macOS** : Utiliser **Postgres.app** (Option 3) - C'est la méthode la plus simple et la plus rapide.

**Pour développement** : Utiliser **Docker** (Option 2) - Plus facile à gérer et à nettoyer.

**Pour production** : Utiliser **Homebrew** (Option 1) - Plus de contrôle et meilleure intégration système.

---

**Date de création** : $(date)
**Statut** : ✅ Guide d'installation créé

