// Entité Ride avec PostGIS (syntaxe TypeORM JavaScript)
const { EntitySchema } = require('typeorm');

const Ride = new EntitySchema({
  name: 'Ride',
  tableName: 'rides',
  columns: {
    id: {
      type: 'int',
      primary: true,
      generated: true
    },
    clientId: {
      type: 'int',
      name: 'client_id'
    },
    driverId: {
      type: 'int',
      nullable: true,
      name: 'driver_id'
    },
    pickupLocation: {
      type: 'geography',
      spatialFeatureType: 'Point',
      srid: 4326,
      name: 'pickup_location'
    },
    pickupAddress: {
      type: 'text',
      nullable: true,
      name: 'pickup_address'
    },
    dropoffLocation: {
      type: 'geography',
      spatialFeatureType: 'Point',
      srid: 4326,
      name: 'dropoff_location'
    },
    dropoffAddress: {
      type: 'text',
      nullable: true,
      name: 'dropoff_address'
    },
    status: {
      type: 'varchar',
      length: 20,
      default: 'pending'
    },
    estimatedPrice: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      name: 'estimated_price'
    },
    finalPrice: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      nullable: true,
      name: 'final_price'
    },
    distance: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      nullable: true,
      name: 'distance_km'
    },
    duration: {
      type: 'int',
      nullable: true,
      name: 'duration_min'
    },
    paymentMethod: {
      type: 'varchar',
      length: 20,
      default: 'cash',
      name: 'payment_method'
    },
    rating: {
      type: 'int',
      nullable: true
    },
    comment: {
      type: 'text',
      nullable: true
    },
    createdAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      name: 'created_at'
    },
    startedAt: {
      type: 'timestamp',
      nullable: true,
      name: 'started_at'
    },
    completedAt: {
      type: 'timestamp',
      nullable: true,
      name: 'completed_at'
    },
    cancelledAt: {
      type: 'timestamp',
      nullable: true,
      name: 'cancelled_at'
    },
    cancellationReason: {
      type: 'text',
      nullable: true,
      name: 'cancellation_reason'
    }
  },
  relations: {
    client: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: { name: 'client_id' },
      onDelete: 'CASCADE'
    },
    driver: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: { name: 'driver_id' },
      onDelete: 'SET NULL'
    }
  },
  indices: [
    {
      name: 'idx_rides_client',
      columns: ['clientId']
    },
    {
      name: 'idx_rides_driver',
      columns: ['driverId']
    },
    {
      name: 'idx_rides_status',
      columns: ['status']
    }
    // Note: Les index spatiaux GIST, composites et partiels sont créés dans la migration SQL
    // (003_optimize_indexes.sql) car TypeORM a des limitations avec ces index avancés
  ]
});

// Fonction pour calculer la distance
Ride.calculateDistance = async function(rideId, dataSource) {
  const repository = dataSource.getRepository('Ride');
  const result = await repository
    .createQueryBuilder('ride')
    .select(
      `ST_Distance(
        ride.pickup_location::geography,
        ride.dropoff_location::geography
      ) / 1000`,
      'distance_km'
    )
    .where('ride.id = :id', { id: rideId })
    .getRawOne();
  
  return result?.distance_km || null;
};

module.exports = Ride;

