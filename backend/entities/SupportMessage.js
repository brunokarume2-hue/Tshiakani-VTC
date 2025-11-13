// Entité SupportMessage avec PostgreSQL
const { EntitySchema } = require('typeorm');

const SupportMessage = new EntitySchema({
  name: 'SupportMessage',
  tableName: 'support_messages',
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
    message: {
      type: 'text'
    },
    isFromUser: {
      type: 'boolean',
      default: true,
      name: 'is_from_user'
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
      name: 'idx_support_messages_user_id',
      columns: ['userId']
    },
    {
      name: 'idx_support_messages_created_at',
      columns: ['createdAt']
    }
  ]
});

module.exports = SupportMessage;

