#!/bin/bash

# Script pour diagnostiquer les erreurs restantes

echo "🔍 Diagnostic des Erreurs Restantes"
echo "===================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"
PACKAGE_RESOLVED="$XCODEPROJ/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Vérification 1: Packages résolus${NC}"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo -e "${GREEN}✅ Package.resolved existe${NC}"
    
    # Vérifier GoogleMaps
    if grep -q "ios-maps-sdk" "$PACKAGE_RESOLVED" 2>/dev/null; then
        echo -e "${GREEN}✅ Package ios-maps-sdk résolu${NC}"
    else
        echo -e "${RED}❌ Package ios-maps-sdk NON résolu${NC}"
    fi
    
    # Vérifier GooglePlaces
    if grep -q "ios-places-sdk" "$PACKAGE_RESOLVED" 2>/dev/null; then
        echo -e "${GREEN}✅ Package ios-places-sdk résolu${NC}"
    else
        echo -e "${RED}❌ Package ios-places-sdk NON résolu${NC}"
    fi
else
    echo -e "${RED}❌ Package.resolved n'existe pas${NC}"
    echo -e "${YELLOW}   → Les packages ne sont pas encore résolus${NC}"
    echo -e "${YELLOW}   → Action: File > Packages > Resolve Package Versions dans Xcode${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 2: Configuration Info.plist${NC}"
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
echo -e "${BLUE}Vérification 3: Frameworks liés${NC}"
if grep -q 'GoogleMaps in Frameworks' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GoogleMaps lié${NC}"
else
    echo -e "${RED}❌ GoogleMaps non lié${NC}"
fi

if grep -q 'GooglePlaces in Frameworks' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GooglePlaces lié${NC}"
else
    echo -e "${RED}❌ GooglePlaces non lié${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 4: Package dependencies${NC}"
if grep -q 'packageProductDependencies' "$XCODEPROJ/project.pbxproj" && grep -A 3 'packageProductDependencies' "$XCODEPROJ/project.pbxproj" | grep -q 'GoogleMaps'; then
    echo -e "${GREEN}✅ GoogleMaps dans packageProductDependencies${NC}"
else
    echo -e "${RED}❌ GoogleMaps manquant dans packageProductDependencies${NC}"
fi

if grep -q 'packageProductDependencies' "$XCODEPROJ/project.pbxproj" && grep -A 3 'packageProductDependencies' "$XCODEPROJ/project.pbxproj" | grep -q 'GooglePlaces'; then
    echo -e "${GREEN}✅ GooglePlaces dans packageProductDependencies${NC}"
else
    echo -e "${RED}❌ GooglePlaces manquant dans packageProductDependencies${NC}"
fi

echo ""
echo "===================================="
echo -e "${YELLOW}Les 2 erreurs les plus probables sont:${NC}"
echo ""
echo -e "${RED}1. Missing package product 'GoogleMaps'${NC}"
echo -e "${RED}2. Missing package product 'GooglePlaces'${NC}"
echo ""
echo -e "${BLUE}Solution:${NC}"
echo "   Les packages doivent être résolus dans Xcode:"
echo "   1. File > Packages > Reset Package Caches"
echo "   2. File > Packages > Resolve Package Versions"
echo "   3. Attendez 2-5 minutes que les packages soient résolus"
echo ""

