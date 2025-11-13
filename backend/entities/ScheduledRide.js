// Entité ScheduledRide avec PostgreSQL + PostGIS
const { EntitySchema } = require('typeorm');

const ScheduledRide = new EntitySchema({
  name: 'ScheduledRide',
  tableName: 'scheduled_rides',
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
    scheduledDate: {
      type: 'timestamp',
      name: 'scheduled_date'
    },
    vehicleType: {
      type: 'varchar',
      length: 50,
      name: 'vehicle_type'
    },
    paymentMethod: {
      type: 'varchar',
      length: 20,
      default: 'cash',
      name: 'payment_method'
    },
    status: {
      type: 'varchar',
      length: 20,
      default: 'pending',
      name: 'status'
    },
    estimatedPrice: {
      type: 'decimal',
      precision: 10,
      scale: 2,
      nullable: true,
      name: 'estimated_price'
    },
    rideId: {
      type: 'int',
      nullable: true,
      name: 'ride_id'
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
    client: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: {
        name: 'client_id',
        referencedColumnName: 'id'
      }
    },
    ride: {
      type: 'many-to-one',
      target: 'Ride',
      joinColumn: {
        name: 'ride_id',
        referencedColumnName: 'id'
      },
      nullable: true
    }
  },
  indices: [
    {
      name: 'idx_scheduled_rides_client_id',
      columns: ['clientId']
    },
    {
      name: 'idx_scheduled_rides_scheduled_date',
      columns: ['scheduledDate']
    },
    {
      name: 'idx_scheduled_rides_status',
      columns: ['status']
    }
  ]
});

module.exports = ScheduledRide;

