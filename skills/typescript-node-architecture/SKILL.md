---
name: typescript-node-architecture
description: "Design or review architecture-heavy TypeScript/Node.js code using strict typing, explicit boundaries, stable contracts, controlled side effects, and predictable async/error behavior. Use for core/backend packages, services, CLI code, durable workers, or architecture changes."
---

# TypeScript Node Architecture

Use this skill for architecture-sensitive TypeScript/Node.js work, not merely because a file ends in .ts.

## Load references selectively

Read only what the task needs:

- TypeScript/runtime/compiler strictness: `references/typescript-runtime.md`
- Module/domain boundaries and async/error design: `references/architecture-boundaries.md`

## Core rules

1. Keep domain rules independent from UI, transport, persistence, frameworks, and vendors.
2. Dependencies point toward stable contracts, not outward toward implementations.
3. Validate untrusted input at boundaries; use `unknown`, not `any`, until parsed.
4. Prefer explicit states and discriminated unions over scattered magic strings/booleans.
5. Side effects must be visible and owned: network, DB, filesystem, clock, randomness, process state.
6. Bound concurrency and propagate cancellation for interruptible work.
7. Do not hide durable work in fire-and-forget promises.
8. Prefer the smallest reversible design; add abstractions only for real boundaries or repeated behavior.
9. Do not add infrastructure without a demonstrated requirement.
10. Run relevant type/tests/verification before declaring completion.

## Default dependency shape

```
UI / CLI / HTTP
      ↓
Application services / use cases
      ↓
Domain contracts and rules
      ↑
Adapters: database, network, filesystem, vendors
```

Adapters implement contracts owned by inner layers. Domain/core packages do not import adapters.

## Workflow

Before coding:
1. Read repository instructions and relevant specs.
2. Identify the domain boundary being changed.
3. Inspect an existing working pattern.
4. List the minimum files/packages required.

During coding:
- keep the change inside approved scope;
- preserve public behavior unless the spec changes it;
- add tests at the narrowest useful layer;
- treat failure paths as first-class behavior.

After coding:
- run type checks and relevant tests;
- inspect imports/boundaries;
- use the repository verification skill.

## Red flags

Stop and reconsider if:
- strict typing is weakened to make code compile;
- domain code imports an ORM/framework/vendor implementation;
- package internals are deep-imported across boundaries;
- retries/timeouts are duplicated across unrelated layers;
- long-running work has no clear lifecycle owner;
- background work can be lost while the system still reports success;
- a new abstraction exists only to make code look architecturally sophisticated.
