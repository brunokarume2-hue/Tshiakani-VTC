#!/bin/bash

# Script pour vérifier les références restantes à l'ancien nom
OLD_NAME="wewa"

echo "🔍 Recherche des occurrences de '$OLD_NAME' dans le projet..."
echo ""

# Rechercher dans tous les fichiers (sauf node_modules, .git, Pods, build, DerivedData)
grep -rnw . -e "$OLD_NAME" \
  --exclude-dir={Pods,build,.git,node_modules,DerivedData} \
  --exclude-dir="Tshiakani VTC.xcodeproj/xcuserdata" \
  --exclude="*.xcuserstate" \
  --exclude="*.xcuserdatad" \
  --exclude="*.md" \
  2>/dev/null

echo ""
echo "✅ Vérification terminée."
echo ""
echo "ℹ️  Note: Les références dans les fichiers de documentation (.md) sont normales"
echo "   et peuvent être conservées pour l'historique du projet."
