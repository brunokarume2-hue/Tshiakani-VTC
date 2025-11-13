# 🔐 Configuration des Variables Twilio dans Railway

## ⚠️ Problème Résolu

Les scripts de déploiement ne configurent plus automatiquement les variables Twilio avec des placeholders. Vous devez les configurer manuellement dans Railway Dashboard.

## 📋 Étapes pour Configurer Twilio dans Railway

### 1. Accéder à Railway Dashboard

1. Aller sur : https://railway.app
2. Sélectionner votre projet : `tshiakani-vtc-backend`
3. Cliquer sur le service déployé
4. Aller dans l'onglet **Variables**

### 2. Ajouter les Variables Twilio

Ajouter les variables suivantes avec vos **vraies valeurs** :

```
TWILIO_ACCOUNT_SID = AC80018f519898d589fc4e9f07f79e0327
TWILIO_AUTH_TOKEN = PF6AMX1753UD629JDFF1D7GE
TWILIO_WHATSAPP_FROM = whatsapp:+14155238886
TWILIO_CONTENT_SID = HX229f5a04fd0510ce1b071852155d3e75
```

### 3. Où Trouver vos Credentials Twilio

1. Aller sur : https://console.twilio.com/
2. Se connecter à votre compte Twilio
3. Dans le Dashboard, vous trouverez :
   - **Account SID** : `AC80018f519898d589fc4e9f07f79e0327`
   - **Auth Token** : Cliquer sur "View" pour voir le token (ex: `PF6AMX1753UD629JDFF1D7GE`)

### 4. Redéployer (si nécessaire)

Après avoir ajouté les variables, Railway redéploiera automatiquement le service.

## 🔄 Alternative : Via CLI Railway

Si vous préférez utiliser la CLI :

```bash
railway variables set TWILIO_ACCOUNT_SID=AC80018f519898d589fc4e9f07f79e0327
railway variables set TWILIO_AUTH_TOKEN=PF6AMX1753UD629JDFF1D7GE
railway variables set TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
railway variables set TWILIO_CONTENT_SID=HX229f5a04fd0510ce1b071852155d3e75
```

## ✅ Vérification

Après configuration, vérifier que le service fonctionne :

```bash
curl https://votre-app.railway.app/health
```

Le service devrait répondre avec un statut OK.

## 🔒 Sécurité

⚠️ **Important** : Ne jamais commiter les vraies valeurs Twilio dans Git. Utilisez toujours Railway Dashboard ou les variables d'environnement pour les secrets.

