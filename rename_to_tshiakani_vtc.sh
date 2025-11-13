#!/bin/bash

# Script de renommage complet du projet : "Tshiakani VTC" -> "Tshiakani VTC"
# Usage: ./rename_to_tshiakani_vtc.sh

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ancien et nouveau noms
OLD_NAME="Tshiakani VTC"
OLD_NAME_NO_SPACE="TshiakaniVTC"
OLD_NAME_CAMEL="tshiakaniVTC"
OLD_NAME_UPPER="TSHIAKANI_VTC"
OLD_BUNDLE="optimacode.com.tshiakani-vtc"
OLD_BUNDLE_TESTS="optimacode.com.tshiakani-vtcTests"
OLD_BUNDLE_UITESTS="optimacode.com.tshiakani-vtcUITests"

NEW_NAME="Tshiakani VTC"
NEW_NAME_NO_SPACE="TshiakaniVTC"
NEW_NAME_CAMEL="tshiakaniVTC"
NEW_NAME_UPPER="TSHIAKANI_VTC"
NEW_BUNDLE="com.bruno.tshiakaniVTC"
NEW_BUNDLE_TESTS="com.bruno.tshiakaniVTCTests"
NEW_BUNDLE_UITESTS="com.bruno.tshiakaniVTCUITests"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}🚀 Début du renommage du projet${NC}"
echo -e "${YELLOW}Ancien nom: ${OLD_NAME}${NC}"
echo -e "${YELLOW}Nouveau nom: ${NEW_NAME}${NC}"
echo ""

# Fonction pour remplacer dans un fichier
replace_in_file() {
    local file="$1"
    if [ -f "$file" ]; then
        sed -i '' "s/${OLD_NAME}/${NEW_NAME}/g" "$file"
        sed -i '' "s/${OLD_NAME_NO_SPACE}/${NEW_NAME_NO_SPACE}/g" "$file"
        sed -i '' "s/${OLD_NAME_CAMEL}/${NEW_NAME_CAMEL}/g" "$file"
        sed -i '' "s/${OLD_NAME_UPPER}/${NEW_NAME_UPPER}/g" "$file"
        sed -i '' "s/${OLD_BUNDLE}/${NEW_BUNDLE}/g" "$file"
        sed -i '' "s/${OLD_BUNDLE_TESTS}/${NEW_BUNDLE_TESTS}/g" "$file"
        sed -i '' "s/${OLD_BUNDLE_UITESTS}/${NEW_BUNDLE_UITESTS}/g" "$file"
        echo -e "${GREEN}✓${NC} Modifié: $file"
    fi
}

# Fonction pour renommer un fichier/dossier
rename_file_or_dir() {
    local old_path="$1"
    local new_path="$2"
    if [ -e "$old_path" ]; then
        mv "$old_path" "$new_path"
        echo -e "${GREEN}✓${NC} Renommé: $old_path -> $new_path"
    fi
}

# 1. Renommer les dossiers principaux
echo -e "${YELLOW}📁 Étape 1: Renommage des dossiers...${NC}"
cd "$PROJECT_DIR"

if [ -d "Tshiakani VTC" ]; then
    rename_file_or_dir "Tshiakani VTC" "Tshiakani VTC"
fi

if [ -d "Tshiakani VTCTests" ]; then
    rename_file_or_dir "Tshiakani VTCTests" "TshiakaniVTCTests"
fi

if [ -d "Tshiakani VTCUITests" ]; then
    rename_file_or_dir "Tshiakani VTCUITests" "TshiakaniVTCUITests"
fi

if [ -d "Tshiakani VTC.xcodeproj" ]; then
    rename_file_or_dir "Tshiakani VTC.xcodeproj" "Tshiakani VTC.xcodeproj"
fi

# 2. Renommer les fichiers Swift principaux
echo -e "${YELLOW}📝 Étape 2: Renommage des fichiers Swift...${NC}"

if [ -f "Tshiakani VTC/TshiakaniVTCApp.swift" ]; then
    rename_file_or_dir "Tshiakani VTC/TshiakaniVTCApp.swift" "Tshiakani VTC/TshiakaniVTCApp.swift"
fi

# 3. Mettre à jour le fichier project.pbxproj
echo -e "${YELLOW}⚙️  Étape 3: Mise à jour du projet Xcode...${NC}"

if [ -f "Tshiakani VTC.xcodeproj/project.pbxproj" ]; then
    replace_in_file "Tshiakani VTC.xcodeproj/project.pbxproj"
    
    # Remplacer les chemins spécifiques dans project.pbxproj
    sed -i '' "s|Tshiakani VTC|Tshiakani VTC|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|Tshiakani VTCTests|TshiakaniVTCTests|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|Tshiakani VTCUITests|TshiakaniVTCUITests|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|TshiakaniVTCApp|TshiakaniVTCApp|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = \"${OLD_BUNDLE}\"|PRODUCT_BUNDLE_IDENTIFIER = \"${NEW_BUNDLE}\"|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = \"${OLD_BUNDLE_TESTS}\"|PRODUCT_BUNDLE_IDENTIFIER = \"${NEW_BUNDLE_TESTS}\"|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = \"${OLD_BUNDLE_UITESTS}\"|PRODUCT_BUNDLE_IDENTIFIER = \"${NEW_BUNDLE_UITESTS}\"|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|TEST_HOST = \"\$(BUILT_PRODUCTS_DIR)/Tshiakani VTC.app|TEST_HOST = \"\$(BUILT_PRODUCTS_DIR)/Tshiakani VTC.app|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|TEST_TARGET_NAME = \"Tshiakani VTC\"|TEST_TARGET_NAME = \"Tshiakani VTC\"|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
    sed -i '' "s|PRODUCT_NAME = \"${OLD_NAME}\"|PRODUCT_NAME = \"${NEW_NAME}\"|g" "Tshiakani VTC.xcodeproj/project.pbxproj"
