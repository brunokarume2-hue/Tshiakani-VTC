# 🗄️ Installation PostgreSQL + PostGIS pour Tshiakani VTC

## 📋 Prérequis

- Node.js 18+
- PostgreSQL 14+ avec PostGIS

## 🔧 Installation PostgreSQL + PostGIS

### macOS (Homebrew) - **Recommandé**

**Lien Homebrew :** https://brew.sh/

```bash
# Installer Homebrew si pas déjà installé
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer PostgreSQL
brew install postgresql@14

# Installer PostGIS
brew install postgis

# Démarrer PostgreSQL
brew services start postgresql@14
```

**Alternative : Installateur officiel**
- **Site :** https://www.postgresql.org/download/macosx/
- **Téléchargement :** https://www.postgresql.org/download/macosx/

### Linux (Ubuntu/Debian)

**Liens officiels :**
- **PostgreSQL :** https://www.postgresql.org/download/linux/ubuntu/
- **PostGIS :** https://postgis.net/install/

```bash
# Installer PostgreSQL et PostGIS
sudo apt-get update
sudo apt-get install postgresql-14 postgresql-14-postgis-3

# Démarrer PostgreSQL
sudo systemctl start postgresql
```

**Installation manuelle (si nécessaire) :**
```bash
# Ajouter le dépôt PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-14 postgresql-14-postgis-3
```

### Windows

**Liens de téléchargement :**
- **PostgreSQL officiel :** https://www.postgresql.org/download/windows/
- **Téléchargement direct :** https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
- **PostGIS Windows :** https://postgis.net/windows_downloads/

**Étapes d'installation :**
1. Télécharger PostgreSQL depuis : https://www.postgresql.org/download/windows/
2. Exécuter l'installateur
3. **Cocher "PostGIS"** dans les composants à installer (option disponible dans l'installateur)
4. Suivre l'assistant d'installation
5. Configurer le mot de passe `postgres` lors de l'installation

## 🗄️ Configuration de la base de données

### 1. Créer la base de données

```bash
# Se connecter à PostgreSQL
psql -U postgres

# Créer la base de données
CREATE DATABASE tshiakani_vtc;

# Se connecter à la base
\c tshiakani_vtc

# Activer PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

# Vérifier PostGIS
SELECT PostGIS_version();
```

### 2. Exécuter les migrations

```bash
cd backend
psql -U postgres -d tshiakani_vtc -f migrations/001_init_postgis.sql
```

## 🔧 Configuration du Backend

### 1. Installer les dépendances

```bash
cd backend
npm install typeorm pg @types/pg
```

### 2. Configurer les variables d'environnement

Créez un fichier `.env` :

```bash
cp .env.postgres.example .env
```

Modifiez `.env` avec vos paramètres PostgreSQL :

```
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
DB_NAME=tshiakani_vtc
```

### 3. Démarrer le serveur

```bash
# Utiliser le serveur avec PostgreSQL
node server.postgres.js

# Ou avec nodemon
nodemon server.postgres.js
```

## ✅ Vérification

### Vérifier PostGIS

```sql
SELECT PostGIS_version();
-- Devrait retourner la version de PostGIS
```

### Vérifier les tables

```sql
\dt
-- Devrait lister : users, rides, notifications, sos_reports
```

### Vérifier les index spatiaux

```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'users' AND indexname LIKE '%location%';
-- Devrait montrer l'index spatial GIST
```

## 🚀 Avantages immédiats

1. **Requêtes géospatiales ultra-rapides**
   ```sql
   -- Trouver conducteurs dans 5 km (très rapide)
   SELECT * FROM find_nearby_drivers(-4.3276, 15.3136, 5);
   ```

2. **Calcul de distance natif**
   ```sql
   -- Distance précise entre deux points
   SELECT ST_Distance(pickup_location, dropoff_location) / 1000 AS km
   FROM rides;
   ```

3. **Indexation spatiale optimale**
   - Index GIST pour performances maximales
   - Requêtes jusqu'à 10x plus rapides que MongoDB

## 📊 Migration depuis MongoDB

Si vous avez déjà des données MongoDB :

1. Exporter les données MongoDB
2. Convertir les coordonnées au format PostGIS
3. Importer dans PostgreSQL

Un script de migration sera créé si nécessaire.

## 🔍 Requêtes utiles

### Trouver les conducteurs proches

```sql
SELECT 
    id, 
    name,
    ST_Distance(
        location::geography,
        ST_MakePoint(15.3136, -4.3276)::geography
    ) / 1000 AS distance_km
FROM users
WHERE role = 'driver'
    AND driver_info->>'isOnline' = 'true'
    AND ST_DWithin(
        location::geography,
        ST_MakePoint(15.3136, -4.3276)::geography,
        5000  -- 5 km en mètres
    )
ORDER BY location <-> ST_MakePoint(15.3136, -4.3276)::geography
LIMIT 10;
```

### Statistiques géographiques

```sql
-- Zones les plus fréquentées
SELECT 
    ST_AsText(ST_Centroid(ST_Collect(pickup_location))) AS center,
    COUNT(*) AS ride_count
FROM rides
WHERE status = 'completed'
GROUP BY ST_SnapToGrid(pickup_location, 0.01)
ORDER BY ride_count DESC
LIMIT 10;
```

## 🆘 Dépannage

### Erreur "extension postgis does not exist"
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### Erreur de connexion
Vérifiez :
- PostgreSQL est démarré
- Les credentials dans `.env`
- Le port 5432 est accessible

### Erreur "relation does not exist"
Exécutez les migrations SQL :
```bash
psql -U postgres -d tshiakani_vtc -f migrations/001_init_postgis.sql
```

