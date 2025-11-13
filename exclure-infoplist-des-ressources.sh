#!/bin/bash

# Script pour exclure explicitement Info.plist des ressources synchronisées
# Solution pour PBXFileSystemSynchronizedRootGroup

echo "🔧 Exclusion d'Info.plist des Ressources"
echo "========================================"
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"
BACKUP_FILE="$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Étape 1: Sauvegarde${NC}"
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo -e "${GREEN}✅ Sauvegarde créée: $(basename $BACKUP_FILE)${NC}"

echo ""
echo -e "${BLUE}Étape 2: Vérification de la configuration${NC}"

# Vérifier que GENERATE_INFOPLIST_FILE = NO
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${RED}❌ GENERATE_INFOPLIST_FILE n'est pas NO${NC}"
fi

# Vérifier INFOPLIST_FILE
if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${RED}❌ INFOPLIST_FILE incorrect${NC}"
fi

echo ""
echo -e "${BLUE}Étape 3: Nettoyage${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData nettoyé${NC}"

echo ""
echo "========================================"
echo -e "${YELLOW}⚠️  SOLUTION DÉFINITIVE:${NC}"
echo ""
echo "Avec PBXFileSystemSynchronizedRootGroup, Info.plist est"
echo "automatiquement synchronisé. La seule solution est de le"
echo "retirer manuellement dans Xcode."
echo ""
echo -e "${BLUE}Instructions PRÉCISES:${NC}"
echo ""
echo "1. Dans Xcode, sélectionnez le target 'Tshiakani VTC'"
echo "   → Cliquez sur l'icône bleue en haut (Project Navigator)"
echo ""
echo "2. Allez dans l'onglet 'Build Phases'"
echo "   → 3ème onglet en haut"
echo ""
echo "3. Développez 'Copy Bundle Resources'"
echo "   → Cliquez sur la flèche à gauche"
echo ""
echo "4. Cherchez 'Info.plist' dans la liste"
echo "   → Faites défiler si nécessaire"
echo "   → Utilisez Cmd+F pour chercher 'Info.plist'"
echo ""
echo "5. Si Info.plist est présent:"
echo "   → Sélectionnez-le (un clic)"
echo "   → Cliquez sur le bouton '-' (moins) en bas"
echo "   → OU appuyez sur Delete (⌫)"
echo ""
echo "6. Vérifiez visuellement qu'Info.plist n'est plus dans la liste"
echo ""
echo "7. Product > Clean Build Folder (⇧⌘K)"
echo ""
echo "8. Product > Build (⌘B)"
echo ""
echo "========================================"
echo ""
echo -e "${GREEN}✅ Sauvegarde créée${NC}"
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo -e "${RED}⚠️  ACTION MANUELLE OBLIGATOIRE dans Xcode${NC}"
echo ""

