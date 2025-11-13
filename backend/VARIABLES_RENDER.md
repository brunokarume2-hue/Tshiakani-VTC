# 📋 Variables d'Environnement pour Render

## 🔑 Liste Complète des Variables

Dans Render Dashboard, section **"Environment Variables"**, ajouter ces variables **une par une** :

### Variables Obligatoires

| **Nom (Key)** | **Valeur (Value)** |
|---------------|-------------------|
| `NODE_ENV` | `production` |
| `PORT` | `10000` |
| `JWT_SECRET` | `ac6dcf4a79db19cffc2c71166699ff4ead6ec0fe259b3f77c67de9543ad99ec4a7e9818c6e4013467eaaf6b12545c34c8ce77b73141df9e28437179971e99eab` |
| `ADMIN_API_KEY` | `aadf3378b1d5eca1c38398e5ee31ad6f978747762f9d546847173eb54e7637d8` |
| `CORS_ORIGIN` | `https://tshiakani-vtc-99cea.web.app,https://tshiakani-vtc-99cea.firebaseapp.com` |
| `TWILIO_ACCOUNT_SID` | `YOUR_TWILIO_ACCOUNT_SID` |
| `TWILIO_AUTH_TOKEN` | `YOUR_TWILIO_AUTH_TOKEN` |
| `TWILIO_WHATSAPP_FROM` | `whatsapp:+14155238886` |
| `TWILIO_CONTENT_SID` | `HX229f5a04fd0510ce1b071852155d3e75` |
| `STRIPE_CURRENCY` | `cdf` |

## 📝 Comment Ajouter dans Render

1. Dans Render Dashboard, ouvrir votre Web Service
2. Aller dans la section **"Environment"**
3. Cliquer sur **"Add Environment Variable"**
4. Pour chaque variable :
   - **Key** : Le nom (ex: `NODE_ENV`)
   - **Value** : La valeur (ex: `production`)
5. Cliquer **"Save Changes"**

## 🔄 Variables Automatiques (Base de Données)

Si vous liez la base de données PostgreSQL, ces variables sont ajoutées **automatiquement** :
- `DATABASE_URL`
- `DB_HOST`
- `DB_PORT`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`

**Vous n'avez pas besoin de les ajouter manuellement !**

## ⚠️ Important

- Copier-coller les valeurs **exactement** comme indiqué
- Ne pas ajouter d'espaces avant ou après les valeurs
- Pour `CORS_ORIGIN`, les deux URLs sont séparées par une virgule (sans espace)

