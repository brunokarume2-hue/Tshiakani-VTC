#!/bin/bash

# Script de configuration du fichier .env
# Usage: ./configure-env.sh

echo "🔧 Configuration du fichier .env pour le backend"
echo ""

# Vérifier si .env existe
if [ ! -f .env ]; then
    echo "❌ Fichier .env non trouvé. Création depuis .env.example..."
    cp .env.example .env
fi

# JWT_SECRET généré
JWT_SECRET="ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab"

# Mettre à jour JWT_SECRET dans .env
if grep -q "JWT_SECRET=" .env; then
    # Remplacer la ligne existante
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    else
        # Linux
        sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
    fi
    echo "✅ JWT_SECRET mis à jour dans .env"
else
    echo "JWT_SECRET=$JWT_SECRET" >> .env
    echo "✅ JWT_SECRET ajouté dans .env"
fi

echo ""
echo "📋 Variables à configurer manuellement dans .env :"
echo ""
echo "1. DATABASE_URL=postgresql://username:password@localhost:5432/tshiakani_vtc"
echo "2. DB_HOST=localhost"
echo "3. DB_PORT=5432"
echo "4. DB_USER=postgres"
echo "5. DB_PASSWORD=votre_mot_de_passe_postgres"
echo "6. DB_NAME=tshiakani_vtc"
echo ""
echo "✅ JWT_SECRET a été configuré automatiquement"
echo ""
echo "💡 Pour éditer le fichier .env :"
echo "   nano .env"
echo "   # ou"
echo "   code .env"
echo ""

