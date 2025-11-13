#!/bin/bash

# Script pour résoudre les problèmes de swift-protobuf

set -e

echo "🔧 Résolution des problèmes swift-protobuf..."
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Tshiakani VTC"

echo "📁 Répertoire du projet: $PROJECT_DIR"
echo ""

# 1. Nettoyer le cache des packages Swift
echo "🧹 Nettoyage du cache des packages Swift..."
if [ -d "$HOME/Library/Caches/org.swift.swiftpm" ]; then
    rm -rf "$HOME/Library/Caches/org.swift.swiftpm"
    echo "   ✅ Cache des packages Swift supprimé"
else
    echo "   ℹ️  Cache des packages Swift n'existe pas"
fi
echo ""

# 2. Nettoyer le DerivedData
echo "🧹 Nettoyage du DerivedData..."
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"
if [ -d "$DERIVED_DATA_PATH" ]; then
    DERIVED_PROJECT_DIRS=$(find "$DERIVED_DATA_PATH" -name "*Tshiakani*" -type d -maxdepth 1 2>/dev/null)
    if [ -n "$DERIVED_PROJECT_DIRS" ]; then
        echo "$DERIVED_PROJECT_DIRS" | while read -r dir; do
            echo "   Suppression de: $dir"
            rm -rf "$dir" 2>/dev/null || echo "   ⚠️  Certains fichiers sont verrouillés (fermez Xcode et réessayez)"
        done
        echo "   ✅ DerivedData nettoyé (ou partiellement nettoyé)"
    else
        echo "   ℹ️  Aucun dossier DerivedData trouvé pour ce projet"
    fi
else
    echo "   ℹ️  Dossier DerivedData n'existe pas"
fi
echo ""

# 3. Sauvegarder et supprimer Package.resolved
echo "📦 Gestion de Package.resolved..."
PACKAGE_RESOLVED="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    BACKUP_FILE="${PACKAGE_RESOLVED}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PACKAGE_RESOLVED" "$BACKUP_FILE"
    echo "   ✅ Package.resolved sauvegardé: $BACKUP_FILE"
    rm -f "$PACKAGE_RESOLVED"
    echo "   ✅ Package.resolved supprimé (sera régénéré par Xcode)"
else
    echo "   ℹ️  Package.resolved n'existe pas"
fi
echo ""

# 4. Nettoyer le cache SwiftPM dans le projet
echo "🧹 Nettoyage du cache SwiftPM du projet..."
SWIFTPM_DIR="$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"
if [ -d "$SWIFTPM_DIR" ]; then
    # Supprimer seulement le cache, pas Package.resolved (déjà supprimé)
    find "$SWIFTPM_DIR" -name "*.cache" -type f -delete 2>/dev/null || true
    echo "   ✅ Cache SwiftPM du projet nettoyé"
else
    echo "   ℹ️  Dossier SwiftPM n'existe pas"
fi
echo ""

echo "✅ Nettoyage terminé!"
echo ""
echo "📋 Prochaines étapes dans Xcode:"
echo ""
echo "   1. Ouvrez le projet dans Xcode"
echo "   2. File > Packages > Reset Package Caches"
echo "   3. File > Packages > Resolve Package Versions"
echo "   4. Attendez que tous les packages soient résolus"
echo "   5. Product > Clean Build Folder (⇧⌘K)"
echo "   6. Product > Build (⌘B)"
echo ""
echo "🔍 Si les erreurs persistent:"
echo "   - Vérifiez les logs de compilation dans Xcode"
echo "   - Consultez RESOLUTION_SWIFTPROTOBUF.md pour plus de détails"
echo ""

