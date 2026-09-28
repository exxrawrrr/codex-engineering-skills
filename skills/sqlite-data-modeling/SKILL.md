---
name: sqlite-data-modeling
description: "Design reliable SQLite persistence for local-first TypeScript applications: durable schema modeling, migrations, transactions, indexes, foreign keys, history, idempotency, restart-safe jobs, checkpoints, locking, and query behavior. Use when changing durable models, migrations, repositories, job state, or historical records."
---

# SQLite Data Modeling

Use this skill for durable application state backed by SQLite.

## Load references selectively

- Runtime pragmas, locking, WAL, query/index behavior: `references/sqlite-runtime.md`
- Migration/versioning discipline: `references/migrations.md`
- Durable jobs, retries, checkpoints, history: `references/durable-state.md`

## Core principles

1. Model durable product concepts explicitly.
2. Preserve history when the product must answer "what changed?" or "did it work?".
3. Retryable operations should be idempotent where practical.
4. Multi-write invariants require short transactions.
5. Foreign keys must actually be enabled and tested.
6. Index from real access patterns, not guesswork.
7. Schema changes require versioned migrations.
8. External/network work does not belong inside DB transactions.
9. In-memory queues are not the source of truth for restart-safe work.
10. Crash recovery must distinguish completed, failed, incomplete, and safe-to-resume work.

## Identity

Prefer stable opaque identifiers for durable entities.

Examples:
- project_id
- scan_id
- page_id
- evidence_id
- finding_id
- action_id
- verification_id
- job_id

URLs, names, and titles are mutable attributes, not primary identity.

## Historical behavior

Do not overwrite old scan/evidence/finding/verification data merely to make latest-state queries easier.

Use explicit timestamps and preserve prior observations when history has product value.

## Transactions

Keep transactions short:

1. prepare/read;
2. perform external work outside transaction;
3. open transaction;
4. persist coherent result;
5. commit;
6. report success.

Do not hold a SQLite write transaction open during network crawling.

## Data shape

Relational concepts belong in tables/columns.
JSON is appropriate for raw/forward-compatible metadata, not as an excuse to hide the entire domain in one blob.

## Testing

Test:
- constraints and foreign keys;
- rollback behavior;
- retry/idempotency;
- migration from old schema;
- database busy/locking behavior where relevant;
- crash/restart reconstruction;
- history preservation;
- partial failure not being reported as success.

## Red flags

Stop if:
- latest scan overwrites history;
- resumable jobs exist only in memory;
- retries can duplicate durable outcomes;
- `INSERT OR REPLACE` is used without understanding delete/reinsert semantics;
- foreign keys are declared but not enabled;
- migrations are edited after release/application;
- network calls happen inside DB transactions;
- schema mirrors UI screens instead of durable domain concepts.
