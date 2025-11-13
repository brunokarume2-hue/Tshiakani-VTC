#!/bin/bash

# Script pour ouvrir Xcode et préparer la compilation

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
XCODEPROJ="$PROJECT_DIR/Tshiakani VTC.xcodeproj"

echo ""
echo "🚀 Ouverture de Xcode..."
echo ""

# Ouvrir Xcode avec le projet
open "$XCODEPROJ"

echo "✅ Xcode ouvert"
echo ""
echo "📋 PROCHAINES ÉTAPES DANS XCODE:"
echo ""
echo "1. Attendez que le projet se charge"
echo ""
echo "2. Vérifiez Build Phases > Copy Bundle Resources:"
echo "   → Target 'Tshiakani VTC' > Build Phases"
echo "   → Développez 'Copy Bundle Resources'"
echo "   → Si Info.plist est présent, RETIREZ-LE"
echo ""
echo "3. Product > Clean Build Folder (⇧⌘K)"
echo ""
echo "4. Product > Build (⌘B)"
echo ""
echo "⚠️  Si l'erreur persiste, on corrigera après"
echo ""

