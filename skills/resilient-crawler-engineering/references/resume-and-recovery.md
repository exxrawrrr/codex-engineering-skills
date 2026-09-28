# Resume and recovery

## Incremental durability

Persist useful output as each URL completes.

Do not wait until the end of a 1,000-page crawl to write all results.

Completed work should survive:
- UI closure;
- worker crash;
- application restart.

## Scan state

A scan should track counts derived from durable URL state, such as:

```
discovered
queued
fetching
completed
failed
skipped
robots_blocked
```

Do not rely only on in-memory counters.

## Restart reconciliation

On process startup:
- identify scans/jobs left active;
- inspect URLs left in `fetching`;
- transition them according to recovery policy;
- requeue only work that is safe to retry;
- preserve completed evidence.

A URL left `fetching` after a crash is not automatically completed and not automatically a permanent failure.

## Checkpoints

Use checkpoints when they simplify recovery, but keep durable per-URL state authoritative.

Checkpoint data may include:
- scan configuration fingerprint;
- discovered/completed counts;
- scheduler cursor/priority state;
- crawler version;
- pause state.

Do not serialize an opaque in-memory object graph as the only recovery mechanism.

## Pause and resume

Pause means:
- stop claiming new URLs;
- allow or cancel in-flight work according to defined policy;
- persist stable state;
- transition scan/job to paused.

Resume means:
- reload durable state;
- reconcile stale in-flight rows;
- continue from queued/retryable work.

## Partial completion

A scan can finish with failures.

Example:

```
812 completed
5 failed
0 queued
coverage: 99.39%
```

The report remains valid if it clearly shows missing coverage.

Do not discard 812 successful pages because 5 failed.

## Failure containment

Separate:
- per-URL failure;
- parser/check failure;
- optional browser failure;
- database/system failure.

Per-URL and optional-subsystem failures should not automatically take down the entire scan.

A persistence/database failure is more serious because durability cannot be trusted; stop claiming successful progress until resolved.
