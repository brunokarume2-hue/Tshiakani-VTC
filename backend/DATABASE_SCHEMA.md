# 🗄️ Schéma de Base de Données - Tshiakani VTC

## 📊 Vue d'Ensemble

Base de données PostgreSQL + PostGIS pour Tshiakani VTC avec les tables principales : users, rides, notifications, sos_reports, price_configurations.

---

## 📋 Tables

### 1. Table: `users`

**Description**: Utilisateurs de l'application (clients, conducteurs, admins, agents)

**Colonnes:**

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique |
| `name` | VARCHAR(255) | NOT NULL | Nom de l'utilisateur |
| `phone_number` | VARCHAR(20) | UNIQUE, NOT NULL | Numéro de téléphone |
| `role` | VARCHAR(20) | NOT NULL, CHECK | Rôle: 'client', 'driver', 'admin', 'agent' |
| `is_verified` | BOOLEAN | DEFAULT false | Utilisateur vérifié |
| `driver_info` | JSONB | DEFAULT '{}' | Informations du conducteur (si role='driver') |
| `location` | GEOGRAPHY(POINT, 4326) | NULLABLE | Position géographique (PostGIS) |
| `fcm_token` | VARCHAR(255) | NULLABLE | Token Firebase Cloud Messaging |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Date de création |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Date de mise à jour |

**Index:**
- `idx_users_location` (GIST) - Index spatial sur `location`
- `idx_users_role` - Index sur `role`
- `idx_users_phone` (UNIQUE) - Index unique sur `phone_number`
- `idx_users_driver_online` (PARTIAL) - Index partiel sur `driver_info->>'isOnline'` WHERE role='driver'
- `idx_users_created_at` - Index sur `created_at DESC`

**Relations:**
- `clientRides` (one-to-many) → `rides.client_id`
- `driverRides` (one-to-many) → `rides.driver_id`

**Exemple de `driver_info` (JSONB):**
```json
{
  "isOnline": true,
  "status": "available",
  "currentRideId": null,
  "documentsStatus": "validated",
  "documents": {
    "license": {
      "status": "validated",
      "url": "https://...",
      "validatedAt": "2025-01-15T00:00:00Z"
    },
    "vehicleRegistration": {
      "status": "validated",
      "url": "https://...",
      "validatedAt": "2025-01-15T00:00:00Z"
    }
  },
  "vehicle": {
    "make": "Honda",
    "model": "CG125",
    "year": 2020,
    "licensePlate": "ABC123"
  },
  "rating": 4.5,
  "totalRides": 150,
  "ratingCount": 120
}
```

---

### 2. Table: `rides`

**Description**: Courses effectuées dans l'application

**Colonnes:**

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique |
| `client_id` | INTEGER | NOT NULL, FK → users(id) | ID du client |
| `driver_id` | INTEGER | NULLABLE, FK → users(id) | ID du conducteur |
| `pickup_location` | GEOGRAPHY(POINT, 4326) | NOT NULL | Point de départ (PostGIS) |
| `dropoff_location` | GEOGRAPHY(POINT, 4326) | NOT NULL | Point d'arrivée (PostGIS) |
| `pickup_address` | TEXT | NULLABLE | Adresse de départ |
| `dropoff_address` | TEXT | NULLABLE | Adresse d'arrivée |
| `status` | VARCHAR(20) | NOT NULL, CHECK, DEFAULT 'pending' | Statut: 'pending', 'accepted', 'driverArriving', 'inProgress', 'completed', 'cancelled' |
| `estimated_price` | DECIMAL(10,2) | NOT NULL | Prix estimé (CDF) |
| `final_price` | DECIMAL(10,2) | NULLABLE | Prix final (CDF) |
| `distance_km` | DECIMAL(10,2) | NULLABLE | Distance en kilomètres |
| `duration_min` | INTEGER | NULLABLE | Durée réelle en minutes |
| `estimated_duration` | INTEGER | NULLABLE | Durée estimée en minutes |
| `payment_method` | VARCHAR(20) | DEFAULT 'cash', CHECK | Méthode: 'cash', 'mobile_money', 'card', 'stripe' |
| `rating` | INTEGER | CHECK (1-5) | Note (1-5 étoiles) |
| `comment` | TEXT | NULLABLE | Commentaire |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Date de création |
| `started_at` | TIMESTAMP | NULLABLE | Date de début |
| `completed_at` | TIMESTAMP | NULLABLE | Date de fin |
| `cancelled_at` | TIMESTAMP | NULLABLE | Date d'annulation |
| `cancellation_reason` | TEXT | NULLABLE | Raison d'annulation |

