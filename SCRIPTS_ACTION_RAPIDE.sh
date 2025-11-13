#!/bin/bash

# Scripts d'action rapide pour les prochaines étapes
# Usage: ./SCRIPTS_ACTION_RAPIDE.sh [action]

set -e

ACTION="${1:-help}"

case "$ACTION" in
    "test-api")
        echo "🧪 Test des endpoints API..."
        cd backend
        ./scripts/test-api.sh
        ;;
    "config-ios")
        echo "📱 Configuration iOS..."
        # Trouver l'adresse IP
        IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
        echo "Adresse IP trouvée: $IP"
        echo ""
        echo "Configuration à utiliser dans l'app iOS:"
        echo "  API Base URL: http://$IP:3000/api"
        echo "  Socket Base URL: http://$IP:3000"
        echo ""
        echo "Option 1: Utiliser UserDefaults dans l'app"
        echo "Option 2: Modifier ConfigurationService.swift"
        ;;
    "config-dashboard")
        echo "🎨 Configuration Dashboard..."
        cd admin-dashboard
        if [ ! -f ".env.local" ]; then
            echo "VITE_API_URL=http://localhost:3000/api" > .env.local
            echo "VITE_SOCKET_URL=http://localhost:3000" >> .env.local
            echo "✅ Fichier .env.local créé"
        else
            echo "✅ Fichier .env.local existe déjà"
        fi
        echo ""
        echo "Pour démarrer le dashboard:"
        echo "  cd admin-dashboard && npm install && npm run dev"
        ;;
    "config-cors")
        echo "🔧 Configuration CORS..."
        cd backend
        # Trouver l'adresse IP
        IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
        echo "Adresse IP trouvée: $IP"
        echo ""
        echo "Ajoutez cette ligne dans backend/.env:"
        echo "CORS_ORIGIN=http://localhost:3001,http://localhost:5173,capacitor://localhost,ionic://localhost,http://$IP:3000"
        ;;
    "setup-storage")
        echo "☁️  Configuration Cloud Storage..."
        cd backend
        npm run setup:storage
        ;;
    "deploy")
        echo "🚀 Déploiement Cloud Run..."
        cd backend
        gcloud builds submit --tag gcr.io/tshiakani-vtc/tshiakani-vtc-api
        gcloud run deploy tshiakani-vtc-api \
          --image gcr.io/tshiakani-vtc/tshiakani-vtc-api \
          --platform managed \
          --region us-central1 \
          --allow-unauthenticated
        ;;
    "help"|*)
        echo "🚀 Scripts d'Action Rapide - Tshiakani VTC"
        echo ""
        echo "Usage: ./SCRIPTS_ACTION_RAPIDE.sh [action]"
        echo ""
        echo "Actions disponibles:"
        echo "  test-api         - Tester les endpoints API"
        echo "  config-ios       - Configurer l'app iOS"
        echo "  config-dashboard - Configurer le dashboard admin"
        echo "  config-cors      - Configurer CORS pour iOS"
        echo "  setup-storage    - Configurer Cloud Storage"
        echo "  deploy           - Déployer sur Cloud Run"
        echo "  help             - Afficher cette aide"
        ;;
esac

