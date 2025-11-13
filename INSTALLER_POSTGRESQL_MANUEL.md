# 🗄️ Installation Manuelle de PostgreSQL + PostGIS

## 📋 Méthodes d'Installation

### Méthode 1 : Postgres.app (Recommandé - Plus Simple)

**Postgres.app** est une application macOS qui inclut PostgreSQL et PostGIS.

1. **Télécharger Postgres.app**
   - Site : https://postgresapp.com/
   - Téléchargement direct : https://postgresapp.com/downloads.html
   - Version recommandée : Latest (inclut PostgreSQL 14+)

2. **Installer**
   - Ouvrir le fichier `.dmg` téléchargé
   - Glisser `Postgres.app` dans le dossier Applications
   - Lancer `Postgres.app` depuis Applications

3. **Configurer PostGIS**
   ```bash
   # Installer PostGIS via Homebrew (si disponible)
   brew install postgis
   
   # Ou utiliser la version incluse dans Postgres.app
   # PostGIS est généralement inclus dans les versions récentes
   ```

4. **Ajouter au PATH**
   ```bash
   # Ajouter cette ligne à ~/.zshrc ou ~/.bash_profile
   export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
   
   # Recharger le shell
   source ~/.zshrc
   ```

5. **Créer la base de données**
   ```bash
   # Se connecter (utilisateur par défaut : votre nom d'utilisateur macOS)
   psql postgres
   
   # Créer la base de données
   CREATE DATABASE TshiakaniVTC;
   
   # Se connecter à la base
   \c TshiakaniVTC
   
   # Activer PostGIS
   CREATE EXTENSION IF NOT EXISTS postgis;
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   ```

### Méthode 2 : Installateur Officiel PostgreSQL

1. **Télécharger**
   - Site : https://www.postgresql.org/download/macosx/
   - Ou directement : https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
   - Choisir : PostgreSQL 14 ou 15 pour macOS

2. **Installer**
   - Exécuter l'installateur
   - **IMPORTANT** : Cocher "PostGIS" dans les composants optionnels
   - Noter le mot de passe `postgres` que vous configurez
   - Port par défaut : 5432

3. **Vérifier l'installation**
   ```bash
   # Ajouter au PATH si nécessaire
   export PATH="/Library/PostgreSQL/14/bin:$PATH"
   
   # Tester
   psql --version
   ```

4. **Créer la base de données**
   ```bash
   psql -U postgres
   CREATE DATABASE TshiakaniVTC;
   \c TshiakaniVTC
   CREATE EXTENSION IF NOT EXISTS postgis;
   ```

### Méthode 3 : Homebrew (Nécessite Privilèges Admin)

Si vous avez les privilèges administrateur :

```bash
# Installer Homebrew (nécessite sudo)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer PostgreSQL + PostGIS
brew install postgresql@14 postgis

# Démarrer PostgreSQL
brew services start postgresql@14

# Ajouter au PATH
echo 'export PATH="/opt/homebrew/opt/postgresql@14/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## ✅ Vérification de l'Installation

Après installation, vérifiez :

```bash
# Vérifier que psql est accessible
psql --version

# Vérifier que PostgreSQL est démarré
lsof -i:5432

# Tester la connexion
psql -U postgres -d postgres -c "SELECT version();"
```

## 🔧 Configuration de la Base de Données

Une fois PostgreSQL installé, exécutez :

```bash
# Utiliser le script automatique
./SCRIPT_SETUP_BDD.sh

# Ou manuellement :
psql -U postgres
CREATE DATABASE TshiakaniVTC;
\c TshiakaniVTC
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

## 📝 Mise à Jour du Fichier .env

Après installation, vérifiez `backend/.env` :

```env
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres  # Ou votre nom d'utilisateur macOS pour Postgres.app
DB_PASSWORD=votre_mot_de_passe  # Si vous avez configuré un mot de passe
DB_NAME=TshiakaniVTC
```

## 🚀 Démarrer les Serveurs

Une fois PostgreSQL installé et configuré :

```bash
./demarrer-serveurs.sh
```

## 🆘 Dépannage

### "psql: command not found"
- Ajoutez PostgreSQL au PATH (voir méthodes ci-dessus)
- Redémarrez votre terminal

### "Connection refused"
- Vérifiez que PostgreSQL est démarré
- Pour Postgres.app : ouvrez l'application
- Pour Homebrew : `brew services start postgresql@14`

### "PostGIS does not exist"
- Installez PostGIS séparément si nécessaire
- Pour Postgres.app : PostGIS est généralement inclus

