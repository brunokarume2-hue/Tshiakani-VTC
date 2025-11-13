#!/bin/bash

# Script final pour nettoyer et vérifier que tout est correct

echo "🧹 Nettoyage Final et Vérification"
echo "==================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Étape 1: Nettoyage complet${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData supprimé${NC}"

rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo -e "${GREEN}✅ Caches Xcode nettoyés${NC}"

echo ""
echo -e "${BLUE}Étape 2: Vérification de la configuration${NC}"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj/project.pbxproj"

if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$XCODEPROJ"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${YELLOW}⚠️  GENERATE_INFOPLIST_FILE incorrect${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$XCODEPROJ"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correct${NC}"
else
    echo -e "${YELLOW}⚠️  INFOPLIST_FILE incorrect${NC}"
fi

echo ""
echo "==================================="
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""
echo -e "${YELLOW}📋 Actions dans Xcode:${NC}"
echo ""
echo "1. Le script a tenté de retirer Info.plist automatiquement"
echo "2. Vérifiez dans Xcode que Info.plist n'est pas dans Copy Bundle Resources:"
echo "   → Target 'Tshiakani VTC' > Build Phases > Copy Bundle Resources"
echo ""
echo "3. Si Info.plist est encore présent, retirez-le manuellement"
echo ""
echo "4. Compilez:"
echo "   → Product > Clean Build Folder (⇧⌘K)"
echo "   → Product > Build (⌘B)"
echo ""
echo "==================================="

