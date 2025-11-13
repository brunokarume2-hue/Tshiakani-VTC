#!/bin/bash

# Script pour corriger les erreurs de build Xcode
# Usage: ./fix-build-errors.sh

echo "🔧 Correction des erreurs de build Xcode..."
echo ""

# 1. Supprimer les DerivedData
echo "📦 Suppression des DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null
echo "✅ DerivedData supprimé"
echo ""

# 2. Nettoyer les modules Swift
echo "🧹 Nettoyage des modules Swift..."
find "/Users/admin/Documents/Tshiakani VTC" -name "*.swiftmodule" -delete 2>/dev/null
find "/Users/admin/Documents/Tshiakani VTC" -name "*.swiftdoc" -delete 2>/dev/null
echo "✅ Modules Swift nettoyés"
echo ""

# 3. Vérifier les fichiers principaux
echo "📋 Vérification des fichiers principaux..."
PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC"

FILES_TO_CHECK=(
    "Models/Location.swift"
    "Models/User.swift"
    "Models/Ride.swift"
    "Models/VehicleType.swift"
    "Resources/Colors/AppColors.swift"
    "Resources/Fonts/AppTypography.swift"
    "Resources/DesignSystem.swift"
    "Services/APIService.swift"
    "Services/LocationService.swift"
    "ViewModels/AuthViewModel.swift"
    "ViewModels/RideViewModel.swift"
    "ViewModels/AuthManager.swift"
)

MISSING_FILES=()

for file in "${FILES_TO_CHECK[@]}"; do
    if [ ! -f "$PROJECT_DIR/$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✅ Tous les fichiers principaux existent"
else
    echo "⚠️ Fichiers manquants:"
    for file in "${MISSING_FILES[@]}"; do
        echo "   - $file"
    done
fi
echo ""

echo "✅ Nettoyage terminé!"
echo ""
echo "📝 Prochaines étapes dans Xcode:"
echo "   1. Ouvrez le projet dans Xcode"
echo "   2. Product > Clean Build Folder (⇧⌘K)"
echo "   3. Vérifiez que tous les fichiers sont dans le target 'Tshiakani VTC'"
echo "   4. Product > Build (⌘B)"
echo ""
