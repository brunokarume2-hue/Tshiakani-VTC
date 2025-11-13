#!/bin/bash

# Script pour corriger les erreurs de résolution des packages

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
echo -e "${RED}  🔥 CORRECTION: Erreurs de Résolution des Packages${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Nettoyer TOUS les caches
echo -e "${BLUE}Étape 1: Nettoyage complet des caches${NC}"
rm -rf "$WORKSPACE/xcshareddata/swiftpm" 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
rm -rf "$PROJECT_DIR"/build 2>/dev/null || true
find "$PROJECT_DIR" -name "*.xcuserstate" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Tous les caches supprimés${NC}"
echo ""

# Étape 2: Vérifier la connectivité réseau
echo -e "${BLUE}Étape 2: Vérification de la connectivité${NC}"
if ping -c 1 github.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Connectivité GitHub OK${NC}"
else
    echo -e "${RED}❌ Problème de connectivité GitHub${NC}"
    echo -e "${YELLOW}⚠️  Vérifiez votre connexion internet${NC}"
fi
echo ""

# Étape 3: Mettre à jour les versions des packages pour éviter les problèmes
echo -e "${BLUE}Étape 3: Mise à jour des versions des packages${NC}"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"

# Vérifier et mettre à jour ios-maps-sdk vers une version plus récente si nécessaire
# Pour l'instant, on garde 10.4.0 mais on va forcer une résolution propre

# Supprimer Package.resolved pour forcer une résolution complète
rm -f "$PACKAGE_RESOLVED" 2>/dev/null || true
echo -e "${GREEN}✅ Package.resolved supprimé (résolution complète forcée)${NC}"
echo ""

# Étape 4: Créer un Package.resolved minimal pour forcer la résolution
echo -e "${BLUE}Étape 4: Création d'un Package.resolved minimal${NC}"
mkdir -p "$WORKSPACE/xcshareddata/swiftpm"

cat > "$PACKAGE_RESOLVED" << 'EOF'
{
  "pins" : [
    {
      "identity" : "ios-maps-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-maps-sdk",
      "state" : {
        "branch" : null,
        "revision" : null,
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "ios-places-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-places-sdk",
      "state" : {
        "branch" : null,
        "revision" : null,
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "swift-algorithms",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-algorithms.git",
      "state" : {
        "branch" : null,
        "revision" : null,
        "version" : "1.2.1"
      }
    }
  ],
  "version" : 3
}
EOF

echo -e "${GREEN}✅ Package.resolved minimal créé${NC}"
echo ""

# Étape 5: Instructions finales
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
echo -e "${BLUE}3. Résolvez les packages (dans cet ordre):${NC}"
echo "   → File > Packages > Reset Package Caches"
echo "   → Attendez 5 secondes"
echo "   → File > Packages > Resolve Package Versions"
echo "   → Attendez 2-3 minutes pour la résolution complète"
echo ""
echo -e "${BLUE}4. Si ios-maps-sdk échoue encore:${NC}"
echo "   → File > Packages > Remove Package"
echo "   → Sélectionnez ios-maps-sdk et supprimez-le"
echo "   → File > Add Package Dependencies..."
echo "   → URL: https://github.com/googlemaps/ios-maps-sdk"
echo "   → Version: Up to Next Major Version (10.4.0)"
echo ""
echo -e "${BLUE}5. Nettoyez et compilez:${NC}"
echo "   → Product > Clean Build Folder (⇧⌘K)"
echo "   → Product > Build (⌘B)"
echo ""
echo -e "${GREEN}💡 Les erreurs devraient être corrigées après la résolution${NC}"
echo ""

