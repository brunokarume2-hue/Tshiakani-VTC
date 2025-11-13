# Tests Tshiakani VTC

Ce répertoire contient tous les tests pour le système Tshiakani VTC, incluant les tests backend (Jest) et iOS (XCTest).

## Structure

```
tests/
├── QA_Tester.md              # Documentation de l'agent QA
├── README.md                 # Ce fichier
├── backend/
│   ├── jest.config.js        # Configuration Jest
│   ├── setup.js              # Configuration des tests backend
│   ├── ride-lifecycle.test.js # Tests E2E du cycle de course
│   └── transaction-service.test.js # Tests du service de transaction
└── ios/
    ├── RideViewModelTests.swift      # Tests du ViewModel de course
    ├── RealtimeServiceTests.swift    # Tests du service temps réel
    └── PaymentServiceTests.swift     # Tests du service de paiement
```

## Tests Backend (Jest)

### Prérequis

1. Node.js et npm installés
2. Base de données PostgreSQL de test configurée
3. Variables d'environnement configurées dans `.env.test`

### Installation

```bash
cd backend
npm install --save-dev jest supertest
```

### Configuration

1. Créer un fichier `.env.test` dans le répertoire `backend/` :
```env
NODE_ENV=test
DATABASE_URL=postgresql://localhost:5432/tshiakani_vtc_test
JWT_SECRET=test-jwt-secret-key-for-testing-only
```

2. Créer la base de données de test :
```bash
createdb tshiakani_vtc_test
```

3. Exécuter les migrations sur la base de test :
```bash
# Adapter selon votre système de migration
npm run migrate:test
```

### Exécution des Tests

```bash
# Tous les tests
cd backend
npm test

# Tests en mode watch
npm run test:watch

# Tests avec coverage
npm run test:coverage

# Un fichier de test spécifique
npm test -- ride-lifecycle.test.js
```

### Tests Disponibles

#### ride-lifecycle.test.js
Tests end-to-end du cycle complet d'une course :
- Demande de course par le client
- Acceptation par le chauffeur
- Démarrage de la course
- Fin de course et paiement
- Validation des statuts

#### transaction-service.test.js
Tests unitaires du service de transaction ACID :
- Acceptation de course avec transaction
- Complétion de course avec transaction
- Annulation de course
- Gestion des erreurs et rollback

## Tests iOS (XCTest)

### Prérequis

1. Xcode installé
2. Projet iOS ouvert dans Xcode
3. Simulateur iOS configuré

### Configuration

1. Ajouter les fichiers de test au projet Xcode :
   - Ouvrir Xcode
   - Sélectionner le target de test (TshiakaniVTCTests)
   - Ajouter les fichiers Swift depuis le répertoire `tests/ios/`

2. Configurer les imports :
   - S'assurer que `@testable import Tshiakani_VTC` fonctionne
   - Vérifier que tous les modules nécessaires sont accessibles

### Exécution des Tests

#### Dans Xcode
1. Ouvrir le projet dans Xcode
2. Appuyer sur `⌘ + U` pour lancer tous les tests
3. Ou utiliser le menu `Product > Test`

#### En ligne de commande
```bash
# Tous les tests
xcodebuild test \
  -scheme "Tshiakani VTC" \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Tests spécifiques
xcodebuild test \
  -scheme "Tshiakani VTC" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:TshiakaniVTCTests/RideViewModelTests
```

### Tests Disponibles

#### RideViewModelTests.swift
Tests du ViewModel de course :
- Création de demande de course
- Mise à jour des statuts
- Annulation de course
- Cycle complet d'une course

#### RealtimeServiceTests.swift
Tests du service de communication temps réel :
- Connexion/déconnexion
- Envoi de demandes
- Réception d'événements
- Mise à jour de position

#### PaymentServiceTests.swift
Tests du service de paiement :
- Traitement des paiements
- Validation des paiements
- Différents modes de paiement
- Intégration avec les courses

## Cycle Complet d'une Course - Scénario de Test

### 1. Demande de Course (Client)
- ✅ Le client crée une demande de course
- ✅ Les coordonnées sont validées
- ✅ Le prix estimé est calculé
- ✅ Les chauffeurs proches sont notifiés

### 2. Acceptation (Chauffeur)
- ✅ Le chauffeur reçoit la demande
- ✅ La proximité est validée (géofencing)
- ✅ Le chauffeur accepte la course
- ✅ Le statut est mis à jour avec transaction ACID
- ✅ Le client est notifié

### 3. Démarrage de la Course
- ✅ Le statut passe à "driverArriving"
- ✅ Le statut passe à "inProgress"
- ✅ La position du chauffeur est tracée en temps réel

### 4. Fin de Course
- ✅ Le statut passe à "completed"
- ✅ Le prix final est calculé
- ✅ La transaction de paiement est créée
- ✅ Le chauffeur est remis disponible

### 5. Paiement
- ✅ Le token de paiement est validé
- ✅ Le paiement est traité
- ✅ Le statut de paiement est mis à jour
- ✅ Le client et le chauffeur sont notifiés

## Bonnes Pratiques

1. **Isolation des Tests**
   - Chaque test doit être indépendant
   - Nettoyer les données après chaque test
   - Utiliser des mocks pour les services externes

2. **Couverture de Code**
   - Viser au moins 80% de couverture
   - Tester les cas d'erreur
   - Tester les cas limites

3. **Assertions**
   - Vérifier les statuts HTTP
   - Vérifier les structures de données
   - Vérifier les mises à jour en base
   - Vérifier les notifications

4. **Performance**
   - Tests doivent s'exécuter rapidement
   - Utiliser des timeouts appropriés
   - Paralléliser quand possible

## Dépannage

### Backend

**Erreur de connexion à la base de données**
- Vérifier que PostgreSQL est démarré
- Vérifier les variables d'environnement
- Vérifier que la base de test existe

**Erreurs de migration**
- Exécuter les migrations sur la base de test
- Vérifier les permissions de la base de données

### iOS

**Erreurs d'import**
- Vérifier que `@testable import Tshiakani_VTC` est correct
- Vérifier que le module est accessible
- Nettoyer le build (⌘ + Shift + K)

**Tests qui échouent**
- Vérifier que les mocks sont correctement configurés
- Vérifier les timeouts
- Vérifier les dépendances

## Contribution

Lors de l'ajout de nouveaux tests :
1. Suivre la structure existante
2. Ajouter des commentaires clairs
3. Tester les cas d'erreur
4. Mettre à jour ce README si nécessaire

## Ressources

- [Documentation Jest](https://jestjs.io/)
- [Documentation XCTest](https://developer.apple.com/documentation/xctest)
- [Agent QA_Tester](./QA_Tester.md)

