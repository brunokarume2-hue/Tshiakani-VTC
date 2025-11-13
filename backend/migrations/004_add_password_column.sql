-- Migration: Ajouter la colonne password à la table users
-- Date: 2025-01-15
-- Description: Ajoute le support des mots de passe pour l'authentification admin

-- Ajouter la colonne password
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Index pour améliorer les performances (optionnel, seulement pour les admins avec mot de passe)
CREATE INDEX IF NOT EXISTS idx_users_password ON users(password) WHERE password IS NOT NULL;

-- Commentaire pour documentation
COMMENT ON COLUMN users.password IS 'Mot de passe hashé (bcrypt) pour les admins et autres utilisateurs nécessitant une authentification par mot de passe';

-- Log de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Migration 004: Colonne password ajoutée avec succès';
END $$;

