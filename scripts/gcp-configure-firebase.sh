#!/bin/bash

# 🔥 Script de Configuration Firebase FCM
# Configure Firebase Cloud Messaging pour Tshiakani VTC

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Configuration par défaut
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc-477711}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${CLOUD_RUN_SERVICE_NAME:-tshiakani-vtc-backend}"
SECRET_NAME="firebase-service-account"

log_info "Configuration Firebase FCM"
log_info "  Project ID: $PROJECT_ID"
log_info "  Region: $REGION"
log_info "  Service Name: $SERVICE_NAME"
echo ""

# Vérifier que gcloud est installé
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI n'est pas installé"
    exit 1
fi

gcloud config set project "$PROJECT_ID"

# Demander le chemin du fichier JSON
if [ -z "$FIREBASE_KEY_FILE" ]; then
    log_info "Chemin du fichier JSON Firebase (téléchargé depuis Firebase Console)"
    read -p "Chemin du fichier (ex: ~/Downloads/tshiakani-vtc-477711-xxxxx.json): " FIREBASE_KEY_FILE
fi

# Vérifier que le fichier existe
if [ ! -f "$FIREBASE_KEY_FILE" ]; then
    log_error "Le fichier n'existe pas: $FIREBASE_KEY_FILE"
    log_info "Téléchargez le fichier depuis Firebase Console :"
    log_info "  Paramètres du projet → Comptes de service → Générer une nouvelle clé privée"
    exit 1
fi

log_success "Fichier trouvé: $FIREBASE_KEY_FILE"

# Créer ou mettre à jour le secret
log_info "Stockage dans Secret Manager..."
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" --quiet &>/dev/null; then
    log_warning "Le secret existe déjà, création d'une nouvelle version..."
    cat "$FIREBASE_KEY_FILE" | gcloud secrets versions add "$SECRET_NAME" \
        --data-file=- \
        --project="$PROJECT_ID"
    log_success "Nouvelle version du secret créée"
else
    cat "$FIREBASE_KEY_FILE" | gcloud secrets create "$SECRET_NAME" \
        --data-file=- \
        --project="$PROJECT_ID"
    log_success "Secret créé dans Secret Manager"
fi

# Configurer les permissions IAM
log_info "Configuration des permissions IAM..."
SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(spec.template.spec.serviceAccountName)" 2>/dev/null || echo "418102154417-compute@developer.gserviceaccount.com")

if [ -n "$SERVICE_ACCOUNT" ]; then
    gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
        --member="serviceAccount:${SERVICE_ACCOUNT}" \
        --role="roles/secretmanager.secretAccessor" \
        --project="$PROJECT_ID" \
        --quiet
    
    log_success "Permissions IAM configurées pour: $SERVICE_ACCOUNT"
else
    log_warning "Impossible de récupérer le service account"
fi

# Mettre à jour les variables d'environnement
log_info "Mise à jour des variables d'environnement Cloud Run..."

# Récupérer le projet Firebase depuis le fichier JSON
FIREBASE_PROJECT_ID=$(cat "$FIREBASE_KEY_FILE" | grep -o '"project_id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "$PROJECT_ID")

gcloud run services update "$SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --update-env-vars="FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID" \
    --quiet

log_success "Variable d'environnement FIREBASE_PROJECT_ID mise à jour: $FIREBASE_PROJECT_ID"

# Résumé
echo ""
log_success "✅ Configuration Firebase FCM complétée !"
echo ""
log_info "Résumé :"
log_info "  - Secret créé : $SECRET_NAME"
log_info "  - Permissions configurées : $SERVICE_ACCOUNT"
log_info "  - Variable d'environnement : FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID"
echo ""
log_info "Prochaines étapes :"
log_info "  1. Vérifier que le code backend utilise firebase-admin correctement"
log_info "  2. Tester l'envoi de notifications"
log_info "  3. Configurer les tokens FCM dans les applications mobiles"

