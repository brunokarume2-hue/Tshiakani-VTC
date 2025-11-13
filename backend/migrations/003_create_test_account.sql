-- Migration pour créer un compte de test
-- Ce compte permet de se connecter rapidement à l'application sans OTP

-- Supprimer le compte de test s'il existe déjà
DELETE FROM users WHERE phone_number = '900000000';

-- Créer le compte de test
INSERT INTO users (
    name,
    phone_number,
    role,
    is_verified,
    created_at,
    updated_at
) VALUES (
    'Compte Test',
    '900000000',
    'client',
    true,
    NOW(),
    NOW()
);

-- Afficher les informations du compte créé
SELECT 
    id,
    name,
    phone_number,
    role,
    is_verified,
    created_at
FROM users 
WHERE phone_number = '900000000';

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Compte de test créé avec succès';
    RAISE NOTICE '📱 Numéro: +243900000000';
    RAISE NOTICE '👤 Nom: Compte Test';
    RAISE NOTICE '🎭 Rôle: client';
END $$;

