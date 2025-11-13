#!/bin/bash

# Script de vérification des préconditions pour le backend
# Usage: ./verifier-preconditions-backend.sh

set -e

echo "🔍 Vérification des préconditions pour le backend..."
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Compteur de problèmes
PROBLEMS=0

# 1. Vérifier le port 3000
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Vérification du port 3000"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -ti:3000)
    PROCESS=$(ps -p $PID -o comm= 2>/dev/null || echo "inconnu")
    echo -e "${YELLOW}⚠️  Le port 3000 est déjà utilisé par le processus $PID ($PROCESS)${NC}"
    echo ""
    echo "Options :"
    echo "  1. Arrêter le processus : kill -9 $PID"
    echo "  2. Utiliser un autre port (modifier PORT dans .env)"
    echo ""
    read -p "Souhaitez-vous arrêter le processus ? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        kill -9 $PID 2>/dev/null || true
        sleep 2
        echo -e "${GREEN}✅ Processus arrêté${NC}"
    else
        echo -e "${RED}❌ Port 3000 toujours utilisé${NC}"
        PROBLEMS=$((PROBLEMS + 1))
    fi
else
    echo -e "${GREEN}✅ Port 3000 disponible${NC}"
fi

echo ""

# 2. Vérifier PostgreSQL
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Vérification de PostgreSQL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier si PostgreSQL est installé
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | head -1)
    echo -e "${GREEN}✅ PostgreSQL installé : $PSQL_VERSION${NC}"
else
    echo -e "${RED}❌ PostgreSQL n'est pas installé${NC}"
    echo "  Installation : brew install postgresql@15"
    PROBLEMS=$((PROBLEMS + 1))
    echo ""
    exit 1
fi

# Vérifier si PostgreSQL est démarré
if pg_isready &> /dev/null; then
    echo -e "${GREEN}✅ PostgreSQL est démarré et accessible${NC}"
else
    echo -e "${YELLOW}⚠️  PostgreSQL n'est pas accessible${NC}"
    echo ""
    echo "Options pour démarrer PostgreSQL :"
    echo "  1. Via Homebrew : brew services start postgresql@15"
    echo "  2. Manuellement : pg_ctl -D /usr/local/var/postgresql@15 start"
    echo ""
    read -p "Souhaitez-vous démarrer PostgreSQL maintenant ? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        # Essayer de démarrer via brew services
        if brew services list | grep -q postgresql; then
            brew services start postgresql@15 2>&1 || brew services start postgresql 2>&1
            sleep 3
            if pg_isready &> /dev/null; then
                echo -e "${GREEN}✅ PostgreSQL démarré${NC}"
            else
                echo -e "${RED}❌ Impossible de démarrer PostgreSQL${NC}"
                PROBLEMS=$((PROBLEMS + 1))
            fi
        else
            echo -e "${YELLOW}⚠️  PostgreSQL n'est pas géré par Homebrew${NC}"
            echo "  Veuillez démarrer PostgreSQL manuellement"
            PROBLEMS=$((PROBLEMS + 1))
        fi
    else
        PROBLEMS=$((PROBLEMS + 1))
    fi
fi

echo ""

# 3. Vérifier le fichier .env
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Vérification du fichier .env"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd backend

if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env n'existe pas${NC}"
    if [ -f "ENV.example" ]; then
        echo "  Création du fichier .env depuis ENV.example..."
        cp ENV.example .env
        echo -e "${YELLOW}⚠️  Veuillez éditer le fichier .env avec vos valeurs${NC}"
        PROBLEMS=$((PROBLEMS + 1))
    else
        echo -e "${RED}❌ ENV.example n'existe pas${NC}"
        PROBLEMS=$((PROBLEMS + 1))
    fi
