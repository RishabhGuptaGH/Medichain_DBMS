-- ============================================================
-- MediChain - Complete Database Setup
-- Run this file to set up the entire database
-- Usage: mysql -u root -p < setup.sql
-- ============================================================

-- Drop existing database if it exists
DROP DATABASE IF EXISTS medichain;

-- Create and use the database
SOURCE database/schema.sql;
SOURCE database/triggers.sql;
SOURCE database/procedures.sql;
SOURCE database/seed_data.sql;

-- Verify setup
SELECT 'Database setup complete!' AS status;
SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'medichain' ORDER BY TABLE_NAME;
