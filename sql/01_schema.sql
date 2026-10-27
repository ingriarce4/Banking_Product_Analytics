-- 01_schema.sql
-- SQLite-compatible schema for a synthetic digital banking analytics project.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS experiment_assignments;
DROP TABLE IF EXISTS events;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    signup_date TEXT NOT NULL,              -- ISO date: YYYY-MM-DD
    country TEXT NOT NULL,
    platform TEXT NOT NULL CHECK (platform IN ('iOS', 'Android', 'Web'))
);

CREATE TABLE payments (
    payment_id TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    payment_date TEXT NOT NULL,             -- ISO date: YYYY-MM-DD
    payment_type TEXT NOT NULL CHECK (payment_type IN ('Card', 'Transfer', 'Online')),
    status TEXT NOT NULL CHECK (status IN ('success', 'failed')),
    failure_reason TEXT,
    amount_eur REAL NOT NULL CHECK (amount_eur >= 0),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE events (
    event_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    event_date TEXT NOT NULL,               -- ISO date: YYYY-MM-DD
    event_name TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE experiment_assignments (
    user_id INTEGER PRIMARY KEY,
    experiment_group TEXT NOT NULL CHECK (experiment_group IN ('control', 'treatment')),
    assigned_date TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_user ON payments(user_id);
CREATE INDEX idx_events_date_user ON events(event_date, user_id);
CREATE INDEX idx_events_name ON events(event_name);
