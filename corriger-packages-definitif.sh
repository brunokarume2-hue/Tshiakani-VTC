#!/bin/bash

# Script DÉFINITIF pour corriger les erreurs "Missing package product"

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
WORKSPACE="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace"
PACKAGE_RESOLVED="$WORKSPACE/xcshareddata/swiftpm/Package.resolved"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🔥 CORRECTION DÉFINITIVE: Missing Package Products${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Tuer Xcode
echo -e "${BLUE}Étape 1: Arrêt de Xcode${NC}"
killall Xcode 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Xcode arrêté${NC}"
echo ""

# Étape 2: Supprimer les caches de packages
echo -e "${BLUE}Étape 2: Suppression des caches de packages${NC}"
rm -rf "$WORKSPACE/xcshareddata/swiftpm" 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/org.swift.swiftpm 2>/dev/null || true
echo -e "${GREEN}✅ Caches de packages supprimés${NC}"
echo ""

# Étape 3: Nettoyer DerivedData
echo -e "${BLUE}Étape 3: Nettoyage du DerivedData${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData nettoyé${NC}"
echo ""

# Étape 4: Vérifier la configuration des packages dans project.pbxproj
echo -e "${BLUE}Étape 4: Vérification de la configuration${NC}"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"

# Vérifier que les packages sont bien référencés
if grep -q "ios-places-sdk" "$PROJECT_FILE" && grep -q "ios-maps-sdk" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ Packages référencés dans project.pbxproj${NC}"
else
    echo -e "${RED}❌ Packages non trouvés dans project.pbxproj${NC}"
    exit 1
fi

# Vérifier que les produits sont bien référencés
if grep -q "GooglePlaces" "$PROJECT_FILE" && grep -q "GoogleMaps" "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ Produits référencés dans project.pbxproj${NC}"
else
    echo -e "${RED}❌ Produits non trouvés dans project.pbxproj${NC}"
    exit 1
fi
echo ""

# Étape 5: Recréer Package.resolved avec les bonnes versions
echo -e "${BLUE}Étape 5: Recréation de Package.resolved${NC}"
mkdir -p "$WORKSPACE/xcshareddata/swiftpm"

cat > "$PACKAGE_RESOLVED" << 'EOF'
{
  "originHash" : "8399231b11c6e9aa45d56130709fbd5d354b4de4f94cbd1734bc4367b4f1e127",
  "pins" : [
    {
      "identity" : "ios-maps-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-maps-sdk",
      "state" : {
        "revision" : "e4c8ab764c05a7e50501f8f7b35a1f8b45203da2",
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "ios-places-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-places-sdk",
      "state" : {
        "revision" : "d07fef1d14fb7095d3681571433ca4e147e34a91",
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "swift-algorithms",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-algorithms.git",
      "state" : {
        "revision" : "87e50f483c54e6efd60e885f7f5aa946cee68023",
        "version" : "1.2.1"
      }
    }
  ],
  "version" : 3
}
EOF

echo -e "${GREEN}✅ Package.resolved recréé${NC}"
echo ""

# Étape 6: Instructions finales
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CORRECTIONS APPLIQUÉES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 PROCHAINES ÉTAPES DANS XCODE:${NC}"
echo ""
echo -e "${BLUE}1. Ouvrez Xcode${NC}"
echo ""
echo -e "${BLUE}2. Ouvrez le projet:${NC}"
echo "   $XCODEPROJ"
echo ""
echo -e "${BLUE}3. Résolvez les packages:${NC}"
echo "   → File > Packages > Resolve Package Versions"
echo "   → Attendez que la résolution se termine"
echo ""
echo -e "${BLUE}4. Si cela ne fonctionne pas:${NC}"
echo "   → File > Packages > Reset Package Caches"
echo "   → Puis File > Packages > Resolve Package Versions"
echo ""
echo -e "${BLUE}5. Nettoyez et compilez:${NC}"
echo "   → Product > Clean Build Folder (⇧⌘K)"
echo "   → Product > Build (⌘B)"
echo ""
echo -e "${GREEN}🎉 Les packages devraient maintenant être résolus !${NC}"
echo ""

