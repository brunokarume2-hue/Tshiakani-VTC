-- Migration pour supprimer les références driver_info de l'app client
-- Note: La colonne driver_info est conservée pour l'app driver séparée

-- Supprimer l'index sur driver_info (utilisé uniquement par l'app client)
DROP INDEX IF EXISTS idx_users_driver_online;

-- Supprimer la fonction find_nearby_drivers qui utilise driver_info
-- (Cette fonction était utilisée par l'app client pour trouver les drivers)
DROP FUNCTION IF EXISTS find_nearby_drivers(DECIMAL, DECIMAL, DECIMAL);

-- Note: La colonne driver_info dans la table users est conservée
-- pour que l'app driver séparée puisse continuer à l'utiliser

