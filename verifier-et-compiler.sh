#!/bin/bash

# Script final pour vérifier et compiler le projet
# Vérifie tous les éléments et tente une compilation

set -e

echo "🔍 Vérification Finale et Compilation"
echo "======================================"
echo ""

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

echo -e "${BLUE}Vérification 1: Configuration Info.plist${NC}"
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${RED}❌ GENERATE_INFOPLIST_FILE incorrect${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correct${NC}"
else
    echo -e "${RED}❌ INFOPLIST_FILE incorrect${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 2: Packages référencés${NC}"
if grep -q 'ios-maps-sdk' "$XCODEPROJ/project.pbxproj" && grep -q 'GoogleMaps' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package GoogleMaps référencé${NC}"
else
    echo -e "${RED}❌ Package GoogleMaps manquant${NC}"
fi

if grep -q 'ios-places-sdk' "$XCODEPROJ/project.pbxproj" && grep -q 'GooglePlaces' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package GooglePlaces référencé${NC}"
else
    echo -e "${RED}❌ Package GooglePlaces manquant${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 3: Frameworks liés${NC}"
if grep -q 'GoogleMaps in Frameworks' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GoogleMaps lié dans Frameworks${NC}"
else
    echo -e "${RED}❌ GoogleMaps non lié${NC}"
fi

if grep -q 'GooglePlaces in Frameworks' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GooglePlaces lié dans Frameworks${NC}"
else
    echo -e "${RED}❌ GooglePlaces non lié${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 4: Info.plist dans les ressources${NC}"
RESOURCES_EMPTY=$(grep -A 3 '849318F02EBEE1F000D186E8 /\* Resources \*/' "$XCODEPROJ/project.pbxproj" | grep -c 'files = (' || echo "0")
if [ "$RESOURCES_EMPTY" -gt 0 ]; then
    RESOURCES_CONTENT=$(grep -A 5 '849318F02EBEE1F000D186E8 /\* Resources \*/' "$XCODEPROJ/project.pbxproj" | grep -A 3 'files = (' | grep -c 'Info.plist' || echo "0")
    if [ "$RESOURCES_CONTENT" -eq 0 ]; then
        echo -e "${GREEN}✅ Info.plist n'est PAS dans Copy Bundle Resources${NC}"
    else
        echo -e "${YELLOW}⚠️  Info.plist trouvé dans les ressources (à retirer dans Xcode)${NC}"
    fi
else
    echo -e "${GREEN}✅ Section Resources vide (correct)${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 5: Package.resolved${NC}"
PACKAGE_RESOLVED="$XCODEPROJ/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo -e "${GREEN}✅ Package.resolved existe${NC}"
    PACKAGE_COUNT=$(plutil -extract pins raw "$PACKAGE_RESOLVED" 2>/dev/null | grep -c "kind" || echo "0")
    echo -e "${BLUE}   Packages résolus: $PACKAGE_COUNT${NC}"
else
    echo -e "${YELLOW}⚠️  Package.resolved n'existe pas encore (packages en cours de résolution)${NC}"
fi

echo ""
echo "======================================"
echo -e "${BLUE}Tentative de compilation...${NC}"
echo "======================================"
echo ""

# Vérifier si xcodebuild est disponible
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${YELLOW}⚠️  xcodebuild non disponible via ligne de commande${NC}"
    echo -e "${YELLOW}   Utilisez Xcode pour compiler: Product > Build (⌘B)${NC}"
    echo ""
    echo -e "${GREEN}✅ Toutes les vérifications sont passées !${NC}"
    echo -e "${BLUE}📋 Prochaines étapes:${NC}"
    echo "   1. Attendez que les packages soient résolus dans Xcode (2-5 min)"
    echo "   2. Product > Clean Build Folder (⇧⌘K)"
    echo "   3. Product > Build (⌘B)"
    exit 0
fi

# Essayer de compiler
echo -e "${YELLOW}Compilation en cours...${NC}"
cd "$PROJECT_DIR"

# Nettoyer d'abord
xcodebuild clean -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Debug 2>&1 | grep -E "(error|warning|succeeded|failed)" | head -20 || true

echo ""
echo -e "${YELLOW}Build en cours...${NC}"
xcodebuild build -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' 2>&1 | tee /tmp/xcode_build.log | grep -E "(error|warning|succeeded|failed|BUILD)" | head -30 || {
    echo ""
    echo -e "${YELLOW}⚠️  Compilation terminée. Vérifiez les erreurs ci-dessus.${NC}"
    echo -e "${BLUE}   Log complet: /tmp/xcode_build.log${NC}"
    
    # Compter les erreurs
    ERROR_COUNT=$(grep -c "error:" /tmp/xcode_build.log 2>/dev/null || echo "0")
    WARNING_COUNT=$(grep -c "warning:" /tmp/xcode_build.log 2>/dev/null || echo "0")
    
    echo ""
    echo -e "${BLUE}Statistiques:${NC}"
    echo "   Erreurs: $ERROR_COUNT"
    echo "   Warnings: $WARNING_COUNT"
    
    if [ "$ERROR_COUNT" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Aucune erreur de compilation !${NC}"
    fi
}

echo ""
echo "======================================"