**Index:**
- `idx_rides_pickup` (GIST) - Index spatial sur `pickup_location`
- `idx_rides_dropoff` (GIST) - Index spatial sur `dropoff_location`
- `idx_rides_client` - Index sur `client_id`
- `idx_rides_driver` - Index sur `driver_id`
- `idx_rides_status` - Index sur `status`
- `idx_rides_created` - Index sur `created_at DESC`
- `idx_rides_client_status` - Index composite sur `(client_id, status)`
- `idx_rides_driver_status` (PARTIAL) - Index partiel sur `(driver_id, status)` WHERE driver_id IS NOT NULL
- `idx_rides_status_created` - Index composite sur `(status, created_at DESC)`

**Relations:**
- `client` (many-to-one) → `users.id` (client_id)
- `driver` (many-to-one) → `users.id` (driver_id)

**Statuts:**
- `pending` - Course créée, en attente d'acceptation
- `accepted` - Course acceptée par un conducteur
- `driverArriving` - Conducteur en route vers le point de départ
- `inProgress` - Course en cours
- `completed` - Course terminée
- `cancelled` - Course annulée

---

### 3. Table: `notifications`

**Description**: Notifications envoyées aux utilisateurs

**Colonnes:**

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique |
| `user_id` | INTEGER | NOT NULL, FK → users(id) | ID de l'utilisateur |
| `type` | VARCHAR(20) | NOT NULL, CHECK | Type: 'ride', 'promotion', 'security', 'system', 'payment' |
| `title` | VARCHAR(255) | NOT NULL | Titre de la notification |
| `message` | TEXT | NOT NULL | Message de la notification |
| `ride_id` | INTEGER | NULLABLE, FK → rides(id) | ID de la course (si liée) |
| `is_read` | BOOLEAN | DEFAULT false | Notification lue |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Date de création |

**Index:**
- `idx_notifications_user` - Index sur `(user_id, created_at DESC)`
- `idx_notifications_read` - Index sur `is_read`
- `idx_notifications_type` - Index sur `type`
- `idx_notifications_user_read` - Index composite sur `(user_id, is_read, created_at DESC)`

**Relations:**
- `user` (many-to-one) → `users.id`
- `ride` (many-to-one) → `rides.id`

---

### 4. Table: `sos_reports`

**Description**: Rapports d'urgence SOS

**Colonnes:**

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique |
| `user_id` | INTEGER | NOT NULL, FK → users(id) | ID de l'utilisateur |
| `location` | GEOGRAPHY(POINT, 4326) | NOT NULL | Position géographique (PostGIS) |
| `address` | TEXT | NULLABLE | Adresse |
| `ride_id` | INTEGER | NULLABLE, FK → rides(id) | ID de la course (si liée) |
| `message` | TEXT | NULLABLE | Message |
| `status` | VARCHAR(20) | DEFAULT 'active', CHECK | Statut: 'active', 'resolved', 'false_alarm', 'pending' |
| `resolved_at` | TIMESTAMP | NULLABLE | Date de résolution |
| `resolved_by` | INTEGER | NULLABLE, FK → users(id) | ID de l'utilisateur qui a résolu |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Date de création |

**Index:**
- `idx_sos_location` (GIST) - Index spatial sur `location`
- `idx_sos_status` - Index sur `status`
- `idx_sos_user` - Index sur `(user_id, created_at DESC)`
- `idx_sos_created` - Index sur `created_at DESC`

**Relations:**
- `user` (many-to-one) → `users.id`
- `ride` (many-to-one) → `rides.id`
- `resolvedBy` (many-to-one) → `users.id` (resolved_by)

---

### 5. Table: `price_configurations`

**Description**: Configuration des prix et tarifs

**Colonnes:**

