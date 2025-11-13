# 📝 Instructions pour Configurer Twilio dans .env

## 🎯 Ce que vous devez faire

Ouvrez le fichier `.env` et trouvez ces lignes (vers la fin du fichier) :

```env
TWILIO_ACCOUNT_SID=votre_account_sid
TWILIO_AUTH_TOKEN=votre_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890
```

## 📋 Étapes dans nano

1. **Ouvrir le fichier** :
   ```bash
   cd "/Users/admin/Documents/Tshiakani VTC/backend"
   nano .env
   ```

2. **Aller à la fin du fichier** :
   - Appuyez sur `Ctrl + V` plusieurs fois pour descendre
   - Ou `Ctrl + W` puis tapez `TWILIO` pour rechercher

3. **Modifier les valeurs** :
   - Utilisez les flèches pour naviguer
   - Remplacez `votre_account_sid` par votre Account SID
   - Remplacez `votre_auth_token` par votre Auth Token
   - Laissez `TWILIO_WHATSAPP_FROM=whatsapp:+14155238886` (sandbox)
   - Modifiez `TWILIO_PHONE_NUMBER` si vous avez un numéro Twilio

4. **Sauvegarder** :
   - `Ctrl + O` puis `Enter` (sauvegarder)
   - `Ctrl + X` (quitter)

## 🔑 Où trouver vos credentials

1. **Aller sur** : [https://console.twilio.com/](https://console.twilio.com/)
2. **Cliquer sur** votre nom (en haut à droite) → **Account**
3. **Copier** :
   - **Account SID** (commence par `AC...`)
   - **Auth Token** (cliquez sur "view" pour le voir)

## ✅ Exemple de configuration finale

```env
TWILIO_ACCOUNT_SID=ACa1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
TWILIO_AUTH_TOKEN=abc123def456ghi789jkl012mno345pqr678
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890
```

## 📱 N'oubliez pas

Pour recevoir des messages WhatsApp en mode test, ajoutez votre numéro au sandbox :
- Envoyez le code fourni par Twilio à `+1 415 523 8886` via WhatsApp

