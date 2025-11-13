-- Migration 006: Créer les tables pour les nouvelles fonctionnalités
-- Support, Favorites, Chat, Scheduled Rides, Shared Rides

-- Table support_messages
CREATE TABLE IF NOT EXISTS support_messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_from_user BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour support_messages
CREATE INDEX IF NOT EXISTS idx_support_messages_user_id ON support_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_created_at ON support_messages(created_at);

-- Table support_tickets
CREATE TABLE IF NOT EXISTS support_tickets (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    category VARCHAR(100),
    status VARCHAR(50) DEFAULT 'open',
    priority VARCHAR(20) DEFAULT 'normal',
    resolved_at TIMESTAMP,
    resolved_by_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour support_tickets
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at);

-- Table favorite_addresses
CREATE TABLE IF NOT EXISTS favorite_addresses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    icon VARCHAR(50),
    is_favorite BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour favorite_addresses
CREATE INDEX IF NOT EXISTS idx_favorite_addresses_user_id ON favorite_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_favorite_addresses_is_favorite ON favorite_addresses(is_favorite);
-- Index spatial pour favorite_addresses (GIST)
CREATE INDEX IF NOT EXISTS idx_favorite_addresses_location ON favorite_addresses USING GIST (location);

-- Table chat_messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id SERIAL PRIMARY KEY,
    ride_id INTEGER NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    sender_name VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_from_driver BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour chat_messages
CREATE INDEX IF NOT EXISTS idx_chat_messages_ride_id ON chat_messages(ride_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at);

-- Table scheduled_rides
CREATE TABLE IF NOT EXISTS scheduled_rides (
    id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pickup_location GEOGRAPHY(POINT, 4326) NOT NULL,
    pickup_address TEXT,
    dropoff_location GEOGRAPHY(POINT, 4326) NOT NULL,
    dropoff_address TEXT,
    scheduled_date TIMESTAMP NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    payment_method VARCHAR(20) DEFAULT 'cash',
    status VARCHAR(20) DEFAULT 'pending',
    estimated_price DECIMAL(10, 2),
    ride_id INTEGER REFERENCES rides(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour scheduled_rides
CREATE INDEX IF NOT EXISTS idx_scheduled_rides_client_id ON scheduled_rides(client_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_rides_scheduled_date ON scheduled_rides(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_scheduled_rides_status ON scheduled_rides(status);
-- Index spatial pour scheduled_rides (GIST)
CREATE INDEX IF NOT EXISTS idx_scheduled_rides_pickup_location ON scheduled_rides USING GIST (pickup_location);
CREATE INDEX IF NOT EXISTS idx_scheduled_rides_dropoff_location ON scheduled_rides USING GIST (dropoff_location);

-- Table shared_rides
CREATE TABLE IF NOT EXISTS shared_rides (
    id SERIAL PRIMARY KEY,
    ride_id INTEGER NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    share_link VARCHAR(500) NOT NULL,
    shared_with JSONB,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour shared_rides
CREATE INDEX IF NOT EXISTS idx_shared_rides_ride_id ON shared_rides(ride_id);
CREATE INDEX IF NOT EXISTS idx_shared_rides_user_id ON shared_rides(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_rides_expires_at ON shared_rides(expires_at);

-- Commentaires pour documentation
COMMENT ON TABLE support_messages IS 'Messages de support entre utilisateurs et administrateurs';
COMMENT ON TABLE support_tickets IS 'Tickets de support pour le suivi des problèmes';
COMMENT ON TABLE favorite_addresses IS 'Adresses favorites des utilisateurs';
COMMENT ON TABLE chat_messages IS 'Messages de chat entre clients et conducteurs pendant une course';
COMMENT ON TABLE scheduled_rides IS 'Courses programmées à l''avance';
COMMENT ON TABLE shared_rides IS 'Courses partagées avec des contacts';

