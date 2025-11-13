// Entité SupportTicket avec PostgreSQL
const { EntitySchema } = require('typeorm');

const SupportTicket = new EntitySchema({
  name: 'SupportTicket',
  tableName: 'support_tickets',
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
    subject: {
      type: 'varchar',
      length: 255
    },
    message: {
      type: 'text'
    },
    category: {
      type: 'varchar',
      length: 100
    },
    status: {
      type: 'varchar',
      length: 50,
      default: 'open'
    },
    priority: {
      type: 'varchar',
      length: 20,
      default: 'normal'
    },
    resolvedAt: {
      type: 'timestamp',
      nullable: true,
      name: 'resolved_at'
    },
    resolvedById: {
      type: 'int',
      nullable: true,
      name: 'resolved_by_id'
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
    },
    resolvedBy: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: {
        name: 'resolved_by_id',
        referencedColumnName: 'id'
      }
    }
  },
  indices: [
    {
      name: 'idx_support_tickets_user_id',
      columns: ['userId']
    },
    {
      name: 'idx_support_tickets_status',
      columns: ['status']
    },
    {
      name: 'idx_support_tickets_created_at',
      columns: ['createdAt']
    }
  ]
});

module.exports = SupportTicket;

