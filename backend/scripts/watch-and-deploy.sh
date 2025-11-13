#!/bin/bash

# Script de surveillance de la facturation et déploiement automatique
# Usage: bash scripts/watch-and-deploy.sh

set -e

echo "🔍 Surveillance de la Facturation et Déploiement Automatique"
echo "============================================================"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
CHECK_INTERVAL=30  # Vérifier toutes les 30 secondes
MAX_ATTEMPTS=120   # Maximum 60 minutes (120 * 30 secondes)

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

section() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Vérifier la facturation
check_billing() {
    BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)" 2>/dev/null || echo "false")
    echo "$BILLING_ENABLED"
}

# Afficher les instructions
show_instructions() {
    echo ""
    section "Instructions pour Activer la Facturation"
    echo ""
    echo "1. Aller sur https://console.cloud.google.com"
    echo "2. Sélectionner le projet: $PROJECT_ID"
    echo "3. Aller dans: Facturation > Gérer les comptes de facturation"
    echo "4. Cliquer sur: Lier un compte de facturation"
    echo "5. Suivre les instructions pour activer la facturation"
    echo "6. Attendre quelques minutes"
    echo ""
}

# Vérification initiale
section "Vérification Initiale de la Facturation"
BILLING_ENABLED=$(check_billing)

if [ "$BILLING_ENABLED" = "true" ]; then
    info "Facturation déjà activée !"
    echo ""
    section "Lancement du Déploiement Automatique"
    echo ""
    bash scripts/setup-and-deploy.sh
    exit 0
else
    error "Facturation non activée"
    show_instructions
fi

echo ""
section "Surveillance de la Facturation"
echo "Vérification toutes les $CHECK_INTERVAL secondes..."
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

# Surveillance de la facturation
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    echo -n "[Tentative $ATTEMPT/$MAX_ATTEMPTS] Vérification de la facturation... "
    
    BILLING_ENABLED=$(check_billing)
    
    if [ "$BILLING_ENABLED" = "true" ]; then
        echo ""
        info "Facturation activée !"
        echo ""
        section "Lancement du Déploiement Automatique"
        echo ""
        bash scripts/setup-and-deploy.sh
        exit 0
    else
        echo "❌ Non activée"
        if [ $((ATTEMPT % 10)) -eq 0 ]; then
            echo ""
            warn "Facturation toujours non activée après $((ATTEMPT * CHECK_INTERVAL / 60)) minutes"
            echo "   Vérifiez que vous avez bien activé la facturation dans GCP Console"
            echo ""
        fi
    fi
    
    # Attendre avant la prochaine vérification
    sleep $CHECK_INTERVAL
done

echo ""
error "Timeout : La facturation n'a pas été activée dans le délai imparti"
echo ""
show_instructions
echo ""
echo "Pour continuer manuellement, exécutez :"
echo "   bash scripts/setup-and-deploy.sh"
echo ""
exit 1

