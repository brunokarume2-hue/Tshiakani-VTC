// Entité User avec PostGIS (syntaxe TypeORM JavaScript)
const { EntitySchema } = require('typeorm');

const User = new EntitySchema({
  name: 'User',
  tableName: 'users',
  columns: {
    id: {
      type: 'int',
      primary: true,
      generated: true
    },
    name: {
      type: 'varchar',
      length: 255
    },
    phoneNumber: {
      type: 'varchar',
      length: 20,
      unique: true,
      nullable: true,
      name: 'phone_number'
    },
    // email: Temporairement commenté car la colonne n'existe pas dans la base
    // email: {
    //   type: 'varchar',
    //   length: 255,
    //   unique: true,
    //   nullable: true,
    //   select: false
    // },
    password: {
      type: 'varchar',
      length: 255,
      nullable: true,
      select: false  // Ne pas inclure par défaut dans les requêtes pour la sécurité
    },
    // profileImageURL: Temporairement commenté car la colonne n'existe pas dans la base
    // profileImageURL: {
    //   type: 'varchar',
    //   length: 500,
    //   nullable: true,
    //   name: 'profile_image_url',
    //   select: false
    // },
    role: {
      type: 'varchar',
      length: 20,
      default: 'client'
    },
    isVerified: {
      type: 'boolean',
      default: false,
      name: 'is_verified'
    },
    location: {
      type: 'geography',
      spatialFeatureType: 'Point',
      srid: 4326,
      nullable: true
    },
    fcmToken: {
      type: 'varchar',
      length: 255,
      nullable: true,
      name: 'fcm_token'
    },
    createdAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      name: 'created_at'
    },
    updatedAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      onUpdate: 'CURRENT_TIMESTAMP',
      name: 'updated_at'
    }
  },
  relations: {
    clientRides: {
      type: 'one-to-many',
      target: 'Ride',
      inverseSide: 'client'
    }
  },
  indices: [
    {
      name: 'idx_users_role',
      columns: ['role']
    },
    {
      name: 'idx_users_phone',
      columns: ['phoneNumber'],
      unique: true
    }
    // Note: Les index spatiaux GIST et partiels complexes sont créés dans la migration SQL
    // (003_optimize_indexes.sql) car TypeORM a des limitations avec ces index avancés
  ]
});

// Méthode statique pour trouver les conducteurs proches
User.findNearbyDrivers = async function(latitude, longitude, radiusKm = 10, dataSource = null) {
  if (!dataSource) {
    dataSource = require('../config/database');
  }

  try {
    const radiusMeters = radiusKm * 1000;
    const drivers = await dataSource.query(
      `SELECT 
        u.id,
        u.name,
        u.phone_number,
        u.driver_info,
        u.fcm_token,
        ST_Distance(
          u.location::geography,
          ST_MakePoint($2, $1)::geography
        ) / 1000 AS distance_km,
        ST_Y(u.location::geometry) AS location_lat,
        ST_X(u.location::geometry) AS location_lon
      FROM users u
      WHERE u.role = 'driver'
        AND u.driver_info->>'isOnline' = 'true'
        AND u.location IS NOT NULL
        AND ST_DWithin(
          u.location::geography,
          ST_MakePoint($2, $1)::geography,
          $3
        )
      ORDER BY u.location <-> ST_MakePoint($2, $1)::geography
      LIMIT 20`,
      [latitude, longitude, radiusMeters]
    );

    // Convertir les résultats en format User
    return drivers.map(driver => ({
      id: driver.id,
      name: driver.name,
      phoneNumber: driver.phone_number,
      driverInfo: driver.driver_info,
      location: driver.location_lat && driver.location_lon ? {
        coordinates: [driver.location_lon, driver.location_lat],
        type: 'Point'
      } : null,
      distance_km: parseFloat(driver.distance_km) || 0,
      fcmToken: driver.fcm_token || null
    }));
  } catch (error) {
    console.error('Erreur recherche conducteurs proches:', error);
    throw error;
  }
};

module.exports = User;

