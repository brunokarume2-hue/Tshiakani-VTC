# 🔧 Résolution des Problèmes Backend - Tshiakani VTC

## 📋 Diagnostic

### ✅ Problèmes Identifiés

1. **PostgreSQL n'est pas accessible**
   - PostgreSQL n'est pas dans le PATH
   - Peut-être installé mais non démarré
   - Peut-être non installé

2. **Port 3000** : ✅ Disponible

3. **Variables .env** : ✅ Configurées
   - DB_HOST: localhost
   - DB_PORT: 5432
   - DB_USER: admin
   - DB_NAME: tshiakanivtc
   - DB_PASSWORD: ***défini***

---

## 🔧 Solutions

### Solution 1 : Vérifier si PostgreSQL est Installé

#### Méthode 1 : Vérifier via Homebrew
```bash
brew list | grep postgresql
```

#### Méthode 2 : Vérifier via le système
```bash
which psql
which pg_isready
which postgres
```

#### Méthode 3 : Vérifier les processus
```bash
ps aux | grep postgres
```

---

### Solution 2 : Installer PostgreSQL (si non installé)

#### Option A : Installation via Homebrew (Recommandé)
```bash
# Installer PostgreSQL
brew install postgresql@15

# Démarrer PostgreSQL
brew services start postgresql@15

# Vérifier que PostgreSQL est démarré
pg_isready
```

#### Option B : Installation via Postgres.app (macOS)
1. Télécharger Postgres.app : https://postgresapp.com/
2. Installer et lancer l'application
3. PostgreSQL sera accessible sur le port 5432

#### Option C : Installation via le site officiel
1. Télécharger depuis : https://www.postgresql.org/download/macosx/
2. Installer le package
3. Démarrer PostgreSQL

---

### Solution 3 : Démarrer PostgreSQL (si installé mais non démarré)

#### Via Homebrew
```bash
brew services start postgresql@15
# ou
brew services start postgresql
```

#### Via pg_ctl
```bash
# Trouver le répertoire de données
pg_config --sharedir

# Démarrer PostgreSQL
pg_ctl -D /usr/local/var/postgresql@15 start
# ou
pg_ctl -D /usr/local/var/postgres start
```

#### Via Postgres.app
1. Ouvrir Postgres.app
2. Cliquer sur "Start" si PostgreSQL n'est pas démarré

---

### Solution 4 : Vérifier la Connexion à la Base de Données

#### Test de Connexion
```bash
# Avec les variables du .env
psql -h localhost -p 5432 -U admin -d tshiakanivtc
```

#### Créer la Base de Données (si elle n'existe pas)
```bash
# Se connecter en tant qu'admin
psql -h localhost -p 5432 -U admin -d postgres

# Créer la base de données
CREATE DATABASE tshiakanivtc;

# Vérifier que la base existe
\l

# Quitter
\q
```

#### Vérifier que PostGIS est Installé
```bash
# Se connecter à la base de données
psql -h localhost -p 5432 -U admin -d tshiakanivtc

# Vérifier PostGIS
SELECT PostGIS_version();

# Si PostGIS n'est pas installé
CREATE EXTENSION postgis;
```

---

### Solution 5 : Configurer les Variables d'Environnement

#### Vérifier le fichier .env
```bash
cd backend
cat .env | grep -E "^DB_|^DATABASE_URL"
```

#### Variables Requises
```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Nyota9090_postgres
DB_NAME=tshiakanivtc
```

#### Créer DATABASE_URL (optionnel)
```env
DATABASE_URL=postgresql://admin:Nyota9090_postgres@localhost:5432/tshiakanivtc
```

---

## 🧪 Tests de Vérification

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

### Test 3 : Vérifier que la Base de Données Existe
```bash
psql -h localhost -p 5432 -U admin -d postgres -c "\l" | grep tshiakanivtc
```

**Résultat attendu** :
```
tshiakanivtc | admin | UTF8 | ...
```

### Test 4 : Vérifier PostGIS
```bash
psql -h localhost -p 5432 -U admin -d tshiakanivtc -c "SELECT PostGIS_version();"
```

**Résultat attendu** :
```
3.x.x
```

---

## 🚀 Démarrage du Backend (Après Résolution)

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

## 📝 Checklist de Résolution

### Prérequis
- [ ] PostgreSQL installé
- [ ] PostgreSQL démarré
- [ ] Base de données `tshiakanivtc` créée
- [ ] PostGIS installé et activé
- [ ] Variables .env configurées
- [ ] Port 3000 disponible

### Tests
- [ ] `pg_isready` fonctionne
- [ ] Connexion à la base de données réussie
- [ ] Base de données existe
- [ ] PostGIS fonctionne

### Backend
- [ ] Backend démarre sans erreur
- [ ] Health check fonctionne
- [ ] Endpoints API fonctionnent
- [ ] WebSocket fonctionne

---

## 🆘 Support

### Si PostgreSQL n'est toujours pas accessible

1. **Vérifier les logs PostgreSQL**
   ```bash
   # Logs Homebrew
   brew services list
   
   # Logs système
   tail -f /usr/local/var/log/postgresql@15.log
   # ou
   tail -f /usr/local/var/log/postgres.log
   ```

2. **Vérifier les permissions**
   ```bash
   # Vérifier les permissions du répertoire de données
   ls -la /usr/local/var/postgresql@15
   # ou
   ls -la /usr/local/var/postgres
   ```

3. **Réinitialiser PostgreSQL (si nécessaire)**
   ```bash
   # ⚠️ ATTENTION : Cela supprimera toutes les données
   rm -rf /usr/local/var/postgresql@15
   initdb /usr/local/var/postgresql@15
   brew services start postgresql@15
   ```

---

## 📚 Ressources

### Documentation
- PostgreSQL : https://www.postgresql.org/docs/
- PostGIS : https://postgis.net/documentation/
- Homebrew : https://brew.sh/

### Guides
- `INSTALLATION_POSTGRESQL_SIMPLE.md` - Guide d'installation
- `DEMARRAGE_BACKEND_GUIDE.md` - Guide de démarrage
- `VERIFICATION_CONNEXION_BACKEND.md` - Guide de vérification

---

**Date de création** : $(date)
**Statut** : ✅ Guide de résolution créé

