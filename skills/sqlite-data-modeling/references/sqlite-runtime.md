# SQLite runtime safety

## Connection baseline

For file-backed application databases, evaluate these deliberately:

- `PRAGMA foreign_keys = ON`
- WAL journal mode when concurrent readers + a single writer pattern benefits from it
- a bounded busy timeout/handling policy
- explicit synchronous/durability choice appropriate to the product

Do not cargo-cult pragmas. Verify driver/runtime behavior and test the selected policy.

## WAL

WAL can improve reader/writer coexistence for local applications, but it does not turn SQLite into a distributed database.

Rules:
- keep write transactions short;
- expect only one writer at a time;
- test shutdown/restart behavior;
- understand checkpoint behavior before adding manual checkpoint logic.

## Busy/locked errors

Treat database busy/locked conditions as a distinct infrastructure failure.

Use bounded wait/retry only when retry is semantically safe.
Never spin indefinitely.

## Query safety

- Use parameterized statements.
- Add indexes for actual WHERE/JOIN/ORDER BY patterns.
- Inspect query plans for important slow queries before speculative indexing.
- Composite-index column order should match access patterns.
- Do not index every column.

## Foreign keys

Declaring foreign keys is insufficient if enforcement is disabled.
Enable enforcement on connections and test it.

Choose delete behavior deliberately; do not default to cascade for convenience.
