-- Migration optimisée pour Render PostgreSQL + PostGIS
-- Script d'initialisation pour le déploiement sur Render

-- Activer l'extension PostGIS (nécessaire pour les données géospatiales)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table Users (inclut les chauffeurs)
CREATE TABLE IF NOT EXISTS users (
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

-- Index spatial pour performances (GIST) - CRITIQUE pour les requêtes géospatiales
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_users_role ON users (role);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users (phone_number);
CREATE INDEX IF NOT EXISTS idx_users_driver_online ON users ((driver_info->>'isOnline')) WHERE role = 'driver';

-- Table Rides (courses)
CREATE TABLE IF NOT EXISTS rides (
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
    payment_method VARCHAR(20) DEFAULT 'cash' CHECK (payment_method IN ('cash', 'mobile_money', 'card', 'stripe')),
    stripe_payment_intent_id VARCHAR(255), -- ID du PaymentIntent Stripe
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT
);

-- Index spatial pour les rides
CREATE INDEX IF NOT EXISTS idx_rides_pickup ON rides USING GIST (pickup_location);
CREATE INDEX IF NOT EXISTS idx_rides_dropoff ON rides USING GIST (dropoff_location);
CREATE INDEX IF NOT EXISTS idx_rides_client ON rides (client_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides (driver_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides (status);
CREATE INDEX IF NOT EXISTS idx_rides_created ON rides (created_at DESC);

-- Table pour les transactions Stripe
CREATE TABLE IF NOT EXISTS stripe_transactions (
    id SERIAL PRIMARY KEY,
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    payment_intent_id VARCHAR(255) UNIQUE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'CDF',
    status VARCHAR(50) NOT NULL, -- 'pending', 'succeeded', 'failed', 'canceled'
    stripe_token VARCHAR(255), -- Token initial (non stocké après traitement)
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_ride ON stripe_transactions (ride_id);
CREATE INDEX IF NOT EXISTS idx_stripe_intent ON stripe_transactions (payment_intent_id);
CREATE INDEX IF NOT EXISTS idx_stripe_status ON stripe_transactions (status);

-- Fonction pour trouver les chauffeurs proches (optimisée pour Render)
CREATE OR REPLACE FUNCTION find_nearby_drivers(
    search_lat DECIMAL,
    search_lon DECIMAL,
    radius_km DECIMAL DEFAULT 5
) RETURNS TABLE (
    id INTEGER,
    name VARCHAR,
    phone_number VARCHAR,
    driver_info JSONB,
    distance_km DECIMAL,
    location_lat DECIMAL,
    location_lon DECIMAL
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
        ST_X(u.location::geometry) AS location_lon
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

-- Vue pour les statistiques des chauffeurs actifs
CREATE OR REPLACE VIEW active_drivers_stats AS
SELECT 
    COUNT(*) FILTER (WHERE role = 'driver' AND driver_info->>'isOnline' = 'true') AS total_online,
    COUNT(*) FILTER (WHERE role = 'driver') AS total_drivers,
    AVG((driver_info->>'rating')::DECIMAL) FILTER (WHERE role = 'driver' AND driver_info->>'rating' IS NOT NULL) AS avg_rating
FROM users;

-- Données de test (optionnel - à supprimer en production)
-- INSERT INTO users (name, phone_number, role, driver_info, location) VALUES
-- ('Chauffeur Test 1', '+243900000001', 'driver', '{"isOnline": true, "rating": 4.5, "vehicle": "Toyota Corolla"}'::jsonb, ST_MakePoint(15.3159, -4.3276)::geography),
-- ('Chauffeur Test 2', '+243900000002', 'driver', '{"isOnline": true, "rating": 4.8, "vehicle": "Honda Civic"}'::jsonb, ST_MakePoint(15.3160, -4.3277)::geography);

COMMENT ON TABLE users IS 'Table des utilisateurs (clients, chauffeurs, admins) avec localisation PostGIS';
COMMENT ON TABLE rides IS 'Table des courses avec points de départ/arrivée géospatiaux';
COMMENT ON TABLE stripe_transactions IS 'Table des transactions Stripe pour le suivi des paiements';

