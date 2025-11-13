// Entité Notification (syntaxe TypeORM JavaScript)
const { EntitySchema } = require('typeorm');

const Notification = new EntitySchema({
  name: 'Notification',
  tableName: 'notifications',
  columns: {
    id: {
      type: 'int',
      primary: true,
      generated: true
    },
    userId: {
      type: 'int',
      name: 'user_id'
    },
    type: {
      type: 'varchar',
      length: 20
    },
    title: {
      type: 'varchar',
      length: 255
    },
    message: {
      type: 'text'
    },
    rideId: {
      type: 'int',
      nullable: true,
      name: 'ride_id'
    },
    isRead: {
      type: 'boolean',
      default: false,
      name: 'is_read'
    },
    createdAt: {
      type: 'timestamp',
      default: () => 'CURRENT_TIMESTAMP',
      name: 'created_at'
    }
  },
  relations: {
    user: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: { name: 'user_id' },
      onDelete: 'CASCADE'
    },
    ride: {
      type: 'many-to-one',
      target: 'Ride',
      joinColumn: { name: 'ride_id' },
      nullable: true,
      onDelete: 'SET NULL'
    }
  },
  indices: [
    {
      name: 'idx_notifications_user',
      columns: ['userId', 'createdAt']
    },
    {
      name: 'idx_notifications_read',
      columns: ['isRead']
    }
    // Note: Les index composites et partiels sont créés dans la migration SQL
    // (003_optimize_indexes.sql) car TypeORM a des limitations avec ces index avancés
  ]
});

module.exports = Notification;

