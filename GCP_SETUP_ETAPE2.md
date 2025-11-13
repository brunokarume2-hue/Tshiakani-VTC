# 🗄️ Étape 2 : Configuration Cloud SQL (PostgreSQL + PostGIS)

## 🎯 Objectif

Configurer une instance Cloud SQL PostgreSQL avec PostGIS pour Tshiakani VTC.

---

## 📋 Prérequis

1. ✅ Étape 1 complétée (Projet GCP créé, APIs activées)
2. ✅ Facturation activée
3. ✅ Cloud SQL API activée
4. ✅ gcloud CLI installé et configuré

---

## 🚀 Étapes de Configuration

### 1. Créer une Instance Cloud SQL

#### Configuration Recommandée

- **Type de base de données**: PostgreSQL 14 ou 15
- **Version**: PostgreSQL 14+ (support PostGIS)
- **Machine type**: `db-f1-micro` (développement) ou `db-n1-standard-1` (production)
- **Stockage**: 20 GB minimum (SSD)
- **Région**: `us-central1` (ou votre région préférée)
- **Haute disponibilité**: Désactivée (développement) ou Activée (production)

#### Créer l'Instance via Script

```bash
# Exécuter le script de création
./scripts/gcp-create-cloud-sql.sh
```

#### Créer l'Instance Manuellement

```bash
# Définir les variables
export PROJECT_ID="tshiakani-vtc"
export INSTANCE_NAME="tshiakani-vtc-db"
export DATABASE_NAME="TshiakaniVTC"
export REGION="us-central1"
export DB_USER="postgres"
export DB_PASSWORD="VOTRE_MOT_DE_PASSE_SECURISE"

# Créer l'instance Cloud SQL
gcloud sql instances create $INSTANCE_NAME \
  --database-version=POSTGRES_14 \
  --tier=db-f1-micro \
  --region=$REGION \
  --storage-type=SSD \
  --storage-size=20GB \
  --storage-auto-increase \
  --backup \
  --enable-bin-log \
  --database-flags=shared_preload_libraries=pg_stat_statements \
  --project=$PROJECT_ID

# Créer l'utilisateur de base de données
gcloud sql users create $DB_USER \
  --instance=$INSTANCE_NAME \
  --password=$DB_PASSWORD \
  --project=$PROJECT_ID

# Créer la base de données
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME \
  --project=$PROJECT_ID
```

---

### 2. Activer l'Extension PostGIS

PostGIS est nécessaire pour les fonctionnalités géospatiales.

```bash
# Se connecter à l'instance
gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME

# Dans le prompt PostgreSQL, exécuter:
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
\q
```

Ou via script automatique :

```bash
# Exécuter le script d'initialisation
./scripts/gcp-init-database.sh
```

---

### 3. Appliquer les Migrations SQL

Les migrations créent les tables, index et fonctions nécessaires.

```bash
# Appliquer les migrations
./scripts/gcp-apply-migrations.sh
```

Ou manuellement :

```bash
# Se connecter à l'instance
gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME

# Exécuter les migrations
psql -h /cloudsql/$CONNECTION_NAME -U $DB_USER -d $DATABASE_NAME -f backend/migrations/001_init_postgis_cloud_sql.sql
psql -h /cloudsql/$CONNECTION_NAME -U $DB_USER -d $DATABASE_NAME -f backend/migrations/002_create_price_configurations.sql
psql -h /cloudsql/$CONNECTION_NAME -U $DB_USER -d $DATABASE_NAME -f backend/migrations/003_optimize_indexes.sql
```

---

### 4. Configurer les Autorisations

#### Autoriser Cloud Run à Se Connecter

```bash
# Obtenir le nom de connexion
export CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME --format="value(connectionName)")

# Ajouter l'autorisation pour Cloud Run
gcloud sql instances patch $INSTANCE_NAME \
  --database-flags=cloudsql.iam_authentication=on \
  --project=$PROJECT_ID

# Accorder l'accès au compte de service
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"
```

---

### 5. Vérifier la Configuration

```bash
# Vérifier l'instance
gcloud sql instances describe $INSTANCE_NAME

# Vérifier les bases de données
gcloud sql databases list --instance=$INSTANCE_NAME

# Vérifier les utilisateurs
gcloud sql users list --instance=$INSTANCE_NAME

# Tester la connexion
gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME
```

