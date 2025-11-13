#!/bin/bash

# Script pour corriger les 4 erreurs de build
# Usage: ./corriger-4-erreurs-build.sh

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODE_PROJECT="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
INFO_PLIST="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
PACKAGE_RESOLVED="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

echo "🔧 Correction des 4 erreurs de build"
echo "======================================"
echo ""

# Vérifier que le projet existe
if [ ! -d "$XCODE_PROJECT" ]; then
    echo "❌ Erreur: Le projet Xcode n'existe pas à $XCODE_PROJECT"
    exit 1
fi

# 1. Vérifier que Info.plist existe
echo "1️⃣ Vérification de Info.plist..."
if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Info.plist n'existe pas. Création..."
    # Le fichier devrait avoir été créé par le script précédent
    echo "⚠️ Veuillez créer le fichier Info.plist manuellement ou utiliser le template"
    exit 1
else
    echo "✅ Info.plist existe"
fi

# 2. Vérifier que les packages sont résolus
echo ""
echo "2️⃣ Vérification des packages..."
if [ ! -f "$PACKAGE_RESOLVED" ]; then
    echo "⚠️ Package.resolved n'existe pas. Les packages doivent être résolus dans Xcode"
else
    echo "✅ Package.resolved existe"
    # Vérifier que Google Maps et Google Places sont présents
    if grep -q "ios-maps-sdk" "$PACKAGE_RESOLVED"; then
        echo "✅ Package ios-maps-sdk (Google Maps) trouvé"
    else
        echo "❌ Package ios-maps-sdk (Google Maps) non trouvé"
    fi
    
    if grep -q "ios-places-sdk" "$PACKAGE_RESOLVED"; then
        echo "✅ Package ios-places-sdk (Google Places) trouvé"
    else
        echo "❌ Package ios-places-sdk (Google Places) non trouvé"
    fi
fi

# 3. Nettoyer le DerivedData
echo ""
echo "3️⃣ Nettoyage du DerivedData..."
DERIVED_DATA_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -name "Tshiakani_VTC-*" -type d 2>/dev/null || true)
if [ -z "$DERIVED_DATA_DIRS" ]; then
    echo "ℹ️ Aucun DerivedData trouvé"
else
    echo "🗑️ Suppression du DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
    echo "✅ DerivedData supprimé"
fi

# 4. Instructions pour Xcode
echo ""
echo "4️⃣ Instructions pour Xcode:"
echo "============================"
echo ""
echo "Les corrections suivantes doivent être faites MANUELLEMENT dans Xcode:"
echo ""
echo "1. Vérifier Build Settings:"
echo "   - GENERATE_INFOPLIST_FILE = NO"
echo "   - INFOPLIST_FILE = 'Tshiakani VTC/Info.plist'"
echo ""
echo "2. Retirer Info.plist de Copy Bundle Resources:"
echo "   - Target > Build Phases > Copy Bundle Resources"
echo "   - Retirer Info.plist si présent"
echo ""
echo "3. Vérifier les packages:"
echo "   - File > Packages > Reset Package Caches"
echo "   - File > Packages > Resolve Package Versions"
echo ""
echo "4. Vérifier les frameworks liés:"
echo "   - Target > General > Frameworks, Libraries, and Embedded Content"
echo "   - Vérifier que GoogleMaps et GooglePlaces sont présents"
echo ""
echo "5. Nettoyer et compiler:"
echo "   - Product > Clean Build Folder (⇧⌘K)"
echo "   - Product > Build (⌘B)"
echo ""

echo "✅ Script terminé"
echo ""
echo "📋 Consultez CORRECTION_4_ERREURS_BUILD_IMMEDIATE.md pour les instructions détaillées"

