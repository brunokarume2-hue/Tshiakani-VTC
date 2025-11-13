-- Migration: Ajouter la colonne email à la table users
-- Date: 2025-01-15
-- Description: Ajoute la colonne email pour correspondre à l'entité User

-- Ajouter la colonne email (nullable, unique)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- Index unique pour email (seulement si email n'est pas NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users(email) WHERE email IS NOT NULL;

-- Commentaire pour documentation
COMMENT ON COLUMN users.email IS 'Adresse email de l''utilisateur (optionnelle)';

-- Log de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Migration 005: Colonne email ajoutée avec succès';
END $$;

