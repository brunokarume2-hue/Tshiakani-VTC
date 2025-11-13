// Entité FavoriteAddress avec PostgreSQL + PostGIS
const { EntitySchema } = require('typeorm');

const FavoriteAddress = new EntitySchema({
  name: 'FavoriteAddress',
  tableName: 'favorite_addresses',
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
    name: {
      type: 'varchar',
      length: 255
    },
    address: {
      type: 'text'
    },
    location: {
      type: 'geography',
      spatialFeatureType: 'Point',
      srid: 4326
    },
    icon: {
      type: 'varchar',
      length: 50,
      nullable: true
    },
    isFavorite: {
      type: 'boolean',
      default: true,
      name: 'is_favorite'
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
      name: 'idx_favorite_addresses_user_id',
      columns: ['userId']
    },
    {
      name: 'idx_favorite_addresses_is_favorite',
      columns: ['isFavorite']
    }
  ]
});

module.exports = FavoriteAddress;

