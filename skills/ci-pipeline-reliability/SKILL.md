---
name: ci-pipeline-reliability
description: "Design, review, or repair CI pipelines so required validation produces trustworthy failure signals: trigger/permission correctness, matrix parity, runner/runtime assumptions, no-soft-fail gates, cache/artifact boundaries, flaky-test policy, and reproducible failure diagnostics. Use for CI workflow reliability before deployment. Do not use for production rollout/rollback strategy, application test design, supply-chain policy, or production observability."
---

# CI Pipeline Reliability

Use this skill when the problem is:

> Can this CI workflow be trusted to run the required checks on the intended changes and fail visibly when those checks fail?

This skill stops at trustworthy pre-deployment validation.

## Load references selectively

- Triggers, permissions, matrices, skip/soft-fail behavior, and runtime assumptions:
  `references/workflow-signal-integrity.md`
- Cache/artifact boundaries, flaky-test handling, retries, and diagnostics:
  `references/cache-artifact-flakiness.md`

## Neighboring skills

Use `testing-typescript-systems` to design the tests themselves.

Use `application-security-local-first` for application trust/security boundaries.

Use release/rollback engineering for production promotion, rollout, and recovery when that skill exists.

This skill owns **whether the CI execution/reporting layer preserves the intended validation signal**.

## When to load

Load this skill when one or more are true:

- a required test or OS/runtime leg may be skipped;
- workflow triggers do not match the intended branch/path/event scope;
- permissions are broader than required or unexpectedly block a gate;
- matrix include/exclude/fail-fast behavior changes validation coverage;
- `continue-on-error` or conditional execution can hide a required failure;
- CI passes while a required validation command never ran;
- cache restoration may make a build non-reproducible or stale;
- artifacts needed by downstream jobs are missing/mis-scoped;
- flaky tests are being retried until green without diagnosis;
- local verification passes but hosted runner assumptions differ.

## When not to load

Do not load this skill for:

- designing application unit/integration/E2E coverage;
- production rollout, canary, blue/green, release promotion, or rollback;
- dependency/supply-chain security policy;
- production logging/metrics/tracing;
- generic local debugging unrelated to CI configuration;
- deployment credentials or environment policy except where CI permission wiring itself is the bug.

## Core rules

1. Define the required CI contract before editing YAML.
2. A required validation gate must fail the workflow when it fails.
3. Distinguish **job cancellation** from **allowed failure**.
4. Distinguish **conditional omission** from a passing check.
5. Matrix coverage is part of the contract; include/exclude changes need review.
6. Record runner OS/image and critical runtime/tool versions when they affect reproducibility.
7. Keep workflow permissions at the least privilege required for the job.
8. Treat fork/untrusted-trigger permission behavior as a separate threat/trust boundary.
9. Pin or deliberately version external actions according to repository policy; do not silently float critical behavior.
10. Cache is an optimization. A cache miss must not make a correct build impossible.
11. Restored cache content is input, not authoritative evidence of a successful current build.
12. Use artifacts for outputs/evidence that downstream jobs or reviewers need.
13. Do not use retry counts to convert a flaky failure into a trustworthy pass.
14. Preserve the first failing signal and diagnostics before retrying.
15. Separate test failure, workflow/configuration failure, runner failure, and external-service failure.
16. Prefer deterministic local/repository fixtures over live external dependencies in required CI gates.
17. Required commands should be visible and reviewable rather than hidden behind opaque scripts with no contract.
18. Report exact PASS/FAIL/SKIPPED/NOT_RUN state; do not summarize skipped required work as green.
19. Do not claim deployment safety because pre-deployment CI is green.

## CI contract worksheet

Before modifying a pipeline, write down:

```text
triggers:
  <events/branches/paths>

required jobs:
  <job names>

required matrix:
  <os/runtime combinations>

required commands:
  <validation commands>

required failure semantics:
  <what must fail the run>

permissions:
  <minimal GITHUB_TOKEN/credentials>

artifacts:
  <what must persist>

cache:
  <what may be reused, and how a miss regenerates it>
```

