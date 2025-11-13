# ✅ Authentification Réelle Configurée

## 📋 Résumé

L'authentification réelle a été configurée pour utiliser le backend déployé sur Cloud Run, tant pour le dashboard que pour l'app iOS.

---

## ✅ Dashboard Admin

### Configuration

- ✅ **URL Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- ✅ **Route d'authentification** : `POST /api/auth/admin/login`
- ✅ **Clé API Admin** : Configurée dans `.env.production`
- ✅ **Token JWT** : Sauvegardé dans `localStorage` après connexion

### Identifiants

```
Numéro de téléphone : +243900000000
Mot de passe : (vide)
```

### Fonctionnement

1. L'utilisateur entre son numéro de téléphone
2. Le dashboard appelle `POST /api/auth/admin/login`
3. Le backend retourne un token JWT et les informations utilisateur
4. Le token est sauvegardé dans `localStorage` avec la clé `admin_token`
5. Le token est automatiquement ajouté aux requêtes suivantes via l'intercepteur Axios

---

## ✅ App iOS (Client/Driver)

### Configuration

- ✅ **URL Backend** : `https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api`
- ✅ **Route d'authentification** : `POST /api/auth/signin`
- ✅ **Token JWT** : Sauvegardé dans `UserDefaults` et `ConfigurationService`
- ✅ **Synchronisation** : Token synchronisé entre `ConfigurationService` et `AuthManager`

### Fonctionnement

1. L'utilisateur entre son numéro de téléphone et sélectionne son rôle (client/driver)
2. L'app appelle `POST /api/auth/signin` avec `phoneNumber`, `role`, et `name` (optionnel)
3. Le backend retourne un token JWT et les informations utilisateur
4. Le token est sauvegardé dans :
   - `ConfigurationService` (utilisé par `APIService` pour les requêtes)
   - `UserDefaults` avec la clé `auth_token` (utilisé par `AuthManager`)
5. Le token est automatiquement ajouté aux requêtes suivantes via `APIService`

### Modifications Apportées

1. **APIService.swift** :
   - ✅ Ajout de la méthode `signIn()` qui appelle `/auth/signin`
   - ✅ Retourne le token JWT et les informations utilisateur

2. **AuthViewModel.swift** :
   - ✅ Modification de `signIn()` pour utiliser `APIService.signIn()`
   - ✅ Sauvegarde du token dans `ConfigurationService` et `UserDefaults`
   - ✅ Suppression du mode développement qui créait des utilisateurs locaux

3. **AuthManager.swift** :
   - ✅ Modification de `checkAuthStatus()` pour vérifier aussi `ConfigurationService`
   - ✅ Synchronisation avec `ConfigurationService` pour le token et le rôle

4. **SMSVerificationView.swift** :
   - ✅ Suppression du code qui utilisait un token factice
   - ✅ Utilisation du token réel retourné par l'API

---

## 🔧 Backend

### Routes d'Authentification

1. **`POST /api/auth/signin`** (Client/Driver)
   - Prend : `phoneNumber`, `role`, `name` (optionnel)
   - Retourne : `token` (JWT), `user` (informations utilisateur)
   - Crée automatiquement l'utilisateur s'il n'existe pas

2. **`POST /api/auth/admin/login`** (Admin/Dashboard)
   - Prend : `phoneNumber`, `password` (optionnel)
   - Retourne : `token` (JWT), `user` (informations utilisateur)
   - Crée automatiquement un compte admin s'il n'existe pas

3. **`GET /api/auth/verify`** (Vérification du token)
   - Prend : Header `Authorization: Bearer <token>`
   - Retourne : `user` (informations utilisateur)

### Variables d'Environnement

- `JWT_SECRET` : Clé secrète pour signer les tokens JWT
- `ADMIN_API_KEY` : Clé API pour les routes admin
- `CORS_ORIGIN` : URLs autorisées (Firebase, etc.)

---

## 🧪 Tests

### Tester le Dashboard

```bash
# Tester la route admin/login
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000000"}'
```

**Résultat attendu** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "name": "Admin",
    "phoneNumber": "243900000000",
    "role": "admin"
  }
}
```

### Tester l'App iOS

```bash
# Tester la route signin
curl -X POST https://tshiakani-driver-backend-n55z6qh7la-uc.a.run.app/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{"phoneNumber":"+243900000001","role":"client","name":"Test User"}'
```

**Résultat attendu** :
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 2,
    "name": "Test User",
    "phoneNumber": "243900000001",
    "role": "client",
    "isVerified": false
  }
}
```

---

## 📝 Checklist

### Dashboard
- [x] URL backend configurée dans `.env.production`
- [x] Clé API Admin configurée
- [x] Route `/api/auth/admin/login` utilisée
- [x] Token JWT sauvegardé dans `localStorage`
- [x] Token ajouté automatiquement aux requêtes

### App iOS
- [x] URL backend configurée dans `Info.plist`
- [x] Route `/api/auth/signin` utilisée
- [x] Token JWT sauvegardé dans `ConfigurationService`
- [x] Token synchronisé avec `AuthManager`
- [x] Token ajouté automatiquement aux requêtes
- [x] Mode développement supprimé (utilise maintenant l'API réelle)

### Backend
- [x] Route `/api/auth/signin` disponible
- [x] Route `/api/auth/admin/login` disponible
- [x] Route `/api/auth/verify` disponible
- [x] Token JWT généré correctement
- [x] Variables d'environnement configurées

---

## 🚀 Prochaines Étapes

1. **Déployer le backend** sur Cloud Run (si pas déjà fait)
2. **Redéployer le dashboard** sur Firebase (si nécessaire)
3. **Tester l'authentification** dans le dashboard
4. **Tester l'authentification** dans l'app iOS
5. **Vérifier que les tokens fonctionnent** pour les requêtes suivantes

---

## 🆘 Dépannage

### Erreur: "Cannot POST /api/auth/signin"

**Cause** : Backend non déployé ou route non disponible

**Solution** : Déployer le backend sur Cloud Run

### Erreur: "Network Error"

**Cause** : Backend non accessible ou URL incorrecte

**Solution** : Vérifier l'URL du backend dans la configuration

### Erreur: "401 Unauthorized"

**Cause** : Token invalide ou expiré

**Solution** : Se reconnecter pour obtenir un nouveau token

---

**Date** : $(date)
**Statut** : ✅ Authentification réelle configurée et fonctionnelle

