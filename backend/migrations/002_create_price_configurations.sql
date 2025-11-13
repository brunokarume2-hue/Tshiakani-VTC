-- Migration pour créer la table price_configurations
-- Permet de stocker les configurations de tarifs ajustables depuis le dashboard

CREATE TABLE IF NOT EXISTS price_configurations (
    id SERIAL PRIMARY KEY,
    
    -- Tarifs de base
    base_price DECIMAL(10, 2) DEFAULT 500.0 NOT NULL,
    price_per_km DECIMAL(10, 2) DEFAULT 200.0 NOT NULL,
    
    -- Multiplicateurs temporels
    rush_hour_multiplier DECIMAL(5, 2) DEFAULT 1.5 NOT NULL,
    night_multiplier DECIMAL(5, 2) DEFAULT 1.3 NOT NULL,
    weekend_multiplier DECIMAL(5, 2) DEFAULT 1.2 NOT NULL,
    
    -- Surge pricing
    surge_low_demand_multiplier DECIMAL(5, 2) DEFAULT 0.9 NOT NULL,
    surge_normal_multiplier DECIMAL(5, 2) DEFAULT 1.0 NOT NULL,
    surge_high_multiplier DECIMAL(5, 2) DEFAULT 1.2 NOT NULL,
    surge_very_high_multiplier DECIMAL(5, 2) DEFAULT 1.4 NOT NULL,
    surge_extreme_multiplier DECIMAL(5, 2) DEFAULT 1.6 NOT NULL,
    
    -- Métadonnées
    is_active BOOLEAN DEFAULT true NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Index pour la recherche rapide de la configuration active
CREATE INDEX IF NOT EXISTS idx_price_config_active ON price_configurations(is_active);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_price_configurations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_price_configurations_updated_at
    BEFORE UPDATE ON price_configurations
    FOR EACH ROW
    EXECUTE FUNCTION update_price_configurations_updated_at();

-- Insérer une configuration par défaut pour Kinshasa
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
    500.0,  -- Prix de base
    200.0,  -- Prix par km
    1.5,    -- Heures de pointe
    1.3,    -- Nuit
    1.2,    -- Week-end
    0.9,    -- Demande faible
    1.0,    -- Demande normale
    1.2,    -- Demande élevée
    1.4,    -- Demande très élevée
    1.6,    -- Demande extrême
    'Configuration par défaut - Kinshasa',
    true
) ON CONFLICT DO NOTHING;

COMMENT ON TABLE price_configurations IS 'Configuration des tarifs ajustables depuis le dashboard admin';
COMMENT ON COLUMN price_configurations.base_price IS 'Prix de base en CDF';
COMMENT ON COLUMN price_configurations.price_per_km IS 'Prix par kilomètre en CDF';
COMMENT ON COLUMN price_configurations.rush_hour_multiplier IS 'Multiplicateur heures de pointe (7h-9h, 17h-19h)';
COMMENT ON COLUMN price_configurations.night_multiplier IS 'Multiplicateur nuit (22h-6h)';
COMMENT ON COLUMN price_configurations.weekend_multiplier IS 'Multiplicateur week-end';
COMMENT ON COLUMN price_configurations.surge_low_demand_multiplier IS 'Multiplicateur demande faible (ratio < 0.5)';
COMMENT ON COLUMN price_configurations.surge_normal_multiplier IS 'Multiplicateur demande normale (ratio 0.5-1.0)';
COMMENT ON COLUMN price_configurations.surge_high_multiplier IS 'Multiplicateur demande élevée (ratio 1.0-1.5)';
COMMENT ON COLUMN price_configurations.surge_very_high_multiplier IS 'Multiplicateur demande très élevée (ratio 1.5-2.0)';
COMMENT ON COLUMN price_configurations.surge_extreme_multiplier IS 'Multiplicateur demande extrême (ratio > 2.0)';

