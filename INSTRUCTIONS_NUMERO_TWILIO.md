# 📱 Instructions Étape par Étape : Obtenir un Numéro Twilio

## 🎯 Objectif
Acheter un numéro Twilio gratuit pour envoyer des SMS/OTP

---

## 📋 Étapes Détaillées

### Étape 1 : Vérifier si vous avez déjà un numéro
1. Sur la page Twilio ouverte, regardez dans le menu de gauche
2. Cliquez sur **"Phone Numbers"** > **"Manage"** > **"Active numbers"**
3. Si vous voyez un numéro listé, notez-le (format : +1234567890)
4. Si la liste est vide, continuez à l'étape 2

### Étape 2 : Acheter un nouveau numéro
1. Dans le menu de gauche, cliquez sur **"Phone Numbers"** > **"Buy a number"**
   - OU allez directement sur : https://console.twilio.com/us1/develop/phone-numbers/manage/incoming
2. Vous verrez un formulaire avec :
   - **Country** : Sélectionnez **"United States"** (USA)
   - **Type** : Laissez "Local" ou "Toll-free"
   - **Capabilities** : Cochez **"SMS"** (et "Voice" si vous voulez)
3. Cliquez sur **"Search"** ou **"Buy a number"**
4. Une liste de numéros disponibles s'affiche
5. Sélectionnez un numéro (ils sont généralement gratuits avec votre crédit de $15.50)
6. Cliquez sur **"Buy"** ou **"Purchase"**

### Étape 3 : Noter le numéro
1. Une fois acheté, le numéro s'affiche
2. Notez-le au format : **+1234567890** (avec le + et le code pays)
3. Exemple : **+15551234567**

---

## 🔍 Que faire si vous ne voyez pas "Buy a number" ?

1. Vérifiez que vous êtes sur la bonne page :
   - URL devrait contenir : `phone-numbers` ou `incoming`
2. Cherchez dans le menu :
   - **"Phone Numbers"** > **"Manage"** > **"Buy a number"**
   - OU **"Develop"** > **"Phone Numbers"** > **"Buy a number"**
3. Si vous ne trouvez pas, dites-moi ce que vous voyez sur votre écran

---

## 📝 Après avoir obtenu le numéro

**Dites-moi simplement le numéro** (format : +1234567890) et je le configurerai automatiquement dans Cloud Run !

Exemple de message :
```
+15551234567
```

---

## ⚠️ Si vous avez des problèmes

Dites-moi :
1. Sur quelle page vous êtes actuellement
2. Ce que vous voyez à l'écran
3. S'il y a des erreurs ou messages

Je vous guiderai étape par étape !

