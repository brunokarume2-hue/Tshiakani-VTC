#!/bin/bash

# Script pour forcer la résolution des packages GoogleMaps et GooglePlaces
# Ce script supprime complètement les références et les recrée

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj"
WORKSPACE_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.xcworkspace"
PACKAGE_RESOLVED="${WORKSPACE_PATH}/xcshareddata/swiftpm/Package.resolved"

echo "🔧 Forcer la résolution des packages GoogleMaps et GooglePlaces"
echo "================================================================"
echo ""

# 1. Fermer Xcode si ouvert (optionnel mais recommandé)
echo "📦 Étape 1: Vérification de Xcode..."
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  Xcode est ouvert. Veuillez le fermer avant de continuer."
    echo "   Appuyez sur Entrée une fois Xcode fermé, ou Ctrl+C pour annuler..."
    read
fi
echo "✅ Xcode fermé"
echo ""

# 2. Supprimer Package.resolved
echo "📦 Étape 2: Suppression de Package.resolved..."
if [ -f "$PACKAGE_RESOLVED" ]; then
    rm -f "$PACKAGE_RESOLVED"
    echo "✅ Package.resolved supprimé"
else
    echo "ℹ️  Package.resolved n'existe pas (c'est normal)"
fi
echo ""

# 3. Nettoyer tous les caches
echo "📦 Étape 3: Nettoyage complet des caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/org.swift.swiftpm 2>/dev/null || true
rm -rf "${WORKSPACE_PATH}/xcshareddata/swiftpm/artifacts" 2>/dev/null || true
rm -rf "${WORKSPACE_PATH}/xcshareddata/swiftpm/checkouts" 2>/dev/null || true
echo "✅ Caches nettoyés"
echo ""

# 4. Créer un Package.resolved minimal pour forcer la résolution
echo "📦 Étape 4: Création d'un Package.resolved minimal..."
mkdir -p "${WORKSPACE_PATH}/xcshareddata/swiftpm"

# Créer un Package.resolved avec juste la structure de base
cat > "$PACKAGE_RESOLVED" << 'EOF'
{
  "pins" : [
  ],
  "version" : 2
}
EOF

echo "✅ Package.resolved minimal créé"
echo ""

# 5. Vérifier la configuration dans project.pbxproj
echo "📦 Étape 5: Vérification de la configuration..."
if grep -q "ios-maps-sdk" "${PROJECT_PATH}/project.pbxproj" && grep -q "ios-places-sdk" "${PROJECT_PATH}/project.pbxproj"; then
    echo "✅ Les packages sont bien configurés dans project.pbxproj"
    echo ""
    echo "   GoogleMaps: https://github.com/googlemaps/ios-maps-sdk (version 10.4.0+)"
    echo "   GooglePlaces: https://github.com/googlemaps/ios-places-sdk (version 10.4.0+)"
else
    echo "❌ Erreur: Les packages ne sont pas correctement configurés"
    exit 1
fi
echo ""

echo "✅ Préparation terminée!"
echo ""
echo "📋 PROCHAINES ÉTAPES OBLIGATOIRES DANS XCODE:"
echo ""
echo "1. Ouvrez Xcode"
echo "2. Ouvrez le projet 'Tshiakani VTC.xcodeproj'"
echo "3. Attendez quelques secondes que Xcode charge le projet"
echo "4. Allez dans File > Packages > Resolve Package Versions"
echo "   (ou cliquez sur l'icône de package en bas du navigateur de projet)"
echo "5. Attendez que les packages soient téléchargés (peut prendre 2-5 minutes)"
echo "6. Vérifiez qu'il n'y a plus d'erreurs dans le navigateur de projet"
echo "7. Compilez le projet (Cmd+B)"
echo ""
echo "🔍 Si les packages ne se résolvent toujours pas:"
echo "   - File > Packages > Reset Package Caches"
echo "   - Puis File > Packages > Resolve Package Versions"
echo "   - Vérifiez votre connexion Internet"
echo ""