| Colonne | Type | Contraintes | Description |
|---------|------|-------------|-------------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique |
| `base_price` | DECIMAL(10,2) | NOT NULL, DEFAULT 500.00 | Prix de base (CDF) |
| `price_per_km` | DECIMAL(10,2) | NOT NULL, DEFAULT 200.00 | Prix par kilomètre (CDF) |
| `rush_hour_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.50 | Multiplicateur heures de pointe |
| `night_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.30 | Multiplicateur nuit |
| `weekend_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.20 | Multiplicateur week-end |
| `surge_low_demand_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 0.90 | Multiplicateur demande faible |
| `surge_normal_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.00 | Multiplicateur demande normale |
| `surge_high_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.20 | Multiplicateur demande élevée |
| `surge_very_high_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.40 | Multiplicateur demande très élevée |
| `surge_extreme_multiplier` | DECIMAL(5,2) | NOT NULL, DEFAULT 1.60 | Multiplicateur demande extrême |
| `description` | TEXT | NULLABLE | Description |
| `is_active` | BOOLEAN | DEFAULT true | Configuration active |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Date de création |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Date de mise à jour |

**Index:**
- `idx_price_config_active` (PARTIAL) - Index partiel sur `is_active` WHERE is_active=true

---

## 🔧 Fonctions SQL

### 1. `calculate_distance(point1, point2)`

**Description**: Calcule la distance entre deux points géographiques (en kilomètres)

**Paramètres:**
- `point1` (GEOGRAPHY) - Premier point
- `point2` (GEOGRAPHY) - Deuxième point

**Retour:**
- `DECIMAL` - Distance en kilomètres

**Exemple:**
```sql
SELECT calculate_distance(
    ST_MakePoint(15.3136, -4.3276)::geography,
    ST_MakePoint(15.3236, -4.3376)::geography
);
-- Retourne: 1.234 (kilomètres)
```

---

### 2. `find_nearby_drivers(search_lat, search_lon, radius_km)`

**Description**: Trouve les conducteurs proches d'un point géographique

**Paramètres:**
- `search_lat` (DECIMAL) - Latitude du point de recherche
- `search_lon` (DECIMAL) - Longitude du point de recherche
- `radius_km` (DECIMAL) - Rayon de recherche en kilomètres (défaut: 10)

**Retour:**
- Table avec les colonnes: `id`, `name`, `phone_number`, `driver_info`, `distance_km`, `location_lat`, `location_lon`, `fcm_token`

**Exemple:**
```sql
SELECT * FROM find_nearby_drivers(-4.3276, 15.3136, 5);
-- Retourne les conducteurs dans un rayon de 5 km
```

---

## 📊 Vues

### 1. `ride_statistics`

**Description**: Statistiques des courses par date

**Colonnes:**
- `date` (DATE) - Date
- `total_rides` (INTEGER) - Nombre total de courses
- `completed_rides` (INTEGER) - Nombre de courses complétées
- `cancelled_rides` (INTEGER) - Nombre de courses annulées
- `total_revenue` (DECIMAL) - Revenus totaux
- `avg_distance` (DECIMAL) - Distance moyenne
- `avg_duration` (DECIMAL) - Durée moyenne
- `avg_rating` (DECIMAL) - Note moyenne

**Exemple:**
```sql
SELECT * FROM ride_statistics 
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY date DESC;
```

---

### 2. `driver_statistics`

**Description**: Statistiques des conducteurs

**Colonnes:**
- `driver_id` (INTEGER) - ID du conducteur
- `driver_name` (VARCHAR) - Nom du conducteur
- `phone_number` (VARCHAR) - Numéro de téléphone
- `total_rides` (INTEGER) - Nombre total de courses
- `completed_rides` (INTEGER) - Nombre de courses complétées
- `cancelled_rides` (INTEGER) - Nombre de courses annulées
- `total_earnings` (DECIMAL) - Revenus totaux
- `avg_rating` (DECIMAL) - Note moyenne
- `active_days` (INTEGER) - Nombre de jours actifs

**Exemple:**
```sql
SELECT * FROM driver_statistics 
ORDER BY total_earnings DESC 
LIMIT 10;
```

---

## 🔍 Index Optimisés

### Index Spatiaux (GIST)

- `idx_users_location` - Recherche de conducteurs proches
- `idx_rides_pickup` - Recherche de courses par point de départ
- `idx_rides_dropoff` - Recherche de courses par point d'arrivée
- `idx_sos_location` - Recherche de SOS par localisation

### Index Composites

- `idx_rides_client_status` - Courses d'un client par statut
- `idx_rides_driver_status` - Courses d'un conducteur par statut
- `idx_rides_status_created` - Courses par statut et date
- `idx_notifications_user_read` - Notifications non lues d'un utilisateur

### Index Partiels

- `idx_users_driver_online` - Conducteurs en ligne uniquement
- `idx_rides_driver_status` - Courses avec conducteur uniquement
- `idx_notifications_user_unread` - Notifications non lues uniquement
- `idx_sos_active_created` - SOS actifs uniquement
- `idx_price_config_active` - Configuration active uniquement

---

## 🔐 Contraintes et Validations

### Contraintes de Vérification

- `users.role` - Doit être 'client', 'driver', 'admin', ou 'agent'
- `rides.status` - Doit être 'pending', 'accepted', 'driverArriving', 'inProgress', 'completed', ou 'cancelled'
- `rides.payment_method` - Doit être 'cash', 'mobile_money', 'card', ou 'stripe'
- `rides.rating` - Doit être entre 1 et 5
- `notifications.type` - Doit être 'ride', 'promotion', 'security', 'system', ou 'payment'
- `sos_reports.status` - Doit être 'active', 'resolved', 'false_alarm', ou 'pending'

### Clés Étrangères

- `rides.client_id` → `users.id` (ON DELETE CASCADE)
- `rides.driver_id` → `users.id` (ON DELETE SET NULL)
- `notifications.user_id` → `users.id` (ON DELETE CASCADE)
- `notifications.ride_id` → `rides.id` (ON DELETE SET NULL)
- `sos_reports.user_id` → `users.id` (ON DELETE CASCADE)
- `sos_reports.ride_id` → `rides.id` (ON DELETE SET NULL)
- `sos_reports.resolved_by` → `users.id`

### Contraintes Uniques

- `users.phone_number` - Numéro de téléphone unique

---

## 📈 Performances

### Optimisations

1. **Index spatiaux GIST** pour les requêtes géographiques
2. **Index composites** pour les requêtes fréquentes
3. **Index partiels** pour réduire la taille des index
4. **Triggers** pour mettre à jour automatiquement `updated_at`
5. **Vues matérialisées** pour les statistiques (si nécessaire)

### Requêtes Optimisées

- Recherche de conducteurs proches: Utilise `idx_users_location` (GIST)
- Courses d'un client: Utilise `idx_rides_client_status`
- Courses d'un conducteur: Utilise `idx_rides_driver_status`
- Notifications non lues: Utilise `idx_notifications_user_unread`

---

## 🔄 Migrations

### Ordre d'Application

1. `001_init_postgis_cloud_sql.sql` - Tables de base et PostGIS
2. `002_create_price_configurations.sql` - Configuration des prix
3. `003_optimize_indexes.sql` - Optimisation des index

### Appliquer les Migrations

```bash
# Via script
./scripts/gcp-apply-migrations.sh

