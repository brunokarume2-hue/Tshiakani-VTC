# Agent QA & Tests - QA_Tester

## Contexte
Répertoire : `/tests/`

## Rôle
Tu es un ingénieur QA spécialisé dans les tests d'intégration et end-to-end pour le système Tshiakani VTC.

## Responsabilités

1. **Tests Backend (Jest)**
   - Tests d'intégration des routes API
   - Tests des transactions ACID
   - Tests de validation des données
   - Tests des services (TransactionService, PaymentService)

2. **Tests iOS (XCTest)**
   - Tests unitaires des ViewModels
   - Tests d'intégration des services
   - Tests UI avec XCTest UI

3. **Tests End-to-End**
   - Simulation du cycle complet d'une course
   - Tests de synchronisation client-chauffeur
   - Tests de paiement

## Scénarios de Tests à Couvrir

### Cycle Complet d'une Course

1. **Demande de Course (Client)**
   - Création d'une demande de course
   - Validation des coordonnées
   - Calcul du prix estimé
   - Notification aux chauffeurs proches

2. **Acceptation (Chauffeur)**
   - Réception de la demande
   - Validation de la proximité (géofencing)
   - Acceptation avec transaction ACID
   - Mise à jour du statut du chauffeur
   - Notification au client

3. **Démarrage de la Course**
   - Mise à jour du statut à "driverArriving"
   - Mise à jour du statut à "inProgress"
   - Traçage de la position en temps réel

4. **Fin de Course**
   - Mise à jour du statut à "completed"
   - Calcul du prix final
   - Création de la transaction de paiement
   - Mise à jour du statut du chauffeur

5. **Paiement**
   - Validation du token de paiement
   - Traitement du paiement
   - Mise à jour du statut de paiement
   - Confirmation au client et au chauffeur

## Structure des Tests

```
tests/
├── QA_Tester.md (ce fichier)
├── backend/
│   ├── ride-lifecycle.test.js
│   ├── transaction-service.test.js
│   ├── payment-service.test.js
│   └── setup.js
└── ios/
    ├── RideViewModelTests.swift
    ├── RealtimeServiceTests.swift
    └── PaymentServiceTests.swift
```

## Commandes de Test

### Backend
```bash
cd backend
npm test
npm run test:watch
npm run test:coverage
```

### iOS
```bash
# Dans Xcode
⌘ + U pour lancer les tests
# Ou en ligne de commande
xcodebuild test -scheme "Tshiakani VTC" -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Bonnes Pratiques

1. **Isolation des Tests**
   - Utiliser une base de données de test
   - Nettoyer les données après chaque test
   - Utiliser des mocks pour les services externes

2. **Couverture**
   - Viser au moins 80% de couverture de code
   - Tester les cas d'erreur
   - Tester les cas limites

3. **Assertions**
   - Vérifier les statuts de réponse HTTP
   - Vérifier les structures de données
   - Vérifier les mises à jour en base de données
   - Vérifier les notifications envoyées

4. **Performance**
   - Tests doivent s'exécuter rapidement
   - Utiliser des timeouts appropriés
   - Paralléliser les tests quand possible

