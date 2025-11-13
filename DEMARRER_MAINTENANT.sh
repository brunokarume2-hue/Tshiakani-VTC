#!/bin/bash
# Script pour démarrer tout et tester

echo "🚀 Démarrage Tshiakani VTC"
echo "=========================="
echo ""

# Démarrer le backend
echo "📡 Démarrage du backend..."
cd backend
npm run dev &
BACKEND_PID=$!
echo "✅ Backend démarré (PID: $BACKEND_PID)"
echo ""

# Attendre que le backend soit prêt
echo "⏳ Attente du démarrage (10 secondes)..."
sleep 10

# Tester le health check
echo "🧪 Test du health check..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Backend opérationnel"
    curl -s http://localhost:3000/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost:3000/health
else
    echo "⚠️  Backend pas encore prêt"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Services Disponibles"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ Backend: http://localhost:3000"
echo "✅ API: http://localhost:3000/api"
echo "✅ Health: http://localhost:3000/health"
echo "✅ WebSocket Driver: http://localhost:3000/ws/driver"
echo "✅ WebSocket Client: http://localhost:3000/ws/client"
echo ""
echo "📱 iOS: http://192.168.1.79:3000/api"
echo "🎨 Dashboard: http://localhost:5173 (démarrer avec: cd admin-dashboard && npm run dev)"
echo ""
echo "Pour arrêter: pkill -f 'node server.postgres'"
echo ""

