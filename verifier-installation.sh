#!/bin/bash

# Script pour vérifier la configuration avant installation sur appareil

echo "🔍 Vérification de la Configuration pour l'Installation"
echo "======================================================"
echo ""

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
BUNDLE_PATH="/Users/admin/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-duetcenfcnuuwofxmoqrcjdsbwuj/Build/Products/Debug-iphoneos/Tshiakani VTC.app"
INFO_PLIST="${BUNDLE_PATH}/Info.plist"

# 1. Vérifier que le bundle existe
echo "📦 Étape 1: Vérification du bundle..."
if [ -d "$BUNDLE_PATH" ]; then
    echo "✅ Bundle trouvé: $BUNDLE_PATH"
else
    echo "❌ Bundle non trouvé. Compilez d'abord le projet."
    exit 1
fi
echo ""

# 2. Vérifier Info.plist
echo "📦 Étape 2: Vérification de Info.plist..."
if [ -f "$INFO_PLIST" ]; then
    echo "✅ Info.plist trouvé"
    
    # Vérifier CFBundleIdentifier
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null)
    if [ -n "$BUNDLE_ID" ]; then
        echo "✅ CFBundleIdentifier: $BUNDLE_ID"
    else
        echo "❌ CFBundleIdentifier manquant!"
        exit 1
    fi
    
    # Vérifier CFBundleName
    BUNDLE_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleName" "$INFO_PLIST" 2>/dev/null)
    if [ -n "$BUNDLE_NAME" ]; then
        echo "✅ CFBundleName: $BUNDLE_NAME"
    else
        echo "⚠️  CFBundleName manquant"
    fi
    
    # Vérifier CFBundleVersion
    BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST" 2>/dev/null)
    if [ -n "$BUNDLE_VERSION" ]; then
        echo "✅ CFBundleVersion: $BUNDLE_VERSION"
    else
        echo "⚠️  CFBundleVersion manquant"
    fi
else
    echo "❌ Info.plist non trouvé!"
    exit 1
fi
echo ""

# 3. Vérifier la signature
echo "📦 Étape 3: Vérification de la signature..."
SIGNATURE=$(codesign -dvvv "$BUNDLE_PATH" 2>&1 | grep -E "Authority|TeamIdentifier" | head -5)
if [ -n "$SIGNATURE" ]; then
    echo "✅ Signature trouvée:"
    echo "$SIGNATURE" | sed 's/^/   /'
else
    echo "⚠️  Signature non trouvée ou problème de signature"
fi
echo ""

# 4. Vérifier l'exécutable
echo "📦 Étape 4: Vérification de l'exécutable..."
EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$INFO_PLIST" 2>/dev/null)
if [ -n "$EXECUTABLE" ]; then
    EXECUTABLE_PATH="${BUNDLE_PATH}/${EXECUTABLE}"
    if [ -f "$EXECUTABLE_PATH" ]; then
        echo "✅ Exécutable trouvé: $EXECUTABLE"
    else
        echo "❌ Exécutable non trouvé: $EXECUTABLE_PATH"
        exit 1
    fi
else
    echo "⚠️  CFBundleExecutable non défini"
fi
echo ""

echo "✅ Vérifications terminées!"
echo ""
echo "📋 Si l'installation échoue encore, vérifiez:"
echo "   1. Que l'appareil est connecté et déverrouillé"
echo "   2. Que vous avez fait confiance à l'ordinateur sur l'appareil"
echo "   3. Que le provisioning profile est valide (Xcode > Settings > Accounts)"
echo "   4. Que l'appareil est enregistré pour le développement"
echo ""

