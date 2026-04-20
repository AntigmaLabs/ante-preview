---
title: "Environment Configuration"
---

# Antix Configuration Reference

## Environment Variables

### ANTIX_ENV (required)

Deployment environment identifier. Controls SSL enforcement, secure cookie
flags, MASTER_KEY availability, and observability resource labels.

| Value        | Description                                         |
|--------------|-----------------------------------------------------|
| `local`      | Local development. SSL disabled, MASTER_KEY allowed. |
| `test`       | Automated test / CI environment. SSL enforced.       |
| `staging`    | Pre-production staging. SSL enforced.                |
| `production` | Live production. SSL enforced, MASTER_KEY disabled.  |

The server refuses to start if `ANTIX_ENV` is missing or set to any value not
listed above.

For local development, set it in your `.env` file or shell:

```bash
export ANTIX_ENV=local
```

Docker Compose sets `ANTIX_ENV=local` by default for the proxy service.
The Dockerfile also defaults to `local`. Production deployments MUST override
this via `-e ANTIX_ENV=production` or equivalent.

### ANTIX_BUDGET_RECONCILE_INTERVAL_SECS (optional)

Interval in seconds between budget reconciliation cycles. The reconciliation
daemon reads authoritative `budget_limit_usd` / `budget_spent_usd` from
Postgres for every user with a budget cap and writes them into Redis via a
Lua script that uses `spent = max(authoritative, redis)` — so settles landed
in Redis but not yet flushed to Postgres are never rolled back. `reserved`
is never touched.

Default: `21600` (6 hours). Set lower for tighter drift recovery (e.g. `3600`
for hourly during a fresh cutover), higher to ease Postgres load. The daemon
only runs if `REDIS_URL` is configured.

**Per-environment override hint.** Staging with a 6h interval gives you slow
CI / QA signal for drift bugs. Consider `ANTIX_BUDGET_RECONCILE_INTERVAL_SECS=900`
(15 min) on staging so divergence metrics and alert rules get realistic
exercise, and keep the default on production.

Observability:

- `antix_budget_reconcile_users_total{direction}` — counter, users processed,
  labelled by drift direction: `in_sync`, `pg_ahead`, `redis_ahead`.
- `antix_budget_reconcile_divergence_micros{direction}` — histogram,
  `|pg - redis|` micro-dollars per user, same labels. Alert on p99 per
  direction (suggested threshold: `100_000` micros = $0.10 sustained).
- `antix_budget_reconcile_errors_total{reason}` — counter; `reason` is
  `pg_scan` or `redis`.
- `antix_budget_reconcile_cycle_duration_seconds{outcome}` — histogram of
  wall-clock cycle duration, `outcome` is `completed` or `scan_failed`.
  Growing p99 = scale the scan query before the user table gets too large.
