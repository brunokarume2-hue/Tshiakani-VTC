#!/bin/bash

# Script de configuration complète pour Tshiakani VTC
# Automatise toutes les étapes de configuration

set -e

echo "🚀 Configuration complète Tshiakani VTC"
echo "========================================"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_ID="${GCP_PROJECT_ID:-tshiakani-vtc}"
BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BACKEND_DIR"

# Fonction pour afficher un message
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Étape 1: Installer les dépendances
echo "📦 Étape 1: Installation des dépendances..."
if [ ! -d "node_modules" ]; then
    info "Installation des dépendances npm..."
    npm install
    success "Dépendances installées"
else
    success "Dépendances déjà installées"
fi

# Étape 2: Configurer les variables d'environnement
echo ""
echo "🔧 Étape 2: Configuration des variables d'environnement..."
if [ ! -f ".env" ]; then
    info "Création du fichier .env..."
    cp ENV.example .env
    success "Fichier .env créé"
    warning "⚠️  IMPORTANT: Éditez le fichier .env et remplissez les valeurs requises"
    warning "   Variables minimales: DB_HOST, DB_USER, DB_PASSWORD, JWT_SECRET"
else
    success "Fichier .env existe déjà"
fi

# Étape 3: Générer les secrets si nécessaire
echo ""
echo "🔐 Étape 3: Génération des secrets..."
if [ -f ".env" ]; then
    # Vérifier si JWT_SECRET est défini
    if ! grep -q "JWT_SECRET=" .env || grep -q "JWT_SECRET=your_jwt_secret" .env; then
        info "Génération du JWT_SECRET..."
        JWT_SECRET=$(openssl rand -hex 32)
        if grep -q "JWT_SECRET=" .env; then
            sed -i.bak "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
        else
            echo "JWT_SECRET=$JWT_SECRET" >> .env
        fi
        success "JWT_SECRET généré"
    else
        success "JWT_SECRET déjà configuré"
    fi
    
    # Vérifier si ADMIN_API_KEY est défini
    if ! grep -q "ADMIN_API_KEY=" .env || grep -q "ADMIN_API_KEY=your_admin_api_key" .env; then
        info "Génération de l'ADMIN_API_KEY..."
        ADMIN_API_KEY=$(openssl rand -hex 32)
        if grep -q "ADMIN_API_KEY=" .env; then
            sed -i.bak "s/ADMIN_API_KEY=.*/ADMIN_API_KEY=$ADMIN_API_KEY/" .env
        else
            echo "ADMIN_API_KEY=$ADMIN_API_KEY" >> .env
        fi
        success "ADMIN_API_KEY généré"
    else
        success "ADMIN_API_KEY déjà configuré"
    fi
else
    warning "Fichier .env non trouvé, impossible de générer les secrets"
fi

# Étape 4: Vérifier la configuration
echo ""
echo "🔍 Étape 4: Vérification de la configuration..."
if [ -f "scripts/pre-deploy-check.sh" ]; then
    chmod +x scripts/pre-deploy-check.sh
    if ./scripts/pre-deploy-check.sh; then
        success "Configuration vérifiée"
    else
        warning "Certaines vérifications ont échoué. Vérifiez les erreurs ci-dessus."
    fi
else
    warning "Script de vérification non trouvé"
fi

# Étape 5: Configuration Cloud Storage (optionnel)
echo ""
echo "☁️  Étape 5: Configuration Cloud Storage (optionnel)..."
read -p "Voulez-vous configurer Cloud Storage maintenant? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "scripts/setup-cloud-storage.sh" ]; then
        chmod +x scripts/setup-cloud-storage.sh
        if ./scripts/setup-cloud-storage.sh; then
            success "Cloud Storage configuré"
        else
            warning "Erreur lors de la configuration de Cloud Storage"
        fi
    else
        warning "Script de configuration Cloud Storage non trouvé"
    fi
else
    info "Configuration Cloud Storage ignorée"
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé de la configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "Configuration locale terminée!"
echo ""
info "Prochaines étapes:"
echo "  1. Éditez le fichier .env et remplissez les valeurs requises"
echo "  2. Configurez votre base de données PostgreSQL"
echo "  3. (Optionnel) Configurez Cloud Storage pour la production"
echo "  4. Testez localement: npm start"
echo "  5. Déployez sur Cloud Run: gcloud run deploy"
echo ""
info "Documentation:"
echo "  - Quick Start: QUICK_START.md"
echo "  - Plan d'action: PLAN_ACTION_IMMEDIAT.md"
echo "  - Architecture: ARCHITECTURE_GOOGLE_CLOUD_CENTRALISEE.md"
echo ""

