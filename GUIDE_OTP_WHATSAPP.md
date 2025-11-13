# 📱 Guide - Vérification OTP via WhatsApp

## 📋 Vue d'ensemble

La vérification de numéro de téléphone avec envoi de code OTP via WhatsApp a été implémentée. Les utilisateurs reçoivent maintenant un code de vérification à 6 chiffres sur WhatsApp (ou SMS en fallback) pour confirmer leur numéro.

## ✅ Ce qui a été fait

### 1. Service OTP Backend

- ✅ `OTPService.js` créé avec support WhatsApp et SMS
- ✅ Génération de codes OTP à 6 chiffres
- ✅ Envoi via Twilio WhatsApp API
- ✅ Fallback automatique vers SMS si WhatsApp échoue
- ✅ Vérification des codes avec expiration (10 minutes)
- ✅ Limite de tentatives (5 max)

### 2. Endpoints Backend

- ✅ `POST /auth/send-otp` - Envoie un code OTP
- ✅ `POST /auth/verify-otp` - Vérifie le code et connecte l'utilisateur
- ✅ `POST /auth/signin` - Conservé pour compatibilité

### 3. Intégration iOS

- ✅ Méthode `sendOTP()` ajoutée dans `APIService`
- ✅ Méthode `verifyOTP()` ajoutée dans `APIService`
- ✅ Méthodes correspondantes dans `AuthViewModel`
- ✅ `SMSVerificationView` mis à jour pour utiliser `verifyOTP()`
- ✅ `WelcomeView` mis à jour pour envoyer le code avant navigation
- ✅ Bouton "Renvoyer le code" fonctionnel

## 🚀 Installation

### Étape 1 : Installer Twilio SDK

```bash
cd backend
npm install twilio
```

### Étape 2 : Configurer Twilio

