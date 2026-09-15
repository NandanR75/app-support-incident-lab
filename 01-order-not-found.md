# Scenario 1: "Order Not Found"

## User report
"I placed an order this morning (order #10025) and it showed a confirmation,
but now when I check my order history it says 'Order not found'."

## Investigation

**Step 1 — Check if the order actually exists in the database:**

```sql
SELECT * FROM orders WHERE order_id = 10025;
```

Result: **0 rows returned.** The order genuinely does not exist in the
database, despite the user seeing a confirmation screen.

**Step 2 — Since the data layer confirms it's missing, move up the stack.**
Check the application/API logs around the time of the order for that user:

```bash
grep "order_id" app.log | grep -i "10025\|checkout"
```

Log shows:
```
2026-09-10 11:58:02 INFO  Checkout started for user_id=1
2026-09-10 11:58:03 INFO  Order created in-memory, order_id=10025
2026-09-10 11:58:04 ERROR Failed to commit order to database: connection timeout
2026-09-10 11:58:04 INFO  Confirmation page rendered (cached order object)
```

## Root cause
The confirmation page was rendered from an **in-memory order object**
before the database write completed. The actual `INSERT` failed due to a
database connection timeout, but the frontend had already shown a success
message — a classic case of the frontend not verifying the backend write
actually succeeded before confirming success to the user.

## Fix
This is a code-level fix (outside a support engineer's typical scope to
implement, but the diagnosis is the deliverable): the checkout flow should
only render the confirmation page **after** receiving a successful write
confirmation from the database, not immediately after submission.

As an immediate support action:
- Confirm with the user that no payment was actually charged (check the
  `payments` table / payment gateway for a matching transaction)
- Ask the user to retry the order
- File a bug ticket for engineering referencing the exact timestamp and
  log lines above, so the race condition can be fixed at the source

## Verification
- Confirm no orphaned payment exists for this attempt:
  ```sql
  SELECT * FROM payments WHERE order_id = 10025;
  ```
  (returns 0 rows — confirms no charge was made, safe to have user retry)
- After the user retries, confirm the new order ID exists and matches a
  successful payment

## Takeaway
"Order not found" could have been a UI bug, a typo, or a data issue — the
SQL check ruled out two of those possibilities in one query, and the log
grep found the real root cause. This is the value of moving methodically
through the stack instead of guessing.
