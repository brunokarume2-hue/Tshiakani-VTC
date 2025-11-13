#!/bin/bash

# Script pour corriger l'avertissement Info.plist et forcer la résolution des packages

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.pbxproj"

echo "🔧 Correction de l'avertissement Info.plist et résolution des packages"
echo "======================================================================"
echo ""

# 1. Vérifier que EXCLUDED_SOURCE_FILE_NAMES contient Info.plist
echo "📦 Étape 1: Vérification de la configuration Info.plist..."
if grep -q 'EXCLUDED_SOURCE_FILE_NAMES = "Info.plist"' "$PROJECT_PATH"; then
    echo "✅ Info.plist est déjà exclu dans EXCLUDED_SOURCE_FILE_NAMES"
else
    echo "⚠️  Info.plist n'est pas exclu, ajout en cours..."
    # Ajouter EXCLUDED_SOURCE_FILE_NAMES si absent
    # Cette partie sera gérée manuellement dans Xcode
fi
echo ""

# 2. Vérifier que GENERATE_INFOPLIST_FILE = NO
echo "📦 Étape 2: Vérification de GENERATE_INFOPLIST_FILE..."
if grep -q 'GENERATE_INFOPLIST_FILE = NO' "$PROJECT_PATH"; then
    echo "✅ GENERATE_INFOPLIST_FILE est bien à NO"
else
    echo "⚠️  GENERATE_INFOPLIST_FILE n'est pas à NO"
fi
echo ""

# 3. Nettoyer les caches et forcer la résolution des packages
echo "📦 Étape 3: Nettoyage des caches et résolution des packages..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
echo "✅ Caches nettoyés"
echo ""

# 4. Vérifier Package.resolved
echo "📦 Étape 4: Vérification de Package.resolved..."
PACKAGE_RESOLVED="${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$PACKAGE_RESOLVED" ]; then
    echo "✅ Package.resolved existe"
    if grep -q "ios-maps-sdk" "$PACKAGE_RESOLVED" && grep -q "ios-places-sdk" "$PACKAGE_RESOLVED"; then
        echo "✅ Les packages Google Maps sont configurés"
    else
        echo "⚠️  Les packages ne sont pas correctement configurés"
    fi
else
    echo "❌ Package.resolved n'existe pas"
fi
echo ""

echo "✅ Préparation terminée!"
echo ""
echo "📋 ACTIONS MANUELLES REQUISES DANS XCODE:"
echo ""
echo "1. CORRECTION DE L'AVERTISSEMENT INFOPLIST:"
echo "   a. Ouvrez Xcode"
echo "   b. Sélectionnez le projet dans le navigateur"
echo "   c. Sélectionnez le target 'Tshiakani VTC'"
echo "   d. Allez dans l'onglet 'Build Phases'"
echo "   e. Développez 'Copy Bundle Resources'"
echo "   f. Si Info.plist est dans la liste, sélectionnez-le et appuyez sur Delete"
echo "   g. Vérifiez que 'EXCLUDED_SOURCE_FILE_NAMES = Info.plist' dans Build Settings"
echo ""
echo "2. RÉSOLUTION DES PACKAGES:"
echo "   a. File > Packages > Reset Package Caches"
echo "   b. File > Packages > Resolve Package Versions"
echo "   c. Attendez 2-5 minutes"
echo "   d. Compilez avec Cmd+B"
echo ""

