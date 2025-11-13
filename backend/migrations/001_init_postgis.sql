-- Migration initiale pour PostgreSQL + PostGIS
-- Wewa Taxi Database Schema

-- Activer l'extension PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table Users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('client', 'driver', 'admin')),
    is_verified BOOLEAN DEFAULT false,
    driver_info JSONB,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography type (WGS84)
    fcm_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index spatial pour performances (GIST)
CREATE INDEX idx_users_location ON users USING GIST (location);
CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_phone ON users (phone_number);
CREATE INDEX idx_users_driver_online ON users ((driver_info->>'isOnline')) WHERE role = 'driver';

-- Table Rides
CREATE TABLE rides (
    id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    pickup_location GEOGRAPHY(POINT, 4326),
    dropoff_location GEOGRAPHY(POINT, 4326),
    pickup_address TEXT,
    dropoff_address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'driverArriving', 'inProgress', 'completed', 'cancelled')),
    estimated_price DECIMAL(10,2) NOT NULL,
    final_price DECIMAL(10,2),
    distance_km DECIMAL(10,2),
    duration_min INTEGER,
    payment_method VARCHAR(20) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'mobile_money', 'card')),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT
);

-- Index spatial pour les rides
CREATE INDEX idx_rides_pickup ON rides USING GIST (pickup_location);
CREATE INDEX idx_rides_dropoff ON rides USING GIST (dropoff_location);
CREATE INDEX idx_rides_client ON rides (client_id);
CREATE INDEX idx_rides_driver ON rides (driver_id);
CREATE INDEX idx_rides_status ON rides (status);
CREATE INDEX idx_rides_created ON rides (created_at DESC);

-- Table Notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('ride', 'promotion', 'security', 'system')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications (user_id, created_at DESC);
CREATE INDEX idx_notifications_read ON notifications (is_read);

-- Table SOS Reports
CREATE TABLE sos_reports (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326),
    address TEXT,
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    message TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'false_alarm')),
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sos_location ON sos_reports USING GIST (location);
CREATE INDEX idx_sos_status ON sos_reports (status);
CREATE INDEX idx_sos_user ON sos_reports (user_id, created_at DESC);

-- Fonction pour calculer la distance entre deux points
CREATE OR REPLACE FUNCTION calculate_distance(
    point1 GEOGRAPHY,
    point2 GEOGRAPHY
) RETURNS DECIMAL AS $$
BEGIN
    RETURN ST_Distance(point1, point2) / 1000; -- Retourne en kilomètres
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour trouver les conducteurs proches (optimisée)
CREATE OR REPLACE FUNCTION find_nearby_drivers(
    search_lat DECIMAL,
    search_lon DECIMAL,
    radius_km DECIMAL DEFAULT 5
) RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    phone_number VARCHAR,
    driver_info JSONB,
    distance_km DECIMAL
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
        ) / 1000 AS distance_km
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

-- Vue pour les statistiques
CREATE OR REPLACE VIEW ride_statistics AS
SELECT 
    DATE(created_at) AS date,
    COUNT(*) AS total_rides,
    COUNT(*) FILTER (WHERE status = 'completed') AS completed_rides,
    SUM(final_price) FILTER (WHERE status = 'completed') AS total_revenue,
    AVG(distance_km) FILTER (WHERE status = 'completed') AS avg_distance
FROM rides
GROUP BY DATE(created_at);

