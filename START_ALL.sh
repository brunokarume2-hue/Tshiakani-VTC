#!/bin/bash
# Script pour démarrer tous les services

echo "🚀 Démarrage des services Tshiakani VTC..."
echo ""

# Démarrer le backend
echo "📡 Démarrage du backend..."
cd backend
npm run dev &
BACKEND_PID=$!
echo "✅ Backend démarré (PID: $BACKEND_PID)"
echo ""

# Attendre que le backend soit prêt
echo "⏳ Attente du démarrage du backend..."
sleep 5

# Tester le health check
echo "🧪 Test du health check..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Backend opérationnel"
else
    echo "⚠️  Backend pas encore prêt, attendez quelques secondes"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Services démarrés"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Backend: http://localhost:3000"
echo "✅ API: http://localhost:3000/api"
echo "✅ Health: http://localhost:3000/health"
echo ""
echo "Pour arrêter: pkill -f 'node server.postgres'"
echo ""