---

## 📊 Structure de la Base de Données

### Table: users

**Colonnes principales:**
- `id` (SERIAL PRIMARY KEY)
- `name` (VARCHAR(255))
- `phone_number` (VARCHAR(20) UNIQUE)
- `role` (VARCHAR(20)) - 'client', 'driver', 'admin'
- `is_verified` (BOOLEAN)
- `driver_info` (JSONB) - Informations du conducteur
- `location` (GEOGRAPHY(POINT, 4326)) - PostGIS
- `fcm_token` (VARCHAR(255))
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Index:**
- Index spatial GIST sur `location`
- Index sur `role`
- Index unique sur `phone_number`
- Index partiel sur `driver_info->>'isOnline'` pour les drivers

### Table: rides

**Colonnes principales:**
- `id` (SERIAL PRIMARY KEY)
- `client_id` (INTEGER) - Référence à users(id)
- `driver_id` (INTEGER) - Référence à users(id)
- `pickup_location` (GEOGRAPHY(POINT, 4326)) - PostGIS
- `dropoff_location` (GEOGRAPHY(POINT, 4326)) - PostGIS
- `pickup_address` (TEXT)
- `dropoff_address` (TEXT)
- `status` (VARCHAR(20)) - 'pending', 'accepted', 'inProgress', 'completed', 'cancelled'
- `estimated_price` (DECIMAL(10,2))
- `final_price` (DECIMAL(10,2))
- `distance_km` (DECIMAL(10,2))
- `duration_min` (INTEGER)
- `payment_method` (VARCHAR(20)) - 'cash', 'mobile_money', 'card'
- `rating` (INTEGER) - 1-5
- `comment` (TEXT)
- `created_at` (TIMESTAMP)
- `started_at` (TIMESTAMP)
- `completed_at` (TIMESTAMP)
- `cancelled_at` (TIMESTAMP)
- `cancellation_reason` (TEXT)

**Index:**
- Index spatial GIST sur `pickup_location`
- Index spatial GIST sur `dropoff_location`
- Index sur `client_id`
- Index sur `driver_id`
- Index sur `status`
- Index sur `created_at DESC`

### Table: notifications

**Colonnes principales:**
- `id` (SERIAL PRIMARY KEY)
- `user_id` (INTEGER) - Référence à users(id)
- `type` (VARCHAR(20)) - 'ride', 'promotion', 'security', 'system'
- `title` (VARCHAR(255))
- `message` (TEXT)
- `ride_id` (INTEGER) - Référence à rides(id)
- `is_read` (BOOLEAN)
- `created_at` (TIMESTAMP)

### Table: sos_reports

**Colonnes principales:**
- `id` (SERIAL PRIMARY KEY)
- `user_id` (INTEGER) - Référence à users(id)
- `location` (GEOGRAPHY(POINT, 4326)) - PostGIS
- `address` (TEXT)
- `ride_id` (INTEGER) - Référence à rides(id)
- `message` (TEXT)
- `status` (VARCHAR(20)) - 'active', 'resolved', 'false_alarm'
- `resolved_at` (TIMESTAMP)
- `resolved_by` (INTEGER) - Référence à users(id)
- `created_at` (TIMESTAMP)

### Table: price_configurations

**Colonnes principales:**
- `id` (SERIAL PRIMARY KEY)
- `base_price` (DECIMAL(10,2))
- `price_per_km` (DECIMAL(10,2))
- `rush_hour_multiplier` (DECIMAL(5,2))
- `night_multiplier` (DECIMAL(5,2))
- `weekend_multiplier` (DECIMAL(5,2))
- `surge_low_demand_multiplier` (DECIMAL(5,2))
- `surge_normal_multiplier` (DECIMAL(5,2))
- `surge_high_multiplier` (DECIMAL(5,2))
- `surge_very_high_multiplier` (DECIMAL(5,2))
- `surge_extreme_multiplier` (DECIMAL(5,2))
- `description` (TEXT)
- `is_active` (BOOLEAN)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

---

## 🔐 Sécurité

