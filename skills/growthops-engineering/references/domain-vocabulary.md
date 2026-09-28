# GrowthOps domain vocabulary

Use canonical terms consistently.

## Project

Local container for one audited property/workspace and its history.

## Scan

One execution that collects and evaluates website state.

A scan has lifecycle, progress, coverage, configuration, and durable history.

## Evidence

Observed fact captured from a source at a point in time.

Examples:
- HTTP status;
- title value;
- canonical URL;
- robots directive;
- broken-link response;
- parser/network failure.

Evidence is not a recommendation.

## Finding

Deterministic interpretation of evidence according to a rule/check.

A finding must trace back to evidence.

## Priority

Deterministic prioritization of a finding/action opportunity according to approved rules.

Do not substitute LLM vibes for priority logic.

## Action

Human-managed task created from one or more findings.

V0.1 actions are primarily manual tracking, not autonomous mutation.

## Verification

Targeted re-check used to determine whether an action changed the underlying evidence/finding state.

## Result

Outcome of verification/action, preserving before/after traceability.

## History

Durable timeline across scans, findings, actions, verifications, and results.

## Check

Deterministic evaluation logic that inspects normalized observations/evidence.

## Parser

Transforms fetched source into normalized structured observations.

Parser is not the same as check/finding logic.

## Job

Persistent execution record for long-running/background work.

## Checkpoint

Durable recovery information enabling interrupted work to continue safely.

## Coverage

Share/count of intended/discovered work successfully analyzed.

Coverage must expose unavailable/skipped/blocked work rather than pretending completeness.

## Browser verifier

Targeted browser-based verification subsystem.

It is not the primary crawler.

## AI explanation

Optional interpretation/explanation layer over bounded structured evidence.

It is not a source of deterministic truth and must not be required for core operation.
