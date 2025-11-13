#!/bin/bash

# Script pour compiler et installer l'app sur le téléphone connecté

set -e

echo "🔧 Compilation et Installation sur Téléphone"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="Tshiakani VTC"
XCODE_PROJECT="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"

echo "📁 Répertoire du projet: $PROJECT_DIR"
echo ""

# 1. Vérifier que Xcode est configuré
echo "🔍 Vérification de Xcode..."
if [ "$(xcode-select -p)" != "/Applications/Xcode.app/Contents/Developer" ]; then
    echo "⚠️  Xcode n'est pas configuré correctement"
    echo ""
    echo "📋 Pour configurer Xcode, exécutez cette commande dans le terminal:"
    echo "   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo ""
    echo "   OU ouvrez Xcode et acceptez la licence:"
    echo "   sudo xcodebuild -license accept"
    echo ""
    exit 1
fi

echo "   ✅ Xcode configuré: $(xcode-select -p)"
echo ""

# 2. Lister les appareils connectés
echo "📱 Appareils iOS connectés:"
xcrun xctrace list devices 2>/dev/null | grep -E "iPhone|iPad" || echo "   ℹ️  Aucun appareil détecté (connectez votre iPhone)"
echo ""

# 3. Nettoyer le build
echo "🧹 Nettoyage du build..."
xcodebuild -project "$XCODE_PROJECT" \
  -scheme "$PROJECT_NAME" \
  -configuration Debug \
  clean 2>&1 | grep -E "(Clean|SUCCEEDED|FAILED)" || true
echo ""

# 4. Compiler le projet
echo "🔨 Compilation du projet..."
echo "   (Cela peut prendre quelques minutes...)"
echo ""

BUILD_OUTPUT=$(xcodebuild -project "$XCODE_PROJECT" \
  -scheme "$PROJECT_NAME" \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  build 2>&1)

# Afficher les erreurs si la compilation échoue
if echo "$BUILD_OUTPUT" | grep -q "BUILD FAILED"; then
    echo "❌ Erreurs de compilation:"
    echo "$BUILD_OUTPUT" | grep -A 5 -E "error:|warning:" | head -30
    echo ""
    echo "📋 Pour voir toutes les erreurs, consultez le fichier build.log"
    exit 1
fi

if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo "✅ Compilation réussie!"
    echo ""
    
    # 5. Trouver l'app compilée
    DERIVED_DATA=$(xcodebuild -project "$XCODE_PROJECT" -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $3}')
    APP_PATH="$DERIVED_DATA/$PROJECT_NAME.app"
    
    if [ -d "$APP_PATH" ]; then
        echo "📦 Application compilée trouvée:"
        echo "   $APP_PATH"
        echo ""
        
        # 6. Installer sur l'appareil connecté
        echo "📱 Installation sur l'appareil..."
        echo "   (Assurez-vous que votre iPhone est connecté et déverrouillé)"
        echo ""
        
        DEVICE_ID=$(xcrun xctrace list devices 2>/dev/null | grep -E "iPhone.*\(.*\)" | head -1 | sed 's/.*(\(.*\))/\1/')
        
        if [ -n "$DEVICE_ID" ]; then
            echo "   Appareil détecté: $DEVICE_ID"
            echo ""
            echo "📋 Pour installer sur l'appareil:"
            echo "   1. Ouvrez Xcode"
            echo "   2. Connectez votre iPhone"
            echo "   3. Sélectionnez votre iPhone comme destination"
            echo "   4. Cliquez sur le bouton Run (▶️)"
            echo ""
            echo "   OU utilisez cette commande:"
            echo "   xcrun devicectl device install app --device $DEVICE_ID \"$APP_PATH\""
        else
            echo "   ⚠️  Aucun appareil iOS détecté"
            echo ""
            echo "📋 Pour installer manuellement:"
            echo "   1. Ouvrez Xcode"
            echo "   2. Connectez votre iPhone via USB"
            echo "   3. Faites confiance à l'ordinateur sur votre iPhone"
            echo "   4. Dans Xcode, sélectionnez votre iPhone comme destination"
            echo "   5. Cliquez sur Run (▶️)"
        fi
    else
        echo "⚠️  Application compilée non trouvée"
        echo "   Essayez de compiler depuis Xcode directement"
    fi
else
    echo "❌ Échec de la compilation"
    echo "$BUILD_OUTPUT" | tail -20
    exit 1
fi

echo ""
echo "✅ Terminé!"

