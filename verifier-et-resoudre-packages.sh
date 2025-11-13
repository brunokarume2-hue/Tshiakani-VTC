#!/bin/bash

# Script pour vérifier et résoudre les packages GoogleMaps et GooglePlaces

echo "🔍 Vérification et Résolution des Packages"
echo "==========================================="
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

echo -e "${BLUE}Vérification 1: Package.resolved${NC}"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo -e "${GREEN}✅ Package.resolved existe${NC}"
    
    # Vérifier GoogleMaps
    if grep -q "ios-maps-sdk" "$PACKAGE_RESOLVED" 2>/dev/null; then
        MAPS_VERSION=$(grep -A 10 "ios-maps-sdk" "$PACKAGE_RESOLVED" | grep "state" | head -1 | sed 's/.*version": "\([^"]*\)".*/\1/' || echo "trouvé")
        echo -e "${GREEN}✅ Package ios-maps-sdk résolu (version: $MAPS_VERSION)${NC}"
    else
        echo -e "${RED}❌ Package ios-maps-sdk NON résolu${NC}"
    fi
    
    # Vérifier GooglePlaces
    if grep -q "ios-places-sdk" "$PACKAGE_RESOLVED" 2>/dev/null; then
        PLACES_VERSION=$(grep -A 10 "ios-places-sdk" "$PACKAGE_RESOLVED" | grep "state" | head -1 | sed 's/.*version": "\([^"]*\)".*/\1/' || echo "trouvé")
        echo -e "${GREEN}✅ Package ios-places-sdk résolu (version: $PLACES_VERSION)${NC}"
    else
        echo -e "${RED}❌ Package ios-places-sdk NON résolu${NC}"
    fi
else
    echo -e "${RED}❌ Package.resolved n'existe pas${NC}"
    echo -e "${YELLOW}   → Les packages ne sont pas encore résolus${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 2: Références dans project.pbxproj${NC}"
if grep -q 'ios-maps-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package ios-maps-sdk référencé${NC}"
else
    echo -e "${RED}❌ Package ios-maps-sdk non référencé${NC}"
fi

if grep -q 'ios-places-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package ios-places-sdk référencé${NC}"
else
    echo -e "${RED}❌ Package ios-places-sdk non référencé${NC}"
fi

echo ""
echo -e "${BLUE}Vérification 3: Package dependencies${NC}"
if grep -q 'GoogleMaps' "$XCODEPROJ/project.pbxproj" && grep -q 'packageProductDependencies' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GoogleMaps dans packageProductDependencies${NC}"
else
    echo -e "${RED}❌ GoogleMaps manquant dans packageProductDependencies${NC}"
fi

if grep -q 'GooglePlaces' "$XCODEPROJ/project.pbxproj" && grep -q 'packageProductDependencies' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GooglePlaces dans packageProductDependencies${NC}"
else
    echo -e "${RED}❌ GooglePlaces manquant dans packageProductDependencies${NC}"
fi

echo ""
echo "==========================================="
echo -e "${YELLOW}⚠️  DIAGNOSTIC:${NC}"
echo ""

# Vérifier si les packages sont résolus mais pas liés
if [ -f "$PACKAGE_RESOLVED" ]; then
    MAPS_RESOLVED=$(grep -q "ios-maps-sdk" "$PACKAGE_RESOLVED" 2>/dev/null && echo "oui" || echo "non")
    PLACES_RESOLVED=$(grep -q "ios-places-sdk" "$PACKAGE_RESOLVED" 2>/dev/null && echo "oui" || echo "non")
    
    if [ "$MAPS_RESOLVED" = "non" ] || [ "$PLACES_RESOLVED" = "non" ]; then
        echo -e "${RED}❌ Les packages ne sont PAS résolus${NC}"
        echo ""
        echo -e "${BLUE}Solution:${NC}"
        echo "1. File > Packages > Reset Package Caches"
        echo "2. File > Packages > Resolve Package Versions"
        echo "3. Attendez 2-5 minutes"
    else
        echo -e "${YELLOW}⚠️  Les packages sont résolus mais l'erreur persiste${NC}"
        echo ""
        echo -e "${BLUE}Solutions possibles:${NC}"
        echo "1. Vérifiez que les frameworks sont liés:"
        echo "   → Target > General > Frameworks, Libraries, and Embedded Content"
        echo "   → GoogleMaps et GooglePlaces doivent être présents"
        echo ""
        echo "2. Nettoyez et recompilez:"
        echo "   → Product > Clean Build Folder (⇧⌘K)"
        echo "   → Product > Build (⌘B)"
        echo ""
        echo "3. Si les frameworks ne sont pas présents, ajoutez-les:"
        echo "   → Bouton '+' > Package Dependencies > GoogleMaps"
        echo "   → Bouton '+' > Package Dependencies > GooglePlaces"
    fi
else
    echo -e "${RED}❌ Package.resolved n'existe pas${NC}"
    echo -e "${YELLOW}   → Les packages ne sont pas résolus${NC}"
    echo ""
    echo -e "${BLUE}Solution:${NC}"
    echo "1. File > Packages > Reset Package Caches"
    echo "2. File > Packages > Resolve Package Versions"
    echo "3. Attendez 2-5 minutes"
fi

echo ""
echo "==========================================="

