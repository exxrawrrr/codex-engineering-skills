# Durable state, jobs, and history

## Persistent jobs

Durable jobs need explicit lifecycle state such as:

```
queued
running
paused
completed
failed
cancelled
```

Persist enough state to answer:
- what definitely completed?
- what failed?
- what is incomplete?
- what can safely resume?

Useful fields may include:
- job_id
- type
- status
- attempt_count
- created_at
- started_at
- heartbeat_at when justified
- finished_at
- safe error code/message
- checkpoint/fingerprint

On restart, reconcile jobs left in `running`; never silently mark them successful.

## Idempotency

For retryable operations define:
- operation identity;
- duplicate prevention rule;
- uniqueness scope;
- whether upsert semantics are actually correct.

Use unique constraints/idempotency keys where appropriate.
Avoid blind `INSERT OR REPLACE`.

## Checkpoints

Checkpoint at stable recovery boundaries.
For crawls this may include per-URL state, discovered URLs, completed/failed counts, scan configuration, and version/config fingerprints.

Prefer normalized durable state over serializing a giant opaque process blob.

## Evidence/history

Evidence is an observation at a point in time.
Prefer append-only behavior for observations unless a narrowly defined correction is needed.

Do not mutate old evidence to look like the newest scan.
