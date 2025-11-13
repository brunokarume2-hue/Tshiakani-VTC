#!/bin/bash

# Script pour analyser et corriger les erreurs de compilation courantes

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  🔍 ANALYSE ET CORRECTION DES ERREURS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier les erreurs communes
echo -e "${BLUE}Vérification des erreurs communes...${NC}"
echo ""

# Erreur 1: Fichiers manquants dans le target
echo -e "${YELLOW}1. Vérification des fichiers essentiels...${NC}"

FICHIERS_IMPORTANTS=(
    "TshiakaniVTCApp.swift"
    "ContentView.swift"
    "Models/User.swift"
    "Models/Ride.swift"
    "Models/Location.swift"
    "Services/APIService.swift"
    "Services/LocationService.swift"
)

for fichier in "${FICHIERS_IMPORTANTS[@]}"; do
    chemin="$PROJECT_DIR/$PROJECT_NAME/$fichier"
    if [ -f "$chemin" ]; then
        echo -e "${GREEN}   ✅ $fichier${NC}"
    else
        echo -e "${RED}   ❌ $fichier MANQUANT${NC}"
    fi
done
echo ""

# Erreur 2: Vérifier Info.plist
echo -e "${YELLOW}2. Vérification de Info.plist...${NC}"
if [ -f "$PROJECT_DIR/$PROJECT_NAME/Info.plist" ]; then
    echo -e "${GREEN}   ✅ Info.plist existe${NC}"
    
    # Vérifier les clés importantes
    if grep -q "GOOGLE_MAPS_API_KEY" "$PROJECT_DIR/$PROJECT_NAME/Info.plist"; then
        echo -e "${GREEN}   ✅ GOOGLE_MAPS_API_KEY présent${NC}"
    else
        echo -e "${YELLOW}   ⚠️  GOOGLE_MAPS_API_KEY manquant${NC}"
    fi
else
    echo -e "${RED}   ❌ Info.plist MANQUANT${NC}"
fi
echo ""

# Erreur 3: Vérifier la configuration du projet
echo -e "${YELLOW}3. Vérification de la configuration du projet...${NC}"
PROJECT_FILE="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj"

if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$PROJECT_FILE"; then
    echo -e "${GREEN}   ✅ GENERATE_INFOPLIST_FILE = NO${NC}"
else
    echo -e "${YELLOW}   ⚠️  GENERATE_INFOPLIST_FILE n'est pas NO${NC}"
fi

if grep -q 'INFOPLIST_FILE = "Tshiakani VTC/Info.plist"' "$PROJECT_FILE"; then
    echo -e "${GREEN}   ✅ INFOPLIST_FILE configuré${NC}"
else
    echo -e "${YELLOW}   ⚠️  INFOPLIST_FILE non configuré${NC}"
fi
echo ""

# Instructions pour obtenir les erreurs
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}📋 POUR ANALYSER LES ERREURS SPÉCIFIQUES:${NC}"
echo ""
echo -e "${BLUE}1. Dans Xcode, ouvrez le panneau d'erreurs:${NC}"
echo "   → Appuyez sur ⌘5 (ou View > Navigators > Show Issue Navigator)"
echo ""
echo -e "${BLUE}2. Copiez les messages d'erreur et envoyez-les moi${NC}"
echo "   → Ou notez les numéros de ligne des erreurs"
echo ""
echo -e "${BLUE}3. Erreurs communes à vérifier:${NC}"
echo "   → 'Cannot find type X in scope'"
echo "   → 'No such module X'"
echo "   → 'Missing required module X'"
echo "   → 'Use of unresolved identifier X'"
echo ""
echo -e "${BLUE}4. Je corrigerai automatiquement une fois que vous m'aurez${NC}"
echo "   donné les messages d'erreur spécifiques"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Ouvrir Xcode pour faciliter
echo -e "${BLUE}Ouverture de Xcode...${NC}"
open "$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
echo -e "${GREEN}✅ Xcode ouvert${NC}"
echo ""

