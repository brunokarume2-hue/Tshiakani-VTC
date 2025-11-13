#!/bin/bash

# Script pour exécuter tous les tests
# Usage: ./run-tests.sh [backend|ios|all]

set -e

# Couleurs pour l'affichage
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction pour exécuter les tests backend
run_backend_tests() {
    print_message "Exécution des tests backend..."
    
    if [ ! -d "backend" ]; then
        print_warning "Répertoire backend non trouvé. Passage des tests backend."
        return
    fi
    
    cd backend
    
    if [ ! -f "package.json" ]; then
        print_warning "package.json non trouvé dans backend/. Installation des dépendances..."
        npm install --save-dev jest supertest
    fi
    
    if [ ! -f "node_modules/.bin/jest" ]; then
        print_message "Installation des dépendances..."
        npm install
    fi
    
    print_message "Lancement des tests Jest..."
    npm test
    
    cd ..
    print_success "Tests backend terminés"
}

# Fonction pour exécuter les tests iOS
run_ios_tests() {
    print_message "Exécution des tests iOS..."
    
    if ! command -v xcodebuild &> /dev/null; then
        print_warning "xcodebuild non trouvé. Les tests iOS nécessitent Xcode."
        return
    fi
    
    # Vérifier si le projet Xcode existe
    if [ ! -f "Tshiakani VTC.xcodeproj/project.pbxproj" ]; then
        print_warning "Projet Xcode non trouvé. Passage des tests iOS."
        return
    fi
    
    print_message "Lancement des tests XCTest..."
    xcodebuild test \
        -scheme "Tshiakani VTC" \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet
    
    print_success "Tests iOS terminés"
}

# Menu principal
case "${1:-all}" in
    backend)
        run_backend_tests
        ;;
    ios)
        run_ios_tests
        ;;
    all)
        print_message "Exécution de tous les tests..."
        run_backend_tests
        echo ""
        run_ios_tests
        print_success "Tous les tests sont terminés"
        ;;
    *)
        echo "Usage: $0 [backend|ios|all]"
        exit 1
        ;;
esac

