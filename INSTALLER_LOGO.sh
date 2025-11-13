#!/bin/bash

# Script pour installer automatiquement le logo Tshiakani VTC
# Cherche l'image dans plusieurs emplacements communs

set -e

APPICON_DIR="Tshiakani VTC/Assets.xcassets/AppIcon.appiconset"
POSSIBLE_LOCATIONS=(
    "$HOME/Downloads/logo_tshiakani.png"
    "$HOME/Downloads/tshiakani_logo.png"
    "$HOME/Downloads/logo.png"
    "$HOME/Downloads/Tshiakani*.png"
    "$HOME/Desktop/logo_tshiakani.png"
    "$HOME/Desktop/tshiakani_logo.png"
    "$HOME/Desktop/logo.png"
    "$HOME/Desktop/Tshiakani*.png"
    "./logo_tshiakani.png"
    "./tshiakani_logo.png"
    "./logo.png"
)

echo "🔍 Recherche du logo Tshiakani VTC..."
echo ""

FOUND_IMAGE=""

# Chercher dans les emplacements possibles
for location in "${POSSIBLE_LOCATIONS[@]}"; do
    # Gérer les wildcards
    if [[ "$location" == *"*"* ]]; then
        for file in $location; do
            if [ -f "$file" ] && [ -r "$file" ]; then
                FOUND_IMAGE="$file"
                break 2
            fi
        done
    else
        if [ -f "$location" ] && [ -r "$location" ]; then
            FOUND_IMAGE="$location"
            break
        fi
    fi
done

if [ -z "$FOUND_IMAGE" ]; then
    echo "❌ Logo non trouvé dans les emplacements communs."
    echo ""
    echo "📋 Veuillez placer votre logo (PNG, 1024x1024) dans un de ces emplacements:"
    echo "   - ~/Downloads/logo_tshiakani.png"
    echo "   - ~/Desktop/logo_tshiakani.png"
    echo "   - Ou dans le dossier du projet: ./logo_tshiakani.png"
    echo ""
    echo "💡 Ou donnez-moi le chemin complet du fichier et je l'installerai !"
    exit 1
fi

echo "✅ Logo trouvé: $FOUND_IMAGE"
echo ""

# Vérifier que sips est disponible
if ! command -v sips &> /dev/null; then
    echo "❌ Erreur: La commande 'sips' n'est pas disponible"
    exit 1
fi

# Vérifier les dimensions (approximatif)
echo "📐 Vérification des dimensions..."
IMAGE_INFO=$(sips -g pixelWidth -g pixelHeight "$FOUND_IMAGE" 2>/dev/null)
WIDTH=$(echo "$IMAGE_INFO" | grep "pixelWidth" | awk '{print $2}')
HEIGHT=$(echo "$IMAGE_INFO" | grep "pixelHeight" | awk '{print $2}')

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
    echo "⚠️  Impossible de vérifier les dimensions, mais on continue..."
else
    echo "   Dimensions: ${WIDTH}x${HEIGHT} pixels"
    if [ "$WIDTH" -lt 512 ] || [ "$HEIGHT" -lt 512 ]; then
        echo "⚠️  Attention: L'image est petite. Recommandé: 1024x1024 pixels"
    fi
fi

echo ""
echo "🔄 Génération des icônes..."

# Créer le dossier si nécessaire
mkdir -p "$APPICON_DIR"

# Copier l'image source comme icône 1024x1024
cp "$FOUND_IMAGE" "$APPICON_DIR/AppIcon-1024x1024.png"
echo "   ✅ Copié: AppIcon-1024x1024.png"

# Générer toutes les tailles nécessaires
generate_icon() {
    local size=$1
    local filename=$2
    
    sips -z $size $size "$FOUND_IMAGE" --out "$APPICON_DIR/$filename" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "   ✅ Généré: $filename (${size}x${size})"
    else
        echo "   ⚠️  Erreur: $filename"
    fi
}

# Générer toutes les tailles iOS
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
generate_icon 76 "AppIcon-76x76-iPad@1x.png"
generate_icon 152 "AppIcon-76x76-iPad@2x.png"
generate_icon 83 "AppIcon-83.5x83.5-iPad@2x.png"

echo ""
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
      "filename" : "AppIcon-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "AppIcon-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "AppIcon-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "AppIcon-40x40@2x.png",
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
echo "🎉 Logo installé avec succès !"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Ouvrir Xcode"
echo "   2. Vérifier Assets.xcassets > AppIcon"
echo "   3. Compiler le projet (⌘B)"
echo ""

