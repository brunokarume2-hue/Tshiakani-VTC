-- ============================================
-- Migration initiale pour Cloud SQL PostgreSQL + PostGIS
-- Tshiakani VTC Database Schema
-- Optimisée pour Google Cloud SQL
-- ============================================

-- Activer les extensions PostgreSQL
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Table: users
-- Utilisateurs (clients, conducteurs, admins)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('client', 'driver', 'admin', 'agent')),
    is_verified BOOLEAN DEFAULT false,
    driver_info JSONB DEFAULT '{}'::jsonb,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography type (WGS84)
    fcm_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour la table users
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone_number);
CREATE INDEX IF NOT EXISTS idx_users_driver_online ON users ((driver_info->>'isOnline')) WHERE role = 'driver';
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at DESC);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Table: rides
-- Courses (rides)
-- ============================================
CREATE TABLE IF NOT EXISTS rides (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    pickup_address TEXT,
    dropoff_address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'accepted', 'driverArriving', 'inProgress', 'completed', 'cancelled')),
    estimated_price DECIMAL(10,2) NOT NULL,
    final_price DECIMAL(10,2),
    distance_km DECIMAL(10,2),
    duration_min INTEGER,
    estimated_duration INTEGER, -- Durée estimée en minutes
    payment_method VARCHAR(20) DEFAULT 'cash' 
        CHECK (payment_method IN ('cash', 'mobile_money', 'card', 'stripe')),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT
);

