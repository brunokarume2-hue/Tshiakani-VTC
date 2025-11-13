# Configuration des Tests Backend

## Variables d'Environnement

Créez un fichier `.env.test` dans le répertoire `backend/` avec les variables suivantes :

```env
NODE_ENV=test
DATABASE_URL=postgresql://localhost:5432/tshiakani_vtc_test
JWT_SECRET=test-jwt-secret-key-for-testing-only

# Configuration PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=tshiakani_vtc_test
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

## Base de Données de Test

1. Créer la base de données de test :
```bash
createdb tshiakani_vtc_test
```

2. Exécuter les migrations :
```bash
# Adapter selon votre système de migration
npm run migrate:test
```

## Installation des Dépendances

```bash
cd backend
npm install --save-dev jest supertest
```

## Exécution des Tests

```bash
# Tous les tests
npm test

# Tests en mode watch
npm run test:watch

# Tests avec coverage
npm run test:coverage
```

