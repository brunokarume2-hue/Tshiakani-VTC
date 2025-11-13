// Entité ChatMessage avec PostgreSQL
const { EntitySchema } = require('typeorm');

const ChatMessage = new EntitySchema({
  name: 'ChatMessage',
  tableName: 'chat_messages',
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
    senderId: {
      type: 'int',
      name: 'sender_id'
    },
    senderName: {
      type: 'varchar',
      length: 255,
      name: 'sender_name'
    },
    message: {
      type: 'text'
    },
    isFromDriver: {
      type: 'boolean',
      default: false,
      name: 'is_from_driver'
    },
    isRead: {
      type: 'boolean',
      default: false,
      name: 'is_read'
    },
    readAt: {
      type: 'timestamp',
      nullable: true,
      name: 'read_at'
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
    sender: {
      type: 'many-to-one',
      target: 'User',
      joinColumn: {
        name: 'sender_id',
        referencedColumnName: 'id'
      }
    }
  },
  indices: [
    {
      name: 'idx_chat_messages_ride_id',
      columns: ['rideId']
    },
    {
      name: 'idx_chat_messages_created_at',
      columns: ['createdAt']
    },
    {
      name: 'idx_chat_messages_sender_id',
      columns: ['senderId']
    }
  ]
});

module.exports = ChatMessage;

