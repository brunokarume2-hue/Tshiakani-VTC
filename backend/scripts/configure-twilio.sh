#!/bin/bash

# Script pour configurer les variables Twilio dans .env
# Usage: ./configure-twilio.sh

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📱 Configuration Twilio pour Tshiakani VTC${NC}"
echo ""

# Vérifier que le fichier .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Le fichier .env n'existe pas${NC}"
    echo -e "${BLUE}📝 Création du fichier .env depuis ENV.example...${NC}"
    cp ENV.example .env
    echo -e "${GREEN}✅ Fichier .env créé${NC}\n"
fi

# Vérifier si les variables Twilio existent déjà
if grep -q "TWILIO_ACCOUNT_SID" .env && ! grep -q "TWILIO_ACCOUNT_SID=votre_account_sid" .env; then
    echo -e "${YELLOW}⚠️  Les variables Twilio sont déjà configurées${NC}"
    echo ""
    echo -e "${BLUE}Variables actuelles:${NC}"
    grep "TWILIO" .env | sed 's/=.*/=***/' 
    echo ""
    read -p "Voulez-vous les mettre à jour ? (o/n): " update
    if [ "$update" != "o" ] && [ "$update" != "O" ]; then
        echo -e "${GREEN}✅ Configuration annulée${NC}"
        exit 0
    fi
    echo ""
fi

echo -e "${BLUE}📋 Pour trouver vos credentials Twilio:${NC}"
echo -e "   1. Allez sur: ${YELLOW}https://console.twilio.com/${NC}"
echo -e "   2. Cliquez sur ${YELLOW}Account${NC} (en haut à droite)"
echo -e "   3. Copiez ${YELLOW}Account SID${NC} et ${YELLOW}Auth Token${NC}"
echo ""

# Demander Account SID
read -p "Entrez votre TWILIO_ACCOUNT_SID: " account_sid
if [ -z "$account_sid" ]; then
    echo -e "${RED}❌ Account SID requis${NC}"
    exit 1
fi

# Demander Auth Token
read -p "Entrez votre TWILIO_AUTH_TOKEN: " auth_token
if [ -z "$auth_token" ]; then
    echo -e "${RED}❌ Auth Token requis${NC}"
    exit 1
fi

# Demander WhatsApp From (avec valeur par défaut)
echo ""
echo -e "${BLUE}📱 Numéro WhatsApp:${NC}"
echo -e "   Pour les tests (Sandbox): ${YELLOW}whatsapp:+14155238886${NC}"
echo -e "   Pour la production: votre numéro WhatsApp Business"
read -p "Entrez TWILIO_WHATSAPP_FROM [whatsapp:+14155238886]: " whatsapp_from
whatsapp_from=${whatsapp_from:-whatsapp:+14155238886}

# Demander Phone Number (optionnel)
echo ""
read -p "Entrez TWILIO_PHONE_NUMBER (optionnel, pour SMS fallback): " phone_number

# Supprimer les anciennes variables Twilio si elles existent
sed -i.bak '/^TWILIO_/d' .env

# Ajouter les nouvelles variables
echo "" >> .env
echo "# ===========================================" >> .env
echo "# Twilio (pour l'envoi de codes OTP via WhatsApp/SMS)" >> .env
echo "# ===========================================" >> .env
echo "TWILIO_ACCOUNT_SID=$account_sid" >> .env
echo "TWILIO_AUTH_TOKEN=$auth_token" >> .env
echo "TWILIO_WHATSAPP_FROM=$whatsapp_from" >> .env
if [ ! -z "$phone_number" ]; then
    echo "TWILIO_PHONE_NUMBER=$phone_number" >> .env
fi

echo ""
echo -e "${GREEN}✅ Configuration Twilio sauvegardée dans .env${NC}"
echo ""
echo -e "${BLUE}📋 Configuration:${NC}"
echo -e "   Account SID: ${GREEN}${account_sid:0:10}...${NC}"
echo -e "   Auth Token: ${GREEN}${auth_token:0:10}...${NC}"
echo -e "   WhatsApp From: ${GREEN}$whatsapp_from${NC}"
if [ ! -z "$phone_number" ]; then
    echo -e "   Phone Number: ${GREEN}$phone_number${NC}"
fi
echo ""
echo -e "${YELLOW}⚠️  N'oubliez pas:${NC}"
echo -e "   - Pour les tests, ajoutez votre numéro au WhatsApp Sandbox"
echo -e "   - Envoyez le code de join à ${YELLOW}+1 415 523 8886${NC}"
echo ""