### Stocker les Mots de Passe dans Secret Manager

```bash
# Créer le secret pour le mot de passe de la base de données
echo -n "VOTRE_MOT_DE_PASSE_SECURISE" | gcloud secrets create db-password \
  --data-file=- \
  --project=$PROJECT_ID

# Accorder l'accès au compte de service
gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:tshiakani-vtc-backend@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=$PROJECT_ID
```

### Configuration de la Connexion

Dans votre application, utilisez la connexion Unix socket pour Cloud SQL :

```javascript
// Configuration pour Cloud SQL
const dbConfig = {
  host: `/cloudsql/${CONNECTION_NAME}`,
  // Ou via IP avec autorisation IP
  // host: 'INSTANCE_IP',
  database: 'TshiakaniVTC',
  user: 'postgres',
  password: process.env.DB_PASSWORD, // Depuis Secret Manager
  // Options Cloud SQL
  extra: {
    socketPath: `/cloudsql/${CONNECTION_NAME}`,
  }
};
```

---

## 🔍 Vérification

### Vérifier l'Instance

```bash
# Vérifier l'état de l'instance
gcloud sql instances describe $INSTANCE_NAME

# Vérifier les bases de données
gcloud sql databases list --instance=$INSTANCE_NAME

# Vérifier les utilisateurs
gcloud sql users list --instance=$INSTANCE_NAME

# Vérifier les extensions
gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME
# Dans PostgreSQL:
\dx  -- Lister les extensions
SELECT PostGIS_version();  -- Vérifier PostGIS
```

### Vérifier les Tables

```sql
-- Se connecter à la base de données
\c TshiakaniVTC

-- Lister les tables
\dt

-- Vérifier les index
\di

-- Vérifier les contraintes
\d users
\d rides
```

---

## 📝 Variables d'Environnement

Mettre à jour `.env.gcp` :

```bash
# Cloud SQL Configuration
export CLOUD_SQL_INSTANCE_NAME="tshiakani-vtc-db"
export CLOUD_SQL_DATABASE_NAME="TshiakaniVTC"
export CLOUD_SQL_USER="postgres"
export CLOUD_SQL_PASSWORD="VOTRE_MOT_DE_PASSE"
export CLOUD_SQL_CONNECTION_NAME="${GCP_PROJECT_ID}:${GCP_REGION}:${CLOUD_SQL_INSTANCE_NAME}"

# Pour les applications Cloud Run
export DB_HOST="/cloudsql/${CLOUD_SQL_CONNECTION_NAME}"
export DB_PORT="5432"
export DB_NAME="${CLOUD_SQL_DATABASE_NAME}"
export DB_USER="${CLOUD_SQL_USER}"
export DB_PASSWORD="${CLOUD_SQL_PASSWORD}"
```

---

## 🚨 Dépannage

### Erreur: "Instance creation failed"

```bash
# Vérifier les quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Vérifier les limites
gcloud sql instances list --project=$PROJECT_ID
```

### Erreur: "PostGIS extension not available"

```bash
# Vérifier que PostGIS est disponible
gcloud sql instances describe $INSTANCE_NAME --format="value(databaseVersion)"

# PostgreSQL 14+ supporte PostGIS
# Si nécessaire, mettre à jour la version
gcloud sql instances patch $INSTANCE_NAME --database-version=POSTGRES_14
```

### Erreur: "Connection refused"

```bash
# Vérifier les autorisations IP
gcloud sql instances describe $INSTANCE_NAME --format="value(ipAddresses)"

# Autoriser une IP spécifique (si nécessaire)
gcloud sql instances patch $INSTANCE_NAME --authorized-networks=IP_ADDRESS
```

---

## 📚 Ressources Utiles

- **Documentation Cloud SQL**: https://cloud.google.com/sql/docs/postgres
- **Documentation PostGIS**: https://postgis.net/documentation
- **Guide de migration**: https://cloud.google.com/sql/docs/postgres/migrate

---

## 🎯 Prochaines Étapes

Une fois cette étape complétée :

1. **Étape 3**: Configuration de Memorystore (Redis)
2. **Étape 4**: Déploiement du Backend sur Cloud Run
3. **Étape 5**: Configuration du Dashboard Admin

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

