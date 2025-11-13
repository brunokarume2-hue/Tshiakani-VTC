# 🔗 Liens de Téléchargement - PostgreSQL + PostGIS

## 📥 Téléchargements directs

### 🍎 macOS

#### Option 1 : Homebrew (Recommandé - Plus simple)
```bash
# Installer Homebrew si pas déjà installé
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer PostgreSQL + PostGIS
brew install postgresql@14 postgis

# Démarrer PostgreSQL
brew services start postgresql@14
```

**Lien Homebrew :** https://brew.sh/

#### Option 2 : Installateur officiel PostgreSQL
- **Site officiel :** https://www.postgresql.org/download/macosx/
- **Téléchargement direct :** https://www.postgresql.org/download/macosx/
- **PostGIS :** Installer séparément via Homebrew ou compiler depuis les sources

#### Option 3 : Postgres.app (Interface graphique)
- **Site :** https://postgresapp.com/
- **Téléchargement :** https://postgresapp.com/downloads.html
- **Note :** PostGIS doit être installé séparément

---

### 🐧 Linux (Ubuntu/Debian)

#### Installation via apt (Recommandé)
```bash
sudo apt-get update
sudo apt-get install postgresql-14 postgresql-14-postgis-3
```

#### Liens officiels
- **PostgreSQL :** https://www.postgresql.org/download/linux/ubuntu/
- **PostGIS :** https://postgis.net/install/
- **Documentation Ubuntu :** https://www.postgresql.org/download/linux/ubuntu/

#### Installation manuelle
```bash
# Ajouter le dépôt PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-14 postgresql-14-postgis-3
```

---

### 🪟 Windows

#### Option 1 : Installateur officiel (Recommandé)
- **Site officiel :** https://www.postgresql.org/download/windows/
- **Téléchargement direct :** https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
- **Version avec PostGIS incluse :** https://postgis.net/windows_downloads/
- **Stack Builder :** Inclut PostGIS dans l'installation

#### Option 2 : PostGIS Windows Installer
- **Site PostGIS :** https://postgis.net/windows_downloads/
- **Téléchargement :** https://postgis.net/windows_downloads/
- **Note :** Nécessite PostgreSQL installé au préalable

#### Étapes d'installation Windows
1. Télécharger PostgreSQL depuis : https://www.postgresql.org/download/windows/
2. Exécuter l'installateur
3. **Cocher "PostGIS"** dans les composants à installer
4. Suivre l'assistant d'installation
5. Configurer le mot de passe `postgres`

---

## 🔍 Vérification de l'installation

### Vérifier PostgreSQL
```bash
psql --version
# Devrait afficher : psql (PostgreSQL) 14.x
```

### Vérifier PostGIS
```bash
psql -U postgres -d wewa_taxi -c "SELECT PostGIS_version();"
# Devrait afficher la version de PostGIS
```

---

## 📚 Documentation officielle

- **PostgreSQL :** https://www.postgresql.org/docs/
- **PostGIS :** https://postgis.net/documentation/
- **TypeORM :** https://typeorm.io/
- **Node.js PostgreSQL (pg) :** https://node-postgres.com/

---

## 🆘 Support

- **Forum PostgreSQL :** https://www.postgresql.org/support/
- **Documentation PostGIS :** https://postgis.net/documentation/
- **Stack Overflow :** Tag `postgresql` et `postgis`

---

## ✅ Installation rapide pour macOS (votre système)

Puisque vous êtes sur macOS, voici la méthode la plus simple :

```bash
# 1. Installer Homebrew (si pas déjà installé)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Installer PostgreSQL + PostGIS
brew install postgresql@14 postgis

# 3. Démarrer PostgreSQL
brew services start postgresql@14

# 4. Vérifier l'installation
psql --version
```

Ensuite, suivez les instructions dans `backend/INSTALLATION_POSTGRES.md` pour configurer la base de données.

