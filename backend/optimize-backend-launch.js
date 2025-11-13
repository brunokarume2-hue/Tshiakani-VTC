#!/usr/bin/env node

/**
 * Script d'optimisation du backend pour le lancement à Kinshasa
 * Désactive les routes et fonctionnalités non essentielles
 */

const fs = require('fs');
const path = require('path');

const SERVER_FILE = path.join(__dirname, 'server.postgres.js');

console.log('🚀 Optimisation du backend pour le lancement à Kinshasa...\n');

// Lire le fichier server.postgres.js
let serverContent = fs.readFileSync(SERVER_FILE, 'utf8');

// Routes à désactiver pour le lancement
const routesToDisable = [
    // Réservation programmée (si elle existe)
    // "app.use('/api/rides/scheduled', require('./routes.postgres/scheduled-rides'));",
    
    // Chat (si elle existe)
    // "app.use('/api/chat', require('./routes.postgres/chat'));",
    
    // Partage de trajet (si elle existe)
    // "app.use('/api/rides/share', require('./routes.postgres/share-ride'));",
];

// Routes essentielles à garder
const essentialRoutes = [
    'app.use(\'/api/auth\', require(\'./routes.postgres/auth\'));',
    'app.use(\'/api/rides\', require(\'./routes.postgres/rides\'));',
    'app.use(\'/api/courses\', require(\'./routes.postgres/rides\'));',
    'app.use(\'/api/users\', require(\'./routes.postgres/users\'));',
    'app.use(\'/api/location\', require(\'./routes.postgres/location\'));',
    'app.use(\'/api/driver\', require(\'./routes.postgres/driver\'));',
    'app.use(\'/api/client\', require(\'./routes.postgres/client\'));',
    'app.use(\'/api/notifications\', require(\'./routes.postgres/notifications\'));',
    'app.use(\'/api/sos\', require(\'./routes.postgres/sos\'));',
    'app.use(\'/api/admin\', require(\'./routes.postgres/admin\'));',
    'app.use(\'/api/admin/pricing\', require(\'./routes.postgres/pricing\'));',
    'app.use(\'/api/paiements\', require(\'./routes.postgres/paiements\'));',
];

console.log('✅ Routes essentielles à garder:');
essentialRoutes.forEach(route => {
    console.log(`   - ${route}`);
});

console.log('\n❌ Routes à désactiver:');
routesToDisable.forEach(route => {
    console.log(`   - ${route}`);
});

// Vérifier que les routes essentielles sont présentes
let allRoutesPresent = true;
essentialRoutes.forEach(route => {
    if (!serverContent.includes(route)) {
        console.log(`⚠️  Route manquante: ${route}`);
        allRoutesPresent = false;
    }
});

if (allRoutesPresent) {
    console.log('\n✅ Toutes les routes essentielles sont présentes');
} else {
    console.log('\n⚠️  Certaines routes essentielles sont manquantes');
}

// Optimisations supplémentaires
console.log('\n🔧 Optimisations supplémentaires:');

// 1. Vérifier la compression
if (serverContent.includes('compression')) {
    console.log('   ✅ Compression activée');
} else {
    console.log('   ⚠️  Compression non activée (recommandé)');
    console.log('   💡 Ajoutez: const compression = require(\'compression\'); app.use(compression());');
}

// 2. Vérifier le rate limiting
if (serverContent.includes('rateLimit')) {
    console.log('   ✅ Rate limiting activé');
} else {
    console.log('   ⚠️  Rate limiting non activé (recommandé)');
}

// 3. Vérifier Helmet
if (serverContent.includes('helmet')) {
    console.log('   ✅ Helmet activé');
} else {
    console.log('   ⚠️  Helmet non activé (recommandé)');
}

// 4. Vérifier les index PostGIS
console.log('   💡 Vérifiez les index PostGIS dans la base de données:');
console.log('      CREATE INDEX IF NOT EXISTS idx_rides_pickup_location ON rides USING GIST (pickupLocation);');
console.log('      CREATE INDEX IF NOT EXISTS idx_rides_dropoff_location ON rides USING GIST (dropoffLocation);');

console.log('\n✅ Optimisation terminée!\n');

// Créer un fichier de configuration pour les optimisations
const configContent = `// Configuration d'optimisation pour le lancement à Kinshasa
module.exports = {
    // Routes à désactiver
    disabledRoutes: ${JSON.stringify(routesToDisable, null, 2)},
    
    // Routes essentielles
    essentialRoutes: ${JSON.stringify(essentialRoutes, null, 2)},
    
    // Optimisations
    optimizations: {
        compression: true,
        rateLimiting: true,
        helmet: true,
        postgisIndexes: true
    }
};
`;

fs.writeFileSync(path.join(__dirname, 'launch-config.js'), configContent);
console.log('📄 Fichier de configuration créé: launch-config.js\n');

console.log('📋 Prochaines étapes:');
console.log('   1. Vérifier les index PostGIS dans la base de données');
console.log('   2. Activer la compression si ce n\'est pas déjà fait');
console.log('   3. Tester les routes essentielles');
console.log('   4. Configurer les variables d\'environnement');
console.log('   5. Déployer en production\n');

