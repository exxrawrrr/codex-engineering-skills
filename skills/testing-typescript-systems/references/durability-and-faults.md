# Durability and fault testing

Durable systems are incomplete until restart behavior is tested.

## SQLite tests

Use isolated temporary database files.

Test:
- fresh schema creation;
- foreign-key enforcement;
- unique constraints;
- transaction rollback;
- busy/locked behavior where relevant;
- old-version migration;
- migration idempotency;
- historical records preserved.

Do not run tests against a developer's real application database.

## Restart/resume

Model process boundaries deliberately.

Example crawl test:

1. create scan;
2. enqueue multiple URLs;
3. process/persist first N;
4. simulate termination;
5. construct fresh application/worker instance;
6. reopen same DB;
7. reconcile stale `running/fetching` state;
8. resume;
9. prove completed URLs are not lost/duplicated;
10. prove remaining URLs finish.

The second half should use new in-memory objects so the test does not accidentally depend on old process state.

## Fault injection

Inject failures at meaningful boundaries:

- DB write failure;
- HTTP timeout/reset;
- parser exception;
- report write failure;
- optional browser failure;
- AI provider failure;
- worker termination between durable steps.

Verify failure containment.

Examples:
- one URL parser failure does not erase other completed URLs;
- browser failure does not fail static audit;
- AI failure does not fail deterministic findings;
- report HTML failure still leaves JSON findings if architecture promises that.

## Partial commit tests

For multi-step operations, inject failure between steps and verify transaction/invariant behavior.

Do not fake durability by only throwing before the operation starts.

## Duplicate delivery/retry

Run the same logical operation twice where retry is possible.

Verify:
- idempotency;
- unique constraints;
- no duplicate durable finding/action/evidence unless duplicates are intentionally historical observations.

## Concurrency

When multiple workers can claim work:
- test double-claim prevention;
- test stale claim recovery;
- test transaction/locking behavior;
- test that counts derive from durable state correctly.

Concurrency tests should be deterministic enough to reproduce failures.
