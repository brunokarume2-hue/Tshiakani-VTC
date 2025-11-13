-- Migration pour ajouter les champs nécessaires à l'authentification Google
-- Ajoute les colonnes email et profile_image_url à la table users

-- Ajouter la colonne email si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email'
    ) THEN
        ALTER TABLE users ADD COLUMN email VARCHAR(255) UNIQUE;
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        RAISE NOTICE 'Colonne email ajoutée';
    ELSE
        RAISE NOTICE 'Colonne email existe déjà';
    END IF;
END $$;

-- Ajouter la colonne profile_image_url si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'profile_image_url'
    ) THEN
        ALTER TABLE users ADD COLUMN profile_image_url VARCHAR(500);
        RAISE NOTICE 'Colonne profile_image_url ajoutée';
    ELSE
        RAISE NOTICE 'Colonne profile_image_url existe déjà';
    END IF;
END $$;

-- Rendre phone_number nullable (pour permettre les comptes Google sans téléphone)
DO $$ 
BEGIN
    ALTER TABLE users ALTER COLUMN phone_number DROP NOT NULL;
    RAISE NOTICE 'Colonne phone_number rendue nullable';
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'phone_number est déjà nullable ou erreur: %', SQLERRM;
END $$;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Migration Google Auth terminée avec succès';
    RAISE NOTICE '📧 Colonne email: ajoutée';
    RAISE NOTICE '🖼️ Colonne profile_image_url: ajoutée';
    RAISE NOTICE '📱 Colonne phone_number: nullable';
END $$;

