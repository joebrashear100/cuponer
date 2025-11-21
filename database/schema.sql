-- FURG Database Schema
-- PostgreSQL with TimescaleDB extension for time-series transaction data

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    last_seen TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_apple_id ON users(apple_id);

-- User profiles (JSONB for flexibility in chat-first approach)
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    location VARCHAR(255),
    employer VARCHAR(255),
    salary DECIMAL(12,2),
    savings_goal JSONB, -- {amount: 30000, deadline: "2026-08-01", purpose: "house down payment"}
    learned_insights TEXT[], -- Array of insights learned through conversation
    spending_preferences JSONB, -- Categories user cares about
    health_metrics JSONB, -- Steps, workout data from HealthKit
    intensity_mode VARCHAR(50) DEFAULT 'moderate', -- mild, moderate, insanity
    emergency_buffer DECIMAL(10,2) DEFAULT 500.00,
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Conversation history
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata JSONB, -- Store additional context like transaction IDs referenced
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_conversations_user_time ON conversations(user_id, created_at DESC);

-- Transactions (TimescaleDB hypertable for efficient time-series queries)
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date TIMESTAMP NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    merchant VARCHAR(255) NOT NULL,
    merchant_category_code VARCHAR(100),
    category VARCHAR(50), -- ML-predicted category
    plaid_transaction_id VARCHAR(255),
    financekit_transaction_id VARCHAR(255),
    notes TEXT,
    is_bill BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    location_lat DECIMAL(10,7),
    location_lon DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id, date)
);

-- Convert to hypertable (must be done after table creation)
SELECT create_hypertable('transactions', 'date', if_not_exists => TRUE);

CREATE INDEX idx_transactions_user ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_merchant ON transactions(merchant);
CREATE INDEX idx_transactions_category ON transactions(category);

-- Bills (predicted recurring expenses)
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    merchant VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    frequency_days INTEGER NOT NULL, -- 7, 14, 30, 90, 365
    next_due_date DATE NOT NULL,
    confidence FLOAT NOT NULL, -- 0.0 to 1.0
    is_active BOOLEAN DEFAULT TRUE,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bills_user_next_due ON bills(user_id, next_due_date);
CREATE INDEX idx_bills_active ON bills(user_id, is_active);

-- Shadow accounts (hidden savings)
CREATE TABLE shadow_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(255),
    account_last_4 VARCHAR(4),
    balance DECIMAL(12,2) DEFAULT 0,
    purpose VARCHAR(100), -- 'savings_goal', 'forced_savings', 'emergency'
    reveal_at TIMESTAMP, -- When to reveal to user
    last_hidden_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_shadow_accounts_user ON shadow_accounts(user_id);

-- Plaid items (connected banks)
CREATE TABLE plaid_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plaid_item_id VARCHAR(255) UNIQUE NOT NULL,
    plaid_access_token TEXT NOT NULL,
    institution_name VARCHAR(255),
    institution_id VARCHAR(255),
    last_synced TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active', -- active, error, disconnected
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_plaid_items_user ON plaid_items(user_id);

-- Learned insights (pattern detection)
CREATE TABLE learned_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    insight TEXT NOT NULL,
    confidence FLOAT NOT NULL,
    category VARCHAR(50), -- 'spending_pattern', 'location_pattern', 'time_pattern'
    evidence JSONB, -- Supporting data
    learned_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_learned_insights_user ON learned_insights(user_id, learned_at DESC);

-- API usage tracking (for rate limiting and cost control)
CREATE TABLE api_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    endpoint VARCHAR(255),
    input_tokens INTEGER,
    output_tokens INTEGER,
    cost DECIMAL(10,6),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_api_usage_user_date ON api_usage(user_id, created_at DESC);

-- Training examples (for ML model improvement)
CREATE TABLE training_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transaction_data JSONB NOT NULL,
    correct_category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_training_examples_created ON training_examples(created_at DESC);

-- Device tokens (for push notifications)
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL, -- 'ios', 'android'
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id, is_active);

-- Create views for common queries

-- View: Recent transactions with bill status
CREATE VIEW recent_transactions_with_bills AS
SELECT
    t.*,
    b.id IS NOT NULL AS is_detected_bill,
    b.confidence AS bill_confidence
FROM transactions t
LEFT JOIN bills b ON t.merchant = b.merchant AND t.user_id = b.user_id AND b.is_active = TRUE
ORDER BY t.date DESC;

-- View: User financial summary
CREATE VIEW user_financial_summary AS
SELECT
    u.id AS user_id,
    u.apple_id,
    up.name,
    up.salary,
    up.intensity_mode,
    (SELECT SUM(balance) FROM shadow_accounts WHERE user_id = u.id) AS total_hidden,
    (SELECT COUNT(*) FROM bills WHERE user_id = u.id AND is_active = TRUE) AS active_bills_count,
    (SELECT COUNT(*) FROM plaid_items WHERE user_id = u.id AND status = 'active') AS connected_banks_count,
    (SELECT COUNT(*) FROM transactions WHERE user_id = u.id AND date > NOW() - INTERVAL '30 days') AS transactions_last_30_days
FROM users u
LEFT JOIN user_profiles up ON u.id = up.user_id;

-- Functions for common operations

-- Function: Calculate upcoming bills
CREATE OR REPLACE FUNCTION calculate_upcoming_bills(p_user_id UUID, p_days INTEGER)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    total DECIMAL(12,2);
BEGIN
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM bills
    WHERE user_id = p_user_id
    AND is_active = TRUE
    AND next_due_date <= CURRENT_DATE + p_days;

    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Function: Update bill next due date
CREATE OR REPLACE FUNCTION update_bill_next_due(p_bill_id UUID)
RETURNS VOID AS $$
DECLARE
    v_frequency INTEGER;
    v_current_due DATE;
BEGIN
    SELECT frequency_days, next_due_date INTO v_frequency, v_current_due
    FROM bills
    WHERE id = p_bill_id;

    UPDATE bills
    SET next_due_date = v_current_due + v_frequency,
        updated_at = NOW()
    WHERE id = p_bill_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Get user balance (would integrate with Plaid in production)
CREATE OR REPLACE FUNCTION get_user_total_balance(p_user_id UUID)
RETURNS DECIMAL(12,2) AS $$
DECLARE
    total DECIMAL(12,2);
BEGIN
    -- This is a placeholder - in production would query Plaid accounts
    -- For now, calculate from transaction history
    SELECT COALESCE(SUM(amount), 0) INTO total
    FROM transactions
    WHERE user_id = p_user_id;

    RETURN ABS(total);
END;
$$ LANGUAGE plpgsql;

-- Triggers

-- Trigger: Update user last_seen on activity
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users SET last_seen = NOW() WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_conversation_updates_last_seen
AFTER INSERT ON conversations
FOR EACH ROW
EXECUTE FUNCTION update_user_last_seen();

-- Trigger: Update profile updated_at
CREATE OR REPLACE FUNCTION update_profile_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_profile_update_timestamp
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_profile_timestamp();

-- Initial data / defaults

-- Create a test user for development (remove in production)
-- INSERT INTO users (apple_id, email) VALUES ('test_user_001', 'test@example.com');
