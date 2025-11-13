/**
 * Configuration Jest pour les tests backend
 */

module.exports = {
  // Environnement de test
  testEnvironment: 'node',
  
  // Répertoires à inclure
  roots: ['<rootDir>'],
  testMatch: [
    '**/__tests__/**/*.js',
    '**/?(*.)+(spec|test).js'
  ],
  
  // Fichiers à ignorer
  testPathIgnorePatterns: [
    '/node_modules/',
    '/dist/',
    '/build/'
  ],
  
  // Configuration des modules
  moduleFileExtensions: ['js', 'json'],
  
  // Setup files
  setupFilesAfterEnv: ['<rootDir>/setup.js'],
  
  // Coverage
  collectCoverage: false,
  collectCoverageFrom: [
    '../../backend/**/*.js',
    '!../../backend/**/*.test.js',
    '!../../backend/node_modules/**',
    '!../../backend/config/**'
  ],
  coverageDirectory: '<rootDir>/coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  
  // Timeout
  testTimeout: 30000,
  
  // Verbose
  verbose: true,
  
  // Transform (si nécessaire pour TypeScript ou autres)
  // transform: {
  //   '^.+\\.ts$': 'ts-jest'
  // },
  
  // Globals
  globals: {
    'ts-jest': {
      tsconfig: {
        // Configuration TypeScript si nécessaire
      }
    }
  }
};

