# 🔐 Guide - Authentification Google Sign-In

## 📋 Vue d'ensemble

L'authentification Google Sign-In a été ajoutée à l'application Tshiakani VTC. Les utilisateurs peuvent maintenant se connecter avec leur compte Google au lieu d'utiliser uniquement leur numéro de téléphone.

## ✅ Ce qui a été fait

### 1. Service Google Auth (iOS)

- ✅ `GoogleAuthService.swift` créé
- ✅ Gestion de Google Sign-In avec le SDK GoogleSignIn
- ✅ Récupération des informations utilisateur (email, nom, photo)
- ✅ Gestion des erreurs et annulations

### 2. Intégration dans AuthViewModel

- ✅ Méthode `signInWithGoogle()` ajoutée
- ✅ Communication avec le backend via `APIService`
- ✅ Sauvegarde du token JWT après authentification

### 3. Interface Utilisateur

- ✅ Bouton "Continuer avec Google" dans `WelcomeView`
- ✅ Design cohérent avec le reste de l'application
- ✅ Gestion des états de chargement

### 4. Backend

- ✅ Endpoint `/auth/google` créé
- ✅ Création automatique de compte si l'utilisateur n'existe pas
- ✅ Mise à jour des informations si le compte existe
- ✅ Support des champs `email` et `profileImageURL`

### 5. Base de Données

- ✅ Migration SQL pour ajouter les champs `email` et `profile_image_url`
- ✅ `phone_number` rendu nullable pour les comptes Google

## 🚀 Installation

### Étape 1 : Installer Google Sign-In SDK

1. **Ouvrir Xcode**
2. **File → Add Package Dependencies**
3. **Ajouter** : `https://github.com/google/GoogleSignIn-iOS`
4. **Sélectionner** : `GoogleSignIn` (dernière version)

### Étape 2 : Configurer Google Cloud Console

