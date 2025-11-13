# 🚀 Guide Rapide - Configuration Twilio (Compte Existant)

## 📋 Vous avez déjà un compte Twilio

Parfait ! Voici comment configurer rapidement vos credentials.

## ⚡ Configuration Rapide (Option 1 : Script)

```bash
cd backend
./scripts/configure-twilio.sh
```

Le script vous demandera :
- Votre Account SID
- Votre Auth Token
- Votre numéro WhatsApp (ou sandbox)
- Votre numéro SMS (optionnel)

## 📝 Configuration Manuelle (Option 2)

### Étape 1 : Trouver vos Credentials

1. **Aller sur** [Twilio Console](https://console.twilio.com/)
2. **Cliquer sur** votre nom en haut à droite → **Account**
3. **Copier** :
   - **Account SID** (commence par `AC...`)
   - **Auth Token** (cliquez sur "view" pour le voir)

### Étape 2 : Modifier le fichier .env

```bash
cd backend
nano .env
```

Trouvez les lignes :
```env
TWILIO_ACCOUNT_SID=votre_account_sid
TWILIO_AUTH_TOKEN=votre_auth_token
```

Remplacez par vos vraies valeurs :
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=votre_auth_token_ici
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890  # Votre numéro Twilio
```

### Étape 3 : Sauvegarder

- `Ctrl + O` puis `Enter` (sauvegarder)
- `Ctrl + X` (quitter)

## 📱 Configuration WhatsApp

### Pour les Tests (Sandbox)

1. **Aller dans** Twilio Console → **Messaging** → **Try it out** → **Send a WhatsApp message**
2. **Envoyer le code** fourni (ex: `join <code>`) à `+1 415 523 8886` via WhatsApp
3. **Votre numéro sera ajouté** au sandbox
4. **Utiliser** : `TWILIO_WHATSAPP_FROM=whatsapp:+14155238886`

### Pour la Production

1. **Demander l'approbation** WhatsApp Business API dans Twilio Console
2. **Utiliser votre numéro approuvé** :
   ```env
   TWILIO_WHATSAPP_FROM=whatsapp:+243900000000
   ```

## ✅ Vérification

```bash
cd backend

# Vérifier que les variables sont définies
grep "TWILIO" .env

# Installer Twilio (si pas déjà fait)
npm install twilio

# Démarrer le serveur
npm run dev
```

## 🎉 C'est prêt !

Une fois configuré, les codes OTP seront envoyés via WhatsApp automatiquement !

