#!/bin/bash

# Script pour forcer automatiquement la résolution des packages
# Ce script télécharge et configure les packages sans nécessiter Xcode en ligne de commande

set -e

PROJECT_DIR="/Users/admin/Documents/Tshiakani VTC"
WORKSPACE_PATH="${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.xcworkspace"
PACKAGE_RESOLVED="${WORKSPACE_PATH}/xcshareddata/swiftpm/Package.resolved"
SWIFTPM_DIR="${WORKSPACE_PATH}/xcshareddata/swiftpm"

echo "🔧 Forçage automatique de la résolution des packages"
echo "====================================================="
echo ""

# 1. Vérifier que Package.resolved existe
if [ ! -f "$PACKAGE_RESOLVED" ]; then
    echo "❌ Package.resolved n'existe pas. Création..."
    mkdir -p "$SWIFTPM_DIR"
    cat > "$PACKAGE_RESOLVED" << 'EOF'
{
  "pins" : [
    {
      "identity" : "ios-maps-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-maps-sdk",
      "state" : {
        "revision" : "e4c8ab764c05a7e50501f8f7b35a1f8b45203da2",
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "ios-places-sdk",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/googlemaps/ios-places-sdk",
      "state" : {
        "revision" : "d07fef1d14fb7095d3681571433ca4e147e34a91",
        "version" : "10.4.0"
      }
    },
    {
      "identity" : "swift-algorithms",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/apple/swift-algorithms.git",
      "state" : {
        "revision" : "87e50f483c54e6efd60e885f7f5aa946cee68023",
        "version" : "1.2.1"
      }
    }
  ],
  "version" : 2
}
EOF
    echo "✅ Package.resolved créé"
else
    echo "✅ Package.resolved existe déjà"
fi
echo ""

# 2. Nettoyer les anciens checkouts et artifacts
echo "📦 Nettoyage des anciens téléchargements..."
rm -rf "${SWIFTPM_DIR}/checkouts" 2>/dev/null || true
rm -rf "${SWIFTPM_DIR}/artifacts" 2>/dev/null || true
echo "✅ Anciens téléchargements supprimés"
echo ""

# 3. Nettoyer les caches système
echo "📦 Nettoyage des caches Swift Package Manager..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages 2>/dev/null || true
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true
rm -rf ~/Library/org.swift.swiftpm 2>/dev/null || true
echo "✅ Caches nettoyés"
echo ""

# 4. Créer un script AppleScript pour forcer la résolution dans Xcode
echo "📦 Création d'un script pour automatiser Xcode..."
cat > "${PROJECT_DIR}/resoudre-dans-xcode.applescript" << 'APPLESCRIPT'
tell application "Xcode"
	activate
	delay 1
	
	-- Ouvrir le projet
	set projectPath to "/Users/admin/Documents/Tshiakani VTC/Tshiakani VTC.xcodeproj"
	try
		open projectPath
		delay 3
	end try
	
	-- Instructions
	display dialog "Le projet est ouvert dans Xcode." & return & return & "Le script va maintenant essayer de résoudre les packages automatiquement." & return & return & "Si cela ne fonctionne pas, suivez ces étapes manuellement:" & return & return & "1. File > Packages > Reset Package Caches" & return & "2. File > Packages > Resolve Package Versions" buttons {"Continuer"} default button "Continuer"
	
	-- Essayer d'utiliser les raccourcis clavier
	tell application "System Events"
		tell process "Xcode"
			-- Essayer File > Packages > Resolve Package Versions
			keystroke "f" using {command down, shift down}
			delay 1
		end tell
	end tell
end tell
APPLESCRIPT

echo "✅ Script AppleScript créé"
echo ""

# 5. Créer un fichier de configuration pour forcer la résolution
echo "📦 Configuration des paramètres de résolution..."
mkdir -p "${SWIFTPM_DIR}/configuration"

# Créer un fichier de configuration qui force la résolution
cat > "${SWIFTPM_DIR}/configuration/swiftpm-config.json" << 'EOF'
{
  "packageResolved": true,
  "autoResolve": true
}
EOF

echo "✅ Configuration créée"
echo ""

# 6. Vérifier la structure du projet
echo "📦 Vérification de la structure..."
if [ -f "${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.pbxproj" ]; then
    if grep -q "ios-maps-sdk" "${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.pbxproj" && \
       grep -q "ios-places-sdk" "${PROJECT_DIR}/Tshiakani VTC.xcodeproj/project.pbxproj"; then
        echo "✅ Les packages sont bien configurés dans project.pbxproj"
    else
        echo "⚠️  Les packages ne sont pas dans project.pbxproj"
    fi
else
    echo "❌ project.pbxproj non trouvé"
    exit 1
fi
echo ""

# 7. Créer un script qui utilise osascript pour ouvrir Xcode et résoudre
echo "📦 Création d'un script d'automatisation Xcode..."
cat > "${PROJECT_DIR}/ouvrir-et-resoudre.sh" << 'SCRIPT'
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
SCRIPT

chmod +x "${PROJECT_DIR}/ouvrir-et-resoudre.sh"
echo "✅ Script d'ouverture créé"
echo ""

echo "✅ Préparation terminée!"
echo ""
echo "📋 Pour forcer la résolution maintenant, exécutez:"
echo "   ./ouvrir-et-resoudre.sh"
echo ""
echo "   OU"
echo ""
echo "   Ouvrez Xcode manuellement et les packages devraient se résoudre automatiquement"
echo "   grâce au Package.resolved que nous avons créé."
echo ""

