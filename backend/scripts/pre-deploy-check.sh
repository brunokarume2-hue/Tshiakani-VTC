#!/bin/bash

# Script de vérification pré-déploiement
# Vérifie que tout est correctement configuré avant le déploiement

set -e

echo "🔍 Vérification pré-déploiement Tshiakani VTC..."
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteur d'erreurs
ERRORS=0
WARNINGS=0

# Fonction pour afficher une erreur
error() {
    echo -e "${RED}❌ $1${NC}"
    ((ERRORS++))
}

# Fonction pour afficher un avertissement
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

# Fonction pour afficher un succès
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Vérifier que Node.js est installé
echo "📦 Vérification des dépendances..."
if ! command -v node &> /dev/null; then
    error "Node.js n'est pas installé"
else
    NODE_VERSION=$(node --version)
    success "Node.js installé: $NODE_VERSION"
fi

# Vérifier que npm est installé
if ! command -v npm &> /dev/null; then
    error "npm n'est pas installé"
else
    success "npm installé: $(npm --version)"
fi

# Vérifier que les dépendances sont installées
if [ ! -d "node_modules" ]; then
    warning "node_modules n'existe pas. Exécutez 'npm install'"
else
    success "Dépendances installées"
fi

# Vérifier les variables d'environnement
echo ""
echo "🔧 Vérification des variables d'environnement..."

if [ -f ".env" ]; then
    success "Fichier .env trouvé"
    
    # Vérifier les variables critiques
    if grep -q "JWT_SECRET=" .env && ! grep -q "JWT_SECRET=your_jwt_secret" .env; then
        success "JWT_SECRET configuré"
    else
        error "JWT_SECRET n'est pas configuré correctement"
    fi
    
    if grep -q "DB_HOST=" .env || grep -q "DATABASE_URL=" .env; then
        success "Configuration base de données trouvée"
    else
        error "Configuration base de données manquante"
    fi
else
    warning "Fichier .env non trouvé. Créez-le à partir de ENV.example"
fi

# Vérifier la configuration Cloud Storage (optionnel)
echo ""
echo "☁️  Vérification Cloud Storage (optionnel)..."
if grep -q "GCP_PROJECT_ID=" .env 2>/dev/null || [ -n "$GCP_PROJECT_ID" ]; then
    success "GCP_PROJECT_ID configuré"
    if command -v node &> /dev/null; then
        if node scripts/verify-storage-config.js 2>/dev/null; then
            success "Configuration Cloud Storage valide"
        else
            warning "Cloud Storage non configuré (optionnel en développement)"
        fi
    fi
else
    warning "Cloud Storage non configuré (optionnel en développement)"
fi

# Vérifier les fichiers critiques
echo ""
echo "📁 Vérification des fichiers critiques..."

REQUIRED_FILES=(
    "server.postgres.js"
    "config/database.js"
    "package.json"
    "Dockerfile"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "Fichier trouvé: $file"
    else
        error "Fichier manquant: $file"
    fi
done

# Vérifier les routes
echo ""
echo "🛣️  Vérification des routes..."

ROUTES_DIR="routes.postgres"
if [ -d "$ROUTES_DIR" ]; then
    success "Dossier routes.postgres trouvé"
    
    REQUIRED_ROUTES=(
        "auth.js"
        "rides.js"
        "users.js"
        "driver.js"
        "client.js"
        "documents.js"
    )
    
    for route in "${REQUIRED_ROUTES[@]}"; do
        if [ -f "$ROUTES_DIR/$route" ]; then
            success "Route trouvée: $route"
        else
            warning "Route manquante: $route"
        fi
    done
else
    error "Dossier routes.postgres non trouvé"
fi

# Vérifier les services
echo ""
echo "⚙️  Vérification des services..."

SERVICES_DIR="services"
if [ -d "$SERVICES_DIR" ]; then
    success "Dossier services trouvé"
    
    if [ -f "$SERVICES_DIR/StorageService.js" ]; then
        success "StorageService trouvé"
    else
        warning "StorageService non trouvé (optionnel)"
    fi
else
    warning "Dossier services non trouvé"
fi

# Vérifier la syntaxe JavaScript
echo ""
echo "🔍 Vérification de la syntaxe JavaScript..."

if command -v node &> /dev/null; then
    if node -c server.postgres.js 2>/dev/null; then
        success "Syntaxe server.postgres.js valide"
    else
        error "Erreur de syntaxe dans server.postgres.js"
    fi
fi

# Résumé
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé de la vérification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ Tout est prêt pour le déploiement!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS avertissement(s) - Déploiement possible${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERRORS erreur(s) et $WARNINGS avertissement(s)${NC}"
    echo -e "${RED}Corrigez les erreurs avant de déployer${NC}"
    exit 1
fi

