# Test levels and Vitest

## Unit tests

Use unit tests for deterministic logic with narrow dependencies.

Good targets:
- parsers;
- normalizers;
- finite-state transitions;
- scoring/rule functions;
- pure formatting;
- retry decision logic.

Prefer table-driven cases for edge-heavy functions.

## Integration tests

Integration tests should combine real owned components.

Examples:
- repository + SQLite;
- crawler scheduler + durable frontier;
- parser + evidence persistence;
- report renderer + stored findings.

Mock only external systems such as remote HTTP or third-party APIs.

## Vitest conventions

Align with repository configuration rather than inventing a second test framework.

Prefer:
- focused `describe` blocks by behavior;
- explicit test names describing input + outcome;
- fake timers for retry/backoff timing when appropriate;
- isolated temp directories/databases;
- deterministic seeds for randomized/property tests.

Do not depend on wall-clock sleeps when fake clocks can prove the same behavior.

## Assertions

Assert externally meaningful outcomes:
- returned value;
- durable state;
- emitted event;
- error classification;
- filesystem artifact;
- final state transition.

Avoid asserting private helper call order unless ordering itself is the contract.

## Property/invariant testing

For parser/normalizer logic with large input surfaces, property tests can be useful.

Examples:
- normalization is idempotent;
- normalized URL remains parseable;
- serialization round-trips;
- invalid state transitions never succeed.

Use property testing selectively, not as a substitute for readable examples.