# Ou manuellement
psql -h $INSTANCE_IP -U $DB_USER -d $DATABASE_NAME -f backend/migrations/001_init_postgis_cloud_sql.sql
psql -h $INSTANCE_IP -U $DB_USER -d $DATABASE_NAME -f backend/migrations/002_create_price_configurations.sql
psql -h $INSTANCE_IP -U $DB_USER -d $DATABASE_NAME -f backend/migrations/003_optimize_indexes.sql
```

---

## 📝 Notes Importantes

1. **PostGIS**: Nécessaire pour les fonctionnalités géospatiales
2. **JSONB**: Utilisé pour `driver_info` pour flexibilité
3. **GEOGRAPHY**: Utilisé au lieu de GEOMETRY pour les calculs de distance précis
4. **Index GIST**: Essentiels pour les performances des requêtes spatiales
5. **Triggers**: Mettent à jour automatiquement `updated_at`

---

## 🔍 Exemples de Requêtes

### Trouver les conducteurs proches

```sql
SELECT * FROM find_nearby_drivers(-4.3276, 15.3136, 5);
```

### Calculer la distance d'une course

```sql
SELECT 
    id,
    calculate_distance(pickup_location, dropoff_location) AS distance_km
FROM rides
WHERE id = 1;
```

### Statistiques des courses

```sql
SELECT * FROM ride_statistics 
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY date DESC;
```

### Statistiques des conducteurs

```sql
SELECT * FROM driver_statistics 
WHERE total_rides > 10
ORDER BY avg_rating DESC;
```

---

**Date de création**: 2025-01-15  
**Version**: 1.0.0

