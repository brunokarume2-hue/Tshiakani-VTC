#!/bin/bash

# Script pour nettoyer les caches et forcer la résolution des packages
# Usage: ./nettoyer-et-resoudre-packages.sh

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_NAME="Tshiakani VTC"
XCODE_PROJECT="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
PACKAGE_RESOLVED="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

echo "🧹 Nettoyage des caches et résolution des packages"
echo "=================================================="
echo ""

# Vérifier que le projet existe
if [ ! -d "$XCODE_PROJECT" ]; then
    echo "❌ Erreur: Le projet Xcode n'existe pas à $XCODE_PROJECT"
    exit 1
fi

# 1. Nettoyer le DerivedData
echo "1️⃣ Nettoyage du DerivedData..."
DERIVED_DATA_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -name "Tshiakani_VTC-*" -type d 2>/dev/null || true)
if [ -z "$DERIVED_DATA_DIRS" ]; then
    echo "ℹ️  Aucun DerivedData trouvé"
else
    echo "🗑️  Suppression du DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*
    echo "✅ DerivedData supprimé"
fi

# 2. Nettoyer le ModuleCache
echo ""
echo "2️⃣ Nettoyage du ModuleCache..."
MODULE_CACHE_DIRS=$(find ~/Library/Developer/Xcode/DerivedData -name "ModuleCache.noindex" -type d 2>/dev/null || true)
if [ -z "$MODULE_CACHE_DIRS" ]; then
    echo "ℹ️  Aucun ModuleCache trouvé"
else
    echo "🗑️  Suppression du ModuleCache..."
    find ~/Library/Developer/Xcode/DerivedData -name "ModuleCache.noindex" -type d -exec rm -rf {} + 2>/dev/null || true
    echo "✅ ModuleCache supprimé"
fi

# 3. Vérifier Package.resolved
echo ""
echo "3️⃣ Vérification de Package.resolved..."
if [ ! -f "$PACKAGE_RESOLVED" ]; then
    echo "⚠️  Package.resolved n'existe pas. Les packages doivent être résolus dans Xcode"
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

# 4. Nettoyer les caches Swift Package Manager
echo ""
echo "4️⃣ Nettoyage des caches Swift Package Manager..."
if [ -d "$PROJECT_DIR/.swiftpm" ]; then
    echo "🗑️  Suppression du cache .swiftpm..."
    rm -rf "$PROJECT_DIR/.swiftpm"
    echo "✅ Cache .swiftpm supprimé"
else
    echo "ℹ️  Aucun cache .swiftpm trouvé"
fi

# 5. Instructions pour Xcode
echo ""
echo "5️⃣ Instructions pour Xcode:"
echo "============================"
echo ""
echo "Les actions suivantes doivent être faites MANUELLEMENT dans Xcode:"
echo ""
echo "1. Ouvrir Xcode et le projet"
echo "2. File > Packages > Reset Package Caches"
echo "3. File > Packages > Resolve Package Versions"
echo "4. Attendre que tous les packages soient résolus (barre de progression en bas)"
echo "5. Product > Clean Build Folder (⇧⌘K)"
echo "6. Product > Build (⌘B)"
echo ""
echo "Vérifier que les frameworks sont liés:"
echo "- Target > General > Frameworks, Libraries, and Embedded Content"
echo "- Vérifier que GoogleMaps et GooglePlaces sont présents"
echo ""

echo "✅ Script terminé"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrir Xcode"
echo "   2. Suivre les instructions ci-dessus"
echo "   3. Vérifier que le build réussit"

