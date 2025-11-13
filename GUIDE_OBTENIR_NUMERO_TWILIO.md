# 📱 Guide : Obtenir un Numéro Twilio

## 📋 Date : 2025-01-15

---

## ⚠️ Problème

Le numéro `+243847305825` n'est pas un numéro Twilio valide.  
Il faut utiliser un **numéro Twilio** acheté depuis votre compte Twilio.

---

## ✅ Solution : Obtenir un Numéro Twilio

### Étape 1 : Accéder au Dashboard Twilio

1. Aller sur : **https://console.twilio.com/**
2. Se connecter avec votre compte

### Étape 2 : Vérifier si vous avez déjà un numéro

1. Dans le menu de gauche, cliquer sur **"Phone Numbers"** > **"Manage"** > **"Active numbers"**
2. Si vous avez déjà un numéro, notez-le (format : +1234567890)
3. Si vous n'avez pas de numéro, passez à l'étape 3

### Étape 3 : Acheter un Numéro Twilio (GRATUIT pour les tests)

1. Aller sur : **https://console.twilio.com/us1/develop/phone-numbers/manage/incoming**
2. Cliquer sur **"Buy a number"**
3. Choisir :
   - **Country** : United States (USA) - **GRATUIT pour les tests**
   - **Capabilities** : Cocher "SMS" (et "Voice" si besoin)
4. Cliquer sur **"Search"**
5. Sélectionner un numéro gratuit (ils sont marqués comme gratuits)
6. Cliquer sur **"Buy"** (gratuit avec votre crédit de $15.50)

### Étape 4 : Noter le Numéro

Une fois acheté, notez le numéro au format : **+1234567890**

---

## 🔧 Configuration

Une fois que vous avez votre numéro Twilio, configurez-le :

```bash
# Option 1 : Via le script rapide
./scripts/gcp-configure-twilio-quick.sh f20d5f80fd6ac08e3ddf6ae9269a9613 +VOTRE_NUMERO_TWILIO

# Option 2 : Via le fichier de configuration
# Éditer scripts/twilio-config.env et mettre votre numéro
# Puis : ./scripts/gcp-configure-twilio-from-env.sh
```

---

## 💡 Numéros de Test Twilio

**Note** : Les numéros de test Twilio (comme +15005550006) ne fonctionnent que pour recevoir des messages, pas pour en envoyer.

Pour **envoyer** des SMS, vous devez avoir un **vrai numéro Twilio** acheté.

---

## 📝 Identifiants Actuels

- **Account SID** : `YOUR_TWILIO_ACCOUNT_SID` ✅
- **Auth Token** : `f20d5f80fd6ac08e3ddf6ae9269a9613` ✅
- **Numéro Twilio** : ⚠️ **À obtenir depuis le Dashboard**

---

## 🚀 Après Obtention du Numéro

1. Configurer le numéro dans Cloud Run
2. Redéployer le backend (si nécessaire)
3. Tester l'envoi d'OTP

---

**Date** : 2025-01-15

