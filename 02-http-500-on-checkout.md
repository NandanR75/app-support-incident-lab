# Scenario 2: HTTP 500 on Checkout (Payment Not Processing)

## User report
"My order shows as 'pending' and I was never charged, but I also never
got an error message."

## Investigation

**Step 1 — Check the order's status directly:**

```sql
SELECT * FROM orders WHERE user_id = 2 ORDER BY created_at DESC LIMIT 1;
```

Result: order exists, `status = 'pending'`, `total_amount = 19.50`.

**Step 2 — Check whether a payment record exists for this order at all:**

```sql
SELECT o.order_id, o.user_id, o.status, o.total_amount, o.created_at
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;
```

Result includes this exact order — **no payment row exists whatsoever**,
not even a `failed` one. This tells us the payment step was never reached
or the API call to the payment service never completed.

**Step 3 — Check the API logs for the checkout endpoint around that time:**

```bash
grep "POST /api/checkout" app.log | tail -20
```

Log shows:
```
2026-09-05 16:20:11 INFO  POST /api/checkout - order_id=2 - status=200
2026-09-05 16:20:12 INFO  Calling payment-service /charge
2026-09-05 16:20:42 ERROR payment-service request timed out after 30000ms
2026-09-05 16:20:42 ERROR Unhandled exception in checkout controller - HTTP 500 returned to client (silently swallowed by frontend retry logic)
```

## Root cause
The order was created successfully, but the call to the external
**payment-service** timed out after 30 seconds. The backend threw an
unhandled exception on that timeout, which should have marked the order
as `failed`, but instead left it stuck in `pending` with the exception
never surfaced to the user (the frontend's retry logic silently caught
the 500 without informing them).

## Fix
Support-level fix (unblock the user immediately):
```sql
-- Manually mark the stuck order as failed so the user isn't charged later
-- by a delayed retry from payment-service, and can safely re-attempt
UPDATE orders SET status = 'cancelled' WHERE order_id = 2;
```

Escalation for engineering: file a bug for two issues found in the logs:
1. Timeouts calling `payment-service` should mark the order `failed`,
   not leave it in `pending` indefinitely
2. The frontend is swallowing 500 errors instead of showing the user a
   clear "payment failed, please retry" message

## Verification
```sql
SELECT status FROM orders WHERE order_id = 2;  -- confirms 'cancelled'
```
Ask the user to retry checkout and confirm the new order completes with
a matching successful payment row.

## Takeaway
The LEFT JOIN query is the fastest way to spot "order exists but payment
never happened" as a pattern — useful for scanning many stuck orders at
once, not just investigating one ticket at a time.
