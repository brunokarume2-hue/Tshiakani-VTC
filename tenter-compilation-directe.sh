#!/bin/bash

# Script pour tenter une compilation directe et voir les erreurs restantes

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
SCHEME="Tshiakani VTC"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔨 TENTATIVE DE COMPILATION DIRECTE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier si xcodebuild est disponible
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${YELLOW}⚠️  xcodebuild non disponible via ligne de commande${NC}"
    echo -e "${YELLOW}   Utilisez Xcode directement${NC}"
    echo ""
    echo -e "${BLUE}Instructions:${NC}"
    echo "1. Ouvrez Xcode"
    echo "2. Ouvrez: $XCODEPROJ"
    echo "3. Product > Clean Build Folder (⇧⌘K)"
    echo "4. Product > Build (⌘B)"
    echo ""
    exit 0
fi

# Tenter la compilation
echo -e "${BLUE}Tentative de compilation...${NC}"
echo ""

cd "$PROJECT_DIR"

# Essayer de compiler
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration Debug \
    clean build \
    2>&1 | tee build-output.log

BUILD_STATUS=$?

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ COMPILATION RÉUSSIE !${NC}"
else
    echo -e "${RED}❌ COMPILATION ÉCHOUÉE${NC}"
    echo ""
    echo -e "${YELLOW}📋 Erreurs détectées:${NC}"
    grep -i "error:" build-output.log | head -20 || echo "Aucune erreur détectée dans le format standard"
    echo ""
    echo -e "${BLUE}Consultez build-output.log pour plus de détails${NC}"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

