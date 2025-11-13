# 🗄️ Installation PostgreSQL - Guide Simple

## 🎯 Méthode la Plus Simple : Postgres.app

**Postgres.app** est la méthode la plus simple pour macOS, sans besoin de privilèges administrateur.

### Étapes :

1. **Télécharger Postgres.app**
   - Ouvrez : https://postgresapp.com/downloads.html
   - Téléchargez la dernière version
   - C'est un fichier `.dmg`

2. **Installer**
   - Double-cliquez sur le fichier `.dmg`
   - Glissez `Postgres.app` dans le dossier **Applications**
   - Ouvrez **Applications** et lancez `Postgres.app`

3. **Premier démarrage**
   - Postgres.app va démarrer automatiquement
   - Cliquez sur "Initialize" pour créer un nouveau serveur
   - Le serveur démarre sur le port 5432

4. **Ajouter au PATH** (pour utiliser `psql` dans le terminal)
   
   Ouvrez votre terminal et exécutez :
   ```bash
   echo 'export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   ```

5. **Créer la base de données**
   ```bash
   # Se connecter (utilisateur = votre nom d'utilisateur macOS)
   psql postgres
   
   # Dans psql, exécutez :
   CREATE DATABASE TshiakaniVTC;
   \c TshiakaniVTC
   CREATE EXTENSION IF NOT EXISTS postgis;
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   \q
   ```

6. **Vérifier**
   ```bash
   psql -d TshiakaniVTC -c "SELECT PostGIS_version();"
   ```

## ✅ C'est tout !

Une fois fait, vous pouvez démarrer les serveurs :
```bash
./demarrer-serveurs.sh
```

## 🔄 Alternative : Installateur Officiel

Si vous préférez l'installateur officiel :

1. Télécharger : https://www.postgresql.org/download/macosx/
2. Exécuter l'installateur
3. **Cocher "PostGIS"** dans les composants
4. Noter le mot de passe `postgres` configuré
5. Suivre les étapes de création de base de données ci-dessus

