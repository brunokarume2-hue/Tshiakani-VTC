#!/bin/bash

# 🧪 Script de test amélioré pour l'envoi d'OTP

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# URL de l'API backend (Cloud Run)
BACKEND_URL="https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api"

# Vérifier les arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 <phoneNumber> [channel]"
    log_info "Exemple: $0 +243847305825 sms"
    log_info "Exemple: $0 +243820098808 sms"
    exit 1
fi

PHONE_NUMBER="$1"
CHANNEL="${2:-sms}" # Canal par défaut: sms

echo -e "${CYAN}🧪 Test amélioré de l'envoi d'OTP${NC}"
echo ""
log_info "📋 Paramètres :"
log_info "  Numéro : ${PHONE_NUMBER}"
log_info "  Canal : ${CHANNEL}"
log_info "  Backend : ${BACKEND_URL}"
echo ""
log_info "🔄 Envoi du code OTP en cours..."
echo ""

START_TIME=$(date +%s)

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BACKEND_URL}/auth/send-otp" \
  -H 'Content-Type: application/json' \
  -d "{\"phoneNumber\": \"${PHONE_NUMBER}\", \"channel\": \"${CHANNEL}\"}")

HTTP_CODE=$(echo "${RESPONSE}" | tail -n1)
BODY=$(echo "${RESPONSE}" | sed '$d')

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
log_info "📥 Réponse de l'API :"
echo "${BODY}" | jq . 2>/dev/null || echo "${BODY}"

echo ""
log_info "📊 Informations :"
log_info "  Code HTTP : ${HTTP_CODE}"
log_info "  Durée : ${DURATION}s"

if [ "${HTTP_CODE}" = "200" ]; then
    if echo "${BODY}" | grep -q '"success": true'; then
        log_success "✅ ✅ ✅ Code OTP envoyé avec succès !"
        
        # Extraire le code OTP si présent (dev only)
        CODE=$(echo "${BODY}" | jq -r '.code // empty' 2>/dev/null)
        if [ -n "${CODE}" ] && [ "${CODE}" != "null" ]; then
            log_info "🔑 Code OTP (dev only) : ${CODE}"
        fi
        
        # Extraire le messageId
        MESSAGE_ID=$(echo "${BODY}" | jq -r '.messageId // empty' 2>/dev/null)
        if [ -n "${MESSAGE_ID}" ] && [ "${MESSAGE_ID}" != "null" ]; then
            log_info "📨 Message ID : ${MESSAGE_ID}"
        fi
        
        # Extraire le canal utilisé
        CHANNEL_USED=$(echo "${BODY}" | jq -r '.channel // empty' 2>/dev/null)
        if [ -n "${CHANNEL_USED}" ] && [ "${CHANNEL_USED}" != "null" ]; then
            log_info "📱 Canal utilisé : ${CHANNEL_USED}"
        fi
        
        echo ""
        log_info "💡 Prochaines étapes :"
        log_info "  1. Vérifier votre téléphone pour le SMS"
        log_info "  2. Vérifier les logs Cloud Run pour plus de détails"
        log_info "  3. Tester la vérification du code OTP"
    else
        log_warning "⚠️  Réponse inattendue"
    fi
else
    log_error "❌ Erreur lors de l'envoi du code OTP"
    
    # Extraire le message d'erreur
    ERROR_MSG=$(echo "${BODY}" | jq -r '.error // .message // "Erreur inconnue"' 2>/dev/null)
    if [ -n "${ERROR_MSG}" ] && [ "${ERROR_MSG}" != "null" ]; then
        log_error "  Message : ${ERROR_MSG}"
    fi
    
    echo ""
    log_info "💡 Raisons possibles :"
    log_info "  1. Numéro de téléphone invalide"
    log_info "  2. Numéro non vérifié dans Twilio (compte trial)"
    log_info "  3. Crédits Twilio insuffisants"
    log_info "  4. Configuration Twilio manquante"
    log_info "  5. Service temporairement indisponible"
    echo ""
    log_info "🔍 Vérifier les logs Cloud Run :"
    log_info "  gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=tshiakani-vtc-backend AND textPayload=~'OTP'\" --limit=10 --format=json --freshness=10m"
fi

echo ""

