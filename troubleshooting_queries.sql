-- troubleshooting_queries.sql
-- Queries referenced in the scenario write-ups under scenarios/.

-- === Scenario 1: "Order not found" ===
-- Check if the order ID the user is reporting actually exists.
SELECT * FROM orders WHERE order_id = 10025;
-- Returns 0 rows -> the order genuinely doesn't exist. Next step: check
-- whether the user has a typo, or whether the order failed to write to
-- the database during checkout (see application/API logs).

-- === Scenario 2: "HTTP 500 on checkout" ===
-- Find orders that exist but have no corresponding payment record -
-- a sign that the payment step silently failed after the order was created.
SELECT o.order_id, o.user_id, o.status, o.total_amount, o.created_at
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;

-- === Scenario 3: "Slow API response" ===
-- A query joining orders and users, used to illustrate why a missing
-- index on orders.user_id causes a full table scan at scale.
EXPLAIN QUERY PLAN
SELECT u.full_name, o.order_id, o.total_amount
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE u.email = 'alice@example.com';

-- Fix used in scenario 3:
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
