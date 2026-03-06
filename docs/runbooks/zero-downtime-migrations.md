# Zero/low-downtime migrations (expand/contract)

This runbook shows a practical pattern for making schema changes safely with minimal downtime.

The core idea is to split risky changes into phases:

1) **Expand**: add new columns/tables/indexes in a backward-compatible way.
2) **Backfill**: populate data gradually and safely (often batched).
3) **Contract**: enforce constraints (NOT NULL/UNIQUE) only after the system is ready.

## Local drill (using this repo)

Start the lab:

```bash
make up
```

Apply migrations:

```bash
make migrate
make migrate-status
```

The migration set in `migrations/` demonstrates:
- creating a baseline table
- expanding with a nullable column
- contracting with explicit preconditions (fails loudly if unsafe)

Rollback the last migration (demo only):

```bash
make migrate-rollback
```

## Operational guardrails

- Make preconditions explicit and fail with actionable messages.
- Prefer additive changes first; avoid table rewrites during peak traffic.
- Practice restore and rollback paths in a lab before production use.

