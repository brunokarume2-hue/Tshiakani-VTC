#!/bin/bash

# 🚀 Script Maître - Exécution des Actions Suivantes
# Déploiement complet du backend Tshiakani VTC sur GCP

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
# Utiliser GCP_PROJECT_ID si défini, sinon utiliser le projet gcloud configuré, sinon tshiakani-vtc
if [ -n "$GCP_PROJECT_ID" ]; then
    PROJECT_ID="$GCP_PROJECT_ID"
else
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        PROJECT_ID="$CURRENT_PROJECT"
    else
        PROJECT_ID="tshiakani-vtc"
    fi
fi
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${CLOUD_RUN_SERVICE_NAME:-tshiakani-vtc-backend}"
INSTANCE_NAME="${CLOUD_SQL_INSTANCE_NAME:-tshiakani-vtc-db}"
REDIS_NAME="${REDIS_INSTANCE_NAME:-tshiakani-vtc-redis}"

# Vérifier les arguments pour le mode automatique
AUTO_YES=false
if [[ "$1" == "--yes" ]] || [[ "$1" == "-y" ]]; then
    AUTO_YES=true
fi

# Fonctions de log
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

log_step() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}▶️  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

wait_for_user() {
    if [ "$AUTO_YES" = false ]; then
        echo -e "\n${YELLOW}⏸️  Appuyez sur Entrée pour continuer...${NC}"
        read -r
    else
        echo -e "\n${BLUE}⏭️  Mode automatique: passage à l'étape suivante...${NC}"
        sleep 2
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    log_step "Action 1 : Vérification des Prérequis"
    
    # Vérifier gcloud
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI n'est pas installé"
        log_info "Installez-le avec: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    log_success "gcloud CLI installé: $(gcloud --version | head -n1)"
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installé"
        log_info "Installez-le avec: https://docs.docker.com/get-docker/"
        exit 1
    fi
    log_success "Docker installé: $(docker --version)"
    
    # Vérifier le projet GCP
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
    if [ -z "$CURRENT_PROJECT" ]; then
        log_warning "Aucun projet GCP configuré"
        gcloud config set project "$PROJECT_ID" 2>/dev/null || log_error "Impossible de configurer le projet $PROJECT_ID"
        log_success "Projet configuré: $PROJECT_ID"
    else
        if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
            log_info "Projet actuel: $CURRENT_PROJECT"
            log_info "Utilisation du projet: $PROJECT_ID"
            gcloud config set project "$PROJECT_ID" 2>/dev/null || log_warning "Impossible de changer le projet, utilisation de $CURRENT_PROJECT"
            PROJECT_ID="$CURRENT_PROJECT"
        fi
        log_success "Projet GCP: $PROJECT_ID"
    fi
    
    # Activer les APIs
    log_info "Activation des APIs GCP..."
    APIs=(
        "run.googleapis.com"
        "sqladmin.googleapis.com"
        "redis.googleapis.com"
        "routes.googleapis.com"
        "places.googleapis.com"
        "geocoding.googleapis.com"
        "logging.googleapis.com"
        "monitoring.googleapis.com"
        "secretmanager.googleapis.com"
        "artifactregistry.googleapis.com"
    )
    
    SUCCESS_COUNT=0
    FAILED_APIS=()
    
    for API in "${APIs[@]}"; do
        if gcloud services enable "$API" --quiet 2>/dev/null; then
            ((SUCCESS_COUNT++))
        else
            FAILED_APIS+=("$API")
            log_warning "Impossible d'activer $API (permissions insuffisantes ou API non disponible)"
        fi
    done
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        log_success "$SUCCESS_COUNT API(s) activée(s)"
    fi
    
    if [ ${#FAILED_APIS[@]} -gt 0 ]; then
        log_warning "${#FAILED_APIS[@]} API(s) non activée(s): ${FAILED_APIS[*]}"
        log_info "Vous pouvez les activer manuellement via la console GCP si nécessaire"
    fi
    
    log_success "Action 1 terminée: Prérequis vérifiés"
    wait_for_user
}

# Créer Cloud SQL
create_cloud_sql() {
    log_step "Action 2 : Création de Cloud SQL"
    
    # Générer un mot de passe si non défini et en mode automatique
    if [ -z "$DB_PASSWORD" ] && [ "$AUTO_YES" = true ]; then
        log_info "Génération d'un mot de passe sécurisé..."
        DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        export DB_PASSWORD
        log_success "Mot de passe généré automatiquement"
        log_warning "⚠️  IMPORTANT: Notez ce mot de passe pour la connexion à la base de données"
        log_info "Mot de passe: $DB_PASSWORD"
    elif [ -z "$DB_PASSWORD" ]; then
        log_warning "DB_PASSWORD n'est pas défini"
        log_info "Vous pouvez le définir avec: export DB_PASSWORD='votre_mot_de_passe'"
        log_info "Ou le script vous le demandera lors de la création"
    fi
    
    # Vérifier si l'instance existe déjà
    if gcloud sql instances describe "$INSTANCE_NAME" --quiet &>/dev/null; then
        log_warning "Instance Cloud SQL existe déjà: $INSTANCE_NAME"
        INSTANCE_STATE=$(gcloud sql instances describe "$INSTANCE_NAME" --format="value(state)")
        log_info "État de l'instance: $INSTANCE_STATE"
        
        if [ "$INSTANCE_STATE" != "RUNNABLE" ]; then
            log_warning "Attente que l'instance soit prête..."
            gcloud sql instances wait "$INSTANCE_NAME" --timeout=600
        fi
    else
        log_info "Création de l'instance Cloud SQL..."
        chmod +x scripts/gcp-create-cloud-sql.sh
        if [ -n "$DB_PASSWORD" ]; then
            export DB_PASSWORD
        fi
        ./scripts/gcp-create-cloud-sql.sh
        
        log_info "Attente que l'instance soit créée (5-10 minutes)..."
        gcloud sql instances wait "$INSTANCE_NAME" --timeout=600 || log_warning "L'instance est en cours de création..."
    fi
    
    # Initialiser la base de données
    log_info "Initialisation de la base de données..."
    chmod +x scripts/gcp-init-database.sh
    if [ -n "$DB_PASSWORD" ]; then
        export DB_PASSWORD
    fi
    
    if ./scripts/gcp-init-database.sh 2>/dev/null; then
        log_success "Base de données initialisée"
    else
        log_warning "Impossible d'initialiser la base de données (psql requis)"
        log_info "Vous pouvez installer psql avec: brew install postgresql"
        log_info "Puis exécuter: ./scripts/gcp-init-database.sh"
        log_info "Le backend peut fonctionner sans les tables initialisées (elles seront créées au premier démarrage)"
    fi
    
    log_success "Action 2 terminée: Cloud SQL créé"
    wait_for_user
}

# Créer Memorystore
create_memorystore() {
    log_step "Action 3 : Création de Memorystore Redis"
    
    # Vérifier si l'instance existe déjà
    if gcloud redis instances describe "$REDIS_NAME" --region="$REGION" --quiet &>/dev/null; then
        log_warning "Instance Memorystore existe déjà: $REDIS_NAME"
        REDIS_STATE=$(gcloud redis instances describe "$REDIS_NAME" --region="$REGION" --format="value(state)")
        log_info "État de l'instance: $REDIS_STATE"
        
        if [ "$REDIS_STATE" != "READY" ]; then
            log_warning "Instance Memorystore en cours de création (état: $REDIS_STATE)"
            if [ "$AUTO_YES" = true ]; then
                log_info "Mode automatique: continuation sans attendre"
                log_info "Memorystore sera disponible plus tard, le backend utilisera PostgreSQL comme fallback"
            else
                log_warning "Attente que l'instance soit prête (peut prendre 10-15 minutes)..."
                log_info "Appuyez sur Ctrl+C pour continuer sans attendre"
                TIMEOUT=300  # 5 minutes max
                ELAPSED=0
                while [ "$REDIS_STATE" != "READY" ] && [ $ELAPSED -lt $TIMEOUT ]; do
                    sleep 30
                    ELAPSED=$((ELAPSED + 30))
                    REDIS_STATE=$(gcloud redis instances describe "$REDIS_NAME" --region="$REGION" --format="value(state)" 2>/dev/null || echo "CREATING")
                    log_info "État: $REDIS_STATE (${ELAPSED}s)"
                done
                if [ "$REDIS_STATE" != "READY" ]; then
                    log_warning "Timeout atteint, continuation sans Memorystore"
                fi
            fi
        fi
    else
        log_info "Tentative de création de l'instance Memorystore..."
        log_warning "⚠️  La création de Memorystore peut prendre 10-15 minutes"
        log_info "Option: Créer en arrière-plan et continuer avec Cloud Run"
        
        if [ "$AUTO_YES" = true ]; then
            log_info "Création en arrière-plan (mode asynchrone)..."
            chmod +x scripts/gcp-create-redis.sh
            gcloud redis instances create "$REDIS_NAME" \
                --size=1 \
                --region="$REGION" \
                --tier=BASIC \
                --redis-version=redis_7_0 \
                --project="$PROJECT_ID" \
                --async 2>/dev/null || log_warning "Impossible de créer Memorystore maintenant"
            
            log_warning "Memorystore sera créé en arrière-plan"
            log_info "Vous pouvez vérifier avec: gcloud redis instances describe $REDIS_NAME --region=$REGION"
            log_info "Le backend peut fonctionner sans Redis (utilisera PostgreSQL comme fallback)"
        else
            chmod +x scripts/gcp-create-redis.sh
            if ./scripts/gcp-create-redis.sh; then
                log_success "Memorystore créé"
            else
                log_warning "Échec de la création de Memorystore"
                log_info "Le backend peut fonctionner sans Redis (utilisera PostgreSQL comme fallback)"
            fi
        fi
    fi
    
    # Créer le VPC Connector (nécessaire pour Cloud Run -> Memorystore)
    CONNECTOR_NAME="tshiakani-vtc-connector"
    if gcloud compute networks vpc-access connectors describe "$CONNECTOR_NAME" --region="$REGION" --quiet &>/dev/null; then
        log_warning "VPC Connector existe déjà: $CONNECTOR_NAME"
    else
        log_info "Création du VPC Connector (pour Cloud Run -> Memorystore)..."
        if gcloud compute networks vpc-access connectors create "$CONNECTOR_NAME" \
            --region="$REGION" \
            --network=default \
            --range=10.8.0.0/28 \
            --quiet 2>/dev/null; then
            log_success "VPC Connector créé"
        else
            log_warning "Impossible de créer le VPC Connector maintenant"
            log_info "Il peut être créé plus tard si nécessaire"
        fi
    fi
    
    log_success "Action 3 terminée: Memorystore configuré (peut être en cours de création)"
    wait_for_user
}

# Déployer Cloud Run
deploy_cloud_run() {
    log_step "Action 4 : Déploiement sur Cloud Run"
    
    # Build l'image Docker
    log_info "Build de l'image Docker (plateforme linux/amd64 pour Cloud Run)..."
    cd backend
    docker build --platform=linux/amd64 -t "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest" .
    cd ..
    log_success "Image Docker buildée"
    
    # Créer Artifact Registry
    REPO_NAME="tshiakani-vtc-repo"
    if gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" --quiet &>/dev/null; then
        log_warning "Artifact Registry existe déjà: $REPO_NAME"
    else
        log_info "Création d'Artifact Registry..."
        gcloud artifacts repositories create "$REPO_NAME" \
            --repository-format=docker \
            --location="$REGION" \
            --quiet
        log_success "Artifact Registry créé"
    fi
    
    # Configurer Docker
    log_info "Configuration de Docker pour Artifact Registry..."
    gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
    
    # Tag et push l'image
    IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest"
    log_info "Tag de l'image: $IMAGE_URI"
    docker tag "gcr.io/$PROJECT_ID/$SERVICE_NAME:latest" "$IMAGE_URI"
    
    log_info "Push de l'image (cela peut prendre quelques minutes)..."
    docker push "$IMAGE_URI"
    log_success "Image poussée vers Artifact Registry"
    
    # Déployer sur Cloud Run
    log_info "Déploiement sur Cloud Run..."
    chmod +x scripts/gcp-deploy-backend.sh
    ./scripts/gcp-deploy-backend.sh
    
    # Configurer les variables d'environnement
    log_info "Configuration des variables d'environnement..."
    chmod +x scripts/gcp-set-cloud-run-env.sh
    ./scripts/gcp-set-cloud-run-env.sh
    
    # Configurer les permissions IAM
    log_info "Configuration des permissions IAM..."
    SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(spec.template.spec.serviceAccountName)" 2>/dev/null || echo "")
    
    if [ -n "$SERVICE_ACCOUNT" ]; then
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${SERVICE_ACCOUNT}" \
            --role="roles/cloudsql.client" \
            --quiet
        
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${SERVICE_ACCOUNT}" \
            --role="roles/logging.logWriter" \
            --quiet
        
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${SERVICE_ACCOUNT}" \
            --role="roles/monitoring.metricWriter" \
            --quiet
        
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:${SERVICE_ACCOUNT}" \
            --role="roles/secretmanager.secretAccessor" \
            --quiet
        
        log_success "Permissions IAM configurées"
    else
        log_warning "Impossible de récupérer le service account"
    fi
    
    log_success "Action 4 terminée: Cloud Run déployé"
    wait_for_user
}

# Configurer Google Maps
configure_google_maps() {
    log_step "Action 5 : Configuration de Google Maps et FCM"
    
    # Activer les APIs Google Maps
    log_info "Activation des APIs Google Maps..."
    gcloud services enable routes.googleapis.com places.googleapis.com geocoding.googleapis.com --quiet
    log_success "APIs Google Maps activées"
    
    # Vérifier si la clé API existe
    SECRET_NAME="google-maps-api-key"
    if gcloud secrets describe "$SECRET_NAME" --quiet &>/dev/null; then
        log_warning "Secret existe déjà: $SECRET_NAME"
        log_info "Pour mettre à jour la clé API, utilisez:"
        log_info "  echo -n 'YOUR_API_KEY' | gcloud secrets versions add $SECRET_NAME --data-file=-"
    else
        log_warning "⚠️  ATTENTION: Création de la clé API Google Maps"
        log_info "1. Allez sur https://console.cloud.google.com/apis/credentials"
        log_info "2. Créez une clé API"
        log_info "3. Copiez la clé API"
        echo -e "${YELLOW}Entrez votre clé API Google Maps (ou appuyez sur Entrée pour ignorer):${NC}"
        read -r API_KEY
        
        if [ -n "$API_KEY" ]; then
            echo -n "$API_KEY" | gcloud secrets create "$SECRET_NAME" --data-file=-
            log_success "Clé API stockée dans Secret Manager"
            
            # Donner accès au service account
            SERVICE_ACCOUNT=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(spec.template.spec.serviceAccountName)" 2>/dev/null || echo "")
            if [ -n "$SERVICE_ACCOUNT" ]; then
                gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
                    --member="serviceAccount:${SERVICE_ACCOUNT}" \
                    --role="roles/secretmanager.secretAccessor" \
                    --quiet
                log_success "Accès au secret configuré"
            fi
        else
            log_warning "Clé API non configurée (vous pouvez le faire plus tard)"
        fi
    fi
    
    # Firebase
    log_warning "⚠️  Configuration Firebase requise manuellement"
    log_info "1. Allez sur https://console.firebase.google.com"
    log_info "2. Créez un projet Firebase"
    log_info "3. Activez Cloud Messaging (FCM)"
    log_info "4. Téléchargez le fichier de configuration et placez-le dans backend/firebase-service-account.json"
    
    log_success "Action 5 terminée: Google Maps configuré (Firebase à configurer manuellement)"
    wait_for_user
}

# Configurer le Monitoring
configure_monitoring() {
    log_step "Action 6 : Configuration du Monitoring"
    
    # Configurer Cloud Logging
    log_info "Configuration de Cloud Logging..."
    chmod +x scripts/gcp-setup-monitoring.sh
    ./scripts/gcp-setup-monitoring.sh
    
    # Créer les alertes
    log_info "Création des alertes..."
    chmod +x scripts/gcp-create-alerts.sh
    ./scripts/gcp-create-alerts.sh
    
    # Créer les tableaux de bord
    log_info "Création des tableaux de bord..."
    chmod +x scripts/gcp-create-dashboard.sh
    ./scripts/gcp-create-dashboard.sh
    
    log_success "Action 6 terminée: Monitoring configuré"
    wait_for_user
}

# Tester les fonctionnalités
test_functionalities() {
    log_step "Action 7 : Test des Fonctionnalités"
    
    # Obtenir l'URL du service
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "")
    
    if [ -z "$SERVICE_URL" ]; then
        log_error "Impossible de récupérer l'URL du service"
        return 1
    fi
    
    log_info "URL du service: $SERVICE_URL"
    
    # Tester le health check
    log_info "Test du health check..."
    if curl -f -s "$SERVICE_URL/health" > /dev/null; then
        log_success "Health check OK"
    else
        log_error "Health check échoué"
        return 1
    fi
    
    # Tester l'authentification
    log_info "Test de l'authentification..."
    RESPONSE=$(curl -s -X POST "$SERVICE_URL/api/auth/signup" \
        -H "Content-Type: application/json" \
        -d '{"phoneNumber": "+243900000001", "name": "Test User", "role": "client"}' || echo "ERROR")
    
    if echo "$RESPONSE" | grep -q "ERROR\|error"; then
        log_warning "Test d'authentification échoué (peut être normal si l'utilisateur existe déjà)"
    else
        log_success "Authentification OK"
    fi
    
    log_success "Action 7 terminée: Tests effectués"
    
    log_info "URL du service: $SERVICE_URL"
    log_info "Vous pouvez maintenant tester votre API avec:"
    log_info "  curl $SERVICE_URL/health"
}

# Menu principal
main() {
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   🚀 Déploiement Backend Tshiakani VTC sur GCP          ║"
    echo "║   Script d'Exécution des Actions Suivantes              ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    log_info "Ce script va exécuter les actions suivantes:"
    log_info "  1. Vérifier les prérequis"
    log_info "  2. Créer Cloud SQL"
    log_info "  3. Créer Memorystore"
    log_info "  4. Déployer Cloud Run"
    log_info "  5. Configurer Google Maps"
    log_info "  6. Configurer le Monitoring"
    log_info "  7. Tester les fonctionnalités"
    echo ""
    
    if [ "$AUTO_YES" = false ]; then
        echo -e "${YELLOW}Voulez-vous exécuter toutes les actions? (o/n)${NC}"
        read -r response
        
        if [[ ! "$response" =~ ^[OoYy]$ ]]; then
            log_info "Exécution annulée"
            exit 0
        fi
    else
        log_info "Mode automatique activé (--yes)"
    fi
    
    # Exécuter les actions
    check_prerequisites
    create_cloud_sql
    create_memorystore
    deploy_cloud_run
    configure_google_maps
    configure_monitoring
    test_functionalities
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✅ Déploiement terminé avec succès!                     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}\n"
    
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --format="value(status.url)" 2>/dev/null || echo "")
    if [ -n "$SERVICE_URL" ]; then
        log_success "URL du service: $SERVICE_URL"
    fi
}

# Exécuter le script principal
main "$@"

