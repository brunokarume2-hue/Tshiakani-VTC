#!/bin/bash

# Script pour corriger les erreurs de build Xcode
# - Résout les packages manquants GoogleMaps et GooglePlaces
# - Nettoie le DerivedData pour résoudre les conflits

set -e

echo "🔧 Correction des erreurs de build Xcode..."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Tshiakani VTC"
XCODE_PROJECT="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

echo "📁 Répertoire du projet: $PROJECT_DIR"
echo ""

# 1. Nettoyer le DerivedData
echo "🧹 Nettoyage du DerivedData..."
if [ -d "$DERIVED_DATA_PATH" ]; then
    # Trouver et supprimer le dossier DerivedData pour ce projet
    DERIVED_PROJECT_DIR=$(find "$DERIVED_DATA_PATH" -name "*Tshiakani*" -type d 2>/dev/null | head -1)
    if [ -n "$DERIVED_PROJECT_DIR" ]; then
        echo "   Suppression de: $DERIVED_PROJECT_DIR"
        rm -rf "$DERIVED_PROJECT_DIR"
        echo "   ✅ DerivedData nettoyé"
    else
        echo "   ℹ️  Aucun dossier DerivedData trouvé pour ce projet"
    fi
else
    echo "   ℹ️  Dossier DerivedData n'existe pas"
fi
echo ""

# 2. Nettoyer le cache des packages Swift
echo "📦 Nettoyage du cache des packages Swift..."
if [ -d "$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm" ]; then
    # Supprimer Package.resolved pour forcer la résolution
    PACKAGE_RESOLVED="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    if [ -f "$PACKAGE_RESOLVED" ]; then
        echo "   Sauvegarde de Package.resolved..."
        cp "$PACKAGE_RESOLVED" "$PACKAGE_RESOLVED.backup"
        echo "   ✅ Package.resolved sauvegardé"
    fi
fi
echo ""

# 3. Instructions pour Xcode
echo "📋 Instructions pour résoudre les packages dans Xcode:"
echo ""
echo "   1. Ouvrez le projet dans Xcode"
echo "   2. Allez dans File > Packages > Reset Package Caches"
echo "   3. Allez dans File > Packages > Resolve Package Versions"
echo "   4. Attendez que les packages soient résolus"
echo "   5. Vérifiez que GoogleMaps et GooglePlaces apparaissent dans:"
echo "      - Project Navigator > Package Dependencies"
echo "   6. Sélectionnez le target 'Tshiakani VTC'"
echo "   7. Allez dans l'onglet 'General'"
echo "   8. Vérifiez dans 'Frameworks, Libraries, and Embedded Content':"
echo "      - GoogleMaps doit être présent"
echo "      - GooglePlaces doit être présent"
echo "   9. Si les packages ne sont pas présents, cliquez sur '+' et ajoutez-les"
echo ""
echo "   10. Nettoyez le build: Product > Clean Build Folder (⇧⌘K)"
echo "   11. Compilez: Product > Build (⌘B)"
echo ""

# 4. Vérifier que les packages sont dans project.pbxproj
echo "🔍 Vérification des packages dans project.pbxproj..."
if grep -q "ios-maps-sdk" "$XCODE_PROJECT/project.pbxproj" && grep -q "ios-places-sdk" "$XCODE_PROJECT/project.pbxproj"; then
    echo "   ✅ Les packages sont référencés dans project.pbxproj"
else
    echo "   ⚠️  Les packages ne sont pas référencés dans project.pbxproj"
    echo "   → Vous devrez les ajouter via Xcode: File > Add Package Dependencies..."
fi
echo ""

# 5. Vérifier Info.plist
echo "🔍 Vérification de Info.plist..."
INFO_PLIST="$PROJECT_DIR/$PROJECT_NAME/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    if grep -q "GOOGLE_MAPS_API_KEY" "$INFO_PLIST"; then
        echo "   ✅ GOOGLE_MAPS_API_KEY trouvée dans Info.plist"
    else
        echo "   ⚠️  GOOGLE_MAPS_API_KEY manquante dans Info.plist"
    fi
else
    echo "   ⚠️  Info.plist non trouvé"
fi
echo ""

echo "✅ Nettoyage terminé!"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Ouvrez Xcode"
echo "   2. Suivez les instructions ci-dessus pour résoudre les packages"
echo "   3. Nettoyez et compilez le projet"
echo ""

