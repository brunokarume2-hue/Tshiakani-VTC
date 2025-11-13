# 🚀 Guide de Démarrage Rapide - Étape 2 : Cloud SQL

## ⚡ Démarrage Rapide (10 minutes)

### 1. Prérequis

```bash
# Vérifier que gcloud est installé
gcloud --version

# Vérifier que psql est installé (pour les migrations)
psql --version

# Si psql n'est pas installé sur macOS
brew install postgresql
```

### 2. Configuration des Variables

```bash
# Charger les variables d'environnement
source .env.gcp

# Ou définir manuellement
export GCP_PROJECT_ID="tshiakani-vtc"
export CLOUD_SQL_INSTANCE_NAME="tshiakani-vtc-db"
export CLOUD_SQL_DATABASE_NAME="TshiakaniVTC"
export CLOUD_SQL_USER="postgres"
export DB_PASSWORD="VOTRE_MOT_DE_PASSE_SECURISE"
```

### 3. Créer l'Instance Cloud SQL

```bash
# Exécuter le script de création
./scripts/gcp-create-cloud-sql.sh
```

Le script va :
- ✅ Créer l'instance Cloud SQL PostgreSQL 14
- ✅ Créer l'utilisateur de base de données
- ✅ Créer la base de données
- ✅ Afficher les informations de connexion

### 4. Initialiser la Base de Données

```bash
# Activer PostGIS
./scripts/gcp-init-database.sh
```

Le script va :
- ✅ Activer l'extension PostGIS
- ✅ Activer l'extension uuid-ossp
- ✅ Vérifier PostGIS

### 5. Appliquer les Migrations

```bash
# Appliquer les migrations SQL
./scripts/gcp-apply-migrations.sh
```

Le script va :
- ✅ Créer les tables (users, rides, notifications, sos_reports, price_configurations)
- ✅ Créer les index optimisés
- ✅ Créer les fonctions PostGIS
- ✅ Créer les vues de statistiques
- ✅ Insérer les données initiales

### 6. Vérifier la Configuration

```bash
# Vérifier la base de données
./scripts/gcp-verify-database.sh
```

---

## 📊 Tables Créées

### 1. `users`
- Utilisateurs (clients, conducteurs, admins)
- Géolocalisation PostGIS
- Informations driver en JSONB

### 2. `rides`
- Courses avec pickup/dropoff locations
- Statuts : pending, accepted, inProgress, completed, cancelled
- Prix estimé et final
- Distance et durée
- Rating et commentaires

### 3. `notifications`
- Notifications utilisateurs
- Types : ride, promotion, security, system, payment

### 4. `sos_reports`
- Rapports d'urgence SOS
- Géolocalisation PostGIS
- Statuts : active, resolved, false_alarm, pending

### 5. `price_configurations`
- Configuration des prix
- Multiplicateurs (rush hour, night, weekend, surge)

---

## 🔍 Vérification Manuelle

### Se Connecter à la Base de Données

```bash
# Via gcloud
gcloud sql connect $INSTANCE_NAME --user=$DB_USER --database=$DATABASE_NAME

# Ou via psql directement
psql -h $INSTANCE_IP -U $DB_USER -d $DATABASE_NAME
```

### Commandes PostgreSQL Utiles

```sql
-- Lister les tables
\dt

-- Lister les index
\di

-- Lister les fonctions
\df

-- Lister les vues
\dv

-- Vérifier PostGIS
SELECT PostGIS_version();

-- Vérifier les extensions
\dx

-- Compter les utilisateurs
SELECT role, COUNT(*) FROM users GROUP BY role;

-- Vérifier les courses
SELECT status, COUNT(*) FROM rides GROUP BY status;
```

---

## 🔐 Sécurité

### Stocker le Mot de Passe dans Secret Manager

```bash
# Créer le secret
echo -n "$DB_PASSWORD" | gcloud secrets create db-password \
  --data-file=- \
  --project=$GCP_PROJECT_ID

# Accorder l'accès au compte de service
gcloud secrets add-iam-policy-binding db-password \
  --member="serviceAccount:tshiakani-vtc-backend@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=$GCP_PROJECT_ID
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

## ✅ Checklist

- [ ] Instance Cloud SQL créée
- [ ] Base de données créée
- [ ] Utilisateur créé
- [ ] PostGIS activé
- [ ] Tables créées
- [ ] Index créés
- [ ] Fonctions créées
- [ ] Vues créées
- [ ] Configuration de prix insérée
- [ ] Vérification réussie

---

## 🚨 Dépannage

### Erreur: "Instance creation failed"
```bash
# Vérifier les quotas
gcloud compute project-info describe --project=$GCP_PROJECT_ID

# Vérifier la facturation
gcloud billing projects describe $GCP_PROJECT_ID
```

### Erreur: "PostGIS extension not available"
```bash
# Vérifier la version PostgreSQL
gcloud sql instances describe $INSTANCE_NAME --format="value(databaseVersion)"

# PostgreSQL 14+ supporte PostGIS
```

### Erreur: "Connection refused"
```bash
# Vérifier les autorisations IP
gcloud sql instances describe $INSTANCE_NAME --format="value(ipAddresses)"

# Autoriser une IP spécifique (si nécessaire)
gcloud sql instances patch $INSTANCE_NAME --authorized-networks=IP_ADDRESS
```

---

## 🎯 Prochaines Étapes

Une fois l'étape 2 complétée :

1. **Étape 3**: Configuration de Memorystore (Redis)
2. **Étape 4**: Déploiement du Backend sur Cloud Run
3. **Étape 5**: Configuration du Dashboard Admin

---

## 📚 Documentation

- **Guide complet**: `GCP_SETUP_ETAPE2.md`
- **Résumé**: `GCP_SETUP_ETAPE2_RESUME.md`
- **Script de création**: `scripts/gcp-create-cloud-sql.sh`
- **Script d'initialisation**: `scripts/gcp-init-database.sh`
- **Script de migrations**: `scripts/gcp-apply-migrations.sh`
- **Script de vérification**: `scripts/gcp-verify-database.sh`

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

