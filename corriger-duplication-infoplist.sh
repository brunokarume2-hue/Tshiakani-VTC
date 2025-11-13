#!/bin/bash

# Script pour corriger l'erreur de duplication Info.plist
# Erreur: Multiple commands produce '.../Info.plist'

echo "🔧 Correction de l'erreur de duplication Info.plist"
echo "=================================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Étape 1: Nettoyage du DerivedData${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData supprimé${NC}"
echo ""

echo -e "${BLUE}Étape 2: Vérification de la configuration${NC}"
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO (correct)${NC}"
else
    echo -e "${RED}❌ GENERATE_INFOPLIST_FILE incorrect${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${RED}❌ INFOPLIST_FILE incorrect${NC}"
fi
echo ""

echo -e "${BLUE}Étape 3: Vérification des ressources${NC}"
RESOURCES_SECTION=$(grep -A 5 '849318F02EBEE1F000D186E8 /\* Resources \*/' "$XCODEPROJ/project.pbxproj" | grep -A 3 'files = (' | grep -c 'Info.plist' || echo "0")
if [ "$RESOURCES_SECTION" -eq 0 ]; then
    echo -e "${GREEN}✅ Info.plist n'est PAS dans les ressources (dans project.pbxproj)${NC}"
else
    echo -e "${YELLOW}⚠️  Info.plist trouvé dans les ressources${NC}"
fi
echo ""

echo "=================================================="
echo -e "${YELLOW}⚠️  ACTION REQUISE DANS XCODE:${NC}"
echo ""
echo "Le problème vient probablement du fait qu'Info.plist est dans"
echo "'Copy Bundle Resources' même s'il n'apparaît pas dans project.pbxproj"
echo "(à cause de PBXFileSystemSynchronizedRootGroup)."
echo ""
echo -e "${BLUE}Instructions:${NC}"
echo ""
echo "1. Ouvrez Xcode (le projet devrait déjà être ouvert)"
echo ""
echo "2. Sélectionnez le target 'Tshiakani VTC' (icône bleue en haut)"
echo ""
echo "3. Allez dans l'onglet 'Build Phases'"
echo ""
echo "4. Développez 'Copy Bundle Resources'"
echo ""
echo "5. Cherchez 'Info.plist' dans la liste"
echo ""
echo "6. Si Info.plist est présent:"
echo "   - Sélectionnez-le"
echo "   - Cliquez sur le bouton '-' (moins) en bas"
echo "   - OU appuyez sur Delete"
echo ""
echo "7. Vérifiez que Info.plist n'est plus dans la liste"
echo ""
echo "8. Nettoyez et compilez:"
echo "   - Product > Clean Build Folder (⇧⌘K)"
echo "   - Product > Build (⌘B)"
echo ""
echo "=================================================="
echo ""
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo -e "${YELLOW}⏳ Action manuelle requise dans Xcode (voir ci-dessus)${NC}"
echo ""