1. **Créer un compte Twilio** : [https://www.twilio.com/](https://www.twilio.com/)
2. **Obtenir les credentials** :
   - Account SID
   - Auth Token
   - Numéro WhatsApp (format: `whatsapp:+14155238886`)
   - Numéro SMS (optionnel, pour fallback)

### Étape 3 : Configurer les Variables d'Environnement

Ajouter dans `backend/.env` :

```env
# Twilio Configuration
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
TWILIO_PHONE_NUMBER=+1234567890  # Optionnel pour SMS fallback
```

### Étape 4 : Activer WhatsApp dans Twilio

1. **Aller dans Twilio Console** → **Messaging** → **Try it out** → **Send a WhatsApp message**
2. **Joindre le Sandbox WhatsApp** :
   - Envoyer le code fourni par Twilio à `+1 415 523 8886`
   - Votre numéro sera ajouté au sandbox
3. **Pour la production** : Demander l'approbation WhatsApp Business API

## 📱 Utilisation

### Flux Utilisateur

1. **L'utilisateur entre son numéro** dans `WelcomeView`
2. **Clique sur "Continuer"**
3. **Le code OTP est envoyé** via WhatsApp
4. **Navigation vers** `SMSVerificationView`
5. **L'utilisateur entre le code** reçu
6. **Vérification et connexion** automatique

### Pour les Développeurs

#### Envoyer un Code OTP

```swift
// Dans AuthViewModel
await authViewModel.sendOTP(
    phoneNumber: "+243900000000",
    channel: "whatsapp" // ou "sms"
)
```

#### Vérifier un Code OTP

```swift
// Dans AuthViewModel
await authViewModel.verifyOTP(
    phoneNumber: "+243900000000",
    code: "123456",
    role: .client,
    userName: "John Doe"
)
```

## 🔧 Configuration Backend

### Variables d'Environnement Requises

```env
# Twilio (requis)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886

# Twilio SMS (optionnel, pour fallback)
TWILIO_PHONE_NUMBER=+1234567890

# Environnement
NODE_ENV=development  # ou production
```

### Format des Numéros de Téléphone

Les numéros doivent être au format international :
- ✅ `+243900000000`
- ✅ `+243 900 000 000`
- ❌ `900000000` (sera automatiquement formaté)

## 📊 Structure des Requêtes

### POST /auth/send-otp

**Request** :
```json
{
  "phoneNumber": "+243900000000",
  "channel": "whatsapp"
}
```

**Response (Development)** :
```json
{
  "success": true,
  "message": "Code OTP envoyé avec succès",
  "channel": "whatsapp",
  "expiresIn": 600,
  "code": "123456"  // Seulement en développement
}
```

**Response (Production)** :
```json
{
  "success": true,
  "message": "Code OTP envoyé avec succès",
  "channel": "whatsapp",
  "expiresIn": 600
}
```

### POST /auth/verify-otp

**Request** :
```json
{
  "phoneNumber": "+243900000000",
  "code": "123456",
  "role": "client",
  "name": "John Doe"
}
```

**Response** :
```json
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "phoneNumber": "900000000",
    "role": "client",
    "isVerified": true
  }
}
```

## 🔒 Sécurité

### Caractéristiques de Sécurité

1. **Codes à 6 chiffres** : Aléatoires et sécurisés
2. **Expiration** : 10 minutes
3. **Limite de tentatives** : 5 maximum
4. **Nettoyage automatique** : Codes expirés supprimés toutes les 5 minutes
5. **Pas d'exposition en production** : Le code n'est pas renvoyé dans la réponse en production

### Bonnes Pratiques

- ✅ Ne jamais exposer le code OTP en production
- ✅ Limiter le nombre de tentatives
- ✅ Expirer les codes rapidement
- ✅ Nettoyer les codes expirés régulièrement
- ✅ Utiliser Redis en production pour le stockage (au lieu de Map)

## 🐛 Dépannage

### Problème : "Twilio non configuré"

**Solution** :
1. Vérifier que `TWILIO_ACCOUNT_SID` et `TWILIO_AUTH_TOKEN` sont définis
2. Vérifier que `twilio` est installé : `npm install twilio`

### Problème : "Erreur lors de l'envoi WhatsApp"

**Solution** :
1. Vérifier que votre numéro est dans le Twilio WhatsApp Sandbox
2. Vérifier le format du numéro (doit être international)
3. Vérifier que `TWILIO_WHATSAPP_FROM` est correct

### Problème : "Code non trouvé"

**Solution** :
- Le code a expiré (10 minutes)
- Le code a été utilisé
- Trop de tentatives (5 max)
- Demander un nouveau code

## 📚 Fichiers Modifiés/Créés

1. ✅ `backend/services/OTPService.js` (nouveau)
2. ✅ `backend/routes.postgres/auth.js` (modifié)
3. ✅ `Tshiakani VTC/Services/APIService.swift` (modifié)
4. ✅ `Tshiakani VTC/ViewModels/AuthViewModel.swift` (modifié)
5. ✅ `Tshiakani VTC/Views/Auth/WelcomeView.swift` (modifié)
6. ✅ `Tshiakani VTC/Views/Auth/SMSVerificationView.swift` (modifié)

## ✅ Checklist

- [x] Service OTP créé
- [x] Endpoints backend créés
- [x] Intégration iOS complète
- [x] Support WhatsApp
- [x] Support SMS (fallback)
- [x] Vérification des codes
- [x] Gestion des erreurs
- [ ] Twilio configuré (à faire)
- [ ] Variables d'environnement configurées (à faire)
- [ ] Test d'envoi WhatsApp (à faire)
- [ ] Test de vérification OTP (à faire)

## 🎉 Résultat

Les utilisateurs peuvent maintenant :
1. **Recevoir un code OTP** via WhatsApp
2. **Vérifier leur numéro** avec le code
3. **Se connecter automatiquement** après vérification
4. **Renvoyer le code** si nécessaire

La vérification OTP via WhatsApp est maintenant complètement implémentée ! 🚀