-- Index pour la table rides
CREATE INDEX IF NOT EXISTS idx_rides_pickup ON rides USING GIST (pickup_location);
CREATE INDEX IF NOT EXISTS idx_rides_dropoff ON rides USING GIST (dropoff_location);
CREATE INDEX IF NOT EXISTS idx_rides_client ON rides (client_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides (driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides (status);
CREATE INDEX IF NOT EXISTS idx_rides_created ON rides (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rides_client_status ON rides (client_id, status);
CREATE INDEX IF NOT EXISTS idx_rides_driver_status ON rides (driver_id, status) WHERE driver_id IS NOT NULL;

-- Index composite pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_rides_status_created ON rides (status, created_at DESC);

-- ============================================
-- Table: notifications
-- Notifications utilisateurs
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('ride', 'promotion', 'security', 'system', 'payment')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour la table notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications (is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (type);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications (user_id, is_read, created_at DESC);

-- ============================================
-- Table: sos_reports
-- Rapports d'urgence SOS
-- ============================================
CREATE TABLE IF NOT EXISTS sos_reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address TEXT,
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'active' 
        CHECK (status IN ('active', 'resolved', 'false_alarm', 'pending')),
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour la table sos_reports
CREATE INDEX IF NOT EXISTS idx_sos_location ON sos_reports USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_reports (status);
CREATE INDEX IF NOT EXISTS idx_sos_user ON sos_reports (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sos_created ON sos_reports (created_at DESC);

-- ============================================
-- Table: price_configurations
-- Configuration des prix
-- ============================================
CREATE TABLE IF NOT EXISTS price_configurations (
    id SERIAL PRIMARY KEY,
    base_price DECIMAL(10,2) NOT NULL DEFAULT 500.00,
    price_per_km DECIMAL(10,2) NOT NULL DEFAULT 200.00,
    rush_hour_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.50,
    night_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.30,
    weekend_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.20,
    surge_low_demand_multiplier DECIMAL(5,2) NOT NULL DEFAULT 0.90,
    surge_normal_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    surge_high_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.20,
    surge_very_high_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.40,
    surge_extreme_multiplier DECIMAL(5,2) NOT NULL DEFAULT 1.60,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour la table price_configurations
CREATE INDEX IF NOT EXISTS idx_price_config_active ON price_configurations (is_active) WHERE is_active = true;

-- Trigger pour mettre à jour updated_at
CREATE TRIGGER update_price_config_updated_at
    BEFORE UPDATE ON price_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Fonctions Utilitaires
-- ============================================

-- Fonction pour calculer la distance entre deux points (en kilomètres)
CREATE OR REPLACE FUNCTION calculate_distance(
    point1 GEOGRAPHY,
    point2 GEOGRAPHY
) RETURNS DECIMAL AS $$
BEGIN
    IF point1 IS NULL OR point2 IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN ST_Distance(point1, point2) / 1000; -- Retourne en kilomètres
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour trouver les conducteurs proches (optimisée pour Cloud SQL)
CREATE OR REPLACE FUNCTION find_nearby_drivers(
    search_lat DECIMAL,
    search_lon DECIMAL,
    radius_km DECIMAL DEFAULT 10
) RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    phone_number VARCHAR,
    driver_info JSONB,
    distance_km DECIMAL,
    location_lat DECIMAL,
    location_lon DECIMAL,
    fcm_token VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u.phone_number,
        u.driver_info,
        ST_Distance(
            u.location,
            ST_MakePoint(search_lon, search_lat)::geography
        ) / 1000 AS distance_km,
        ST_Y(u.location::geometry) AS location_lat,
        ST_X(u.location::geometry) AS location_lon,
        u.fcm_token
    FROM users u
    WHERE u.role = 'driver'
        AND u.driver_info->>'isOnline' = 'true'
        AND u.location IS NOT NULL
        AND ST_DWithin(
            u.location,
            ST_MakePoint(search_lon, search_lat)::geography,
            radius_km * 1000  -- Convertir en mètres
        )
    ORDER BY u.location <-> ST_MakePoint(search_lon, search_lat)::geography
    LIMIT 20;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- Vues
-- ============================================

-- Vue pour les statistiques des courses
CREATE OR REPLACE VIEW ride_statistics AS
SELECT 
    DATE(created_at) AS date,
    COUNT(*) AS total_rides,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_rides,
    COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled_rides,
    SUM(final_price) FILTER (WHERE status = 'completed') AS total_revenue,
    AVG(distance_km) FILTER (WHERE status = 'completed') AS avg_distance,
    AVG(duration_min) FILTER (WHERE status = 'completed') AS avg_duration,
    AVG(rating) FILTER (WHERE status = 'completed' AND rating IS NOT NULL) AS avg_rating
FROM rides
GROUP BY DATE(created_at);

-- Vue pour les statistiques des conducteurs
CREATE OR REPLACE VIEW driver_statistics AS
SELECT 
    u.id AS driver_id,
    u.name AS driver_name,
    u.phone_number,
    COUNT(r.id) AS total_rides,
    COUNT(r.id) FILTER (WHERE r.status = 'completed') AS completed_rides,
    COUNT(r.id) FILTER (WHERE r.status = 'cancelled') AS cancelled_rides,
    SUM(r.final_price) FILTER (WHERE r.status = 'completed') AS total_earnings,
    AVG(r.rating) FILTER (WHERE r.status = 'completed' AND r.rating IS NOT NULL) AS avg_rating,
    COUNT(DISTINCT DATE(r.created_at)) AS active_days
FROM users u
LEFT JOIN rides r ON u.id = r.driver_id
WHERE u.role = 'driver'
GROUP BY u.id, u.name, u.phone_number;

-- ============================================
-- Données Initiales
-- ============================================

-- Insérer une configuration de prix par défaut
INSERT INTO price_configurations (
    base_price,
    price_per_km,
    rush_hour_multiplier,
    night_multiplier,
    weekend_multiplier,
    surge_low_demand_multiplier,
    surge_normal_multiplier,
    surge_high_multiplier,
    surge_very_high_multiplier,
    surge_extreme_multiplier,
    description,
    is_active
) VALUES (
    500.00,
    200.00,
    1.50,
    1.30,
    1.20,
    0.90,
    1.00,
    1.20,
    1.40,
    1.60,
    'Configuration par défaut - Kinshasa, RDC',
    true
) ON CONFLICT DO NOTHING;

-- ============================================
-- Commentaires sur les Tables
-- ============================================

COMMENT ON TABLE users IS 'Utilisateurs de l''application (clients, conducteurs, admins)';
COMMENT ON TABLE rides IS 'Courses effectuées dans l''application';
COMMENT ON TABLE notifications IS 'Notifications envoyées aux utilisateurs';
COMMENT ON TABLE sos_reports IS 'Rapports d''urgence SOS';
COMMENT ON TABLE price_configurations IS 'Configuration des prix et tarifs';

COMMENT ON COLUMN users.location IS 'Position géographique de l''utilisateur (PostGIS)';
COMMENT ON COLUMN users.driver_info IS 'Informations spécifiques au conducteur (JSON)';
COMMENT ON COLUMN rides.pickup_location IS 'Point de départ de la course (PostGIS)';
COMMENT ON COLUMN rides.dropoff_location IS 'Point d''arrivée de la course (PostGIS)';
COMMENT ON COLUMN rides.status IS 'Statut de la course: pending, accepted, inProgress, completed, cancelled';

-- ============================================
-- Fin de la Migration
-- ============================================

