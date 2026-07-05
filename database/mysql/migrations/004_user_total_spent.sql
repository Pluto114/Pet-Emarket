-- Migration 004: Add total_spent column for membership upgrade tracking
ALTER TABLE user_account ADD COLUMN IF NOT EXISTS total_spent DECIMAL(12,2) NOT NULL DEFAULT 0;
