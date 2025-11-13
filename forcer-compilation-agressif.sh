#!/bin/bash

# Script agressif pour forcer la compilation en supprimant tous les obstacles
# On corrigera après si nécessaire

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"
INFOPLIST_PATH="$PROJECT_DIR/$PROJECT_NAME/Info.plist"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🔥 FORÇAGE AGressif DE LA COMPILATION${NC}"
echo -e "${RED}  Suppression de TOUS les obstacles${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Tuer tous les processus Xcode
echo -e "${RED}Étape 1: Arrêt forcé de Xcode${NC}"
killall Xcode 2>/dev/null || true
killall com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Xcode arrêté${NC}"
echo ""

# Étape 2: Supprimer TOUT le DerivedData
echo -e "${RED}Étape 2: Suppression complète du DerivedData${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ Tout le DerivedData supprimé${NC}"
echo ""

# Étape 3: Supprimer les modules et archives
echo -e "${RED}Étape 3: Suppression des modules et archives${NC}"
rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
echo -e "${GREEN}✅ Modules et archives supprimés${NC}"
echo ""

# Étape 4: Nettoyer les fichiers de build locaux
echo -e "${RED}Étape 4: Nettoyage des fichiers de build locaux${NC}"
find "$PROJECT_DIR" -name "*.xcuserstate" -delete 2>/dev/null || true
find "$PROJECT_DIR" -name "*.xcuserdatad" -type d -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_DIR" -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_DIR" -name ".build" -type d -exec rm -rf {} + 2>/dev/null || true
echo -e "${GREEN}✅ Fichiers de build locaux supprimés${NC}"
echo ""

# Étape 5: Forcer la suppression d'Info.plist des ressources dans project.pbxproj
echo -e "${RED}Étape 5: Modification agressive du projet${NC}"
if [ -f "$PROJECT_FILE" ]; then
    # Créer une sauvegarde
    cp "$PROJECT_FILE" "$PROJECT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    # S'assurer que GENERATE_INFOPLIST_FILE = NO
    sed -i '' 's/GENERATE_INFOPLIST_FILE = YES/GENERATE_INFOPLIST_FILE = NO/g' "$PROJECT_FILE"
    
    # S'assurer que INFOPLIST_FILE est correct
    if ! grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
        # Ajouter INFOPLIST_FILE si absent
        sed -i '' '/GENERATE_INFOPLIST_FILE = NO/a\
				INFOPLIST_FILE = "Tshiakani VTC/Info.plist";
' "$PROJECT_FILE"
    fi
    
    echo -e "${GREEN}✅ Projet modifié${NC}"
else
    echo -e "${YELLOW}⚠️  Fichier project.pbxproj non trouvé${NC}"
fi
echo ""

# Étape 6: Créer/forcer .xcode-ignore
echo -e "${RED}Étape 6: Forçage de .xcode-ignore${NC}"
XCODE_IGNORE="$PROJECT_DIR/$PROJECT_NAME/.xcode-ignore"
echo "Info.plist" > "$XCODE_IGNORE"
echo "*.xcuserstate" >> "$XCODE_IGNORE"
echo "*.xcuserdatad" >> "$XCODE_IGNORE"
echo -e "${GREEN}✅ .xcode-ignore forcé${NC}"
echo ""

# Étape 7: Supprimer les fichiers de verrouillage
echo -e "${RED}Étape 7: Suppression des fichiers de verrouillage${NC}"
rm -rf "$PROJECT_DIR/.DS_Store" 2>/dev/null || true
find "$PROJECT_DIR" -name ".DS_Store" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Fichiers de verrouillage supprimés${NC}"
echo ""

# Étape 8: Nettoyer les pods si présents
echo -e "${RED}Étape 8: Nettoyage des dépendances${NC}"
if [ -f "$PROJECT_DIR/Podfile" ]; then
    cd "$PROJECT_DIR"
    pod deintegrate 2>/dev/null || true
    pod cache clean --all 2>/dev/null || true
    echo -e "${GREEN}✅ Pods nettoyés${NC}"
else
    echo -e "${GREEN}✅ Pas de Podfile${NC}"
fi
echo ""

# Étape 9: Résumé final
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ NETTOYAGE AGressif TERMINÉ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 PROCHAINES ÉTAPES:${NC}"
echo ""
echo -e "${BLUE}1. Ouvrez Xcode${NC}"
echo ""
echo -e "${BLUE}2. Ouvrez le projet:${NC}"
echo "   $XCODEPROJ"
echo ""
echo -e "${BLUE}3. Vérifiez Build Phases > Copy Bundle Resources${NC}"
echo "   → Si Info.plist est présent, RETIREZ-LE manuellement"
echo ""
echo -e "${BLUE}4. Product > Clean Build Folder (⇧⌘K)${NC}"
echo ""
echo -e "${BLUE}5. Product > Build (⌘B)${NC}"
echo ""
echo -e "${RED}⚠️  Si l'erreur persiste, on corrigera après la compilation${NC}"
echo ""

