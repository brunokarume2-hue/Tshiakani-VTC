// Script pour créer des données de test dans la base de données
require('dotenv').config();
const AppDataSource = require('../config/database');
const User = require('../entities/User');
const Ride = require('../entities/Ride');

// Coordonnées de Kinshasa (RDC)
const KINSHASA_CENTER = {
  lat: -4.3276,
  lng: 15.3136
};

// Générer un point aléatoire autour de Kinshasa
function randomPoint(center, radiusKm = 10) {
  const radius = radiusKm / 111; // Conversion approximative km -> degrés
  const u = Math.random();
  const v = Math.random();
  const w = radius * Math.sqrt(u);
  const t = 2 * Math.PI * v;
  const x = w * Math.cos(t);
  const y = w * Math.sin(t);
  return {
    lat: center.lat + y,
    lng: center.lng + x
  };
}

// Noms et prénoms congolais
const firstNames = ['Jean', 'Marie', 'Pierre', 'Paul', 'Joseph', 'Antoine', 'François', 'David', 'Daniel', 'Michel', 'André', 'Philippe', 'Claude', 'Bernard', 'Henri'];
const lastNames = ['Mukendi', 'Kabila', 'Tshisekedi', 'Lumumba', 'Kasa-Vubu', 'Mobutu', 'Kabila', 'Nzongola', 'Mbuyi', 'Kazadi', 'Mputu', 'Ngalula', 'Kankonde', 'Mwanza', 'Kalombo'];

function randomName() {
  return `${firstNames[Math.floor(Math.random() * firstNames.length)]} ${lastNames[Math.floor(Math.random() * lastNames.length)]}`;
}

function randomPhone() {
  return `243${8 + Math.floor(Math.random() * 2)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}${Math.floor(Math.random() * 10)}`;
}

