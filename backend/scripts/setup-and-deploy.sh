#!/bin/bash

# Script automatique de configuration et déploiement
# Usage: bash scripts/setup-and-deploy.sh

set -e

echo "🚀 Configuration et Déploiement Automatique - Tshiakani VTC"
echo "============================================================"
echo ""

# Variables
PROJECT_ID="tshiakani-vtc-99cea"
REGION="us-central1"

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}✅ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Étape 1 : Vérifier la facturation
echo "📋 Étape 1 : Vérification de la facturation..."
BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" = "true" ]; then
    info "Facturation activée"
    BILLING_ACCOUNT=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingAccountName)" 2>/dev/null || echo "")
    if [ ! -z "$BILLING_ACCOUNT" ]; then
        info "Compte de facturation: $BILLING_ACCOUNT"
    fi
else
    error "Facturation non activée"
    echo ""
    echo "📝 Pour activer la facturation:"
    echo "   1. Aller sur https://console.cloud.google.com"
    echo "   2. Sélectionner le projet: $PROJECT_ID"
    echo "   3. Aller dans Facturation > Gérer les comptes de facturation"
    echo "   4. Cliquer sur 'Lier un compte de facturation'"
    echo "   5. Suivre les instructions pour activer la facturation"
    echo ""
    echo "⚠️  Le script ne peut pas continuer sans facturation activée."
    echo "   Une fois la facturation activée, relancez ce script."
    exit 1
fi

echo ""

# Étape 2 : Activer les APIs nécessaires
echo "📋 Étape 2 : Activation des APIs nécessaires..."

APIS=(
    "cloudbuild.googleapis.com"
    "run.googleapis.com"
    "artifactregistry.googleapis.com"
    "containerregistry.googleapis.com"
    "cloudresourcemanager.googleapis.com"
)

for API in "${APIS[@]}"; do
    echo -n "   Activation de $API... "
    if gcloud services enable $API --project=${PROJECT_ID} 2>/dev/null; then
        info "Activé"
    else
        # Vérifier si l'API est déjà activée
        if gcloud services list --enabled --project=${PROJECT_ID} --filter="name:$API" --format="value(name)" 2>/dev/null | grep -q "$API"; then
            info "Déjà activé"
        else
            warn "Échec (peut nécessiter des permissions supplémentaires)"
        fi
    fi
done

echo ""

# Étape 3 : Vérifier les APIs activées
echo "📋 Étape 3 : Vérification des APIs activées..."
ENABLED_APIS=$(gcloud services list --enabled --project=${PROJECT_ID} --format="value(name)" 2>/dev/null || echo "")

for API in "${APIS[@]}"; do
    if echo "$ENABLED_APIS" | grep -q "$API"; then
        info "$API est activé"
    else
        warn "$API n'est pas activé"
    fi
done

echo ""

# Étape 4 : Vérifier la configuration Redis
echo "📋 Étape 4 : Vérification de la configuration Redis..."

if [ -f "scripts/deploy-cloud-run.sh" ]; then
    if grep -q "REDIS_URL=" scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_URL=""' scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_URL=" "' scripts/deploy-cloud-run.sh; then
        info "REDIS_URL configuré dans deploy-cloud-run.sh"
        REDIS_URL=$(grep "REDIS_URL=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$REDIS_URL" ] && [ "$REDIS_URL" != "" ]; then
            info "Upstash Redis configuré (gratuit)"
        fi
    elif grep -q "REDIS_HOST=" scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_HOST=""' scripts/deploy-cloud-run.sh && ! grep -q 'REDIS_HOST=" "' scripts/deploy-cloud-run.sh; then
        info "REDIS_HOST configuré dans deploy-cloud-run.sh"
        REDIS_HOST=$(grep "REDIS_HOST=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$REDIS_HOST" ] && [ "$REDIS_HOST" != "" ]; then
            info "Redis Memorystore configuré (payant)"
        fi
    else
        warn "Redis non configuré (mode dégradé)"
        echo ""
        echo "📝 Pour configurer Upstash Redis (gratuit):"
        echo "   1. Créer un compte sur https://upstash.com/"
        echo "   2. Créer une base de données Redis (tier gratuit)"
        echo "   3. Récupérer l'URL de connexion (REDIS_URL)"
        echo "   4. Configurer REDIS_URL dans scripts/deploy-cloud-run.sh"
        echo ""
        echo "   Voir GUIDE_UPSTASH_REDIS.md pour le guide complet"
    fi
else
    warn "Fichier deploy-cloud-run.sh non trouvé"
fi

echo ""

# Étape 5 : Vérifier la configuration Twilio
echo "📋 Étape 5 : Vérification de la configuration Twilio..."

if [ -f "scripts/deploy-cloud-run.sh" ]; then
    if grep -q "TWILIO_ACCOUNT_SID=" scripts/deploy-cloud-run.sh && ! grep -q 'TWILIO_ACCOUNT_SID=""' scripts/deploy-cloud-run.sh; then
        TWILIO_SID=$(grep "TWILIO_ACCOUNT_SID=" scripts/deploy-cloud-run.sh | head -1 | cut -d'"' -f2)
        if [ ! -z "$TWILIO_SID" ] && [ "$TWILIO_SID" != "" ]; then
            info "Twilio configuré"
        else
            warn "Twilio non configuré"
        fi
    else
        warn "Twilio non configuré"
    fi
fi

echo ""

# Étape 6 : Déployer le backend
echo "📋 Étape 6 : Déploiement du backend..."
echo ""

if [ -f "scripts/deploy-cloud-run.sh" ]; then
    info "Lancement du script de déploiement..."
    echo ""
    bash scripts/deploy-cloud-run.sh
else
    error "Fichier deploy-cloud-run.sh non trouvé"
    exit 1
fi

echo ""
echo "============================================================"
info "Configuration et déploiement terminés !"
echo "============================================================"
echo ""

# Étape 7 : Vérifier le déploiement
echo "📋 Étape 7 : Vérification du déploiement..."
echo ""

SERVICE_NAME="tshiakani-driver-backend"
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region=${REGION} --project=${PROJECT_ID} --format="value(status.url)" 2>/dev/null || echo "")

if [ ! -z "$SERVICE_URL" ]; then
    info "Service déployé avec succès"
    info "URL du service: $SERVICE_URL"
    echo ""
    echo "🧪 Test de la route de santé..."
    if curl -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/health" | grep -q "200\|404"; then
        info "Service accessible"
    else
        warn "Service peut prendre quelques minutes pour être accessible"
    fi
else
    warn "Impossible de récupérer l'URL du service"
fi

echo ""
echo "============================================================"
info "Déploiement terminé !"
echo "============================================================"
echo ""
echo "📝 Prochaines étapes:"
echo "   1. Vérifier les logs Cloud Run pour confirmer la connexion Redis"
echo "   2. Tester l'inscription avec OTP depuis l'URL du service"
echo "   3. Configurer Upstash Redis (gratuit) si ce n'est pas déjà fait"
echo ""
echo "📚 Documentation:"
echo "   → GUIDE_UPSTASH_REDIS.md"
echo "   → REDEPLOIEMENT_REDIS.md"
echo "   → PROCHAINES_ETAPES_ACTUELLES.md"
echo ""

