#!/bin/bash

# Script pour tester la connexion admin

echo "🔐 Test de connexion admin..."
echo ""

# Test de connexion
RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000","password":""}')

TOKEN=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "❌ Erreur de connexion"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Connexion réussie!"
echo "   Token: ${TOKEN:0:50}..."
echo ""

# Test de l'API admin
echo "📊 Test de l'API admin..."
STATS=$(curl -s http://localhost:3000/api/admin/stats \
  -H "Authorization: Bearer $TOKEN")

if echo "$STATS" | grep -q "users"; then
  echo "✅ API admin fonctionne!"
  echo "$STATS" | python3 -m json.tool 2>/dev/null | head -10
else
  echo "⚠️  Réponse API: $STATS"
fi

echo ""
echo "🎯 Dashboard disponible sur: http://localhost:3001"
echo "   Identifiants: +243900000000 / (vide)"

