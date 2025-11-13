#!/bin/bash

# Script pour tester l'authentification en local
# Usage: ./tester-auth-local.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Test de l'authentification admin en local...${NC}"
echo ""

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "backend/server.postgres.js" ]; then
    echo -e "${RED}❌ Erreur: backend/server.postgres.js non trouvé${NC}"
    exit 1
fi

# Étape 1: Vérifier PostgreSQL
echo -e "${BLUE}📋 Étape 1: Vérification de PostgreSQL...${NC}"
if command -v pg_isready &> /dev/null; then
    if pg_isready -h localhost -p 5432 &> /dev/null; then
        echo -e "${GREEN}✅ PostgreSQL est en cours d'exécution${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL n'est pas accessible sur localhost:5432${NC}"
        echo -e "${YELLOW}ℹ️  Démarrez PostgreSQL ou vérifiez la configuration${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  pg_isready non trouvé (PostgreSQL peut être installé différemment)${NC}"
fi

# Étape 2: Démarrer le backend
echo -e "${BLUE}📋 Étape 2: Démarrage du backend...${NC}"
cd backend

# Vérifier que les dépendances sont installées
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  Dépendances non installées. Installation...${NC}"
    npm install
fi

# Démarrer le backend en arrière-plan
echo -e "${BLUE}🚀 Démarrage du backend en arrière-plan...${NC}"
npm run dev > ../backend-test.log 2>&1 &
BACKEND_PID=$!

# Attendre que le backend démarre
echo -e "${BLUE}⏳ Attente du démarrage du backend (10 secondes)...${NC}"
sleep 10

# Étape 3: Tester le health check
echo -e "${BLUE}📋 Étape 3: Test du health check...${NC}"
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health || echo "ERROR")

if [[ "$HEALTH_RESPONSE" == *"status"* ]]; then
    echo -e "${GREEN}✅ Backend accessible${NC}"
else
    echo -e "${RED}❌ Backend non accessible${NC}"
    echo -e "${YELLOW}ℹ️  Vérifiez les logs: cat backend-test.log${NC}"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# Étape 4: Tester la route admin/login
echo -e "${BLUE}📋 Étape 4: Test de la route admin/login...${NC}"
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}' || echo "ERROR")

if [[ "$LOGIN_RESPONSE" == *"token"* ]]; then
    echo -e "${GREEN}✅ Route admin/login fonctionne${NC}"
    echo -e "${GREEN}📄 Réponse:${NC}"
    echo "$LOGIN_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$LOGIN_RESPONSE"
else
    echo -e "${RED}❌ Route admin/login ne fonctionne pas${NC}"
    echo -e "${YELLOW}📄 Réponse:${NC}"
    echo "$LOGIN_RESPONSE"
    kill $BACKEND_PID 2>/dev/null || true
    exit 1
fi

# Étape 5: Résumé
echo ""
echo -e "${GREEN}✅ Test réussi!${NC}"
echo ""
echo -e "${BLUE}📋 Résumé:${NC}"
echo "  - Backend accessible sur http://localhost:3000"
echo "  - Route admin/login fonctionnelle"
echo "  - Identifiants: +243900000000 / (vide)"
echo ""
echo -e "${YELLOW}ℹ️  Pour arrêter le backend, utilisez: kill $BACKEND_PID${NC}"
echo -e "${YELLOW}ℹ️  Pour voir les logs: tail -f backend-test.log${NC}"