If you cannot state the intended contract, you cannot tell whether the YAML is reliable.

## Workflow review order

1. **Trigger reachability**
   - Does the workflow run on the events/branches/paths it is supposed to protect?
   - Can a path filter silently omit a required validation?

2. **Permission boundary**
   - What token permissions does each job actually need?
   - Are untrusted/fork events handled safely?

3. **Job dependency graph**
   - Are required jobs reachable?
   - Can `needs`, conditions, or cancellation prevent a gate from running?

4. **Matrix coverage**
   - Enumerate the generated legs.
   - Review include/exclude separately.
   - Confirm experimental/allowed-failure legs are intentionally classified.

5. **Failure propagation**
   - Review job/step `continue-on-error`.
   - Review `if:` conditions on required gates.
   - Ensure wrappers propagate subprocess exit codes.

6. **Runtime assumptions**
   - Verify shell, working directory, package manager/runtime version, services, and environment variables.

7. **Cache and artifacts**
   - Verify keys/restore behavior.
   - Confirm a cache miss rebuilds correctly.
   - Confirm downstream jobs consume current-run artifacts, not accidental stale state.

8. **Diagnostics**
   - Preserve test reports, logs, screenshots/core dumps, or structured failure evidence when useful.

## Matrix discipline

For every required matrix:

- know the exact legs;
- know whether `fail-fast` cancellation is acceptable;
- know which legs, if any, are experimental;
- never let a required leg become allowed-to-fail by accident;
- avoid duplicate legs that add cost without coverage;
- do not infer cross-platform support from one runner.

When independent platform evidence matters, disabling fail-fast can be useful so one failing leg does not erase evidence from the other. That is a tradeoff, not a universal default.

## Flaky test policy

A flaky test is a reliability defect, not a normal green-path feature.

When a test flakes:

1. preserve the original failure;
2. classify whether the cause is test, product, runner, timing, shared state, or external dependency;
3. reproduce with the smallest deterministic fixture possible;
4. fix the cause;
5. quarantine only with an explicit owner/expiry/visibility policy when immediate repair is impossible.

Retries may collect evidence. They must not silently redefine success for a required gate.

## Evidence preference

Strong CI reliability evidence:
- exact workflow/ref;
- expected matrix and observed jobs;
- exact commands/step names;
- runner/runtime version output;
- a negative fixture proving skipped/soft-failed required work is rejected;
- cache-miss success plus cache-hit success where cache correctness matters;
- artifact presence/digest where downstream use matters;
- preserved failing logs/result files.

Weak evidence:
- green badge with unknown skipped steps;
- one successful rerun after a flaky failure;
- local success on a different runtime;
- workflow YAML "looks correct";
- cache hit as proof that current source built successfully.

## Completion rule

A CI reliability task is complete only when a reviewer can answer:

1. What events trigger the required validation?
2. Which jobs/matrix legs are mandatory?
3. Which commands actually ran?
4. How does a required failure propagate?
5. What permissions/runtime assumptions were verified?
6. What cache/artifact behavior matters?
7. What remains outside CI's claim?

## Limitations

This skill does not prove:

- application correctness beyond executed tests;
- production deployment safety;
- rollback readiness;
- dependency/supply-chain integrity;
- runtime production health;
- absence of intermittent infrastructure failures.

A green CI run is evidence for the checks that actually executed, under the recorded environment. Nothing more.

## Red flags

Stop and reconsider if:

- a required step uses `continue-on-error: true`;
- a required matrix leg is excluded without an explicit contract change;
- a green check is produced after the real validation step was skipped;
- flaky tests are retried until green with the first failure discarded;
- cache contents are treated as authoritative current build output;
- a downstream job consumes an artifact whose producer was skipped;
- write permissions are granted "just in case";
- CI success is used as a substitute for deployment/rollback planning.
