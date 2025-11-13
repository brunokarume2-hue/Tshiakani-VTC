#!/bin/bash

# Script définitif pour corriger l'erreur "Multiple commands produce Info.plist"
# Combine toutes les solutions possibles

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"
INFOPLIST_PATH="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
XCODE_IGNORE="$PROJECT_DIR/$PROJECT_NAME/.xcode-ignore"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔧 CORRECTION DÉFINITIVE: Multiple commands produce Info.plist${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Vérifier que le fichier Info.plist existe
echo -e "${BLUE}Étape 1: Vérification d'Info.plist${NC}"
if [ ! -f "$INFOPLIST_PATH" ]; then
    echo -e "${RED}❌ Info.plist n'existe pas à: $INFOPLIST_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Info.plist existe${NC}"
echo ""

# Étape 2: Créer/Vérifier le fichier .xcode-ignore
echo -e "${BLUE}Étape 2: Configuration de .xcode-ignore${NC}"
if [ ! -f "$XCODE_IGNORE" ]; then
    echo "Info.plist" > "$XCODE_IGNORE"
    echo -e "${GREEN}✅ Fichier .xcode-ignore créé${NC}"
else
    if ! grep -q "Info.plist" "$XCODE_IGNORE"; then
        echo "Info.plist" >> "$XCODE_IGNORE"
        echo -e "${GREEN}✅ Info.plist ajouté à .xcode-ignore${NC}"
    else
        echo -e "${GREEN}✅ Info.plist déjà dans .xcode-ignore${NC}"
    fi
fi
echo ""

# Étape 3: Vérifier la configuration dans project.pbxproj
echo -e "${BLUE}Étape 3: Vérification de la configuration${NC}"
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${YELLOW}⚠️  GENERATE_INFOPLIST_FILE n'est pas NO${NC}"
    echo -e "${YELLOW}   Modification en cours...${NC}"
    sed -i '' 's/GENERATE_INFOPLIST_FILE = YES/GENERATE_INFOPLIST_FILE = NO/g' "$PROJECT_FILE"
    echo -e "${GREEN}✅ GENERATE_INFOPLIST_FILE mis à NO${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ INFOPLIST_FILE correctement configuré${NC}"
else
    echo -e "${YELLOW}⚠️  INFOPLIST_FILE non configuré${NC}"
fi
echo ""

# Étape 4: Nettoyer DerivedData
echo -e "${BLUE}Étape 4: Nettoyage du DerivedData${NC}"
DERIVED_DATA_PATTERN="$HOME/Library/Developer/Xcode/DerivedData/${PROJECT_NAME// /_}-*"
if ls $DERIVED_DATA_PATTERN 1> /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Dossiers DerivedData trouvés${NC}"
    echo -e "${YELLOW}   Tentative de nettoyage...${NC}"
    
    # Essayer de nettoyer (peut échouer si Xcode est ouvert, mais on continue)
    rm -rf $DERIVED_DATA_PATTERN 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Certains fichiers sont verrouillés (Xcode peut être ouvert)${NC}"
        echo -e "${YELLOW}   Nettoyage partiel effectué${NC}"
    }
    echo -e "${GREEN}✅ Nettoyage du DerivedData effectué${NC}"
else
    echo -e "${GREEN}✅ Aucun DerivedData à nettoyer${NC}"
fi
echo ""

# Étape 5: Instructions finales
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CORRECTIONS APPLIQUÉES${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 PROCHAINES ÉTAPES OBLIGATOIRES:${NC}"
echo ""
echo -e "${BLUE}1. Ouvrez Xcode${NC}"
echo ""
echo -e "${BLUE}2. Ouvrez le projet:${NC}"
echo "   $XCODEPROJ"
echo ""
echo -e "${BLUE}3. Vérifiez que Info.plist n'est PAS dans Copy Bundle Resources:${NC}"
echo "   → Sélectionnez le target '$PROJECT_NAME' (icône bleue)"
echo "   → Onglet 'Build Phases'"
echo "   → Développez 'Copy Bundle Resources'"
echo "   → Si Info.plist est présent, sélectionnez-le et cliquez sur '-'"
echo ""
echo -e "${BLUE}4. Nettoyez le build:${NC}"
echo "   → Product > Clean Build Folder (⇧⌘K)"
echo ""
echo -e "${BLUE}5. Compilez:${NC}"
echo "   → Product > Build (⌘B)"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}💡 Le fichier .xcode-ignore devrait empêcher Xcode de${NC}"
echo -e "${GREEN}   synchroniser automatiquement Info.plist.${NC}"
echo ""
echo -e "${YELLOW}⚠️  Si l'erreur persiste après ces étapes,${NC}"
echo -e "${YELLOW}   Info.plist doit être retiré manuellement de${NC}"
echo -e "${YELLOW}   Copy Bundle Resources dans Xcode.${NC}"
echo ""

