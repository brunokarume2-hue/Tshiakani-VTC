// Entité SharedRide avec PostgreSQL
const { EntitySchema } = require('typeorm');

const SharedRide = new EntitySchema({
  name: 'SharedRide',
  tableName: 'shared_rides',
  columns: {
    id: {
      type: 'int',
      primary: true,
      generated: true
    },
    rideId: {
      type: 'int',
      name: 'ride_id'
    },
    userId: {
      type: 'int',
      name: 'user_id'
    },
    shareLink: {
      type: 'varchar',
      length: 500,
      name: 'share_link'
    },
    sharedWith: {
      type: 'jsonb',
      nullable: true,
      name: 'shared_with'
    },
    expiresAt: {
      type: 'timestamp',
      nullable: true,
      name: 'expires_at'
    },
    createdAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      name: 'created_at'
    }
  },
  relations: {
    ride: {
      type: 'many-to-one',
      target: 'Ride',
      joinColumn: {
        name: 'ride_id',
        referencedColumnName: 'id'
      }
    },
    user: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: {
        name: 'user_id',
        referencedColumnName: 'id'
      }
    }
  },
  indices: [
    {
      name: 'idx_shared_rides_ride_id',
      columns: ['rideId']
    },
    {
      name: 'idx_shared_rides_user_id',
      columns: ['userId']
    },
    {
      name: 'idx_shared_rides_expires_at',
      columns: ['expiresAt']
    }
  ]
});

module.exports = SharedRide;

