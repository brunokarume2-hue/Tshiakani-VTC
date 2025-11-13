#!/bin/bash

# Script pour configurer automatiquement tout (iOS, Dashboard, CORS)
# Usage: ./scripts/configurer-tout.sh

set -e

echo "🚀 Configuration Complète - Tshiakani VTC"
echo "=========================================="
echo ""

# Trouver l'adresse IP locale
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

if [ -z "$IP" ]; then
    echo "❌ Impossible de trouver l'adresse IP locale"
    exit 1
fi

echo "✅ Adresse IP trouvée: $IP"
echo ""

# 1. Configuration CORS dans le backend
echo "1️⃣ Configuration CORS..."
cd backend

if [ -f .env ]; then
    # Vérifier si CORS_ORIGIN existe
    if grep -q "CORS_ORIGIN=" .env; then
        # Vérifier si l'IP est déjà présente
        if grep -q "CORS_ORIGIN.*$IP" .env; then
            echo "✅ CORS_ORIGIN contient déjà l'IP $IP"
        else
            # Ajouter l'IP à CORS_ORIGIN
            echo "📝 Ajout de l'IP $IP à CORS_ORIGIN..."
            # Lire la ligne actuelle
            CURRENT_CORS=$(grep "CORS_ORIGIN=" .env | head -1)
            # Ajouter les nouveaux origines si nécessaire
            NEW_CORS="${CURRENT_CORS},capacitor://localhost,ionic://localhost,http://$IP:3000"
            # Remplacer dans le fichier
            sed -i.bak "s|^CORS_ORIGIN=.*|CORS_ORIGIN=${NEW_CORS#CORS_ORIGIN=}|" .env
            echo "✅ CORS_ORIGIN mis à jour"
        fi
    else
        # Ajouter CORS_ORIGIN
        echo "📝 Ajout de CORS_ORIGIN..."
        echo "CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://$IP:3000" >> .env
        echo "✅ CORS_ORIGIN ajouté"
    fi
else
    echo "⚠️  Fichier .env non trouvé. Créez-le d'abord avec: npm run setup"
fi

echo ""

# 2. Configuration Dashboard
echo "2️⃣ Configuration Dashboard..."
cd ../admin-dashboard

if [ ! -f .env.local ]; then
    echo "📝 Création de .env.local..."
    cat > .env.local << EOF
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
EOF
    echo "✅ Fichier .env.local créé"
else
    echo "✅ Fichier .env.local existe déjà"
fi

echo ""

# 3. Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé de la Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ CORS configuré avec l'IP: $IP"
echo "✅ Dashboard configuré"
echo ""
echo "📱 Configuration iOS:"
echo "   API Base URL: http://$IP:3000/api"
echo "   Socket Base URL: http://$IP:3000"
echo ""
echo "🎨 Configuration Dashboard:"
echo "   API URL: http://localhost:3000/api"
echo "   Socket URL: http://localhost:3000"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Redémarrer le serveur backend (npm run dev)"
echo "   2. Configurer l'app iOS avec les URLs ci-dessus"
echo "   3. Démarrer le dashboard (cd admin-dashboard && npm run dev)"
echo "   4. Tester les connexions"
echo ""

