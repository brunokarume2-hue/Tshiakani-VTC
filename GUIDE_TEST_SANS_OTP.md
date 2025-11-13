# 🧪 Guide de Test Sans OTP - Mode Développement

**Date**: 2025  
**Status**: ✅ Mode Développement Activé

---

## 🎯 Objectif

Permettre de tester l'application sans que le système OTP/SMS fonctionne en utilisant un mode développement avec code de test ou bypass OTP.

---

## ✅ Configuration

### FeatureFlags.swift

Le mode développement est activé dans `FeatureFlags.swift`:

```swift
// MARK: - Mode Développement/Test

/// Mode développement/test (active le bypass OTP pour les tests)
static let developmentMode = true // Actif pour les tests

/// Code OTP de test (fonctionne toujours en mode développement)
static let testOTPCode = "123456" // Code de test

/// Bypass OTP en mode développement (permet de se connecter sans code)
static let bypassOTP = true // Actif pour les tests
```

---

## 🔧 Comment Tester

### Option 1: Bypass OTP (Recommandé pour les tests)

Avec `bypassOTP = true`, **n'importe quel code à 6 chiffres fonctionne**.

**Étapes**:
1. Lancer l'application
2. Aller sur l'écran d'inscription/connexion
3. Entrer un numéro de téléphone (ex: `820 098 808`)
4. Sur l'écran de vérification SMS, entrer **n'importe quel code à 6 chiffres** (ex: `000000`, `123456`, `999999`)
5. Le code sera accepté automatiquement
6. Vous serez connecté et redirigé vers `ClientMainView`

### Option 2: Code de Test

Avec `bypassOTP = false`, utiliser le code de test.

**Étapes**:
1. Lancer l'application
2. Aller sur l'écran d'inscription/connexion
3. Entrer un numéro de téléphone (ex: `820 098 808`)
4. Sur l'écran de vérification SMS, entrer le code de test: **`123456`**
5. Le code sera accepté
6. Vous serez connecté et redirigé vers `ClientMainView`

---

## 📱 Interface de Test

### Écran de Vérification SMS

En mode développement, l'écran affiche:

```
┌─────────────────────────────────┐
│      [Icône SMS]                │
│                                 │
│      Vérification               │
│  Nous avons envoyé un code à   │
│    +243 820 098 808            │
│                                 │
│  [0] [0] [0] [0] [0] [0]       │
│                                 │
│      [Vérifier]                 │
│                                 │
│    Renvoyer le code            │
│                                 │
│    ───────────────────          │
│   Mode Développement            │
│   Code de test: 123456          │
│                                 │
│   ⚠️ Bypass OTP activé          │
│   Tout code fonctionne          │
└─────────────────────────────────┘
```

---

## 🔄 Flux de Test Complet

### 1. Inscription

```
OnboardingView
    ↓
AuthGateView
    ↓
"S'inscrire"
    ↓
RegistrationView
    - Entrer numéro: 820 098 808
    ↓
SMSVerificationView
    - Entrer code: 123456 (ou n'importe quel code)
    ↓
✅ Connexion réussie
    ↓
ClientMainView
```

### 2. Connexion

```
OnboardingView
    ↓
AuthGateView
    ↓
"Se connecter"
    ↓
LoginView
    - Entrer numéro: 820 098 808
    ↓
SMSVerificationView
    - Entrer code: 123456 (ou n'importe quel code)
    ↓
✅ Connexion réussie
    ↓
ClientMainView
```

---

## 🎛️ Configuration des Options

### Activer le Bypass OTP (Recommandé)

Dans `FeatureFlags.swift`:

```swift
static let developmentMode = true
static let bypassOTP = true // Tout code fonctionne
```

**Avantages**:
- ✅ Plus rapide pour les tests
- ✅ Pas besoin de se souvenir du code
- ✅ Test facile avec n'importe quel code

### Utiliser le Code de Test

Dans `FeatureFlags.swift`:

```swift
static let developmentMode = true
static let bypassOTP = false // Utiliser le code de test
static let testOTPCode = "123456" // Code de test
```

**Avantages**:
- ✅ Simule un comportement plus réaliste
- ✅ Test du formatage du code
- ✅ Test de la validation

### Désactiver le Mode Développement (Production)

Dans `FeatureFlags.swift`:

```swift
static let developmentMode = false
static let bypassOTP = false
```

