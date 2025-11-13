#!/bin/bash

# Script pour générer toutes les tailles d'icônes iOS à partir d'une image source 1024x1024
# Usage: ./SCRIPT_GENERER_APPICON.sh chemin/vers/logo_1024x1024.png

set -e

APPICON_DIR="Tshiakani VTC/Assets.xcassets/AppIcon.appiconset"
SOURCE_IMAGE="$1"

# Vérifier que l'image source existe
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Erreur: L'image source n'existe pas: $SOURCE_IMAGE"
    echo ""
    echo "Usage: ./SCRIPT_GENERER_APPICON.sh chemin/vers/logo_1024x1024.png"
    exit 1
fi

echo "🎨 Génération des icônes iOS pour Tshiakani VTC"
echo "================================================"
echo ""
echo "📸 Image source: $SOURCE_IMAGE"
echo "📁 Dossier de destination: $APPICON_DIR"
echo ""

# Vérifier que sips est disponible
if ! command -v sips &> /dev/null; then
    echo "❌ Erreur: La commande 'sips' n'est pas disponible"
    echo "   Ce script nécessite macOS avec les outils de développement"
    exit 1
fi

# Créer le dossier si nécessaire
mkdir -p "$APPICON_DIR"

# Fonction pour générer une icône
generate_icon() {
    local size=$1
    local filename=$2
    local output="$APPICON_DIR/$filename"
    
    echo "  📐 Génération: $filename (${size}x${size})"
    sips -z $size $size "$SOURCE_IMAGE" --out "$output" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "     ✅ Créé: $output"
    else
        echo "     ❌ Erreur lors de la création de $output"
        return 1
    fi
}

# Générer toutes les tailles nécessaires pour iOS
echo "🔄 Génération des icônes..."
echo ""

# iPhone App (iOS 7-15)
generate_icon 20 "AppIcon-20x20@1x.png"
generate_icon 40 "AppIcon-20x20@2x.png"
generate_icon 60 "AppIcon-20x20@3x.png"

generate_icon 29 "AppIcon-29x29@1x.png"
generate_icon 58 "AppIcon-29x29@2x.png"
generate_icon 87 "AppIcon-29x29@3x.png"

generate_icon 40 "AppIcon-40x40@1x.png"
generate_icon 80 "AppIcon-40x40@2x.png"
generate_icon 120 "AppIcon-40x40@3x.png"

generate_icon 60 "AppIcon-60x60@1x.png"
generate_icon 120 "AppIcon-60x60@2x.png"
generate_icon 180 "AppIcon-60x60@3x.png"

# iPad App (iOS 7-15)
generate_icon 20 "AppIcon-20x20-iPad@1x.png"
generate_icon 40 "AppIcon-20x20-iPad@2x.png"

generate_icon 29 "AppIcon-29x29-iPad@1x.png"
generate_icon 58 "AppIcon-29x29-iPad@2x.png"

generate_icon 40 "AppIcon-40x40-iPad@1x.png"
generate_icon 80 "AppIcon-40x40-iPad@2x.png"

generate_icon 76 "AppIcon-76x76-iPad@1x.png"
generate_icon 152 "AppIcon-76x76-iPad@2x.png"

generate_icon 83.5 "AppIcon-83.5x83.5-iPad@2x.png"

# App Store (requis)
generate_icon 1024 "AppIcon-1024x1024.png"

echo ""
echo "✅ Toutes les icônes ont été générées !"
echo ""

# Mettre à jour le Contents.json
echo "📝 Mise à jour de Contents.json..."

cat > "$APPICON_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "AppIcon-20x20@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40x40@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "AppIcon-20x20-iPad@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20x20-iPad@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29x29-iPad@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29x29-iPad@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40x40-iPad@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40x40-iPad@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-76x76-iPad@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-76x76-iPad@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "AppIcon-83.5x83.5-iPad@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "AppIcon-1024x1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
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
echo "🎉 Terminé ! Toutes les icônes sont prêtes."
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrir Xcode"
echo "   2. Sélectionner Assets.xcassets > AppIcon"
echo "   3. Vérifier que toutes les icônes sont bien chargées"
echo "   4. Compiler le projet (⌘B)"
echo ""

