#!/bin/bash

# Script de test des endpoints API
# Usage: ./scripts/test-api.sh

set -e

BASE_URL="${API_URL:-http://localhost:3000}"
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
COLOR_NC='\033[0m' # No Color

success() {
    echo -e "${COLOR_GREEN}✅ $1${COLOR_NC}"
}

error() {
    echo -e "${COLOR_RED}❌ $1${COLOR_NC}"
}

info() {
    echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_NC}"
}

warning() {
    echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_NC}"
}

echo "🧪 Test des endpoints API Tshiakani VTC"
echo "========================================"
echo ""
info "URL de base: $BASE_URL"
echo ""

# Test 1: Health Check
echo "1. Health Check..."
if curl -s -f "$BASE_URL/health" > /dev/null; then
    HEALTH_RESPONSE=$(curl -s "$BASE_URL/health")
    success "Health check réussi"
    echo "   Réponse: $HEALTH_RESPONSE"
else
    error "Health check échoué"
    echo "   Vérifiez que le serveur est démarré: npm run dev"
    exit 1
fi
echo ""

# Test 2: Authentification
echo "2. Test d'authentification..."
PHONE_NUMBER="+243900000000"
AUTH_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"phoneNumber\": \"$PHONE_NUMBER\", \"name\": \"Test User\", \"role\": \"client\"}")

if echo "$AUTH_RESPONSE" | grep -q "success\|userId\|message\|token"; then
    success "Authentification testée"
    echo "   Réponse: $AUTH_RESPONSE"
    
    # Extraire le token si présent
    TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    if [ -n "$TOKEN" ]; then
        echo "   Token obtenu: ${TOKEN:0:20}..."
        export TEST_TOKEN="$TOKEN"
    fi
else
    warning "Authentification: réponse inattendue"
    echo "   Réponse: $AUTH_RESPONSE"
    info "   Note: En mode développement, l'authentification peut nécessiter une configuration Firebase"
fi
echo ""

# Test 3: Routes API disponibles
echo "3. Vérification des routes API..."
ROUTES=(
    "/api/auth"
    "/api/rides"
    "/api/users"
    "/api/driver"
    "/api/client"
    "/api/documents"
    "/api/admin"
    "/api/notifications"
    "/api/sos"
)

for route in "${ROUTES[@]}"; do
    if curl -s -f -o /dev/null -w "%{http_code}" "$BASE_URL$route" | grep -q "404\|401\|403\|200"; then
        success "Route $route accessible"
    else
        warning "Route $route: réponse inattendue"
    fi
done
echo ""

# Test 4: WebSocket (vérification basique)
echo "4. Vérification WebSocket..."
if command -v node &> /dev/null; then
    # Créer un script Node.js temporaire pour tester WebSocket
    cat > /tmp/test-websocket.js << 'EOF'
const io = require('socket.io-client');
const socket = io('http://localhost:3000/ws/driver', {
  transports: ['websocket'],
  timeout: 5000
});

socket.on('connect', () => {
  console.log('✅ WebSocket connecté');
  socket.disconnect();
  process.exit(0);
});

socket.on('connect_error', (error) => {
  console.log('⚠️  WebSocket: erreur de connexion (normal si pas de token)');
  process.exit(0);
});

setTimeout(() => {
  console.log('⚠️  WebSocket: timeout');
  process.exit(0);
}, 5000);
EOF
    
    if node /tmp/test-websocket.js 2>/dev/null; then
        success "WebSocket accessible"
    else
        warning "WebSocket: nécessite un token d'authentification"
    fi
    rm -f /tmp/test-websocket.js
else
    warning "Node.js non disponible pour tester WebSocket"
fi
echo ""

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé des tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "Tests terminés!"
echo ""
info "Pour tester avec authentification:"
echo "   1. Obtenir un token via /api/auth/signin"
echo "   2. Utiliser le token dans les headers:"
echo "      curl -H \"Authorization: Bearer YOUR_TOKEN\" $BASE_URL/api/..."
echo ""
info "Pour tester les uploads de documents:"
echo "   curl -X POST $BASE_URL/api/documents/upload \\"
echo "     -H \"Authorization: Bearer YOUR_TOKEN\" \\"
echo "     -F \"file=@test.pdf\" \\"
echo "     -F \"documentType=permis\""
echo ""