fi

# 4. Mettre à jour tous les fichiers Swift
echo -e "${YELLOW}📄 Étape 4: Mise à jour des fichiers Swift...${NC}"

find "Tshiakani VTC" -type f -name "*.swift" | while read file; do
    replace_in_file "$file"
done

# Mettre à jour le nom de la structure App dans le fichier principal
if [ -f "Tshiakani VTC/TshiakaniVTCApp.swift" ]; then
    sed -i '' "s/struct TshiakaniVTCApp/struct TshiakaniVTCApp/g" "Tshiakani VTC/TshiakaniVTCApp.swift"
    sed -i '' "s|//  TshiakaniVTCApp.swift|//  TshiakaniVTCApp.swift|g" "Tshiakani VTC/TshiakaniVTCApp.swift"
    sed -i '' "s|//  Tshiakani VTC|//  Tshiakani VTC|g" "TshiakaniVTCApp.swift"
fi

# 5. Mettre à jour les fichiers de test
echo -e "${YELLOW}🧪 Étape 5: Mise à jour des fichiers de test...${NC}"

if [ -d "TshiakaniVTCTests" ]; then
    find "TshiakaniVTCTests" -type f -name "*.swift" | while read file; do
        replace_in_file "$file"
    done
fi

if [ -d "TshiakaniVTCUITests" ]; then
    find "TshiakaniVTCUITests" -type f -name "*.swift" | while read file; do
        replace_in_file "$file"
    done
fi

# 6. Mettre à jour les fichiers de configuration
echo -e "${YELLOW}⚙️  Étape 6: Mise à jour des fichiers de configuration...${NC}"

# Mettre à jour les fichiers Info.plist s'ils existent
find . -name "Info.plist" -type f | while read file; do
    replace_in_file "$file"
done

# Mettre à jour les fichiers de schéma Xcode
find "Tshiakani VTC.xcodeproj" -name "*.plist" -type f | while read file; do
    replace_in_file "$file"
done

# 7. Mettre à jour les fichiers de documentation et configuration
echo -e "${YELLOW}📚 Étape 7: Mise à jour de la documentation...${NC}"

find . -type f \( -name "*.md" -o -name "*.json" -o -name "*.txt" -o -name "*.sh" \) ! -path "*/node_modules/*" ! -path "*/.git/*" | while read file; do
    replace_in_file "$file"
done

# 8. Mettre à jour les fichiers backend (si nécessaire)
echo -e "${YELLOW}🔧 Étape 8: Mise à jour du backend...${NC}"

if [ -d "backend" ]; then
    find "backend" -type f \( -name "*.js" -o -name "*.json" -o -name "*.md" \) ! -path "*/node_modules/*" | while read file; do
        replace_in_file "$file"
    done
fi

# 9. Mettre à jour les fichiers admin-dashboard
echo -e "${YELLOW}🎨 Étape 9: Mise à jour du dashboard admin...${NC}"

if [ -d "admin-dashboard" ]; then
    find "admin-dashboard" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.json" -o -name "*.html" -o -name "*.md" \) ! -path "*/node_modules/*" | while read file; do
        replace_in_file "$file"
    done
fi

# 10. Nettoyer le cache Xcode
echo -e "${YELLOW}🧹 Étape 10: Nettoyage du cache Xcode...${NC}"

# Supprimer les dossiers de build
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
echo -e "${GREEN}✓${NC} Cache Xcode nettoyé"

# 11. Mettre à jour Git (sans perdre l'historique)
echo -e "${YELLOW}📦 Étape 11: Mise à jour Git...${NC}"

# Git détectera automatiquement les renommages
echo -e "${GREEN}✓${NC} Git prêt pour le commit"

echo ""
echo -e "${GREEN}✅ Renommage terminé avec succès !${NC}"
echo ""
echo -e "${YELLOW}📋 Prochaines étapes :${NC}"
echo "1. Ouvrez le projet dans Xcode : Tshiakani VTC.xcodeproj"
echo "2. Vérifiez le Bundle Identifier dans les paramètres du projet"
echo "3. Nettoyez le build : Product > Clean Build Folder (⇧⌘K)"
echo "4. Compilez le projet : Product > Build (⌘B)"
echo "5. Vérifiez que tout fonctionne correctement"
echo "6. Committez les changements : git add -A && git commit -m 'Rename project to Tshiakani VTC'"
echo ""
echo -e "${YELLOW}⚠️  Important :${NC}"
echo "- Vérifiez les certificats et provisioning profiles dans Xcode"
echo "- Mettez à jour le Bundle Identifier dans le Developer Portal si nécessaire"
echo "- Testez l'application complètement avant de déployer"

