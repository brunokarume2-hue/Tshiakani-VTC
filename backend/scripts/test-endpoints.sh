#!/bin/bash

# Script de test pour les endpoints API
# Usage: ./scripts/test-endpoints.sh [TOKEN]

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${API_BASE_URL:-http://localhost:3000}"
TOKEN="${1:-}"

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Fonction pour tester un endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    if [ -z "$TOKEN" ]; then
        echo -e "${YELLOW}⚠${NC} Token manquant pour $description"
        return 1
    fi
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL$endpoint" \
            -H "Authorization: Bearer $TOKEN")
    elif [ "$method" = "POST" ]; then
        response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$data")
    elif [ "$method" = "PUT" ]; then
        response=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$data")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL$endpoint" \
            -H "Authorization: Bearer $TOKEN")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        print_result 0 "$description (HTTP $http_code)"
        return 0
    else
        print_result 1 "$description (HTTP $http_code)"
        echo "Réponse: $body"
        return 1
    fi
}

# Test de connexion
echo "🔐 Test de connexion..."
login_response=$(curl -s -X POST "$BASE_URL/api/auth/signin" \
    -H "Content-Type: application/json" \
    -d '{
        "phoneNumber": "+243900000001",
        "password": "password123"
    }')

token=$(echo "$login_response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$token" ]; then
    echo -e "${RED}✗${NC} Échec de la connexion"
    echo "Réponse: $login_response"
    exit 1
else
    echo -e "${GREEN}✓${NC} Connexion réussie"
    TOKEN="$token"
fi

echo ""
echo "🧪 Tests des endpoints..."
echo ""

# Tests Support
echo "📞 Tests Support"
test_endpoint "POST" "/api/support/message" '{"message":"Test message"}' "Envoyer un message de support"
test_endpoint "GET" "/api/support/messages" "" "Récupérer les messages de support"
test_endpoint "POST" "/api/support/ticket" '{"subject":"Test","message":"Test message","category":"general"}' "Créer un ticket de support"
test_endpoint "GET" "/api/support/tickets" "" "Récupérer les tickets de support"
test_endpoint "GET" "/api/support/faq" "" "Récupérer la FAQ"
echo ""

# Tests Favorites
echo "⭐ Tests Favorites"
test_endpoint "GET" "/api/favorites" "" "Récupérer les favoris"
test_endpoint "POST" "/api/favorites" '{"name":"Maison","address":"123 Rue Example","location":{"latitude":-4.3276,"longitude":15.3136},"icon":"home"}' "Ajouter un favori"
# Note: ID du favori à adapter selon les données
test_endpoint "DELETE" "/api/favorites/1" "" "Supprimer un favori"
echo ""

# Tests Chat
echo "💬 Tests Chat"
# Note: ID de course à adapter selon les données
test_endpoint "GET" "/api/chat/1/messages" "" "Récupérer les messages d'une course"
test_endpoint "POST" "/api/chat/1/messages" '{"message":"Bonjour"}' "Envoyer un message"
test_endpoint "PUT" "/api/chat/messages/1/read" "" "Marquer un message comme lu"
echo ""

# Tests Scheduled Rides
echo "📅 Tests Scheduled Rides"
test_endpoint "GET" "/api/scheduled-rides" "" "Récupérer les courses programmées"
test_endpoint "POST" "/api/scheduled-rides" '{"pickupLocation":{"latitude":-4.3276,"longitude":15.3136,"address":"123 Rue Example"},"dropoffLocation":{"latitude":-4.3376,"longitude":15.3236,"address":"456 Avenue Example"},"scheduledDate":"2024-01-15T10:00:00.000Z","vehicleType":"economy","paymentMethod":"cash"}' "Créer une course programmée"
# Note: ID de course programmée à adapter selon les données
test_endpoint "PUT" "/api/scheduled-rides/1" '{"scheduledDate":"2024-01-15T11:00:00.000Z"}' "Mettre à jour une course programmée"
test_endpoint "DELETE" "/api/scheduled-rides/1" "" "Annuler une course programmée"
echo ""

# Tests Share
echo "🔗 Tests Share"
# Note: ID de course à adapter selon les données
test_endpoint "GET" "/api/rides/1/share" "" "Générer un lien de partage"
test_endpoint "POST" "/api/share/ride" '{"rideId":"1","contacts":["+243900000002"],"link":"https://tshiakanivtc.com/share/test"}' "Partager une course"
test_endpoint "POST" "/api/share/location" '{"rideId":"1","location":{"latitude":-4.3276,"longitude":15.3136}}' "Partager une position"
test_endpoint "GET" "/api/share/rides" "" "Récupérer les courses partagées"
echo ""

# Tests SOS
echo "🚨 Tests SOS"
test_endpoint "POST" "/api/sos/alert" '{"latitude":-4.3276,"longitude":15.3136,"message":"Test SOS"}' "Activer une alerte SOS"
test_endpoint "POST" "/api/sos/deactivate" "" "Désactiver une alerte SOS"
echo ""

echo "✅ Tests terminés"