else
    echo -e "${GREEN}✅ Fichier .env existe${NC}"
    
    # Vérifier les variables de base de données
    echo ""
    echo "  Vérification des variables de base de données..."
    
    # Charger les variables d'environnement
    set -a
    source .env 2>/dev/null || true
    set +a
    
    DB_HOST=${DB_HOST:-"non défini"}
    DB_PORT=${DB_PORT:-"non défini"}
    DB_USER=${DB_USER:-"non défini"}
    DB_NAME=${DB_NAME:-"non défini"}
    DB_PASSWORD=${DB_PASSWORD:-"non défini"}
    DATABASE_URL=${DATABASE_URL:-"non défini"}
    
    if [ "$DATABASE_URL" != "non défini" ] && [ ! -z "$DATABASE_URL" ]; then
        echo -e "  ${GREEN}✅ DATABASE_URL est défini${NC}"
    elif [ "$DB_HOST" != "non défini" ] && [ "$DB_USER" != "non défini" ] && [ "$DB_NAME" != "non défini" ]; then
        echo -e "  ${GREEN}✅ Variables individuelles définies${NC}"
        echo "    DB_HOST: $DB_HOST"
        echo "    DB_PORT: $DB_PORT"
        echo "    DB_USER: $DB_USER"
        echo "    DB_NAME: $DB_NAME"
        echo "    DB_PASSWORD: ${DB_PASSWORD:0:3}***"
        
        # Vérifier si les valeurs sont les valeurs par défaut
        if [ "$DB_HOST" = "localhost" ] && [ "$DB_USER" = "postgres" ] && [ "$DB_NAME" = "tshiakani_vtc" ]; then
            echo -e "  ${YELLOW}⚠️  Valeurs par défaut détectées - vérifiez qu'elles sont correctes${NC}"
        fi
    else
        echo -e "  ${RED}❌ Variables de base de données manquantes${NC}"
        echo "    DB_HOST: $DB_HOST"
        echo "    DB_USER: $DB_USER"
        echo "    DB_NAME: $DB_NAME"
        PROBLEMS=$((PROBLEMS + 1))
    fi
fi

echo ""

# 4. Vérifier la connexion à la base de données
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Vérification de la connexion à la base de données"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if pg_isready &> /dev/null; then
    # Essayer de se connecter à la base de données
    if [ "$DATABASE_URL" != "non défini" ] && [ ! -z "$DATABASE_URL" ]; then
        # Utiliser DATABASE_URL
        if PGPASSWORD="${DB_PASSWORD}" psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
            echo -e "${GREEN}✅ Connexion à la base de données réussie${NC}"
        else
            echo -e "${YELLOW}⚠️  Impossible de se connecter avec DATABASE_URL${NC}"
            PROBLEMS=$((PROBLEMS + 1))
        fi
    elif [ "$DB_HOST" != "non défini" ] && [ "$DB_USER" != "non défini" ] && [ "$DB_NAME" != "non défini" ]; then
        # Utiliser les variables individuelles
        if PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &> /dev/null; then
            echo -e "${GREEN}✅ Connexion à la base de données réussie${NC}"
            
            # Vérifier si la base de données existe
            DB_EXISTS=$(PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -w "$DB_NAME" | wc -l)
            if [ "$DB_EXISTS" -eq 1 ]; then
                echo -e "${GREEN}✅ Base de données '$DB_NAME' existe${NC}"
            else
                echo -e "${YELLOW}⚠️  Base de données '$DB_NAME' n'existe pas${NC}"
                echo "  Création de la base de données..."
                read -p "Souhaitez-vous créer la base de données ? (o/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[OoYy]$ ]]; then
                    PGPASSWORD="${DB_PASSWORD}" createdb -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" "$DB_NAME" 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✅ Base de données créée${NC}"
                    else
                        echo -e "${RED}❌ Impossible de créer la base de données${NC}"
                        PROBLEMS=$((PROBLEMS + 1))
                    fi
                else
                    PROBLEMS=$((PROBLEMS + 1))
                fi
            fi
        else
            echo -e "${RED}❌ Impossible de se connecter à la base de données${NC}"
            echo "  Vérifiez :"
            echo "    - Les identifiants dans .env"
            echo "    - Que la base de données existe"
            echo "    - Que l'utilisateur a les permissions"
            PROBLEMS=$((PROBLEMS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️  Variables de base de données non configurées${NC}"
        PROBLEMS=$((PROBLEMS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  PostgreSQL n'est pas accessible - impossible de tester la connexion${NC}"
    PROBLEMS=$((PROBLEMS + 1))
fi

echo ""

# 5. Vérifier les dépendances Node.js
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Vérification des dépendances Node.js"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -d "node_modules" ]; then
    echo -e "${GREEN}✅ Dépendances installées${NC}"
else
    echo -e "${YELLOW}⚠️  Dépendances non installées${NC}"
    echo "  Installation en cours..."
    npm install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dépendances installées${NC}"
    else
        echo -e "${RED}❌ Erreur lors de l'installation${NC}"
        PROBLEMS=$((PROBLEMS + 1))
    fi
fi

echo ""

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $PROBLEMS -eq 0 ]; then
    echo -e "${GREEN}✅ Toutes les préconditions sont satisfaites !${NC}"
    echo ""
    echo "Vous pouvez maintenant démarrer le backend :"
    echo "  ./demarrer-backend.sh"
    echo "  ou"
    echo "  cd backend && npm start"
else
    echo -e "${YELLOW}⚠️  $PROBLEMS problème(s) détecté(s)${NC}"
    echo ""
    echo "Veuillez résoudre les problèmes ci-dessus avant de démarrer le backend."
fi

echo ""

