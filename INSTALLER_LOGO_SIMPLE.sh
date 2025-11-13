#!/bin/bash

# Script simple pour installer le logo - accepte le chemin en argument
# Usage: ./INSTALLER_LOGO_SIMPLE.sh chemin/vers/logo.png

set -e

APPICON_DIR="Tshiakani VTC/Assets.xcassets/AppIcon.appiconset"
SOURCE_IMAGE="$1"

if [ -z "$SOURCE_IMAGE" ]; then
    echo "📋 Usage: ./INSTALLER_LOGO_SIMPLE.sh chemin/vers/votre/logo.png"
    echo ""
    echo "💡 Vous pouvez aussi glisser-déposer le fichier dans le terminal après avoir tapé:"
    echo "   ./INSTALLER_LOGO_SIMPLE.sh "
    exit 1
fi

# Vérifier que le fichier existe
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Erreur: Le fichier n'existe pas: $SOURCE_IMAGE"
    exit 1
fi

echo "✅ Logo trouvé: $SOURCE_IMAGE"
echo ""

# Créer le dossier
mkdir -p "$APPICON_DIR"

# Copier l'image comme icône 1024x1024
echo "📋 Installation de l'icône..."
cp "$SOURCE_IMAGE" "$APPICON_DIR/AppIcon-1024x1024.png"
echo "   ✅ Copié: AppIcon-1024x1024.png"

# Configuration minimale (iOS 11+ accepte une seule icône 1024x1024)
cat > "$APPICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-1024x1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "✅ Contents.json mis à jour"
echo ""
echo "🎉 Logo installé !"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrir Xcode"
echo "   2. Vérifier: Assets.xcassets > AppIcon"
echo "   3. Compiler: Product > Build (⌘B)"
echo ""

