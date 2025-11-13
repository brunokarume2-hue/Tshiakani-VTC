#!/bin/bash
echo "🧹 Nettoyage complet du build..."
echo ""

# Nettoyer DerivedData
echo "1. Nettoyage du DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-* 2>/dev/null
echo "   ✅ DerivedData nettoyé"

# Nettoyer les caches Xcode
echo "2. Nettoyage des caches Xcode..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/* 2>/dev/null
echo "   ✅ Caches Xcode nettoyés"

# Nettoyer les caches SwiftPM
echo "3. Nettoyage des caches SwiftPM..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null
echo "   ✅ Caches SwiftPM nettoyés"

echo ""
echo "✅ Nettoyage terminé!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrez Xcode"
echo "   2. Product > Clean Build Folder (⇧⌘K)"
echo "   3. Product > Build (⌘B)"
