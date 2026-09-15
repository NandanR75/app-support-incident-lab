-- seed_data.sql
-- Sample data. Includes a few intentionally inconsistent rows used by the
-- troubleshooting scenarios (e.g. an order with no matching payment).

INSERT INTO users (email, full_name, created_at) VALUES
('alice@example.com', 'Alice Johnson', '2026-08-01 09:00:00'),
('bob@example.com',   'Bob Smith',     '2026-08-03 14:30:00'),
('carla@example.com', 'Carla Diaz',    '2026-08-10 11:15:00');

INSERT INTO orders (user_id, status, total_amount, created_at) VALUES
(1, 'paid',      59.99, '2026-09-01 10:00:00'),
(2, 'pending',   19.50, '2026-09-05 16:20:00'),
(3, 'cancelled', 89.00, '2026-09-08 08:45:00'),
(1, 'paid',      120.00, '2026-09-10 12:00:00');
-- Note: order_id 10025 (referenced in scenario 01) does NOT exist here -
-- that's the point of the scenario.

INSERT INTO payments (order_id, amount, status, processed_at) VALUES
(1, 59.99, 'success', '2026-09-01 10:01:00'),
-- order_id 2 (Bob's pending order) has NO matching payment row at all -
-- this is the root cause explored in scenario 02.
(3, 89.00, 'failed', '2026-09-08 08:46:00');
-- order_id 4 also has no payment row - used in scenario 02 as well.
