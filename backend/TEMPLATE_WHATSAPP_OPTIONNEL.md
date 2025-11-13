# 📱 Option : Utiliser un Template WhatsApp pour les Codes OTP

## 📋 Vue d'ensemble

Actuellement, le service OTP envoie des messages texte simples. Si vous préférez utiliser un **template WhatsApp** (comme dans votre exemple), voici comment l'activer.

## 🔧 Modification du Service OTP

### Option 1 : Message Texte Simple (Actuel - Recommandé)

Le service utilise actuellement des messages texte simples, ce qui est **plus simple** et **fonctionne immédiatement** :

```javascript
body: `🔐 Votre code de vérification Tshiakani VTC est: ${code}\n\nCe code expire dans 10 minutes.`
```

### Option 2 : Template WhatsApp (Si vous avez créé un template)

Si vous avez créé un template WhatsApp dans Twilio Console, vous pouvez l'utiliser :

1. **Créer un template** dans Twilio Console → Content → Templates
2. **Modifier** `backend/services/OTPService.js`
3. **Décommenter** la section avec `contentSid` et `contentVariables`

## 📝 Exemple de Template

Votre exemple utilise :
```javascript
contentSid: 'HXb5b62575e6e4ff6129ad7c8efe1f983e',
contentVariables: '{"1":"12/1","2":"3pm"}',
```

Pour les codes OTP, vous pourriez créer un template comme :
```
Votre code de vérification Tshiakani VTC est: {{1}}
Ce code expire dans {{2}} minutes.
```

Puis utiliser :
```javascript
contentVariables: JSON.stringify({
  "1": code,      // Code OTP
  "2": "10"       // Minutes d'expiration
})
```

## ✅ Recommandation

Pour les codes OTP, **les messages texte simples sont recommandés** car :
- ✅ Plus rapide à configurer
- ✅ Pas besoin d'approbation de template
- ✅ Fonctionne immédiatement
- ✅ Plus flexible pour les modifications

Les templates sont utiles pour :
- Messages marketing
- Notifications complexes
- Messages avec images/liens

## 🎯 État Actuel

Le service utilise actuellement des **messages texte simples**, ce qui est parfait pour les codes OTP.

Si vous souhaitez utiliser un template, dites-moi et je peux modifier le code pour supporter les deux options.

