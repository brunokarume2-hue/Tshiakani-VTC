#!/bin/bash

# Script final pour corriger définitivement l'erreur de duplication Info.plist

echo "🔧 Correction Finale: Duplication Info.plist"
echo "==========================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Étape 1: Nettoyage complet${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData supprimé${NC}"

rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo -e "${GREEN}✅ Caches nettoyés${NC}"

echo ""
echo -e "${BLUE}Étape 2: Vérification de la configuration${NC}"

# Vérifier GENERATE_INFOPLIST_FILE
GENERATE_COUNT=$(grep -c "GENERATE_INFOPLIST_FILE = NO" "$PROJECT_FILE" || echo "0")
if [ "$GENERATE_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO (pour le target principal)${NC}"
else
    echo -e "${YELLOW}⚠️  Vérification de GENERATE_INFOPLIST_FILE${NC}"
fi

# Vérifier INFOPLIST_FILE
if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${RED}❌ INFOPLIST_FILE incorrect${NC}"
fi

echo ""
echo -e "${BLUE}Étape 3: Vérification des ressources${NC}"

# La section Resources devrait être vide
RESOURCES_SECTION=$(grep -A 5 '849318F02EBEE1F000D186E8 /\* Resources \*/' "$PROJECT_FILE" | grep -A 3 'files = (')

if echo "$RESOURCES_SECTION" | grep -q "Info.plist"; then
    echo -e "${RED}❌ Info.plist trouvé dans les ressources${NC}"
    echo -e "${YELLOW}   → Modification nécessaire${NC}"
else
    echo -e "${GREEN}✅ Section Resources vide (pas d'Info.plist dans project.pbxproj)${NC}"
fi

echo ""
echo "==========================================="
echo -e "${YELLOW}⚠️  SOLUTION DÉFINITIVE:${NC}"
echo ""
echo "Le problème vient de PBXFileSystemSynchronizedRootGroup qui"
echo "synchronise automatiquement Info.plist et l'ajoute aux ressources."
echo ""
echo -e "${BLUE}Solution dans Xcode (OBLIGATOIRE):${NC}"
echo ""
echo "1. Target 'Tshiakani VTC' > Build Phases"
echo ""
echo "2. Développez 'Copy Bundle Resources'"
echo ""
echo "3. Cherchez 'Info.plist' dans la liste"
echo "   → Faites défiler si nécessaire"
echo "   → Il peut être présent même si la section semble vide"
echo ""
echo "4. Si Info.plist est présent:"
echo "   → Sélectionnez-le (un clic)"
echo "   → Cliquez sur '-' (moins) en bas"
echo "   → OU appuyez sur Delete (⌫)"
echo ""
echo "5. Vérifiez qu'Info.plist n'est plus dans la liste"
echo ""
echo "6. Product > Clean Build Folder (⇧⌘K)"
echo ""
echo "7. Product > Build (⌘B)"
echo ""
echo "==========================================="
echo ""
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo -e "${RED}⚠️  ACTION MANUELLE OBLIGATOIRE dans Xcode (voir ci-dessus)${NC}"
echo ""

