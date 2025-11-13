#!/bin/bash

# Script pour configurer CORS via fichier YAML
# Usage: ./scripts/configurer-cors-yaml.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
GCP_PROJECT_ID="tshiakani-vtc-477711"
SERVICE_NAME="tshiakani-vtc-backend"
REGION="us-central1"

echo -e "${BLUE}🌐 Configuration CORS via fichier YAML${NC}"
echo ""

# URLs autorisées pour CORS
CORS_ORIGINS="https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com,capacitor://localhost,ionic://localhost,http://localhost:3001,http://localhost:5173"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI n'est pas installé${NC}"
    exit 1
fi

# Créer un fichier YAML temporaire
ENV_YAML=$(mktemp)

echo -e "${BLUE}📝 Création du fichier de configuration...${NC}"

# Récupérer les variables existantes
echo -e "${YELLOW}⚠️  Récupération des variables d'environnement actuelles...${NC}"
CURRENT_ENV=$(gcloud run services describe ${SERVICE_NAME} \
    --region ${REGION} \
    --project ${GCP_PROJECT_ID} \
    --format="get(spec.template.spec.containers[0].env)" 2>/dev/null)

# Créer le fichier YAML avec toutes les variables
cat > "$ENV_YAML" << EOF
# Variables d'environnement pour Cloud Run
# Généré automatiquement le $(date)

EOF

# Ajouter les variables existantes (sauf CORS_ORIGIN)
echo "$CURRENT_ENV" | python3 -c "
import sys
import re

data = sys.stdin.read()
# Parser les variables au format {'name': '...', 'value': '...'}
pattern = r\"{'name': '([^']+)', 'value': '([^']+)'}\"
matches = re.findall(pattern, data)

for name, value in matches:
    if name != 'CORS_ORIGIN':
        # Échapper les caractères spéciaux pour YAML
        value_escaped = value.replace('\"', '\\\"').replace('\\n', '\\\\n')
        print(f'{name}: \"{value_escaped}\"')
" >> "$ENV_YAML" 2>/dev/null || {
    # Fallback : ajouter manuellement les variables principales
    cat >> "$ENV_YAML" << EOF
NODE_ENV: "production"
INSTANCE_CONNECTION_NAME: "tshiakani-vtc-477711:us-central1:tshiakani-vtc-db"
DB_USER: "postgres"
DB_PASSWORD: "H38TYjMcJfTudmFmSVzvWZk45"
DB_NAME: "TshiakaniVTC"
DB_HOST: "/cloudsql/tshiakani-vtc-477711:us-central1:tshiakani-vtc-db"
REDIS_HOST: "10.184.176.123"
REDIS_PORT: "6379"
GOOGLE_MAPS_API_KEY: "AIzaSyBBSOYw1qSUrp3yU4t097tjRZRwRZ0z1w8"
FIREBASE_PROJECT_ID: "tshiakani-vtc-477711-306f0"
EOF
}

# Ajouter CORS_ORIGIN
cat >> "$ENV_YAML" << EOF
CORS_ORIGIN: "${CORS_ORIGINS}"
EOF

echo -e "${GREEN}✅ Fichier YAML créé${NC}"
echo ""
echo -e "${BLUE}📋 Contenu du fichier :${NC}"
cat "$ENV_YAML"
echo ""

read -p "Voulez-vous appliquer cette configuration ? (o/N) : " apply

if [[ "$apply" =~ ^[Oo]$ ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Application de la configuration...${NC}"
    
    # Utiliser --set-env-vars avec le fichier
    # Note: gcloud ne supporte pas directement --env-vars-file pour update
    # Il faut utiliser --set-env-vars avec toutes les variables
    
    # Construire la chaîne de variables
    ENV_STRING=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z_]+: ]]; then
            name=$(echo "$line" | cut -d: -f1 | tr -d ' ')
            value=$(echo "$line" | cut -d: -f2- | sed 's/^ *"\(.*\)"$/\1/' | sed 's/^ *//')
            if [ -z "$ENV_STRING" ]; then
                ENV_STRING="${name}=${value}"
            else
                ENV_STRING="${ENV_STRING},${name}=${value}"
            fi
        fi
    done < "$ENV_YAML"
    
    echo -e "${YELLOW}⚠️  Exécution de la commande...${NC}"
    gcloud run services update ${SERVICE_NAME} \
        --set-env-vars="${ENV_STRING}" \
        --region ${REGION} \
        --project ${GCP_PROJECT_ID} 2>&1 | grep -v "Setting IAM Policy" || {
        echo -e "${RED}❌ Erreur lors de la configuration${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  Utilisez la Console GCP à la place :${NC}"
        echo "https://console.cloud.google.com/run/detail/us-central1/${SERVICE_NAME}?project=${GCP_PROJECT_ID}"
        rm -f "$ENV_YAML"
        exit 1
    }
    
    echo -e "${GREEN}✅ CORS configuré avec succès${NC}"
else
    echo -e "${YELLOW}⚠️  Configuration annulée${NC}"
    echo ""
    echo -e "${BLUE}📝 Le fichier YAML a été créé : ${ENV_YAML}${NC}"
    echo "Vous pouvez l'utiliser manuellement ou via la Console GCP"
fi

# Nettoyer
# rm -f "$ENV_YAML"

echo ""

