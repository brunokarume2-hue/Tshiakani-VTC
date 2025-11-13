#!/bin/bash

# Script de vérification des fonctionnalités pour le lancement à Kinshasa
# Vérifie que toutes les fonctionnalités essentielles sont activées
# et que les fonctionnalités non essentielles sont désactivées

echo "🔍 Vérification des fonctionnalités pour le lancement à Kinshasa..."
echo ""

# Couleurs pour l'affichage
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctionnalités essentielles (doivent être activées)
ESSENTIAL_FEATURES=(
    "authentication"
    "immediateRideBooking"
    "realtimeTracking"
    "payment"
    "rideHistory"
    "rating"
)

# Fonctionnalités à désactiver (doivent être désactivées)
DISABLED_FEATURES=(
    "scheduledRides"
    "shareRide"
    "chatWithDriver"
    "advancedFavorites"
    "sosAdvanced"
    "advancedPromotions"
    "useFirebase"
)

# Vérifier FeatureFlags.swift
FEATURE_FLAGS_FILE="Tshiakani VTC/Resources/FeatureFlags.swift"

if [ ! -f "$FEATURE_FLAGS_FILE" ]; then
    echo -e "${RED}❌ Fichier FeatureFlags.swift non trouvé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Fichier FeatureFlags.swift trouvé${NC}"
echo ""

# Vérifier les fonctionnalités essentielles
echo "🔍 Vérification des fonctionnalités essentielles..."
echo ""

for feature in "${ESSENTIAL_FEATURES[@]}"; do
    if grep -q "static let $feature = true" "$FEATURE_FLAGS_FILE"; then
        echo -e "${GREEN}✅ $feature: activé${NC}"
    else
        echo -e "${RED}❌ $feature: désactivé (devrait être activé)${NC}"
    fi
done

echo ""
echo "🔍 Vérification des fonctionnalités à désactiver..."
echo ""

for feature in "${DISABLED_FEATURES[@]}"; do
    if grep -q "static let $feature = false" "$FEATURE_FLAGS_FILE"; then
        echo -e "${GREEN}✅ $feature: désactivé${NC}"
    else
        echo -e "${YELLOW}⚠️  $feature: activé (devrait être désactivé pour le lancement)${NC}"
    fi
done

echo ""
echo "🔍 Vérification des fichiers modifiés..."
echo ""

# Vérifier ClientHomeView.swift
if grep -q "FeatureFlags.scheduledRides" "Tshiakani VTC/Views/Client/ClientHomeView.swift"; then
    echo -e "${GREEN}✅ ClientHomeView.swift: utilise FeatureFlags${NC}"
else
    echo -e "${YELLOW}⚠️  ClientHomeView.swift: ne utilise pas FeatureFlags${NC}"
fi

# Vérifier RideTrackingView.swift
if grep -q "FeatureFlags.chatWithDriver" "Tshiakani VTC/Views/Client/RideTrackingView.swift"; then
    echo -e "${GREEN}✅ RideTrackingView.swift: utilise FeatureFlags${NC}"
else
    echo -e "${YELLOW}⚠️  RideTrackingView.swift: ne utilise pas FeatureFlags${NC}"
fi

# Vérifier ProfileSettingsView.swift
if grep -q "FeatureFlags.advancedFavorites" "Tshiakani VTC/Views/Profile/ProfileSettingsView.swift"; then
    echo -e "${GREEN}✅ ProfileSettingsView.swift: utilise FeatureFlags${NC}"
else
    echo -e "${YELLOW}⚠️  ProfileSettingsView.swift: ne utilise pas FeatureFlags${NC}"
fi

echo ""
echo "🔍 Vérification des services..."
echo ""

# Vérifier que Firebase n'est pas utilisé dans RealtimeService
if grep -q "firebaseService" "Tshiakani VTC/Services/RealtimeService.swift"; then
    echo -e "${RED}❌ RealtimeService.swift: utilise Firebase (devrait utiliser WebSocket uniquement)${NC}"
else
    echo -e "${GREEN}✅ RealtimeService.swift: n'utilise pas Firebase${NC}"
fi

# Vérifier que Firebase n'est pas utilisé dans APIService
if grep -q "firebaseService" "Tshiakani VTC/Services/APIService.swift"; then
    echo -e "${YELLOW}⚠️  APIService.swift: utilise Firebase (peut être optimisé)${NC}"
else
    echo -e "${GREEN}✅ APIService.swift: n'utilise pas Firebase${NC}"
fi

# Vérifier que WebSocket est utilisé
if grep -q "SocketIOService\|IntegrationBridgeService" "Tshiakani VTC/Services/RealtimeService.swift"; then
    echo -e "${GREEN}✅ RealtimeService.swift: utilise WebSocket${NC}"
else
    echo -e "${RED}❌ RealtimeService.swift: n'utilise pas WebSocket${NC}"
fi

echo ""
echo "📋 Résumé:"
echo "   - Fonctionnalités essentielles: ${#ESSENTIAL_FEATURES[@]}"
echo "   - Fonctionnalités à désactiver: ${#DISABLED_FEATURES[@]}"
echo ""

echo "✅ Vérification terminée!"
echo ""
echo "💡 Pour activer/désactiver des fonctionnalités, modifiez FeatureFlags.swift"

