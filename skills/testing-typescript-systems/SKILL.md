---
name: testing-typescript-systems
description: "Design, implement, or review tests for TypeScript systems with durable state and network boundaries: Vitest unit/integration tests, fixture-driven regression suites, MSW/network mocks, SQLite tests, fault injection, restart/resume verification, and focused E2E coverage. Use for test strategy, regression coverage, crawler/database/job testing, or proving a feature is actually complete."
---

# Testing TypeScript Systems

Use this skill for system behavior where correctness spans more than a pure function.

## Load references selectively

- Test pyramid, unit/integration boundaries, Vitest conventions:
  `references/test-levels-and-vitest.md`
- Fixtures and regression corpus:
  `references/fixtures-and-regressions.md`
- Network determinism and MSW:
  `references/network-testing.md`
- SQLite, jobs, crash/restart, fault injection:
  `references/durability-and-faults.md`
- E2E and release-gate strategy:
  `references/e2e-and-release-gates.md`

## Core principles

1. Test observable behavior and invariants, not private implementation details.
2. Put each test at the lowest layer that can prove the behavior.
3. Unit tests should be fast and deterministic.
4. Integration tests should exercise real boundaries where bugs actually occur.
5. Network tests must not depend on the public internet unless explicitly marked as non-deterministic smoke tests.
6. Durable systems must be tested across restart/interruption boundaries.
7. Every production bug should earn a regression test or fixture.
8. Fixtures are versioned test assets, not disposable samples.
9. Mock only the external boundary you do not own.
10. Do not mock the unit under test into proving itself.
11. A passing happy path is not enough for retryable/resumable systems.
12. Never claim coverage or reliability without evidence from executed tests.

## Default test layering

Prefer:

```
unit
  ↓
package integration
  ↓
cross-package integration
  ↓
targeted E2E
```

Do not push everything into Playwright.

Use browser E2E only for user-visible flows or behavior that cannot be proven cheaply below the UI.

## What belongs where

Unit:
- URL normalization;
- rule evaluation;
- state-transition validation;
- parsers/serializers;
- priority calculations;
- retry classification.

Integration:
- SQLite repository behavior;
- migration behavior;
- crawler + queue + persistence;
- HTTP client against deterministic mocked responses;
- report generation from real stored records;
- job claiming/checkpoint/resume.

E2E:
- create project;
- launch scan;
- inspect findings;
- create action;
- verify result;
- open generated report;
- critical onboarding/release flows.

## Failure-first mindset

For every feature ask:
- what if input is malformed?
- what if dependency times out?
- what if operation runs twice?
- what if process dies halfway through?
- what if DB write fails after external work?
- what if optional subsystem is unavailable?
- what if stale state exists after restart?

Tests should prove defined behavior for those cases.

## Workflow

Before implementation:
1. identify acceptance criteria;
2. map each criterion to a test level;
3. identify reusable fixtures;
4. identify failure modes;
5. define deterministic boundaries.

During implementation:
- add focused tests near the changed behavior;
- prefer small explicit fixtures over giant opaque snapshots;
- keep tests readable enough to explain the contract.

After implementation:
1. run focused tests first;
2. run affected package/integration tests;
3. run broader regression suite appropriate to change;
4. run E2E only where relevant;
5. run repository verification loop;
6. report exact PASS/FAIL/NOT RUN status.

## Red flags

Stop and reconsider if:
- tests only assert that mocks were called;
- all dependencies are mocked, so integration never happens;
- network tests call random public websites;
- a crawler retry test uses real sleep for long backoff;
- restart-safe code has no restart test;
- migrations are tested only on fresh databases;
- snapshots hide large behavioral changes;
- tests depend on execution order;
- production data or user files are used as fixtures;
- a flaky test is simply retried until green.
