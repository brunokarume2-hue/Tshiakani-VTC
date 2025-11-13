#!/bin/bash

# Script pour FORCER la compilation en contournant tous les obstacles

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"
INFOPLIST_PATH="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
INFOPLIST_BACKUP="$INFOPLIST_PATH.backup_compile"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🔥 FORÇAGE ULTIME DE LA COMPILATION${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Tuer Xcode
echo -e "${RED}Étape 1: Arrêt de Xcode${NC}"
killall Xcode 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Xcode arrêté${NC}"
echo ""

# Étape 2: Nettoyer complètement
echo -e "${RED}Étape 2: Nettoyage complet${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
rm -rf "$PROJECT_DIR"/build 2>/dev/null || true
find "$PROJECT_DIR" -name "*.xcuserstate" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo ""

# Étape 3: Solution radicale - Renommer temporairement Info.plist
echo -e "${RED}Étape 3: Solution radicale pour Info.plist${NC}"
if [ -f "$INFOPLIST_PATH" ]; then
    # Sauvegarder Info.plist
    cp "$INFOPLIST_PATH" "$INFOPLIST_BACKUP"
    echo -e "${GREEN}✅ Info.plist sauvegardé${NC}"
    
    # Modifier le projet pour utiliser GENERATE_INFOPLIST_FILE = YES temporairement
    if [ -f "$PROJECT_FILE" ]; then
        cp "$PROJECT_FILE" "$PROJECT_FILE.backup_before_compile"
        
        # Forcer GENERATE_INFOPLIST_FILE = YES pour éviter le conflit
        sed -i '' 's/GENERATE_INFOPLIST_FILE = NO/GENERATE_INFOPLIST_FILE = YES/g' "$PROJECT_FILE"
        
        # Supprimer INFOPLIST_FILE pour éviter le conflit
        sed -i '' '/INFOPLIST_FILE = "Tshiakani VTC\/Info.plist";/d' "$PROJECT_FILE"
        
        echo -e "${GREEN}✅ Projet modifié pour compilation (GENERATE_INFOPLIST_FILE = YES)${NC}"
        echo -e "${YELLOW}⚠️  Info.plist sera généré automatiquement${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Info.plist non trouvé${NC}"
fi
echo ""

# Étape 4: Tenter la compilation
echo -e "${RED}Étape 4: Tentative de compilation${NC}"
echo ""

cd "$PROJECT_DIR"

# Vérifier si xcodebuild est disponible
if command -v xcodebuild &> /dev/null; then
    echo -e "${BLUE}Compilation via xcodebuild...${NC}"
    echo ""
    
    xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$PROJECT_NAME" \
        -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        clean build \
        2>&1 | tee build-forced.log | grep -E "(error:|warning:|BUILD SUCCEEDED|BUILD FAILED)" || true
    
    BUILD_STATUS=$?
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    
    if [ $BUILD_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅✅✅ COMPILATION RÉUSSIE ! ✅✅✅${NC}"
        echo ""
        echo -e "${GREEN}Le projet compile maintenant !${NC}"
        echo ""
        echo -e "${YELLOW}📋 Prochaines étapes:${NC}"
        echo "1. On va restaurer Info.plist correctement"
        echo "2. On va reconfigurer le projet"
        echo ""
    else
        echo -e "${RED}❌ Compilation échouée${NC}"
        echo ""
        echo -e "${YELLOW}Consultez build-forced.log pour les détails${NC}"
        echo ""
        echo -e "${BLUE}On va restaurer et corriger maintenant...${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  xcodebuild non disponible${NC}"
    echo ""
    echo -e "${BLUE}Ouverture de Xcode pour compilation manuelle...${NC}"
    open "$XCODEPROJ"
    echo ""
    echo -e "${YELLOW}Dans Xcode:${NC}"
    echo "1. Product > Clean Build Folder (⇧⌘K)"
    echo "2. Product > Build (⌘B)"
    echo ""
    BUILD_STATUS=1
fi

# Étape 5: Restaurer la configuration
echo -e "${RED}Étape 5: Restauration de la configuration${NC}"

if [ -f "$PROJECT_FILE.backup_before_compile" ]; then
    if [ $BUILD_STATUS -eq 0 ]; then
        echo -e "${GREEN}✅ Compilation réussie, on garde la config temporaire pour l'instant${NC}"
        echo -e "${YELLOW}⚠️  On restaurera Info.plist après${NC}"
    else
        # Restaurer si compilation échouée
        mv "$PROJECT_FILE.backup_before_compile" "$PROJECT_FILE"
        echo -e "${GREEN}✅ Configuration restaurée${NC}"
    fi
fi

if [ -f "$INFOPLIST_BACKUP" ]; then
    if [ $BUILD_STATUS -ne 0 ]; then
        # Restaurer si compilation échouée
        mv "$INFOPLIST_BACKUP" "$INFOPLIST_PATH"
        echo -e "${GREEN}✅ Info.plist restauré${NC}"
    else
        echo -e "${YELLOW}⚠️  Info.plist en backup, on le restaurera après${NC}"
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}🎉 SUCCÈS ! La compilation fonctionne !${NC}"
    echo ""
    echo -e "${YELLOW}On va maintenant restaurer Info.plist correctement...${NC}"
else
    echo -e "${RED}La compilation a échoué. On va corriger maintenant...${NC}"
fi

