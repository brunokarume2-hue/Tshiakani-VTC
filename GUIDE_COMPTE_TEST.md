# 🧪 Guide - Compte de Test

## 📋 Vue d'ensemble

Le mode développement a été supprimé et remplacé par un **compte de test** dans la base de données PostgreSQL. Cela permet une connexion rapide sans OTP tout en gardant la sécurité pour les autres utilisateurs.

## ✅ Ce qui a été fait

### 1. Mode Développement Désactivé

- ✅ `developmentMode = false` dans `FeatureFlags.swift`
- ✅ `bypassOTP = false` dans `FeatureFlags.swift`
- ✅ Code de bypass OTP supprimé de `SMSVerificationView.swift`

### 2. Compte de Test Créé

- ✅ Script SQL pour créer le compte de test
- ✅ Script shell pour exécuter la création
- ✅ Configuration dans `FeatureFlags.swift`

### 3. Bouton de Connexion Rapide

- ✅ Bouton "Connexion rapide (Compte Test)" dans `WelcomeView.swift`
- ✅ Connexion automatique sans OTP pour le compte de test

## 🚀 Utilisation

### Étape 1 : Créer le Compte de Test dans la Base de Données

```bash
cd backend
./scripts/create-test-account.sh
```

Ou manuellement avec psql :

```bash
psql -U postgres -d tshiakani_vtc -f migrations/003_create_test_account.sql
```

### Étape 2 : Utiliser le Compte de Test dans l'Application

1. **Lancer l'application**
2. **Aller sur l'écran d'accueil** (`WelcomeView`)
3. **Cliquer sur "Connexion rapide (Compte Test)"**
4. **Vous serez connecté automatiquement** sans OTP

### Informations du Compte de Test

- **📱 Numéro** : `+243900000000`
- **👤 Nom** : `Compte Test`
- **🎭 Rôle** : `client`
- **✅ Vérifié** : `true`

## 📝 Détails Techniques

### Script SQL

Le script `003_create_test_account.sql` :
- Supprime l'ancien compte de test s'il existe
- Crée un nouveau compte avec les informations de test
- Affiche les informations du compte créé

### Configuration FeatureFlags

```swift
// Compte de Test
static let testAccountPhoneNumber = "+243900000000"
static let testAccountName = "Compte Test"
static let testAccountRole: UserRole = .client
```

### Bouton de Connexion Rapide

Le bouton dans `WelcomeView.swift` :
- Remplit automatiquement les champs avec les informations du compte de test
- Se connecte directement via `authViewModel.signIn()`
- Bypass l'écran de vérification OTP

## 🔒 Sécurité

### Pour le Compte de Test

- ✅ Le compte de test est **uniquement pour les tests**
- ✅ Il ne devrait **pas être utilisé en production**
- ✅ Le compte peut être supprimé facilement si nécessaire

### Pour les Autres Utilisateurs

- ✅ **OTP requis** pour tous les autres comptes
- ✅ Pas de bypass OTP
- ✅ Sécurité normale maintenue

## 🛠️ Maintenance

### Supprimer le Compte de Test

```sql
DELETE FROM users WHERE phone_number = '900000000';
```

### Recréer le Compte de Test

```bash
cd backend
./scripts/create-test-account.sh
```

### Vérifier le Compte de Test

```sql
SELECT id, name, phone_number, role, is_verified, created_at
FROM users 
WHERE phone_number = '900000000';
```

## 📱 Interface Utilisateur

### Écran d'Accueil (WelcomeView)

L'écran affiche maintenant :

```
┌─────────────────────────────────┐
│      [Logo Tshiakani VTC]       │
│                                 │
│      Bienvenue                  │
│      Transport rapide et        │
│      sécurisé                   │
│                                 │
│  [⚡ Connexion rapide]          │
│  (Compte Test)                  │
│                                 │
│  ─────────── OU ───────────    │
│                                 │
│  [Formulaire de connexion]     │
│  - Rôle: Client                 │
│  - Nom (optionnel)              │
│  - Numéro de téléphone          │
│  [Continuer]                    │
└─────────────────────────────────┘
```

## 🎯 Avantages

### Pour les Tests

- ✅ **Connexion instantanée** : Un seul clic
- ✅ **Pas d'OTP requis** : Pour le compte de test uniquement
- ✅ **Répétable** : Même compte à chaque fois
- ✅ **Simple** : Pas de configuration complexe

### Pour le Développement

- ✅ **Mode production** : Pas de bypass OTP général
- ✅ **Sécurité maintenue** : OTP requis pour les autres comptes
- ✅ **Facile à tester** : Compte de test toujours disponible
- ✅ **Pas de dépendance SMS** : Pour les tests uniquement

## 🚨 Notes Importantes

### Avant la Production

1. **Supprimer le compte de test** :
   ```sql
   DELETE FROM users WHERE phone_number = '900000000';
   ```

2. **Vérifier que le mode développement est désactivé** :
   ```swift
   static let developmentMode = false
   static let bypassOTP = false
   ```

3. **Tester avec un vrai compte** :
   - Créer un compte avec un vrai numéro
   - Vérifier que l'OTP fonctionne
   - Tester le flux complet

### Pour les Tests Automatisés

Le compte de test peut être utilisé dans les tests automatisés :

```swift
let testPhoneNumber = FeatureFlags.testAccountPhoneNumber
let testName = FeatureFlags.testAccountName
let testRole = FeatureFlags.testAccountRole

// Se connecter avec le compte de test
await agent.authenticate(
    phoneNumber: testPhoneNumber,
    role: testRole,
    name: testName
)
```

## 📚 Fichiers Modifiés

1. **FeatureFlags.swift**
   - Mode développement désactivé
   - Ajout des constantes du compte de test

2. **WelcomeView.swift**
   - Ajout du bouton "Connexion rapide"
   - Amélioration de la gestion du numéro de téléphone

3. **SMSVerificationView.swift**
   - Suppression du code de bypass OTP
   - Simplification de la vérification

4. **backend/migrations/003_create_test_account.sql**
   - Script SQL pour créer le compte de test

5. **backend/scripts/create-test-account.sh**
   - Script shell pour exécuter la création

## ✅ Checklist

- [x] Mode développement désactivé
- [x] Bypass OTP supprimé
- [x] Compte de test configuré
- [x] Script SQL créé
- [x] Script shell créé
- [x] Bouton de connexion rapide ajouté
- [x] Code de bypass supprimé de SMSVerificationView
- [ ] Compte de test créé dans la base de données (à faire)
- [ ] Test de connexion rapide (à faire)

## 🎉 Résultat

Vous pouvez maintenant :
1. **Créer le compte de test** dans la base de données
2. **Utiliser le bouton "Connexion rapide"** dans l'application
3. **Vous connecter instantanément** sans OTP
4. **Tester toutes les fonctionnalités** de l'application

Le mode développement est supprimé, mais vous avez toujours un moyen rapide de tester l'application avec le compte de test !

