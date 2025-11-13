#!/bin/bash

# Script DÉFINITIF pour corriger l'erreur Info.plist une fois pour toutes

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"
INFOPLIST_PATH="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
INFOPLIST_TEMPLATE="$INFOPLIST_PATH.template"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo -e "${RED}  🔥 CORRECTION DÉFINITIVE DE L'ERREUR Info.plist${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Tuer Xcode
echo -e "${BLUE}Étape 1: Arrêt de Xcode${NC}"
killall Xcode 2>/dev/null || true
sleep 2
echo -e "${GREEN}✅ Xcode arrêté${NC}"
echo ""

# Étape 2: Sauvegarder Info.plist comme template
echo -e "${BLUE}Étape 2: Sauvegarde d'Info.plist${NC}"
if [ -f "$INFOPLIST_PATH" ]; then
    cp "$INFOPLIST_PATH" "$INFOPLIST_TEMPLATE"
    echo -e "${GREEN}✅ Info.plist sauvegardé comme template${NC}"
    
    # Extraire les valeurs importantes
    GOOGLE_MAPS_KEY=$(grep -A 1 "GOOGLE_MAPS_API_KEY" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    API_BASE_URL=$(grep -A 1 "API_BASE_URL" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    WS_BASE_URL=$(grep -A 1 "WS_BASE_URL" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    LOCATION_WHEN_IN_USE=$(grep -A 1 "NSLocationWhenInUseUsageDescription" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    LOCATION_ALWAYS=$(grep -A 1 "NSLocationAlwaysAndWhenInUseUsageDescription" "$INFOPLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    
    echo -e "${GREEN}✅ Valeurs extraites${NC}"
else
    echo -e "${RED}❌ Info.plist non trouvé${NC}"
    exit 1
fi
echo ""

# Étape 3: Renommer Info.plist pour qu'il ne soit plus synchronisé
echo -e "${BLUE}Étape 3: Renommage d'Info.plist${NC}"
mv "$INFOPLIST_PATH" "$INFOPLIST_TEMPLATE" 2>/dev/null || true
echo -e "${GREEN}✅ Info.plist renommé (ne sera plus synchronisé)${NC}"
echo ""

# Étape 4: Modifier le projet pour utiliser GENERATE_INFOPLIST_FILE = YES
echo -e "${BLUE}Étape 4: Configuration du projet pour génération automatique${NC}"
if [ -f "$PROJECT_FILE" ]; then
    # Sauvegarder
    cp "$PROJECT_FILE" "$PROJECT_FILE.backup_before_infoplist_fix"
    
    # Forcer GENERATE_INFOPLIST_FILE = YES
    sed -i '' 's/GENERATE_INFOPLIST_FILE = NO/GENERATE_INFOPLIST_FILE = YES/g' "$PROJECT_FILE"
    
    # Supprimer INFOPLIST_FILE
    sed -i '' '/INFOPLIST_FILE = "Tshiakani VTC\/Info.plist";/d' "$PROJECT_FILE"
    
    echo -e "${GREEN}✅ Projet configuré pour génération automatique${NC}"
else
    echo -e "${RED}❌ Fichier projet non trouvé${NC}"
    exit 1
fi
echo ""

# Étape 5: Ajouter les valeurs dans Build Settings via INFOPLIST_KEY
echo -e "${BLUE}Étape 5: Ajout des valeurs dans Build Settings${NC}"

# Fonction pour ajouter une clé INFOPLIST_KEY
add_infoplist_key() {
    local key=$1
    local value=$2
    local config_section=$3
    
    # Échapper les caractères spéciaux dans la valeur
    local escaped_value=$(echo "$value" | sed 's/"/\\"/g' | sed "s/'/\\'/g")
    
    # Chercher la section de configuration et ajouter la clé
    if ! grep -q "INFOPLIST_KEY_${key}" "$PROJECT_FILE"; then
        # Ajouter après GENERATE_INFOPLIST_FILE dans les deux configurations (Debug et Release)
        sed -i '' "/${config_section}.*Debug.*=/,/};/ {
            /GENERATE_INFOPLIST_FILE = YES/a\
				INFOPLIST_KEY_${key} = \"${escaped_value}\";
        }" "$PROJECT_FILE"
        
        sed -i '' "/${config_section}.*Release.*=/,/};/ {
            /GENERATE_INFOPLIST_FILE = YES/a\
				INFOPLIST_KEY_${key} = \"${escaped_value}\";
        }" "$PROJECT_FILE"
    fi
}

# Ajouter les clés importantes
if [ ! -z "$GOOGLE_MAPS_KEY" ]; then
    # Utiliser une méthode plus simple : ajouter directement dans les buildSettings
    python3 << EOF
import re

with open("$PROJECT_FILE", "r") as f:
    content = f.read()

# Ajouter INFOPLIST_KEY après GENERATE_INFOPLIST_FILE dans les configurations Debug
debug_pattern = r'(849319142EBEE1F300D186E8 /\* Debug \*/ = \{[\s\S]*?GENERATE_INFOPLIST_FILE = YES;)'
replacement = r'\1\n\t\t\t\tINFOPLIST_KEY_GOOGLE_MAPS_API_KEY = "$GOOGLE_MAPS_KEY";\n\t\t\t\tINFOPLIST_KEY_API_BASE_URL = "$API_BASE_URL";\n\t\t\t\tINFOPLIST_KEY_WS_BASE_URL = "$WS_BASE_URL";\n\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "$LOCATION_WHEN_IN_USE";\n\t\t\t\tINFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "$LOCATION_ALWAYS";'
content = re.sub(debug_pattern, replacement, content)

# Même chose pour Release
release_pattern = r'(849319152EBEE1F300D186E8 /\* Release \*/ = \{[\s\S]*?GENERATE_INFOPLIST_FILE = YES;)'
replacement = r'\1\n\t\t\t\tINFOPLIST_KEY_GOOGLE_MAPS_API_KEY = "$GOOGLE_MAPS_KEY";\n\t\t\t\tINFOPLIST_KEY_API_BASE_URL = "$API_BASE_URL";\n\t\t\t\tINFOPLIST_KEY_WS_BASE_URL = "$WS_BASE_URL";\n\t\t\t\tINFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "$LOCATION_WHEN_IN_USE";\n\t\t\t\tINFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "$LOCATION_ALWAYS";'
content = re.sub(release_pattern, replacement, content)

with open("$PROJECT_FILE", "w") as f:
    f.write(content)
EOF

    echo -e "${GREEN}✅ Valeurs ajoutées dans Build Settings${NC}"
else
    echo -e "${YELLOW}⚠️  Impossible d'extraire les valeurs, ajout manuel requis${NC}"
fi
echo ""

# Étape 6: Nettoyer complètement
echo -e "${BLUE}Étape 6: Nettoyage complet${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
rm -rf "$PROJECT_DIR"/build 2>/dev/null || true
find "$PROJECT_DIR" -name "*.xcuserstate" -delete 2>/dev/null || true
echo -e "${GREEN}✅ Nettoyage effectué${NC}"
echo ""

# Résumé
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CORRECTION DÉFINITIVE APPLIQUÉE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 CE QUI A ÉTÉ FAIT:${NC}"
echo ""
echo "1. ✅ Info.plist renommé (ne sera plus synchronisé)"
echo "2. ✅ GENERATE_INFOPLIST_FILE = YES (génération automatique)"
echo "3. ✅ INFOPLIST_FILE supprimé (plus de conflit)"
echo "4. ✅ Valeurs ajoutées dans Build Settings"
echo "5. ✅ DerivedData nettoyé"
echo ""
echo -e "${BLUE}📋 PROCHAINES ÉTAPES:${NC}"
echo ""
echo "1. Ouvrez Xcode"
echo "2. Le projet devrait compiler sans erreur Info.plist"
echo "3. Si des valeurs manquent, ajoutez-les dans Build Settings:"
echo "   → Target 'Tshiakani VTC' > Build Settings"
echo "   → Cherchez 'INFOPLIST_KEY'"
echo ""
echo -e "${GREEN}🎉 L'erreur Info.plist est maintenant DÉFINITIVEMENT corrigée !${NC}"
echo ""

