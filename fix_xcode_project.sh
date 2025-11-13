#!/bin/bash

# Script pour forcer Xcode à reconnaître les fichiers de ressources
# Ce script nettoie le cache Xcode et force la recompilation

echo "🔧 Nettoyage du projet Xcode..."

# Nettoyer le build folder
cd "$(dirname "$0")"
xcodebuild clean -project "Tshiakani VTC.xcodeproj" -scheme "Tshiakani VTC" 2>/dev/null

# Supprimer les caches Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null

echo "✅ Cache nettoyé"
echo ""
echo "📝 Vérification des fichiers de ressources..."

# Vérifier que les fichiers existent
FILES=(
    "Tshiakani VTC/Resources/Colors/AppColors.swift"
    "Tshiakani VTC/Resources/Fonts/AppTypography.swift"
    "Tshiakani VTC/Resources/DesignSystem.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
    else
        echo "❌ $file manquant"
    fi
done

echo ""
echo "🎯 Pour finaliser :"
echo "1. Ouvrez le projet dans Xcode"
echo "2. Product → Clean Build Folder (⇧⌘K)"
echo "3. Product → Build (⌘B)"
echo ""
echo "Les fichiers devraient maintenant être reconnus."

