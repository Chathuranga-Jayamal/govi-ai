-- Govi-AI Database Schema
-- Managed manually, outside Claude Code

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    preferred_language VARCHAR(2) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE advisory_docs (
    doc_id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding VECTOR(384) NOT NULL,
    language VARCHAR(2) NOT NULL,
    source VARCHAR(255)
);