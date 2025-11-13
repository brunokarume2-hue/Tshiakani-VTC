#!/bin/bash

# Script de correction des erreurs de compilation Xcode
# Résout les problèmes de packages et nettoie les caches

set -e

echo "🔧 Correction des erreurs de compilation Xcode"
echo "=============================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Étape 1: Nettoyage du DerivedData${NC}"
echo "Suppression du DerivedData pour forcer une reconstruction complète..."
rm -rf ~/Library/Developer/Xcode/DerivedData/${PROJECT_NAME// /_}-* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData nettoyé${NC}"
echo ""

echo -e "${YELLOW}Étape 2: Nettoyage des caches Xcode${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo -e "${GREEN}✅ Caches Xcode nettoyés${NC}"
echo ""

echo -e "${YELLOW}Étape 3: Réinitialisation des packages Swift${NC}"
# Supprimer Package.resolved pour forcer la résolution
PACKAGE_RESOLVED="$XCODEPROJ/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo "Suppression de Package.resolved..."
    rm -f "$PACKAGE_RESOLVED"
    echo -e "${GREEN}✅ Package.resolved supprimé${NC}"
else
    echo "Package.resolved n'existe pas encore"
fi
echo ""

echo -e "${YELLOW}Étape 4: Vérification de la structure du projet${NC}"
if [ ! -d "$XCODEPROJ" ]; then
    echo -e "${RED}❌ Erreur: Le projet Xcode n'a pas été trouvé à $XCODEPROJ${NC}"
    exit 1
fi

if [ ! -f "$PROJECT_DIR/$PROJECT_NAME/Info.plist" ]; then
    echo -e "${RED}❌ Erreur: Info.plist n'a pas été trouvé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Structure du projet vérifiée${NC}"
echo ""

echo -e "${YELLOW}Étape 5: Vérification de la configuration Info.plist${NC}"
# Vérifier que GENERATE_INFOPLIST_FILE est bien NO dans project.pbxproj
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO (correct)${NC}"
else
    echo -e "${YELLOW}⚠️  GENERATE_INFOPLIST_FILE n'est pas défini à NO${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${YELLOW}⚠️  INFOPLIST_FILE n'est pas correctement configuré${NC}"
fi
echo ""

echo -e "${YELLOW}Étape 6: Vérification des packages Swift${NC}"
# Vérifier que les packages sont référencés
if grep -q 'ios-maps-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package ios-maps-sdk (GoogleMaps) référencé${NC}"
else
    echo -e "${RED}❌ Package ios-maps-sdk non trouvé${NC}"
fi

if grep -q 'ios-places-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package ios-places-sdk (GooglePlaces) référencé${NC}"
else
    echo -e "${RED}❌ Package ios-places-sdk non trouvé${NC}"
fi
echo ""

echo "=============================================="
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""
echo "📋 Actions à effectuer dans Xcode:"
echo ""
echo "1. Ouvrez le projet dans Xcode"
echo ""
echo "2. Pour corriger Info.plist dans Copy Bundle Resources:"
echo "   - Sélectionnez le target 'Tshiakani VTC'"
echo "   - Allez dans l'onglet 'Build Phases'"
echo "   - Développez 'Copy Bundle Resources'"
echo "   - Si Info.plist est présent, sélectionnez-le et supprimez-le (bouton -)"
echo ""
echo "3. Pour résoudre les packages:"
echo "   - File > Packages > Reset Package Caches"
echo "   - File > Packages > Resolve Package Versions"
echo "   - Attendez que tous les packages soient résolus"
echo ""
echo "4. Vérifiez les frameworks liés:"
echo "   - Sélectionnez le target 'Tshiakani VTC'"
echo "   - Allez dans l'onglet 'General'"
echo "   - Scrollez jusqu'à 'Frameworks, Libraries, and Embedded Content'"
echo "   - Vérifiez que GoogleMaps et GooglePlaces sont présents"
echo "   - Si absents, cliquez sur '+' et ajoutez-les depuis 'Package Dependencies'"
echo ""
echo "5. Nettoyez et compilez:"
echo "   - Product > Clean Build Folder (⇧⌘K)"
echo "   - Product > Build (⌘B)"
echo ""
echo "=============================================="

