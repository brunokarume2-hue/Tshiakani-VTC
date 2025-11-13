#!/bin/bash

# Script pour démarrer le dashboard admin
# Usage: ./DEMARRER_DASHBOARD.sh

set -e

echo "🎨 Démarrage du Dashboard Admin - Tshiakani VTC"
echo "================================================"
echo ""

# Vérifier que le backend est démarré
echo "🔍 Vérification du backend..."
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend opérationnel"
else
    echo "⚠️  Backend pas encore démarré"
    echo "   Démarrez le backend avec: cd backend && npm run dev"
    echo ""
    read -p "Voulez-vous continuer quand même ? (o/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        exit 1
    fi
fi
echo ""

# Aller dans le dossier admin-dashboard
cd admin-dashboard

# Vérifier que .env.local existe
if [ ! -f .env.local ]; then
    echo "📝 Création de .env.local..."
    cat > .env.local << EOF
VITE_API_URL=http://localhost:3000/api
VITE_SOCKET_URL=http://localhost:3000
EOF
    echo "✅ .env.local créé"
else
    echo "✅ .env.local existe déjà"
fi
echo ""

# Vérifier que node_modules existe
if [ ! -d node_modules ]; then
    echo "📦 Installation des dépendances..."
    npm install
    echo "✅ Dépendances installées"
else
    echo "✅ Dépendances déjà installées"
fi
echo ""

# Démarrer le dashboard
echo "🚀 Démarrage du dashboard..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Dashboard Admin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Dashboard accessible sur: http://localhost:5173"
echo "✅ API Backend: http://localhost:3000/api"
echo "✅ WebSocket: http://localhost:3000"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter le dashboard"
echo ""

npm run dev
