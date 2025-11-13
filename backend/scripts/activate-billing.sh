#!/bin/bash

# Script pour activer la facturation (si un compte de facturation existe)
# Usage: bash scripts/activate-billing.sh

set -e

echo "🔍 Activation de la Facturation - Tshiakani VTC"
echo "============================================================"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"

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

# Vérifier l'état actuel
section "Vérification de l'état actuel"
BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "true" ]; then
    info "Facturation déjà activée !"
    BILLING_ACCOUNT=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingAccountName)" 2>/dev/null || echo "")
    if [ ! -z "$BILLING_ACCOUNT" ]; then
        info "Compte de facturation: $BILLING_ACCOUNT"
    fi
    echo ""
    section "Lancement du Déploiement Automatique"
    echo ""
    bash scripts/setup-and-deploy.sh
    exit 0
fi

echo ""

# Vérifier les comptes de facturation disponibles
section "Vérification des comptes de facturation disponibles"
BILLING_ACCOUNTS=$(gcloud billing accounts list --format="value(name,displayName,open)" 2>/dev/null || echo "")

if [ -z "$BILLING_ACCOUNTS" ]; then
    error "Aucun compte de facturation trouvé"
    echo ""
    warn "Pour activer la facturation, vous devez :"
    echo ""
    echo "1. Aller sur https://console.cloud.google.com/billing"
    echo "2. Cliquer sur 'Créer un compte de facturation'"
    echo "3. Suivre les instructions pour créer un compte de facturation"
    echo "4. Une fois le compte créé, exécutez à nouveau ce script"
    echo ""
    echo "Ou utilisez cette commande pour lier manuellement :"
    echo "   gcloud billing projects link ${PROJECT_ID} --billing-account=BILLING_ACCOUNT_ID"
    echo ""
    exit 1
fi

echo ""
info "Comptes de facturation disponibles :"
echo ""

# Afficher les comptes de facturation
gcloud billing accounts list --format="table(name,displayName,open)" 2>/dev/null || echo ""

echo ""

# Chercher un compte de facturation ouvert
OPEN_BILLING_ACCOUNT=$(gcloud billing accounts list --filter="open=true" --format="value(name)" --limit=1 2>/dev/null || echo "")

if [ ! -z "$OPEN_BILLING_ACCOUNT" ]; then
    info "Compte de facturation ouvert trouvé: $OPEN_BILLING_ACCOUNT"
    echo ""
    section "Tentative de liaison du projet au compte de facturation"
    echo ""
    
    if gcloud billing projects link ${PROJECT_ID} --billing-account=${OPEN_BILLING_ACCOUNT} 2>&1; then
        info "Projet lié au compte de facturation avec succès !"
        echo ""
        
        # Vérifier que la facturation est activée
        sleep 5
        BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)" 2>/dev/null || echo "false")
        
        if [ "$BILLING_ENABLED" = "true" ]; then
            info "Facturation activée avec succès !"
            echo ""
            section "Lancement du Déploiement Automatique"
            echo ""
            bash scripts/setup-and-deploy.sh
            exit 0
        else
            warn "La facturation peut prendre quelques minutes pour être activée"
            echo ""
            echo "Vérifiez avec :"
            echo "   gcloud billing projects describe ${PROJECT_ID} --format=\"value(billingEnabled)\""
            echo ""
            echo "Une fois activée, exécutez :"
            echo "   bash scripts/setup-and-deploy.sh"
            echo ""
            exit 0
        fi
    else
        error "Échec de la liaison du projet au compte de facturation"
        echo ""
        warn "Cela peut être dû à :"
        echo "   - Permissions insuffisantes"
        echo "   - Compte de facturation fermé ou suspendu"
        echo "   - Nécessité d'une action manuelle dans la console"
        echo ""
        show_manual_instructions
        exit 1
    fi
else
    warn "Aucun compte de facturation ouvert trouvé"
    echo ""
    show_manual_instructions
    exit 1
fi

show_manual_instructions() {
    echo ""
    section "Instructions Manuelles pour Activer la Facturation"
    echo ""
    echo "1. Aller sur https://console.cloud.google.com"
    echo "2. Sélectionner le projet: ${PROJECT_ID}"
    echo "3. Aller dans: Facturation > Gérer les comptes de facturation"
    echo "4. Cliquer sur: Lier un compte de facturation"
    echo "5. Sélectionner un compte de facturation existant ou créer un nouveau compte"
    echo "6. Suivre les instructions pour activer la facturation"
    echo "7. Attendre quelques minutes pour que la facturation soit activée"
    echo ""
    echo "Une fois la facturation activée, exécutez :"
    echo "   bash scripts/setup-and-deploy.sh"
    echo ""
}

