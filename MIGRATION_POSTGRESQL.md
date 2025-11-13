# 🗄️ Migration vers PostgreSQL + PostGIS

## 🎯 Pourquoi PostgreSQL + PostGIS ?

### Avantages par rapport à MongoDB

1. **Performance géospatiale supérieure**
   - PostGIS est spécialement optimisé pour les requêtes géographiques
   - Indexation spatiale (GIST) très performante
   - Requêtes de proximité jusqu'à 10x plus rapides

2. **Fonctions géospatiales natives**
   - `ST_Distance` : Calcul de distance précis
   - `ST_Within` : Points dans une zone
   - `ST_Buffer` : Zones de recherche
   - Support des projections géographiques

3. **Standards SQL**
   - Requêtes SQL standard et bien documentées
   - Compatible avec de nombreux outils
   - Meilleure intégration avec les outils BI

4. **Transactions ACID**
   - Cohérence des données garantie
   - Meilleur pour les opérations financières (paiements)

5. **Requêtes complexes**
   - JOINs efficaces
   - Agrégations avancées
   - Vues et fonctions stockées

## 📊 Comparaison

| Fonctionnalité | MongoDB | PostgreSQL + PostGIS |
|---------------|---------|----------------------|
| Requêtes géospatiales | Basique | ⭐⭐⭐⭐⭐ Excellent |
| Performance proximité | Moyenne | ⭐⭐⭐⭐⭐ Très rapide |
| Indexation spatiale | 2dsphere | GIST (plus rapide) |
| Calcul distance | Manuel | ST_Distance natif |
| Zones de recherche | Limité | ST_Buffer, ST_Within |
| Transactions | Limité | ACID complet |
| Requêtes complexes | Difficile | SQL standard |

## 🚀 Migration proposée

### Structure avec PostgreSQL + PostGIS

```sql
-- Extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Table Users avec géolocalisation
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) CHECK (role IN ('client', 'driver', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    driver_info JSONB,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography type
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index spatial pour performances
CREATE INDEX idx_users_location ON users USING GIST (location);
CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_phone ON users (phone_number);

-- Table Rides avec géolocalisation
CREATE TABLE rides (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES users(id),
    driver_id INTEGER REFERENCES users(id),
    pickup_location GEOGRAPHY(POINT, 4326),
    dropoff_location GEOGRAPHY(POINT, 4326),
    status VARCHAR(20),
    estimated_price DECIMAL(10,2),
    final_price DECIMAL(10,2),
    distance_km DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index spatial pour les rides
CREATE INDEX idx_rides_pickup ON rides USING GIST (pickup_location);
CREATE INDEX idx_rides_dropoff ON rides USING GIST (dropoff_location);
```

### Requêtes optimisées avec PostGIS

```sql
-- Trouver les conducteurs proches (5 km)
SELECT 
    id, 
    name,
    ST_Distance(location, ST_MakePoint(15.3136, -4.3276)::geography) / 1000 AS distance_km
FROM users
WHERE role = 'driver'
    AND driver_info->>'isOnline' = 'true'
    AND ST_DWithin(
        location,
        ST_MakePoint(15.3136, -4.3276)::geography,
        5000  -- 5 km en mètres
    )
ORDER BY location <-> ST_MakePoint(15.3136, -4.3276)::geography
LIMIT 10;

-- Calculer la distance d'une course
SELECT 
    id,
    ST_Distance(pickup_location, dropoff_location) / 1000 AS distance_km
FROM rides
WHERE id = 123;
```

## 🔧 Adaptation du code Node.js

### Utiliser Sequelize ou TypeORM avec PostGIS

**Option 1 : Sequelize avec sequelize-postgres**
```bash
npm install sequelize pg pg-hstore
npm install sequelize-postgres
```

**Option 2 : TypeORM (recommandé pour PostGIS)**
```bash
npm install typeorm pg
npm install @types/pg
```

## 📝 Avantages pour Wewa Taxi

1. **Recherche de conducteurs proches** : Beaucoup plus rapide
2. **Calcul de distance** : Natif et précis
3. **Zones de service** : Facile à implémenter
4. **Analytics géographiques** : Requêtes complexes simplifiées
5. **Scalabilité** : Meilleure pour de grandes quantités de données

## ⚠️ Considérations

- **Migration nécessaire** : Il faut migrer les données existantes
- **Apprentissage** : L'équipe doit connaître SQL/PostGIS
- **Déploiement** : PostgreSQL nécessite plus de configuration que MongoDB

## ✅ Recommandation

**OUI, je recommande PostgreSQL + PostGIS pour Wewa Taxi !**

C'est le choix optimal pour une application de transport avec géolocalisation.

