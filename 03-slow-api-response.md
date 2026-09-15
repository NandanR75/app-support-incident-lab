# Scenario 3: Slow API Response on "My Orders" Page

## User report
"The 'My Orders' page takes 10+ seconds to load. It used to be instant."

## Investigation

**Step 1 — Check application logs for the endpoint's response time:**

```bash
grep "GET /api/orders" app.log | tail -20
```

Log shows the endpoint consistently taking 8-11 seconds, which lines up
with the user's complaint — this rules out network/frontend issues and
points at the backend or database.

**Step 2 — Identify the query the endpoint runs, and check its query plan:**

```sql
EXPLAIN QUERY PLAN
SELECT u.full_name, o.order_id, o.total_amount
FROM orders o
JOIN users u ON o.user_id = u.user_id
WHERE u.email = 'alice@example.com';
```

Result:
```
SEARCH u USING INDEX sqlite_autoindex_users_1 (email=?)
SCAN o
```

The `SCAN o` line is the red flag — it means every single row in the
`orders` table is being scanned to find matches, instead of using an
index. As the orders table grows, this scan gets linearly slower, which
matches the "it used to be instant" complaint (the table has grown since
launch).

## Root cause
There is no index on `orders.user_id`, the column this query joins on. At
small scale, a full table scan is fast enough to be invisible; at
production scale, it's the bottleneck.

## Fix

```sql
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
```

Re-running the same `EXPLAIN QUERY PLAN` afterward confirms the fix:
```
SEARCH u USING INDEX sqlite_autoindex_users_1 (email=?)
SEARCH o USING INDEX idx_orders_user_id (user_id=?)
```

`SCAN o` has become `SEARCH o USING INDEX` — the database can now jump
directly to matching rows instead of checking every row in the table.

## Verification
- Re-run the original query and confirm the query plan shows `SEARCH`
  instead of `SCAN`
- Time the actual API endpoint before/after the index is applied in a
  staging environment
- Monitor the endpoint's response time in production after deployment to
  confirm it matches the improvement seen in staging

## Takeaway
`EXPLAIN QUERY PLAN` (or `EXPLAIN ANALYZE` in Postgres/MySQL) turns "the
database feels slow" into a concrete, provable diagnosis — and gives you
evidence to justify the fix rather than just guessing that "adding an
index" will help.
