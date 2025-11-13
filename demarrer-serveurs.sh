#!/bin/bash

# Script pour démarrer le backend et le dashboard
# Usage: ./demarrer-serveurs.sh

echo "🚀 Démarrage des serveurs Tshiakani VTC"
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que les fichiers .env existent
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠️  Fichier backend/.env non trouvé${NC}"
    echo "Exécutez d'abord : cd backend && ./configure-env.sh"
    exit 1
fi

if [ ! -f "admin-dashboard/.env" ]; then
    echo -e "${YELLOW}⚠️  Fichier admin-dashboard/.env non trouvé${NC}"
    echo "Exécutez d'abord : cd admin-dashboard && cp .env.example .env"
    exit 1
fi

echo -e "${GREEN}✅ Fichiers .env trouvés${NC}"
echo ""

# Fonction pour vérifier si un port est utilisé
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0  # Port utilisé
    else
        return 1  # Port libre
    fi
}

# Vérifier les ports
if check_port 3000; then
    echo -e "${YELLOW}⚠️  Le port 3000 est déjà utilisé${NC}"
    echo "Le backend pourrait ne pas démarrer correctement"
    echo ""
fi

if check_port 5173; then
    echo -e "${YELLOW}⚠️  Le port 5173 est déjà utilisé${NC}"
    echo "Le dashboard pourrait ne pas démarrer correctement"
    echo ""
fi

echo "📋 Démarrant les serveurs..."
echo ""
echo -e "${BLUE}Backend:${NC} http://localhost:3000"
echo -e "${BLUE}Dashboard:${NC} http://localhost:5173"
echo ""
echo "Pour arrêter les serveurs, appuyez sur Ctrl+C"
echo ""

# Démarrer le backend en arrière-plan
echo -e "${GREEN}🔄 Démarrage du backend...${NC}"
cd backend
npm run dev > ../backend.log 2>&1 &
BACKEND_PID=$!
cd ..

# Attendre un peu que le backend démarre
sleep 3

# Démarrer le dashboard en arrière-plan
echo -e "${GREEN}🔄 Démarrage du dashboard...${NC}"
cd admin-dashboard
npm run dev > ../dashboard.log 2>&1 &
DASHBOARD_PID=$!
cd ..

echo ""
echo -e "${GREEN}✅ Serveurs démarrés !${NC}"
echo ""
echo "PIDs:"
echo "  Backend: $BACKEND_PID"
echo "  Dashboard: $DASHBOARD_PID"
echo ""
echo "Logs:"
echo "  Backend: tail -f backend.log"
echo "  Dashboard: tail -f dashboard.log"
echo ""
echo "Pour arrêter: kill $BACKEND_PID $DASHBOARD_PID"
echo ""

# Attendre que l'utilisateur appuie sur Ctrl+C
trap "echo ''; echo 'Arrêt des serveurs...'; kill $BACKEND_PID $DASHBOARD_PID 2>/dev/null; exit" INT

# Garder le script actif
wait

