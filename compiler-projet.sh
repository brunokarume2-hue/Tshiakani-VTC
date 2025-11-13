#!/bin/bash

# Script pour compiler le projet automatiquement
# Ce script ouvre Xcode et compile le projet

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj"

echo "🔨 Compilation du projet Tshiakani VTC"
echo "======================================"
echo ""

# Vérifier si Xcode est installé
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ Xcode n'est pas installé dans /Applications/Xcode.app"
    exit 1
fi

echo "📦 Ouverture de Xcode avec le projet..."
open -a Xcode "$PROJECT_PATH"

# Attendre que Xcode s'ouvre
sleep 5

echo "✅ Xcode ouvert"
echo ""
echo "🚀 Compilation en cours via AppleScript..."
echo ""

# Utiliser osascript pour compiler
osascript << 'APPLESCRIPT'
tell application "Xcode"
	activate
	delay 3
	
	-- Vérifier que le projet est ouvert
	try
		set projectName to name of workspace document 1
		display dialog "Projet ouvert: " & projectName & return & return & "Compilation en cours..." buttons {"OK"} default button "OK"
		
		-- Utiliser System Events pour compiler
		tell application "System Events"
			tell process "Xcode"
				-- Utiliser le raccourci clavier Cmd+B pour compiler
				keystroke "b" using command down
				display dialog "Commande de compilation envoyée (Cmd+B)" & return & return & "Vérifiez la barre d'état en bas de Xcode pour voir la progression." buttons {"OK"} default button "OK"
			end tell
		end tell
	on error
		display dialog "Le projet n'est pas ouvert. Veuillez l'ouvrir manuellement et compiler avec Cmd+B." buttons {"OK"} default button "OK"
	end try
end tell
APPLESCRIPT

echo ""
echo "✅ Commande de compilation envoyée!"
echo ""
echo "📋 Vérifiez dans Xcode:"
echo "   - La barre d'état en bas devrait afficher 'Building...'"
echo "   - Les erreurs apparaîtront dans le panneau des problèmes"
echo "   - Le statut de compilation apparaîtra dans la barre de titre"
echo ""

