# Architecture boundaries

## Contracts

Reusable core code should return stable domain/application outcomes, not leak raw vendor exceptions.

Separate:
- expected domain/application failures;
- invalid external input;
- transient infrastructure failures;
- permanent infrastructure failures;
- invariant/programmer violations.

Add context at boundaries without wrapping the same error repeatedly.

## Async lifecycle

- Every long-running operation has an owner.
- Propagate `AbortSignal` or equivalent cancellation where interruption is valid.
- Never launch unbounded `Promise.all` over unknown input sizes.
- Await persistence required for correctness before reporting success.
- Retries are bounded and belong to the layer that understands failure semantics.
- Cleanup belongs in `finally` or explicit lifecycle hooks.

## Persistence boundary

- Domain/core logic must not depend on ORM query syntax.
- Keep transactions explicit at application/persistence boundaries.
- Retryable/resumable operations should be idempotent where practical.
- Preserve historical records when history is part of product behavior.

## Package API discipline

A package should have one clear responsibility and a narrow public API.

Avoid:
- circular dependencies;
- giant service classes;
- generic `utils` dumping grounds;
- barrels that expose internals;
- duplicate domain types in multiple packages.

If a package cannot be explained in one sentence, ownership is probably wrong.
