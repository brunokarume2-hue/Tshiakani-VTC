#!/bin/bash

echo "🔧 Correction du conflit Info.plist..."

# 1. Vérifier que le fichier .xcode-ignore existe
if [ ! -f "Tshiakani VTC/.xcode-ignore" ]; then
    echo "❌ Le fichier .xcode-ignore n'existe pas. Création..."
    echo "Info.plist" > "Tshiakani VTC/.xcode-ignore"
    echo "✅ Fichier .xcode-ignore créé"
else
    echo "✅ Le fichier .xcode-ignore existe déjà"
fi

# 2. Nettoyer le dossier DerivedData
echo ""
echo "🧹 Nettoyage du dossier DerivedData..."
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData/Tshiakani_VTC-*"

if ls $DERIVED_DATA_PATH 1> /dev/null 2>&1; then
    echo "⚠️  Fermez Xcode avant de continuer pour permettre le nettoyage complet."
    echo "   Appuyez sur Entrée une fois Xcode fermé..."
    read
    
    rm -rf $DERIVED_DATA_PATH
    echo "✅ Dossier DerivedData nettoyé"
else
    echo "✅ Aucun dossier DerivedData à nettoyer"
fi

# 3. Instructions finales
echo ""
echo "✅ Correction terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "   1. Ouvrez Xcode"
echo "   2. Fermez le projet s'il est ouvert"
echo "   3. Rouvrez le projet 'Tshiakani VTC.xcodeproj'"
echo "   4. Xcode devrait maintenant ignorer Info.plist dans la synchronisation"
echo "   5. Compilez le projet (Cmd+B)"
echo ""
echo "💡 Si l'erreur persiste :"
echo "   - Dans Xcode, allez dans Product > Clean Build Folder (Cmd+Shift+K)"
echo "   - Puis compilez à nouveau"