**Attention**: En production, l'OTP réel sera requis.

---

## 📋 Checklist de Test

### Tests Fonctionnels

- [ ] **Test Inscription**
  - [ ] Entrer un numéro de téléphone
  - [ ] Arriver sur l'écran de vérification SMS
  - [ ] Voir le message "Mode Développement"
  - [ ] Voir le code de test affiché
  - [ ] Entrer un code (n'importe quel code si bypass activé)
  - [ ] Vérifier que la connexion fonctionne
  - [ ] Vérifier la redirection vers ClientMainView

- [ ] **Test Connexion**
  - [ ] Entrer un numéro de téléphone
  - [ ] Arriver sur l'écran de vérification SMS
  - [ ] Entrer un code
  - [ ] Vérifier que la connexion fonctionne
  - [ ] Vérifier la redirection vers ClientMainView

- [ ] **Test Persistance**
  - [ ] Se connecter
  - [ ] Fermer l'application
  - [ ] Rouvrir l'application
  - [ ] Vérifier que la session est maintenue
  - [ ] Vérifier la redirection automatique vers ClientMainView

---

## 🔒 Sécurité

### ⚠️ Important pour la Production

**Avant le déploiement en production**, assurez-vous de:

1. **Désactiver le mode développement**
   ```swift
   static let developmentMode = false
   static let bypassOTP = false
   ```

2. **Configurer l'OTP réel**
   - Intégrer un service SMS (Twilio, Firebase, etc.)
   - Configurer l'API backend pour envoyer les codes
   - Tester l'envoi et la vérification des codes réels

3. **Vérifier la sécurité**
   - Vérifier que le bypass est bien désactivé
   - Tester avec des codes incorrects
   - Vérifier que seuls les codes valides fonctionnent

---

## 🚀 Passage en Production

### Étapes

1. **Désactiver le mode développement**
   ```swift
   static let developmentMode = false
   ```

2. **Configurer l'API OTP**
   - Intégrer un service SMS
   - Configurer l'envoi de codes
   - Configurer la vérification des codes

3. **Tester l'OTP réel**
   - Tester l'envoi de codes
   - Tester la vérification
   - Tester avec des codes incorrects

4. **Déployer**
   - Build de production
   - Tests finaux
   - Déploiement

---

## 📊 Résumé

### Mode Développement (Actuel)

- ✅ **Bypass OTP activé**: Tout code fonctionne
- ✅ **Code de test affiché**: 123456
- ✅ **Message visible**: "Mode Développement"
- ✅ **Test facile**: Pas besoin de code réel

### Mode Production (À venir)

- ❌ **Bypass OTP désactivé**: Seuls les codes valides fonctionnent
- ❌ **Code de test désactivé**: Pas de code de test
- ❌ **Message masqué**: Pas de message de développement
- ✅ **Sécurité**: Vérification réelle des codes

---

## 🆘 Dépannage

### Problème: Le code ne fonctionne pas

**Solution**:
1. Vérifier que `developmentMode = true`
2. Vérifier que `bypassOTP = true` ou utiliser le code `123456`
3. Vérifier que le code a 6 chiffres
4. Vérifier que tous les champs sont remplis

### Problème: La connexion échoue

**Solution**:
1. Vérifier que le numéro de téléphone est valide (9 chiffres)
2. Vérifier que le code est complet (6 chiffres)
3. Vérifier les logs dans la console
4. Vérifier que l'API backend fonctionne (si utilisé)

### Problème: Redirection incorrecte

**Solution**:
1. Vérifier que `AuthManager.isAuthenticated = true`
2. Vérifier que `AuthManager.userRole = .client`
3. Vérifier que `RootView` observe correctement `authManager`
4. Vérifier la navigation dans `RootView`

---

## 📝 Notes

### Pour les Tests

- Utilisez le bypass OTP pour les tests rapides
- Utilisez le code de test pour simuler un comportement réaliste
- Testez avec différents numéros de téléphone
- Testez la persistance de la session

### Pour la Production

- Désactivez toujours le mode développement
- Configurez l'OTP réel avant le déploiement
- Testez l'OTP réel avant le lancement
- Surveillez les erreurs d'authentification

---

**Document créé par**: Agent Architecte Principal  
**Date**: 2025  
**Status**: ✅ Mode Développement Activé

