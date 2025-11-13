-- Migration 003: Optimisation des index pour améliorer les performances
-- Cette migration ajoute les index manquants et optimise les requêtes fréquentes

-- ============================================================================
-- 1. INDEX COMPOSITES POUR LES REQUÊTES FRÉQUENTES
-- ============================================================================

-- Index composite pour les chauffeurs disponibles avec localisation
-- Optimise: SELECT * FROM users WHERE role='driver' AND driver_info->>'isOnline'='true' AND location IS NOT NULL
CREATE INDEX IF NOT EXISTS idx_users_driver_online_location 
ON users (role, location) 
USING GIST (location)
WHERE role = 'driver' 
  AND driver_info->>'isOnline' = 'true'
  AND location IS NOT NULL;

-- Index composite pour les rides d'un client avec statut et date
-- Optimise: SELECT * FROM rides WHERE client_id=X AND status=Y ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_rides_client_status_created 
ON rides (client_id, status, created_at DESC);

-- Index composite pour les rides d'un chauffeur avec statut et date
-- Optimise: SELECT * FROM rides WHERE driver_id=X AND status=Y ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_rides_driver_status_created 
ON rides (driver_id, status, created_at DESC) 
WHERE driver_id IS NOT NULL;

-- Index composite pour les rides en attente ou acceptées (pour matching)
-- Optimise: SELECT * FROM rides WHERE status IN ('pending', 'accepted') ORDER BY created_at
CREATE INDEX IF NOT EXISTS idx_rides_pending_accepted 
ON rides (status, created_at) 
WHERE status IN ('pending', 'accepted');

-- ============================================================================
-- 2. INDEX SUR LES COLONNES DE DATE
-- ============================================================================

-- Index sur completed_at pour les statistiques et rapports
CREATE INDEX IF NOT EXISTS idx_rides_completed_at 
ON rides (completed_at DESC) 
WHERE completed_at IS NOT NULL;

-- Index sur started_at pour les analyses de durée
CREATE INDEX IF NOT EXISTS idx_rides_started_at 
ON rides (started_at DESC) 
WHERE started_at IS NOT NULL;

-- Index sur cancelled_at pour les analyses d'annulation
CREATE INDEX IF NOT EXISTS idx_rides_cancelled_at 
ON rides (cancelled_at DESC) 
WHERE cancelled_at IS NOT NULL;

-- ============================================================================
-- 3. INDEX POUR LES NOTIFICATIONS
-- ============================================================================

-- Index composite pour les notifications non lues d'un utilisateur
-- Optimise: SELECT * FROM notifications WHERE user_id=X AND is_read=false ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread 
ON notifications (user_id, is_read, created_at DESC) 
WHERE is_read = false;

-- Index pour les notifications par type et date
CREATE INDEX IF NOT EXISTS idx_notifications_type_created 
ON notifications (type, created_at DESC);

-- ============================================================================
-- 4. INDEX POUR LES SOS REPORTS
-- ============================================================================

-- Index composite pour les SOS actifs avec localisation
-- Optimise: SELECT * FROM sos_reports WHERE status='active' ORDER BY created_at DESC
CREATE INDEX IF NOT EXISTS idx_sos_active_created 
ON sos_reports (status, created_at DESC) 
WHERE status = 'active';

-- Index composite pour les SOS d'un utilisateur
CREATE INDEX IF NOT EXISTS idx_sos_user_created 
ON sos_reports (user_id, created_at DESC);

-- ============================================================================
-- 5. INDEX POUR LES PRICE CONFIGURATIONS
-- ============================================================================

-- Index composite pour la configuration active (déjà présent mais vérifions)
-- L'index existe déjà mais on peut l'améliorer
DROP INDEX IF EXISTS idx_price_config_active;
CREATE INDEX IF NOT EXISTS idx_price_config_active_updated 
ON price_configurations (is_active, updated_at DESC) 
WHERE is_active = true;

-- ============================================================================
-- 6. STATISTIQUES DES INDEX
-- ============================================================================

-- Mettre à jour les statistiques pour que le planificateur utilise les nouveaux index
ANALYZE users;
ANALYZE rides;
ANALYZE notifications;
ANALYZE sos_reports;
ANALYZE price_configurations;

-- ============================================================================
-- 7. COMMENTAIRES POUR DOCUMENTATION
-- ============================================================================

COMMENT ON INDEX idx_users_driver_online_location IS 
'Index composite GIST pour optimiser la recherche de chauffeurs disponibles avec localisation';

COMMENT ON INDEX idx_rides_client_status_created IS 
'Index composite pour optimiser la récupération des rides d''un client par statut et date';

COMMENT ON INDEX idx_rides_driver_status_created IS 
'Index composite pour optimiser la récupération des rides d''un chauffeur par statut et date';

COMMENT ON INDEX idx_rides_pending_accepted IS 
'Index partiel pour optimiser la recherche de rides en attente ou acceptées';

COMMENT ON INDEX idx_notifications_user_unread IS 
'Index composite partiel pour optimiser la récupération des notifications non lues';

COMMENT ON INDEX idx_sos_active_created IS 
'Index composite partiel pour optimiser la récupération des SOS actifs';

-- ============================================================================
-- 8. VÉRIFICATION DES INDEX EXISTANTS
-- ============================================================================

-- Vérifier que les index spatiaux existent
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_users_location' 
        AND tablename = 'users'
    ) THEN
        CREATE INDEX idx_users_location ON users USING GIST (location);
        RAISE NOTICE 'Index idx_users_location créé';
    ELSE
        RAISE NOTICE 'Index idx_users_location existe déjà';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_rides_pickup' 
        AND tablename = 'rides'
    ) THEN
        CREATE INDEX idx_rides_pickup ON rides USING GIST (pickup_location);
        RAISE NOTICE 'Index idx_rides_pickup créé';
    ELSE
        RAISE NOTICE 'Index idx_rides_pickup existe déjà';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_rides_dropoff' 
        AND tablename = 'rides'
    ) THEN
        CREATE INDEX idx_rides_dropoff ON rides USING GIST (dropoff_location);
        RAISE NOTICE 'Index idx_rides_dropoff créé';
    ELSE
        RAISE NOTICE 'Index idx_rides_dropoff existe déjà';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_sos_location' 
        AND tablename = 'sos_reports'
    ) THEN
        CREATE INDEX idx_sos_location ON sos_reports USING GIST (location);
        RAISE NOTICE 'Index idx_sos_location créé';
    ELSE
        RAISE NOTICE 'Index idx_sos_location existe déjà';
    END IF;
END $$;

-- ============================================================================
-- 9. OPTIMISATION DE LA FONCTION find_nearby_drivers
-- ============================================================================

-- Améliorer la fonction pour utiliser les nouveaux index
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

COMMENT ON FUNCTION find_nearby_drivers IS 
'Fonction optimisée pour trouver les chauffeurs proches d''un point géographique. Utilise les index GIST pour de meilleures performances.';