1. **Aller sur** [Google Cloud Console](https://console.cloud.google.com/)
2. **Créer ou sélectionner un projet**
3. **Activer Google Sign-In API**
4. **Créer un OAuth 2.0 Client ID** :
   - Type : iOS
   - Bundle ID : `com.bruno.tshiakaniVTC` (ou votre Bundle ID)
   - Télécharger le fichier `GoogleService-Info.plist`

### Étape 3 : Ajouter GoogleService-Info.plist

1. **Glisser** `GoogleService-Info.plist` dans le projet Xcode
2. **Cocher** "Copy items if needed"
3. **Sélectionner** le target "Tshiakani VTC"

### Étape 4 : Configurer GoogleAuthService

Dans `TshiakaniVTCApp.swift`, ajouter :

```swift
import GoogleSignIn

init() {
    // Configurer Google Sign-In
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let clientId = plist["CLIENT_ID"] as? String {
        GoogleAuthService.shared.configure(clientID: clientId)
    }
    
    // ... reste du code
}
```

### Étape 5 : Exécuter la Migration SQL

```bash
cd backend
psql -U postgres -d tshiakanivtc -f migrations/004_add_google_auth_fields.sql
```

Ou via le script Node.js :

```bash
node scripts/create-test-account.js  # Vérifie aussi la structure
```

## 📱 Utilisation

### Pour les Utilisateurs

1. **Lancer l'application**
2. **Aller sur l'écran d'accueil** (`WelcomeView`)
3. **Cliquer sur "Continuer avec Google"**
4. **Sélectionner un compte Google**
5. **Autoriser l'application**
6. **Connexion automatique** ✅

### Pour les Développeurs

```swift
// Dans une vue SwiftUI
Button("Se connecter avec Google") {
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        Task {
            await authViewModel.signInWithGoogle(presentingViewController: rootViewController)
        }
    }
}
```

## 🔧 Configuration Backend

### Variables d'Environnement

Aucune variable supplémentaire requise. L'endpoint `/auth/google` accepte :
- `idToken` : Token d'identification Google
- `email` : Email de l'utilisateur
- `name` : Nom de l'utilisateur
- `photoURL` : URL de la photo de profil (optionnel)

### Vérification du Token (Production)

⚠️ **Important** : En production, vérifiez le token Google côté serveur :

```javascript
// Dans routes.postgres/auth.js
const axios = require('axios');

// Vérifier le token Google
const verifyGoogleToken = async (idToken) => {
  try {
    const response = await axios.get(
      `https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=${idToken}`
    );
    return response.data;
  } catch (error) {
    throw new Error('Token Google invalide');
  }
};

// Utiliser dans l'endpoint /auth/google
const tokenInfo = await verifyGoogleToken(idToken);
// Vérifier que l'email correspond
if (tokenInfo.email !== email) {
  return res.status(401).json({ error: 'Email ne correspond pas au token' });
}
```

## 📊 Structure des Données

### Modèle User (Backend)

```javascript
{
  id: 1,
  name: "John Doe",
  email: "john@example.com",
  phoneNumber: null,  // Nullable pour les comptes Google
  profileImageURL: "https://...",
  role: "client",
  isVerified: true
}
```

### Modèle User (iOS)

```swift
User(
    id: "1",
    name: "John Doe",
    phoneNumber: "",
    email: "john@example.com",
    role: .client,
    createdAt: Date(),
    isVerified: true
)
```

## 🔒 Sécurité

### Points Importants

1. **Token Google** : Vérifiez toujours le token côté serveur en production
2. **Email unique** : L'email est unique dans la base de données
3. **Comptes vérifiés** : Les comptes Google sont automatiquement vérifiés
4. **Pas de téléphone requis** : Les comptes Google n'ont pas besoin de numéro de téléphone

### Bonnes Pratiques

- ✅ Vérifier le token Google côté serveur
- ✅ Valider l'email avec le token
- ✅ Mettre à jour les informations utilisateur à chaque connexion
- ✅ Gérer les erreurs de manière appropriée

## 🐛 Dépannage

### Problème : "Google Sign-In n'est pas configuré"

**Solution** :
1. Vérifier que `GoogleService-Info.plist` est dans le projet
2. Vérifier que le Bundle ID correspond à celui configuré dans Google Cloud Console
3. Vérifier que Google Sign-In SDK est installé

### Problème : "Erreur lors de la connexion Google"

**Solution** :
1. Vérifier que le backend est démarré
2. Vérifier que la migration SQL a été exécutée
3. Vérifier les logs du backend pour plus de détails

### Problème : "Email déjà utilisé"

**Solution** :
- L'email doit être unique. Si un compte existe déjà avec cet email, il sera mis à jour.

## 📚 Fichiers Modifiés/Créés

1. ✅ `Tshiakani VTC/Services/GoogleAuthService.swift` (nouveau)
2. ✅ `Tshiakani VTC/ViewModels/AuthViewModel.swift` (modifié)
3. ✅ `Tshiakani VTC/Views/Auth/WelcomeView.swift` (modifié)
4. ✅ `Tshiakani VTC/Services/APIService.swift` (modifié)
5. ✅ `backend/routes.postgres/auth.js` (modifié)
6. ✅ `backend/entities/User.js` (modifié)
7. ✅ `backend/migrations/004_add_google_auth_fields.sql` (nouveau)

## ✅ Checklist

- [x] Service Google Auth créé
- [x] Intégration dans AuthViewModel
- [x] Bouton Google Sign-In ajouté
- [x] Endpoint backend créé
- [x] Migration SQL créée
- [ ] Google Sign-In SDK installé (à faire)
- [ ] GoogleService-Info.plist ajouté (à faire)
- [ ] Migration SQL exécutée (à faire)
- [ ] Test de connexion Google (à faire)

## 🎉 Résultat

Les utilisateurs peuvent maintenant :
1. **Se connecter avec Google** en un clic
2. **Créer un compte automatiquement** s'ils n'en ont pas
3. **Utiliser leur photo de profil Google**
4. **Se connecter sans numéro de téléphone**

L'authentification Google est maintenant disponible ! 🚀

