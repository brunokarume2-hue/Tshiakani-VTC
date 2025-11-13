# Intégration des Tests dans le Workflow de Développement

## Workflow CI/CD

### GitHub Actions (Exemple)

```yaml
name: Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_DB: tshiakani_vtc_test
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: |
          cd backend
          npm install
      - name: Run tests
        run: |
          cd backend
          npm test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/tshiakani_vtc_test
          JWT_SECRET: test-jwt-secret

  ios-tests:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: |
          xcodebuild test \
            -scheme "Tshiakani VTC" \
            -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Tests Locaux

### Pré-commit Hooks

Créer un fichier `.git/hooks/pre-commit` :

```bash
#!/bin/bash

# Exécuter les tests avant chaque commit
echo "Exécution des tests..."

# Tests backend
cd backend
npm test
if [ $? -ne 0 ]; then
    echo "Les tests backend ont échoué. Commit annulé."
    exit 1
fi

# Tests iOS (optionnel, peut être long)
# xcodebuild test -scheme "Tshiakani VTC" -destination 'platform=iOS Simulator,name=iPhone 15'

echo "Tous les tests ont réussi."
exit 0
```

### Tests Automatiques

Utiliser `nodemon` ou `watchman` pour exécuter les tests automatiquement :

```bash
# Backend
cd backend
npm install -g nodemon
nodemon --exec "npm test" --watch "**/*.js"

# iOS
# Utiliser le mode watch de Xcode (⌘ + Control + Option + U)
```

## Stratégie de Test

### 1. Tests Unitaires
- Testent des fonctions individuelles
- Exécution rapide (< 1s)
- Pas de dépendances externes
- Mock des services

### 2. Tests d'Intégration
- Testent l'interaction entre composants
- Utilisent une base de données de test
- Exécution modérée (< 10s)
- Mock des services externes (Firebase, Stripe)

### 3. Tests End-to-End
- Testent le flux complet
- Utilisent une base de données de test
- Exécution plus longue (< 30s)
- Testent les transactions ACID

## Bonnes Pratiques

### 1. Nommage des Tests
```javascript
// ✅ Bon
test('DEVRAIT accepter une course valide', async () => {
  // ...
});

// ❌ Mauvais
test('test1', () => {
  // ...
});
```

### 2. Structure AAA (Arrange-Act-Assert)
```javascript
test('DEVRAIT créer une course', async () => {
  // Arrange - Préparer les données
  const client = await createTestUser('client');
  const pickup = { latitude: -4.3276, longitude: 15.3156 };
  
  // Act - Exécuter l'action
  const ride = await createTestRide(client.id);
  
  // Assert - Vérifier le résultat
  expect(ride.status).toBe('pending');
});
```

### 3. Isolation des Tests
```javascript
// ✅ Chaque test est indépendant
beforeEach(async () => {
  // Nettoyer la base de données
  await cleanupDatabase();
});

// ❌ Les tests dépendent les uns des autres
test('test1', () => {
  // Crée des données
});

test('test2', () => {
  // Utilise les données de test1
});
```

### 4. Mocking
```javascript
// Mock des services externes
jest.mock('../services/PaymentService', () => ({
  processPayment: jest.fn().mockResolvedValue({ success: true })
}));
```

## Métriques de Qualité

### Couverture de Code
- Viser au moins 80% de couverture
- Couvrir les cas d'erreur
- Couvrir les cas limites

### Temps d'Exécution
- Tests unitaires : < 1s chacun
- Tests d'intégration : < 10s chacun
- Tests E2E : < 30s chacun
- Suite complète : < 5 minutes

### Maintenabilité
- Tests clairs et lisibles
- Commentaires explicatifs
- Documentation à jour
- Refactoring régulier

## Dépannage

### Tests qui échouent de manière intermittente
- Vérifier les timeouts
- Vérifier l'isolation des tests
- Vérifier les races conditions
- Utiliser des mocks stables

### Tests lents
- Optimiser les requêtes de base de données
- Utiliser des mocks au lieu de vrais services
- Paralléliser les tests
- Utiliser des bases de données en mémoire

### Tests qui passent localement mais échouent en CI
- Vérifier les variables d'environnement
- Vérifier les dépendances
- Vérifier les versions de Node.js/PostgreSQL
- Vérifier les permissions

## Ressources

- [Jest Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Strategies](https://martinfowler.com/articles/practical-test-pyramid.html)

