#!/bin/bash

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
PROJECT_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj"

echo "🚀 Ouverture de Xcode et résolution automatique des packages..."
echo ""

# Ouvrir Xcode avec le projet
open -a Xcode "$PROJECT_PATH"

# Attendre que Xcode s'ouvre
sleep 5

# Utiliser osascript pour automatiser
osascript << 'APPLESCRIPT'
tell application "Xcode"
	activate
	delay 2
	
	-- Attendre que le projet soit chargé
	delay 3
	
	-- Afficher un message
	display dialog "Xcode est maintenant ouvert avec le projet." & return & return & "Les packages devraient se résoudre automatiquement." & return & return & "Si ce n'est pas le cas, allez dans:" & return & "File > Packages > Resolve Package Versions" buttons {"OK"} default button "OK"
end tell
APPLESCRIPT

echo "✅ Xcode ouvert. Les packages devraient se résoudre automatiquement."
echo "   Si ce n'est pas le cas, utilisez File > Packages > Resolve Package Versions"
