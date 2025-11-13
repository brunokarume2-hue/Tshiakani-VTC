-- Migration pour ajouter la colonne 'name' à la table 'users'
-- Date: 2025-11-10
-- Description: Ajoute la colonne name qui manque dans la table users

-- Vérifier si la colonne existe déjà avant de l'ajouter
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'name'
    ) THEN
        ALTER TABLE users ADD COLUMN name VARCHAR(255);
        RAISE NOTICE 'Colonne name ajoutée à la table users';
    ELSE
        RAISE NOTICE 'Colonne name existe déjà dans la table users';
    END IF;
END $$;

