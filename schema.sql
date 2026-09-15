-- schema.sql
-- Minimal e-commerce schema used across the troubleshooting scenarios.

CREATE TABLE IF NOT EXISTS users (
    user_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    email       TEXT NOT NULL UNIQUE,
    full_name   TEXT NOT NULL,
    created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL,
    status      TEXT NOT NULL,   -- 'pending', 'paid', 'shipped', 'cancelled'
    total_amount REAL NOT NULL,
    created_at  TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS payments (
    payment_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id    INTEGER NOT NULL,
    amount      REAL NOT NULL,
    status      TEXT NOT NULL,   -- 'success', 'failed', 'pending'
    processed_at TEXT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
