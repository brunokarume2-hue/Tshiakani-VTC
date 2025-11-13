# ✅ Migration vers Authentification par Mot de Passe

## 📋 Date : 2025-01-15

---

## 🎯 Objectif

Simplifier le processus d'authentification en remplaçant l'OTP (One-Time Password) par une méthode traditionnelle avec mot de passe.

---

## ✅ Modifications Apportées

### 1. Backend - Routes d'Authentification

#### Nouvelle Route `/auth/register`
- **Méthode** : `POST`
- **Paramètres** :
  - `phoneNumber` (requis) : Numéro de téléphone
  - `name` (requis) : Nom complet
  - `password` (requis, min 6 caractères) : Mot de passe
  - `role` (optionnel) : Rôle utilisateur (client/driver, défaut: client)
- **Fonctionnalités** :
  - Vérifie si le numéro existe déjà
  - Hash le mot de passe avec bcrypt
  - Crée l'utilisateur dans la base de données
  - Génère un token JWT
  - Retourne le token et les informations utilisateur

#### Nouvelle Route `/auth/login`
- **Méthode** : `POST`
- **Paramètres** :
  - `phoneNumber` (requis) : Numéro de téléphone
  - `password` (requis) : Mot de passe
- **Fonctionnalités** :
  - Vérifie les identifiants
  - Compare le mot de passe avec bcrypt
  - Génère un token JWT
  - Retourne le token et les informations utilisateur

#### Routes Anciennes Conservées
- `/auth/send-otp` : Conservée pour compatibilité (peut être supprimée plus tard)
- `/auth/verify-otp` : Conservée pour compatibilité (peut être supprimée plus tard)
- `/auth/signin` : Conservée pour compatibilité (peut être supprimée plus tard)

### 2. iOS - Services

#### APIService.swift
- **Nouvelle méthode `register()`** : Appelle `/auth/register`
- **Nouvelle méthode `login()`** : Appelle `/auth/login`
- **Anciennes méthodes conservées** : `sendOTP()`, `verifyOTP()`, `signIn()`

#### AuthViewModel.swift
- **Nouvelle méthode `register()`** : Gère l'inscription avec mot de passe
- **Nouvelle méthode `login()`** : Gère la connexion avec mot de passe
- **Anciennes méthodes conservées** : `sendOTP()`, `verifyOTP()`, `signIn()`

### 3. iOS - Vues

#### RegistrationView.swift
- **Formulaire simplifié** :
  - Champ téléphone (avec indicatif +243)
  - Champ nom complet
  - Champ mot de passe
  - Champ confirmation mot de passe
- **Validation** :
  - Téléphone : minimum 9 chiffres
  - Nom : non vide
  - Mot de passe : minimum 6 caractères
  - Confirmation : doit correspondre au mot de passe
- **Suppression** : Plus de référence à OTP/SMS

#### LoginView.swift
- **Formulaire simplifié** :
  - Champ téléphone (avec indicatif +243)
  - Champ mot de passe
- **Validation** :
  - Téléphone : minimum 9 chiffres
  - Mot de passe : non vide
- **Suppression** : Plus de référence à OTP/SMS

---

## 🔒 Sécurité

### Hash des Mots de Passe
- **Algorithme** : bcrypt
- **Salt rounds** : 10
- **Stockage** : Hash uniquement (pas de mot de passe en clair)

### Validation
- **Mot de passe minimum** : 6 caractères
- **Vérification** : Numéro de téléphone unique
- **Token JWT** : Expiration de 7 jours (configurable)

---

## 📊 Base de Données

### Table `users`
- **Colonne `password`** : Déjà existante (varchar 255, nullable)
- **Colonne `is_verified`** : Définie à `true` lors de l'inscription
- **Aucune migration nécessaire** : La structure existe déjà

---

## 🧪 Tests

### Test d'Inscription
```bash
curl -X POST "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243847305825",
    "name": "Test User",
    "password": "password123",
    "role": "client"
  }'
```

### Test de Connexion
```bash
curl -X POST "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "+243847305825",
    "password": "password123"
  }'
```

---

## 🔄 Migration des Utilisateateurs Existants

### Utilisateurs sans Mot de Passe
- Les utilisateurs existants sans mot de passe devront s'inscrire à nouveau
- Ou utiliser la fonctionnalité "Réinitialiser le mot de passe" (à implémenter)

### Utilisateurs avec OTP
- Les utilisateurs qui se sont inscrits avec OTP devront créer un mot de passe
- Ou utiliser la fonctionnalité "Réinitialiser le mot de passe" (à implémenter)

---

## 🚀 Déploiement

### Backend
1. **Redéployer le backend sur Cloud Run**
   ```bash
   cd backend
   ./scripts/gcp-deploy-backend.sh
   ```

2. **Vérifier les routes**
   ```bash
   curl -X POST "https://tshiakani-vtc-backend-418102154417.us-central1.run.app/api/auth/register" \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "+243847305825", "name": "Test", "password": "test123"}'
   ```

### iOS
1. **Builder l'app dans Xcode**
   - `Product` > `Clean Build Folder` (⇧⌘K)
   - `Product` > `Build` (⌘B)

2. **Tester l'inscription**
   - Ouvrir l'app
   - Cliquer sur "S'inscrire"
   - Remplir le formulaire (téléphone, nom, mot de passe)
   - Vérifier que l'inscription fonctionne

3. **Tester la connexion**
   - Cliquer sur "Se connecter"
   - Entrer le téléphone et le mot de passe
   - Vérifier que la connexion fonctionne

---

## 📝 Prochaines Étapes

### Fonctionnalités à Ajouter (Optionnel)
1. **Réinitialisation du mot de passe**
   - Route `/auth/forgot-password`
   - Route `/auth/reset-password`
   - Envoi d'email ou SMS avec lien de réinitialisation

2. **Changement de mot de passe**
   - Route `/auth/change-password`
   - Nécessite l'authentification (token JWT)

3. **Suppression des routes OTP**
   - Supprimer `/auth/send-otp`
   - Supprimer `/auth/verify-otp`
   - Supprimer le service OTP (si plus utilisé)

---

## ✅ Checklist de Déploiement

- [x] Routes backend `/auth/register` et `/auth/login` créées
- [x] Méthodes `register()` et `login()` dans APIService.swift
- [x] Méthodes `register()` et `login()` dans AuthViewModel.swift
- [x] RegistrationView.swift modifié (formulaire avec mot de passe)
- [x] LoginView.swift modifié (formulaire avec mot de passe)
- [ ] Backend redéployé sur Cloud Run
- [ ] Tests d'inscription réussis
- [ ] Tests de connexion réussis
- [ ] App iOS testée avec succès

---

**Date** : 2025-01-15  
**Statut** : ✅ **Modifications Appliquées - Prêt pour Déploiement**

