#!/bin/bash

# Script pour configurer automatiquement l'app iOS avec l'IP locale
# Usage: ./scripts/configurer-ios.sh

set -e

echo "📱 Configuration iOS - Tshiakani VTC"
echo "===================================="
echo ""

# Trouver l'adresse IP locale
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)

if [ -z "$IP" ]; then
    echo "❌ Impossible de trouver l'adresse IP locale"
    exit 1
fi

echo "✅ Adresse IP trouvée: $IP"
echo ""

# Configuration pour iOS
API_URL="http://$IP:3000/api"
SOCKET_URL="http://$IP:3000"

echo "📋 Configuration à utiliser:"
echo "   API Base URL: $API_URL"
echo "   Socket Base URL: $SOCKET_URL"
echo ""

# Instructions pour l'app iOS
echo "📱 Instructions pour l'app iOS:"
echo ""
echo "Option 1: Configuration via UserDefaults (Recommandé)"
echo "   1. Ouvrir l'app iOS dans Xcode"
echo "   2. Lancer l'app sur le simulateur"
echo "   3. Aller dans les paramètres de l'app"
echo "   4. Trouver 'Configuration Backend'"
echo "   5. Configurer:"
echo "      - API Base URL: $API_URL"
echo "      - Socket Base URL: $SOCKET_URL"
echo ""

echo "Option 2: Modification du code"
echo "   Modifier ConfigurationService.swift:"
echo "   - Remplacer l'IP par défaut par: $IP"
echo ""

# Mettre à jour le fichier Info.plist si nécessaire
INFO_PLIST="Tshiakani VTC/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "⚠️  Info.plist trouvé. Vous pouvez aussi configurer:"
    echo "   <key>API_BASE_URL</key>"
    echo "   <string>$API_URL</string>"
    echo "   <key>WS_BASE_URL</key>"
    echo "   <string>$SOCKET_URL</string>"
    echo ""
fi

# Configuration CORS
echo "🔧 Configuration CORS dans le backend:"
echo ""
echo "Ajoutez cette ligne dans backend/.env:"
echo "CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://$IP:3000"
echo ""

echo "✅ Configuration terminée!"
echo ""
echo "Prochaines étapes:"
echo "   1. Configurer CORS dans backend/.env"
echo "   2. Redémarrer le serveur backend"
echo "   3. Configurer l'app iOS avec les URLs ci-dessus"
echo "   4. Tester la connexion depuis l'app"
echo ""

