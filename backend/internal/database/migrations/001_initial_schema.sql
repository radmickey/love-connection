CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    apple_id VARCHAR(500) UNIQUE,
    username VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255),
    device_token TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_apple_id ON users(apple_id);

CREATE TABLE IF NOT EXISTS pairs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id != user2_id)
);

CREATE INDEX IF NOT EXISTS idx_pairs_user1 ON pairs(user1_id);
CREATE INDEX IF NOT EXISTS idx_pairs_user2 ON pairs(user2_id);

CREATE TABLE IF NOT EXISTS love_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pair_id UUID,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    duration_seconds INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_love_events_pair ON love_events(pair_id);
CREATE INDEX IF NOT EXISTS idx_love_events_sender ON love_events(sender_id);
CREATE INDEX IF NOT EXISTS idx_love_events_created ON love_events(created_at DESC);