async function seedData() {
  try {
    // Initialiser la connexion
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
      console.log('✅ Connexion à la base de données établie');
    }

    const userRepository = AppDataSource.getRepository(User);
    const rideRepository = AppDataSource.getRepository(Ride);

    // Vérifier si des conducteurs existent déjà
    const existingDrivers = await userRepository.count({ where: { role: 'driver' } });
    const existingRides = await rideRepository.count();
    
    if (existingDrivers > 0 || existingRides > 0) {
      console.log('⚠️  Des conducteurs ou courses existent déjà.');
      console.log(`   Conducteurs: ${existingDrivers}, Courses: ${existingRides}`);
      console.log('   Création uniquement des données manquantes...\n');
    }

    console.log('🌱 Création des données de test...\n');

    // Récupérer les clients existants ou en créer
    let clients = await userRepository.find({ where: { role: 'client' } });
    if (clients.length < 20) {
      console.log(`👥 Création de ${20 - clients.length} clients supplémentaires...`);
      for (let i = clients.length; i < 20; i++) {
        const client = userRepository.create({
          name: randomName(),
          phoneNumber: randomPhone(),
          role: 'client',
          isVerified: Math.random() > 0.3, // 70% vérifiés
          location: null // Les clients n'ont pas de localisation permanente
        });
        await userRepository.save(client);
        clients.push(client);
      }
      console.log(`✅ ${clients.length} clients au total\n`);
    } else {
      console.log(`✅ ${clients.length} clients existants\n`);
    }

    // Créer 10 conducteurs (seulement s'ils n'existent pas)
    const existingDriversCount = await userRepository.count({ where: { role: 'driver' } });
    const driversToCreate = Math.max(0, 10 - existingDriversCount);
    
    if (driversToCreate > 0) {
      console.log(`🏍️  Création de ${driversToCreate} conducteurs...`);
    } else {
      console.log('✅ Conducteurs déjà existants');
    }
    
    const drivers = await userRepository.find({ where: { role: 'driver' } });
    
    for (let i = 0; i < driversToCreate; i++) {
      const point = randomPoint(KINSHASA_CENTER, 15);
      const isOnline = Math.random() > 0.4; // 60% en ligne
      
      // Créer le driver sans location d'abord
      const driver = userRepository.create({
        name: randomName(),
        phoneNumber: randomPhone(),
        role: 'driver',
        isVerified: Math.random() > 0.2, // 80% vérifiés
        driverInfo: {
          isOnline: isOnline,
          status: isOnline ? (Math.random() > 0.5 ? 'disponible' : 'en_course') : 'hors_ligne',
          rating: parseFloat((4 + Math.random()).toFixed(1)), // Note entre 4.0 et 5.0
          totalRides: Math.floor(Math.random() * 100),
          vehicleType: ['moto', 'taxi', 'van'][Math.floor(Math.random() * 3)],
          vehiclePlate: `KIN-${Math.floor(Math.random() * 9000) + 1000}-${String.fromCharCode(65 + Math.floor(Math.random() * 26))}${String.fromCharCode(65 + Math.floor(Math.random() * 26))}`
        }
      });
      const savedDriver = await userRepository.save(driver);
      
      // Mettre à jour la location avec une requête SQL brute
      await AppDataSource.query(
        `UPDATE users SET location = ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography WHERE id = $3`,
        [point.lng, point.lat, savedDriver.id]
      );
      
      // Recharger le driver avec la location
      const driverWithLocation = await userRepository.findOne({ where: { id: savedDriver.id } });
      drivers.push(driverWithLocation);
    }
    if (driversToCreate > 0) {
      console.log(`✅ ${drivers.length} conducteurs au total\n`);
    } else {
      console.log(`✅ ${drivers.length} conducteurs existants\n`);
    }

    // Créer 50 courses (seulement si aucune n'existe)
    const existingRidesCount = await rideRepository.count();
    const ridesToCreate = Math.max(0, 50 - existingRidesCount);
    
    if (ridesToCreate > 0) {
      console.log(`🚗 Création de ${ridesToCreate} courses...`);
    } else {
      console.log('✅ Courses déjà existantes');
    }
    const statuses = ['pending', 'accepted', 'inProgress', 'completed', 'cancelled'];
    const statusWeights = [0.1, 0.1, 0.1, 0.6, 0.1]; // 60% complétées
    
    const rides = [];
    const now = new Date();
    
    for (let i = 0; i < ridesToCreate; i++) {
      const pickup = randomPoint(KINSHASA_CENTER, 20);
      const dropoff = randomPoint(pickup, 5); // Destination proche du pickup
      
      const statusIndex = Math.random() < statusWeights[0] ? 0 :
                         Math.random() < statusWeights[0] + statusWeights[1] ? 1 :
                         Math.random() < statusWeights[0] + statusWeights[1] + statusWeights[2] ? 2 :
                         Math.random() < statusWeights[0] + statusWeights[1] + statusWeights[2] + statusWeights[3] ? 3 : 4;
      const status = statuses[statusIndex];
      
      const client = clients[Math.floor(Math.random() * clients.length)];
      const driver = status !== 'pending' ? drivers[Math.floor(Math.random() * drivers.length)] : null;
      
      const estimatedPrice = Math.floor(Math.random() * 5000) + 1000; // Entre 1000 et 6000 CDF
      const finalPrice = status === 'completed' ? estimatedPrice + Math.floor(Math.random() * 500) - 250 : null;
      const distance = Math.random() * 10 + 1; // Entre 1 et 11 km
      const duration = Math.floor(distance * 3 + Math.random() * 10); // Environ 3 min/km
      
      const createdAt = new Date(now.getTime() - Math.random() * 7 * 24 * 60 * 60 * 1000); // Derniers 7 jours
      const startedAt = status !== 'pending' ? new Date(createdAt.getTime() + Math.random() * 5 * 60 * 1000) : null;
      const completedAt = status === 'completed' ? new Date((startedAt || createdAt).getTime() + duration * 60 * 1000) : null;
      
      // Créer la course directement avec SQL pour gérer les locations PostGIS
      const result = await AppDataSource.query(
        `INSERT INTO rides (
          client_id, driver_id, pickup_location, dropoff_location, 
          pickup_address, dropoff_address, status, estimated_price, final_price,
          distance_km, duration_min, payment_method, rating, created_at, started_at, completed_at
        ) VALUES ($1, $2, 
          ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography,
          ST_SetSRID(ST_MakePoint($5, $6), 4326)::geography,
          $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
        ) RETURNING id`,
        [
          client.id,
          driver ? driver.id : null,
          pickup.lng, pickup.lat,
          dropoff.lng, dropoff.lat,
          `Avenue ${randomName()}, Kinshasa`,
          `Boulevard ${randomName()}, Kinshasa`,
          status,
          estimatedPrice,
          finalPrice,
          parseFloat(distance.toFixed(2)),
          duration,
          ['cash', 'mobile_money', 'card'][Math.floor(Math.random() * 3)],
          status === 'completed' && Math.random() > 0.3 ? Math.floor(Math.random() * 2) + 4 : null,
          createdAt,
          startedAt,
          completedAt
        ]
      );
      
      const rideId = result[0].id;
      const savedRide = await rideRepository.findOne({ where: { id: rideId } });
      rides.push(savedRide);
    }
    console.log(`✅ ${rides.length} courses créées\n`);

    console.log('✅ Données de test créées avec succès!');
    console.log(`\n📊 Résumé:`);
    console.log(`   - ${clients.length} clients`);
    console.log(`   - ${drivers.length} conducteurs`);
    console.log(`   - ${rides.length} courses`);
    console.log(`   - ${drivers.filter(d => d.driverInfo?.isOnline).length} conducteurs en ligne`);
    console.log(`   - ${rides.filter(r => r.status === 'completed').length} courses complétées`);
    
  } catch (error) {
    console.error('❌ Erreur lors de la création des données:', error);
    process.exit(1);
  } finally {
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
  }
}

// Exécuter le script
seedData();

