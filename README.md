# Application Support & Incident Management Lab

Practice scenarios for tracing application issues across the full stack —
**Frontend → API → Backend → Database** — the core skill in Application
Support roles, where the job is to figure out *where* in the stack a
failure happened before it can be routed to the right fix.

## Why this project

"The application is broken" is not a diagnosis. This lab walks through
realistic incidents where the fix requires reading logs, running SQL
against a sample database, and reasoning about which layer of the stack
is actually at fault.

## Structure

```
app-support-incident-lab/
├── sql/
│   ├── schema.sql              # Sample e-commerce schema (orders, users, payments)
│   ├── seed_data.sql           # Sample data, including intentionally broken rows
│   └── troubleshooting_queries.sql  # Queries used in the scenarios below
├── scenarios/
│   ├── 01-order-not-found.md
│   ├── 02-http-500-on-checkout.md
│   └── 03-slow-api-response.md
├── scripts/
│   └── log_analyzer.py         # Parses a sample app log and summarizes errors
└── README.md
```

## Sample database

A small SQLite e-commerce schema (`orders`, `users`, `payments`) is used
across all scenarios. Build it with:

```bash
sqlite3 app_support.db < sql/schema.sql
sqlite3 app_support.db < sql/seed_data.sql
```

## Scenarios

| # | Scenario | Layer at fault |
|---|---|---|
| 1 | [Order Not Found](scenarios/01-order-not-found.md) | Database (data issue) |
| 2 | [HTTP 500 on Checkout](scenarios/02-http-500-on-checkout.md) | Backend/API (application bug) |
| 3 | [Slow API Response](scenarios/03-slow-api-response.md) | Database (missing index) |

Each scenario follows: **User report → Investigation (logs + SQL) → Root
cause → Fix → Verification**.

## Log analyzer script

`scripts/log_analyzer.py` parses a sample application log
(`scenarios/sample_app.log`) and prints a summary of error types and
counts — a simplified version of what you'd do manually with `grep` or in
a tool like Splunk/Kibana.

```bash
python3 scripts/log_analyzer.py scenarios/sample_app.log
```
![Demo run](Screenshot%20(458).png)
