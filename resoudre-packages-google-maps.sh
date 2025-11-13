#!/bin/bash

# Script pour résoudre les packages Google Maps manquants

set -e

echo "🔧 Résolution des Packages Google Maps"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Tshiakani VTC"

echo "📁 Répertoire du projet: $PROJECT_DIR"
echo ""

# 1. Supprimer Package.resolved
echo "📦 Suppression de Package.resolved..."
PACKAGE_RESOLVED="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    BACKUP="${PACKAGE_RESOLVED}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PACKAGE_RESOLVED" "$BACKUP"
    rm -f "$PACKAGE_RESOLVED"
    echo "   ✅ Package.resolved supprimé (sauvegarde: $BACKUP)"
else
    echo "   ℹ️  Package.resolved n'existe pas"
fi
echo ""

# 2. Nettoyer les caches
echo "🧹 Nettoyage des caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null && echo "   ✅ Cache SwiftPM nettoyé" || echo "   ℹ️  Cache SwiftPM déjà nettoyé"
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null && echo "   ✅ DerivedData nettoyé" || echo "   ℹ️  DerivedData déjà nettoyé"
echo ""

# 3. Vérifier les packages dans project.pbxproj
echo "🔍 Vérification de la configuration..."
if grep -q "ios-maps-sdk" "$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj" && \
   grep -q "ios-places-sdk" "$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj"; then
    echo "   ✅ Les packages sont référencés dans project.pbxproj"
else
    echo "   ⚠️  Les packages ne sont pas référencés dans project.pbxproj"
    echo "   → Vous devrez les ajouter via Xcode"
fi
echo ""

echo "✅ Nettoyage terminé!"
echo ""
echo "📋 Prochaines étapes dans Xcode:"
echo ""
echo "   1. Ouvrez le projet dans Xcode"
echo "   2. File > Packages > Reset Package Caches"
echo "   3. File > Packages > Resolve Package Versions"
echo "   4. Attendez que les packages soient résolus (barre de progression)"
echo "   5. Vérifiez dans Package Dependencies que vous voyez:"
echo "      - ios-maps-sdk"
echo "      - ios-places-sdk"
echo "   6. Target > General > Frameworks, Libraries, and Embedded Content"
echo "      - Vérifiez que GoogleMaps et GooglePlaces sont présents"
echo "      - Si absents, cliquez sur '+' et ajoutez-les"
echo "   7. Product > Clean Build Folder (⇧⌘K)"
echo "   8. Product > Build (⌘B)"
echo ""
echo "📖 Guide complet: RESOLUTION_PACKAGES_GOOGLE_MAPS.md"
echo ""

