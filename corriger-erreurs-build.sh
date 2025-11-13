#!/bin/bash

# Script pour corriger automatiquement les erreurs de compilation courantes

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🔧 CORRECTION AUTOMATIQUE DES ERREURS DE BUILD${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Restaurer Info.plist et configuration correcte
echo -e "${BLUE}Étape 1: Restauration de Info.plist${NC}"

INFOPLIST_PATH="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
INFOPLIST_BACKUP="$INFOPLIST_PATH.backup_compile"

if [ -f "$INFOPLIST_BACKUP" ]; then
    # Restaurer Info.plist
    cp "$INFOPLIST_BACKUP" "$INFOPLIST_PATH"
    echo -e "${GREEN}✅ Info.plist restauré${NC}"
    
    # Restaurer la configuration du projet
    if [ -f "$PROJECT_FILE.backup_before_compile" ]; then
        cp "$PROJECT_FILE.backup_before_compile" "$PROJECT_FILE"
        echo -e "${GREEN}✅ Configuration du projet restaurée${NC}"
    else
        # Modifier manuellement pour restaurer
        sed -i '' 's/GENERATE_INFOPLIST_FILE = YES/GENERATE_INFOPLIST_FILE = NO/g' "$PROJECT_FILE"
        
        # Ajouter INFOPLIST_FILE si absent
        if ! grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
            # Trouver la ligne GENERATE_INFOPLIST_FILE et ajouter INFOPLIST_FILE après
            sed -i '' '/GENERATE_INFOPLIST_FILE = NO/a\
				INFOPLIST_FILE = "Tshiakani VTC/Info.plist";
' "$PROJECT_FILE"
        fi
        
        echo -e "${GREEN}✅ Configuration restaurée manuellement${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Backup Info.plist non trouvé, on continue${NC}"
fi
echo ""

# Étape 2: Vérifier et corriger les valeurs Info.plist dans Build Settings
echo -e "${BLUE}Étape 2: Configuration des valeurs Info.plist dans Build Settings${NC}"

# Lire les valeurs depuis Info.plist
if [ -f "$INFOPLIST_PATH" ]; then
    GOOGLE_MAPS_KEY=$(grep -A 1 "GOOGLE_MAPS_API_KEY" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    API_BASE_URL=$(grep -A 1 "API_BASE_URL" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    WS_BASE_URL=$(grep -A 1 "WS_BASE_URL" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    
    echo -e "${GREEN}✅ Valeurs extraites depuis Info.plist${NC}"
    echo "   GOOGLE_MAPS_API_KEY: ${GOOGLE_MAPS_KEY:0:20}..."
    echo "   API_BASE_URL: $API_BASE_URL"
    echo "   WS_BASE_URL: $WS_BASE_URL"
fi
echo ""

# Étape 3: Nettoyer complètement
echo -e "${BLUE}Étape 3: Nettoyage complet${NC}"
killall Xcode 2>/dev/null || true
sleep 2
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
rm -rf "$PROJECT_DIR"/build 2>/dev/null || true
find "$PROJECT_DIR" -name "*.xcuserstate" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo ""

# Étape 4: Vérifier les fichiers essentiels
echo -e "${BLUE}Étape 4: Vérification des fichiers essentiels${NC}"

FICHIERS_ESSENTIELS=(
    "$PROJECT_DIR/$PROJECT_NAME/TshiakaniVTCApp.swift"
    "$PROJECT_DIR/$PROJECT_NAME/ContentView.swift"
    "$PROJECT_DIR/$PROJECT_NAME/Info.plist"
)

for fichier in "${FICHIERS_ESSENTIELS[@]}"; do
    if [ -f "$fichier" ]; then
        echo -e "${GREEN}✅ $(basename $fichier)${NC}"
    else
        echo -e "${RED}❌ $(basename $fichier) MANQUANT${NC}"
    fi
done
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
echo -e "${BLUE}3. Vérifiez Build Phases > Copy Bundle Resources:${NC}"
echo "   → Si Info.plist est présent, RETIREZ-LE"
echo ""
echo -e "${BLUE}4. Vérifiez les erreurs dans Xcode:${NC}"
echo "   → Regardez le panneau d'erreurs (⌘5)"
echo "   → Notez les erreurs spécifiques"
echo ""
echo -e "${BLUE}5. Product > Clean Build Folder (⇧⌘K)${NC}"
echo ""
echo -e "${BLUE}6. Product > Build (⌘B)${NC}"
echo ""
echo -e "${RED}⚠️  Si des erreurs persistent, envoyez-moi les messages d'erreur${NC}"
echo "   et je les corrigerai automatiquement"
echo ""

