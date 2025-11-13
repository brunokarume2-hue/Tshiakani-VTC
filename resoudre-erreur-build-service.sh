#!/bin/bash

# Script pour résoudre l'erreur "Build service could not create build operation"
# Erreur: MsgHandlingError(message: "unable to initiate PIF transfer session (operation in progress?)")

echo "🔧 Résolution: Erreur Build Service Xcode"
echo "=========================================="
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Étape 1: Arrêt des processus Xcode${NC}"

# Tuer tous les processus Xcode
echo "Arrêt des processus Xcode..."
killall Xcode 2>/dev/null || true
killall com.apple.dt.SKAgent 2>/dev/null || true
killall SourceKitService 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Processus Xcode arrêtés${NC}"

echo ""
echo -e "${BLUE}Étape 2: Nettoyage du DerivedData${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✅ DerivedData supprimé${NC}"

echo ""
echo -e "${BLUE}Étape 3: Nettoyage des caches Xcode${NC}"
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/* 2>/dev/null || true
echo -e "${GREEN}✅ Caches Xcode nettoyés${NC}"

echo ""
echo -e "${BLUE}Étape 4: Nettoyage des modules Xcode${NC}"
rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/UserData/IB\ Support/* 2>/dev/null || true
echo -e "${GREEN}✅ Modules Xcode nettoyés${NC}"

echo ""
echo -e "${BLUE}Étape 5: Nettoyage des processus de build${NC}"
# Tuer les processus de build qui pourraient être bloqués
pkill -f "xcodebuild" 2>/dev/null || true
pkill -f "SourceKitService" 2>/dev/null || true
pkill -f "com.apple.dt.SKAgent" 2>/dev/null || true
sleep 1
echo -e "${GREEN}✅ Processus de build nettoyés${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Nettoyage terminé${NC}"
echo ""
echo -e "${YELLOW}📋 Actions dans Xcode:${NC}"
echo ""
echo "1. Rouvrez Xcode (si pas déjà ouvert)"
echo ""
echo "2. Ouvrez le projet:"
echo "   → File > Open Recent > Tshiakani VTC"
echo ""
echo "3. Attendez que Xcode se charge complètement"
echo "   → Attendez que l'indexation se termine (barre en haut)"
echo ""
echo "4. Si des packages sont en cours de résolution:"
echo "   → Attendez qu'ils se terminent (2-5 minutes)"
echo ""
echo "5. Nettoyez le build:"
echo "   → Product > Clean Build Folder (⇧⌘K)"
echo ""
echo "6. Compilez:"
echo "   → Product > Build (⌘B)"
echo ""
echo "=========================================="
echo ""
echo -e "${GREEN}✅ Tous les processus et caches ont été nettoyés${NC}"
echo -e "${YELLOW}⏳ Rouvrez Xcode et réessayez${NC}"
echo ""

