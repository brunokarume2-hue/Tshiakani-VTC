// Entité SOSReport avec PostGIS (syntaxe TypeORM JavaScript)
const { EntitySchema } = require('typeorm');

const SOSReport = new EntitySchema({
  name: 'SOSReport',
  tableName: 'sos_reports',
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
    location: {
      type: 'geography',
      spatialFeatureType: 'Point',
      srid: 4326
    },
    address: {
      type: 'text',
      nullable: true
    },
    rideId: {
      type: 'int',
      nullable: true,
      name: 'ride_id'
    },
    message: {
      type: 'text',
      default: "Signalement d''urgence"
    },
    status: {
      type: 'varchar',
      length: 20,
      default: 'active'
    },
    resolvedAt: {
      type: 'timestamp',
      nullable: true,
      name: 'resolved_at'
    },
    resolvedById: {
      type: 'int',
      nullable: true,
      name: 'resolved_by'
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
    },
    resolvedBy: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: { name: 'resolved_by' },
      nullable: true
    }
  },
  indices: [
    {
      name: 'idx_sos_status',
      columns: ['status']
    },
    {
      name: 'idx_sos_user',
      columns: ['userId', 'createdAt']
    }
    // Note: Les index spatiaux GIST et partiels sont créés dans la migration SQL
    // (003_optimize_indexes.sql) car TypeORM a des limitations avec ces index avancés
  ]
});

module.exports = SOSReport;

