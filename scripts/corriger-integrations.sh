#!/bin/bash

# Script de correction automatique des intégrations
# Corrige les URLs backend dans les apps iOS et configure le dashboard

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="https://tshiakani-vtc-backend-418102154417.us-central1.run.app"
API_URL="${BACKEND_URL}/api"
WS_URL="${BACKEND_URL}"
GCP_PROJECT_ID="tshiakani-vtc-477711"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"
ADMIN_API_KEY="aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8"

echo -e "${BLUE}🔧 Correction des Intégrations Backend${NC}"
echo ""

# 1. Mettre à jour Info.plist
echo -e "${BLUE}📱 1. Mise à jour Info.plist...${NC}"
INFO_PLIST="Tshiakani VTC/Info.plist"
INFO_PLIST_TEMPLATE="Tshiakani VTC/Info.plist.template"

if [ -f "$INFO_PLIST" ]; then
    # Sauvegarder l'original
    cp "$INFO_PLIST" "${INFO_PLIST}.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Mettre à jour les URLs
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - utiliser sed
        sed -i '' "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$INFO_PLIST"
    else
        # Linux
        sed -i "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$INFO_PLIST"
    fi
    echo -e "${GREEN}✅ Info.plist mis à jour${NC}"
else
    echo -e "${YELLOW}⚠️  Info.plist non trouvé, création depuis le template...${NC}"
    if [ -f "$INFO_PLIST_TEMPLATE" ]; then
        cp "$INFO_PLIST_TEMPLATE" "$INFO_PLIST"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$INFO_PLIST"
        else
            sed -i "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$INFO_PLIST"
        fi
        echo -e "${GREEN}✅ Info.plist créé depuis le template${NC}"
    else
        echo -e "${RED}❌ Template Info.plist non trouvé${NC}"
    fi
fi

# 2. Mettre à jour ConfigurationService.swift
echo -e "${BLUE}📱 2. Mise à jour ConfigurationService.swift...${NC}"
CONFIG_SERVICE="Tshiakani VTC/Services/ConfigurationService.swift"

if [ -f "$CONFIG_SERVICE" ]; then
    # Sauvegarder l'original
    cp "$CONFIG_SERVICE" "${CONFIG_SERVICE}.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Mettre à jour les URLs fallback
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$CONFIG_SERVICE"
    else
        sed -i "s|https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app|${BACKEND_URL}|g" "$CONFIG_SERVICE"
    fi
    echo -e "${GREEN}✅ ConfigurationService.swift mis à jour${NC}"
else
    echo -e "${RED}❌ ConfigurationService.swift non trouvé${NC}"
fi

# 3. Créer .env.production pour le dashboard
echo -e "${BLUE}📊 3. Configuration Dashboard Frontend...${NC}"
DASHBOARD_ENV="admin-dashboard/.env.production"

if [ ! -f "$DASHBOARD_ENV" ]; then
    cat > "$DASHBOARD_ENV" << EOF
# Configuration Production - Dashboard Admin
VITE_API_URL=${API_URL}
VITE_ADMIN_API_KEY=${ADMIN_API_KEY}
EOF
    echo -e "${GREEN}✅ Fichier .env.production créé${NC}"
else
    # Mettre à jour si existe déjà
    if grep -q "VITE_API_URL" "$DASHBOARD_ENV"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|VITE_API_URL=.*|VITE_API_URL=${API_URL}|g" "$DASHBOARD_ENV"
        else
            sed -i "s|VITE_API_URL=.*|VITE_API_URL=${API_URL}|g" "$DASHBOARD_ENV"
        fi
    else
        echo "VITE_API_URL=${API_URL}" >> "$DASHBOARD_ENV"
    fi
    
    if grep -q "VITE_ADMIN_API_KEY" "$DASHBOARD_ENV"; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|VITE_ADMIN_API_KEY=.*|VITE_ADMIN_API_KEY=${ADMIN_API_KEY}|g" "$DASHBOARD_ENV"
        else
            sed -i "s|VITE_ADMIN_API_KEY=.*|VITE_ADMIN_API_KEY=${ADMIN_API_KEY}|g" "$DASHBOARD_ENV"
        fi
    else
        echo "VITE_ADMIN_API_KEY=${ADMIN_API_KEY}" >> "$DASHBOARD_ENV"
    fi
    echo -e "${GREEN}✅ Fichier .env.production mis à jour${NC}"
fi

# 4. Configurer CORS dans Cloud Run
echo -e "${BLUE}🌐 4. Configuration CORS dans Cloud Run...${NC}"

if command -v gcloud &> /dev/null; then
    # URLs autorisées pour CORS (échappées correctement)
    CORS_ORIGINS="https://tshiakani-vtc.firebaseapp.com,https://tshiakani-vtc.web.app,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"
    
    echo -e "${YELLOW}⚠️  Configuration CORS...${NC}"
    
    # Utiliser --update-env-vars avec des guillemets simples pour éviter les problèmes d'échappement
    gcloud run services update ${SERVICE_NAME} \
        --update-env-vars="CORS_ORIGIN='${CORS_ORIGINS}'" \
        --region ${REGION} \
        --project ${GCP_PROJECT_ID} \
        --quiet 2>&1 | grep -v "Setting IAM Policy" || echo -e "${YELLOW}⚠️  Erreur lors de la configuration CORS, à faire manuellement${NC}"
    
    echo -e "${GREEN}✅ CORS configuré dans Cloud Run${NC}"
else
    echo -e "${YELLOW}⚠️  gcloud CLI non trouvé, CORS à configurer manuellement${NC}"
    echo "Commande à exécuter :"
    echo "gcloud run services update ${SERVICE_NAME} \\"
    echo "  --update-env-vars=\"CORS_ORIGIN=${CORS_ORIGINS}\" \\"
    echo "  --region ${REGION} \\"
    echo "  --project ${GCP_PROJECT_ID}"
fi

# 5. Résumé
echo ""
echo -e "${GREEN}✅ Corrections terminées !${NC}"
echo ""
echo -e "${BLUE}📋 Résumé des modifications :${NC}"
echo "  ✅ Info.plist : ${API_URL}"
echo "  ✅ ConfigurationService.swift : ${BACKEND_URL}"
echo "  ✅ Dashboard .env.production : ${API_URL}"
echo "  ✅ CORS Cloud Run : Configuré"
echo ""
echo -e "${YELLOW}⚠️  Actions suivantes :${NC}"
echo "  1. Rebuild l'app iOS dans Xcode"
echo "  2. Redémarrer le dashboard : cd admin-dashboard && npm run dev"
echo "  3. Tester les connexions"
echo ""

