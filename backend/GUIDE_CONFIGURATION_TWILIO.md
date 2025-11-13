# 📱 Guide - Configuration Twilio pour OTP WhatsApp

## 📋 Vue d'ensemble

Ce guide vous explique comment configurer Twilio pour envoyer des codes OTP via WhatsApp dans l'application Tshiakani VTC.

## ✅ Variables ajoutées dans .env

Les variables suivantes ont été ajoutées dans `backend/.env` :

```env
TWILIO_ACCOUNT_SID=votre_account_sid
TWILIO_AUTH_TOKEN=votre_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890
```

## 🚀 Configuration Twilio

### Étape 1 : Créer un compte Twilio

1. **Aller sur** [https://www.twilio.com/](https://www.twilio.com/)
2. **Créer un compte gratuit** (trial account)
3. **Vérifier votre numéro de téléphone** (pour le compte trial)

### Étape 2 : Obtenir les Credentials

1. **Aller dans Twilio Console** : [https://console.twilio.com/](https://console.twilio.com/)
2. **Account Info** (en haut à droite)
3. **Copier** :
   - **Account SID** → `TWILIO_ACCOUNT_SID`
   - **Auth Token** → `TWILIO_AUTH_TOKEN` (cliquez sur "view" pour le voir)

### Étape 3 : Configurer WhatsApp Sandbox (pour les tests)

1. **Aller dans** Twilio Console → **Messaging** → **Try it out** → **Send a WhatsApp message**
2. **Joindre le Sandbox** :
   - Envoyez le code fourni par Twilio (ex: `join <code>`) à `+1 415 523 8886` via WhatsApp
   - Votre numéro sera ajouté au sandbox
3. **Le numéro WhatsApp Sandbox** est : `whatsapp:+14155238886`

### Étape 4 : Mettre à jour le fichier .env

```bash
cd backend
nano .env
```

Remplacer les valeurs :

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=votre_auth_token_ici
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890  # Optionnel, votre numéro Twilio pour SMS
```

### Étape 5 : Installer Twilio SDK

```bash
cd backend
npm install twilio
```

### Étape 6 : Tester

```bash
cd backend
npm run dev
```

Ensuite, testez l'envoi d'un code OTP depuis l'application iOS.

## 📱 Utilisation

### En Mode Sandbox (Tests)

- ✅ **Gratuit** : Compte trial Twilio
- ✅ **Limite** : Seuls les numéros ajoutés au sandbox peuvent recevoir des messages
- ✅ **Format** : `whatsapp:+14155238886` (numéro sandbox)

### En Production

1. **Demander l'approbation WhatsApp Business API** :
   - Aller dans Twilio Console → **Messaging** → **Settings** → **WhatsApp Sandbox**
   - Cliquer sur **"Request Production Access"**
   - Remplir le formulaire d'approbation
   - Attendre l'approbation (peut prendre quelques jours)

2. **Utiliser votre numéro WhatsApp Business** :
   ```env
   TWILIO_WHATSAPP_FROM=whatsapp:+243900000000  # Votre numéro approuvé
   ```

## 🔧 Dépannage

### Erreur : "Twilio non configuré"

**Solution** :
- Vérifier que `TWILIO_ACCOUNT_SID` et `TWILIO_AUTH_TOKEN` sont définis dans `.env`
- Vérifier que `twilio` est installé : `npm list twilio`

### Erreur : "Numéro non autorisé"

**Solution** :
- Vérifier que votre numéro est ajouté au WhatsApp Sandbox
- Envoyer le code de join au numéro `+1 415 523 8886`

### Erreur : "WhatsApp échoue, SMS aussi"

**Solution** :
- Vérifier que `TWILIO_PHONE_NUMBER` est configuré pour le fallback SMS
- Vérifier que votre compte Twilio a des crédits (trial ou payant)

## 📊 Coûts

### Compte Trial (Gratuit)

- ✅ **$15.50 de crédit** offert
- ✅ **WhatsApp Sandbox** : Gratuit
- ✅ **SMS** : ~$0.0075 par message
- ⚠️ **Limite** : Seulement les numéros vérifiés peuvent recevoir des messages

### Compte Payant

- **WhatsApp** : ~$0.005 par message
- **SMS** : ~$0.0075 par message
- **Pas de limite** sur les numéros

## ✅ Vérification

Après configuration, vérifiez :

```bash
cd backend
# Vérifier que les variables sont définies
grep "TWILIO" .env

# Vérifier que Twilio est installé
npm list twilio

# Démarrer le serveur
npm run dev
```

Vous devriez voir dans les logs :
```
✅ OTPService initialisé avec Twilio
```

## 🎉 Résultat

Une fois configuré, les utilisateurs recevront des codes OTP via WhatsApp (ou SMS en fallback) pour vérifier leur numéro de téléphone !

