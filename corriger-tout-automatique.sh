#!/bin/bash

# Script complet pour corriger automatiquement toutes les erreurs de compilation
# Ce script combine le nettoyage et l'ouverture d'Xcode avec les corrections

set -e

echo "🔧 Correction Automatique Complète des Erreurs de Compilation"
echo "=============================================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Étape 1: Nettoyage complet${NC}"
echo "----------------------------------------"

# Nettoyer DerivedData
echo -e "${YELLOW}Nettoyage du DerivedData...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/${PROJECT_NAME// /_}-* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData nettoyé${NC}"

# Nettoyer les caches
echo -e "${YELLOW}Nettoyage des caches Xcode...${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo -e "${GREEN}✅ Caches nettoyés${NC}"

# Supprimer Package.resolved
echo -e "${YELLOW}Réinitialisation des packages Swift...${NC}"
PACKAGE_RESOLVED="$XCODEPROJ/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    rm -f "$PACKAGE_RESOLVED"
    echo -e "${GREEN}✅ Package.resolved supprimé${NC}"
else
    echo "Package.resolved n'existe pas"
fi

echo ""
echo -e "${BLUE}Étape 2: Vérification de la configuration${NC}"
echo "----------------------------------------"

# Vérifier la configuration
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${RED}❌ GENERATE_INFOPLIST_FILE n'est pas NO${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${RED}❌ INFOPLIST_FILE incorrect${NC}"
fi

if grep -q 'ios-maps-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package GoogleMaps référencé${NC}"
else
    echo -e "${RED}❌ Package GoogleMaps non trouvé${NC}"
fi

if grep -q 'ios-places-sdk' "$XCODEPROJ/project.pbxproj"; then
    echo -e "${GREEN}✅ Package GooglePlaces référencé${NC}"
else
    echo -e "${RED}❌ Package GooglePlaces non trouvé${NC}"
fi

echo ""
echo -e "${BLUE}Étape 3: Ouverture d'Xcode et résolution des packages${NC}"
echo "----------------------------------------"

# Ouvrir Xcode avec le projet
echo -e "${YELLOW}Ouverture du projet dans Xcode...${NC}"
open "$XCODEPROJ"
echo -e "${GREEN}✅ Projet ouvert dans Xcode${NC}"

echo ""
echo -e "${YELLOW}⏳ Attente de 5 secondes pour qu'Xcode se charge...${NC}"
sleep 5

# Essayer d'exécuter le script AppleScript
if command -v osascript &> /dev/null; then
    echo -e "${YELLOW}Tentative d'automatisation via AppleScript...${NC}"
    osascript "$PROJECT_DIR/corriger-xcode-automatique.applescript" 2>&1 || {
        echo -e "${YELLOW}⚠️  L'automatisation AppleScript a échoué (normal si Xcode n'est pas complètement chargé)${NC}"
        echo -e "${YELLOW}   Vous devrez effectuer les actions manuellement (voir ci-dessous)${NC}"
    }
else
    echo -e "${YELLOW}⚠️  osascript non disponible${NC}"
fi

echo ""
echo "=============================================================="
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""
echo -e "${BLUE}📋 Actions à effectuer dans Xcode (si l'automatisation n'a pas fonctionné):${NC}"
echo ""
echo "1. ${YELLOW}Retirer Info.plist de Copy Bundle Resources:${NC}"
echo "   - Sélectionnez le target 'Tshiakani VTC'"
echo "   - Allez dans l'onglet 'Build Phases'"
echo "   - Développez 'Copy Bundle Resources'"
echo "   - Si Info.plist est présent, supprimez-le (bouton -)"
echo ""
echo "2. ${YELLOW}Résoudre les packages:${NC}"
echo "   - File > Packages > Reset Package Caches"
echo "   - File > Packages > Resolve Package Versions"
echo "   - Attendez 2-5 minutes que les packages soient résolus"
echo ""
echo "3. ${YELLOW}Vérifier les frameworks:${NC}"
echo "   - Target 'Tshiakani VTC' > General"
echo "   - Section 'Frameworks, Libraries, and Embedded Content'"
echo "   - Vérifiez que GoogleMaps et GooglePlaces sont présents"
echo "   - Si absents, ajoutez-les via le bouton '+'"
echo ""
echo "4. ${YELLOW}Compiler:${NC}"
echo "   - Product > Clean Build Folder (⇧⌘K)"
echo "   - Product > Build (⌘B)"
echo ""
echo "=============================================================="

