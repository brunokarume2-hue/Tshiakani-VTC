#!/bin/bash

# Script pour réinstaller les packages GoogleMaps et GooglePlaces
# Ce script nettoie les caches et force la résolution des packages Swift

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj"
WORKSPACE_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.xcworkspace"

echo "🔧 Réinstallation des packages GoogleMaps et GooglePlaces"
echo "=================================================="
echo ""

# 1. Nettoyer les caches Swift Package Manager
echo "📦 Étape 1: Nettoyage des caches Swift Package Manager..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
echo "✅ Caches nettoyés"
echo ""

# 2. Supprimer Package.resolved s'il existe
echo "📦 Étape 2: Suppression de Package.resolved..."
find "${PROJECT_DIR}" -name "Package.resolved" -type f -delete 2>/dev/null || true
echo "✅ Package.resolved supprimé"
echo ""

# 3. Nettoyer le projet Xcode
echo "📦 Étape 3: Nettoyage du projet Xcode..."
cd "${PROJECT_DIR}"
xcodebuild clean -project "Tshiakani VTC.xcodeproj" -scheme "Tshiakani VTC" 2>/dev/null || echo "⚠️  Nettoyage partiel (peut être ignoré)"
echo "✅ Projet nettoyé"
echo ""

# 4. Résoudre les packages avec xcodebuild
echo "📦 Étape 4: Résolution des packages Swift..."
echo "   Cette étape peut prendre quelques minutes..."
xcodebuild -resolvePackageDependencies -project "Tshiakani VTC.xcodeproj" 2>&1 | tee /tmp/xcode-package-resolution.log || {
    echo "⚠️  Résolution automatique échouée, mais cela peut être normal"
    echo "   Les packages seront résolus lors de la prochaine ouverture dans Xcode"
}
echo ""

# 5. Vérifier que les packages sont bien référencés
echo "📦 Étape 5: Vérification de la configuration..."
if grep -q "ios-maps-sdk" "${PROJECT_PATH}/project.pbxproj" && grep -q "ios-places-sdk" "${PROJECT_PATH}/project.pbxproj"; then
    echo "✅ Les packages GoogleMaps et GooglePlaces sont bien configurés dans le projet"
else
    echo "❌ Erreur: Les packages ne sont pas correctement configurés"
    exit 1
fi
echo ""

echo "✅ Réinstallation terminée!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrez le projet dans Xcode"
echo "   2. Allez dans File > Packages > Resolve Package Versions"
echo "   3. Attendez que les packages soient téléchargés et résolus"
echo "   4. Si nécessaire, allez dans File > Packages > Reset Package Caches"
echo "   5. Compilez le projet (Cmd+B)"
echo ""
echo "🔗 URLs des packages:"
echo "   - GoogleMaps: https://github.com/googlemaps/ios-maps-sdk"
echo "   - GooglePlaces: https://github.com/googlemaps/ios-places-sdk"
echo ""

