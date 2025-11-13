#!/bin/bash

# Script pour modifier directement project.pbxproj et s'assurer qu'Info.plist n'est pas dans les ressources
# Note: Avec PBXFileSystemSynchronizedRootGroup, cette modification peut ne pas suffire

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"
PROJECT_FILE="$XCODEPROJ/project.pbxproj"

echo "🔧 Correction directe de project.pbxproj"
echo "========================================"
echo ""

# Vérifier que la section Resources est vide
echo "Vérification de la section Resources..."
RESOURCES_SECTION=$(grep -A 5 '849318F02EBEE1F000D186E8 /\* Resources \*/' "$PROJECT_FILE" | grep -A 3 'files = (')

if echo "$RESOURCES_SECTION" | grep -q "Info.plist"; then
    echo "⚠️  Info.plist trouvé dans les ressources"
    echo "   → Modification du fichier project.pbxproj..."
    
    # Créer une sauvegarde
    cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
    
    # Retirer Info.plist de la section Resources
    # Cette opération est complexe car il faut identifier la référence exacte
    # Pour l'instant, on vérifie juste que la section est vide
    
    echo "✅ Sauvegarde créée: project.pbxproj.backup"
    echo "⚠️  Modification manuelle recommandée dans Xcode"
else
    echo "✅ Section Resources vide (pas d'Info.plist dans project.pbxproj)"
    echo ""
    echo "⚠️  Le problème vient probablement de PBXFileSystemSynchronizedRootGroup"
    echo "   qui synchronise automatiquement les fichiers."
    echo ""
    echo "   Solution: Retirer Info.plist manuellement dans Xcode:"
    echo "   → Target > Build Phases > Copy Bundle Resources"
    echo "   → Retirer Info.plist si présent"
fi

echo ""
echo "========================================"
echo "✅ Vérification terminée"
echo ""

