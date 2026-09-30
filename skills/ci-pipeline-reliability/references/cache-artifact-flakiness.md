# Cache, artifact, and flakiness discipline

Caches and artifacts both persist data, but they serve different reliability purposes.

## Cache

Use cache to avoid recomputing/downloading reusable inputs or intermediates.

A reliable workflow must still be correct on a cache miss.

Review:
- key inputs;
- restore keys/fallback breadth;
- runtime/OS/tool version in the key when relevant;
- whether generated/compiled state can become stale;
- trust boundary of restored cache contents.

Never cache secrets.

Treat restored cache contents as untrusted/reusable input, not proof of a current successful build.

## Artifact

Use artifacts for current-run outputs that need to:
- pass between jobs;
- remain available for diagnosis;
- be reviewed/downloaded later;
- prove what a build/test step produced.

Examples:
- test reports;
- screenshots;
- logs/core dumps;
- built packages/binaries;
- coverage;
- compatibility reports.

When downstream correctness depends on an artifact:
- ensure the producer job cannot be silently skipped;
- ensure the consumer uses the current run's artifact;
- use names/paths that make version/run identity clear;
- consider digest/attestation requirements when the release process owns them.

## Flakiness

Retries can help diagnose nondeterminism, but retries are not a reliability proof.

Bad pattern:

```text
run test
if fail: retry
if any retry passes: report green
```

Better:
- preserve the first failure;
- mark the gate according to repository flaky-test policy;
- collect repeat evidence;
- fix shared-state/timing/external dependency causes;
- quarantine visibly only as a bounded exception.

## Failure classification

Classify before fixing:

- **product/test failure** — command ran and assertion/build failed;
- **workflow/config failure** — command never ran correctly;
- **runner/environment failure** — required environment unavailable/broken;
- **external dependency failure** — remote service/network dependency failed;
- **flaky/nondeterministic failure** — same controlled state yields inconsistent outcomes.

Do not edit test expectations when the workflow itself is the broken layer.

## Diagnostics

Capture only useful evidence.

Prefer:
- failing command + exit code;
- relevant structured report;
- runner/runtime identity;
- exact matrix leg;
- artifact path/name;
- cache hit/miss/key summary;
- minimal logs around failure.

Avoid giant unbounded logs or secrets in artifacts.
