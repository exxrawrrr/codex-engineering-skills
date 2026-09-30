---
name: api-contract-testing
description: "Design, implement, or review machine-readable API contract checks for HTTP/provider-consumer boundaries: OpenAPI/schema conformance, backward-compatibility diffs, consumer-driven contracts, provider verification, and versioned contract fixtures. Use when an API change may break an existing caller or when CI needs executable compatibility evidence. Do not use as a substitute for general integration testing, API architecture, authorization/security review, or production observability."
---

# API Contract Testing

Use this skill when the question is:

> Does this provider/consumer change preserve the API contract that another component depends on?

Do not load it merely because a task contains HTTP or JSON.

## Load references selectively

- Compatibility direction, change classification, and schema limits:
  `references/compatibility-rules.md`
- Consumer/provider contract workflow and verification evidence:
  `references/provider-consumer-contracts.md`

## Neighboring skills

Use `typescript-node-architecture` to design API/domain boundaries.

Use `testing-typescript-systems` for general unit, integration, fixture, fault, and E2E strategy.

Use `application-security-local-first` for authorization, SSRF, XSS, secrets, and trust boundaries.

This skill owns **executable compatibility evidence for an API contract**.

## When to load

Load this skill when one or more are true:

- an OpenAPI or similar machine-readable description changes;
- a request/response schema may break existing consumers;
- provider implementation must be checked against its published contract;
- consumer expectations need to be captured and replayed against a provider;
- a contract artifact or interaction fixture is versioned in source control;
- CI must block an incompatible provider/consumer change.

## When not to load

Do not load this skill for:

- internal refactors with no externally consumed contract change;
- ordinary endpoint unit/integration tests with no compatibility claim;
- API authentication/authorization design;
- performance/load testing;
- production rollout or rollback planning;
- runtime observability;
- documentation-only prose that is not treated as an executable contract.

## Core rules

1. Define the contract owner and compatibility direction before choosing a tool.
2. Separate **schema validity** from **backward compatibility**.
3. Separate **provider conformance** from **consumer compatibility**.
4. Treat a static schema diff as evidence about the schema, not proof that all consumers are safe.
5. Prefer contract checks against versioned artifacts or explicit consumer expectations.
6. A compatibility rule must state whether it applies to requests, responses, or both.
7. Required-field changes, type narrowing, enum narrowing, status-code changes, and endpoint removal require explicit compatibility review.
8. Do not call an additive change safe without checking the consumer/parser assumptions that matter.
9. Verify the provider against the contract; do not verify only generated documentation.
10. Keep provider states/fixtures deterministic and independent.
11. Record the provider version/ref and contract version/ref when reporting a completed verification.
12. Contract tests complement integration/E2E tests; they do not replace behavioral system tests.
13. Do not infer authorization correctness, semantic correctness, performance, or production readiness from a passing contract check.
14. If no execution occurred, report `NOT_RUN` rather than a compatibility verdict.

## Contract modes

### Schema/provider contract

Examples:
- OpenAPI description;
- JSON Schema used as an interface contract;
- protobuf/IDL or equivalent interface description.

Use this mode to ask:
- is the contract structurally valid?
- does the provider conform to it?
- did a versioned contract change in a potentially incompatible way?

### Consumer-driven contract

Use this mode when actual consumer expectations should constrain the provider.

The useful evidence chain is:

```text
consumer expectation
  -> versioned contract/interactions
  -> provider verification
  -> compatibility result for named versions
```

Do not replace consumer expectations with a giant provider schema if the compatibility question is specifically about what consumers use.

## Compatibility workflow

Before changing code:

1. identify provider and known consumers;
2. identify the contract artifact and its version/ref;
3. define compatibility direction;
4. list the endpoints/interactions affected;
5. classify likely breaking changes;
6. choose schema diff, provider verification, consumer contract verification, or a combination;
7. define exact pass/fail evidence.

During implementation:

- change the contract and implementation intentionally;
- keep generated artifacts reproducible;
- avoid hand-editing generated output when source-of-truth exists;
- add/update provider states or contract fixtures;
- keep each interaction small enough to diagnose.

After implementation:

1. validate the contract syntax/schema;
2. run compatibility diff when version-to-version compatibility is claimed;
3. run provider verification where provider conformance is claimed;
4. run consumer-driven verification where consumer compatibility is claimed;
5. run ordinary integration tests for behavior not represented by the contract;
6. report exact command/result and contract/provider refs;
7. state what remains unproven.

## Evidence preference

Strong evidence:
- exact contract version/ref;
- exact provider/consumer version/ref;
- deterministic verification command;
- named incompatible diff;
- provider verification result;
- consumer interaction verification result;
- failing fixture that becomes passing after a compatible fix.

Weak evidence:
- documentation looks unchanged;
- generated client still compiles in one language;
- endpoint returned 200 once;
- schema file parses;
- a diff tool reported no issue without declaring its compatibility rules.

## Completion rule

A contract-testing task is complete only when a reviewer can answer:

1. What contract was tested?
2. Compatibility in which direction?
3. Which provider/consumer versions were involved?
4. Which checks actually ran?
5. What exact incompatibility would have failed the gate?
6. What remains outside the contract?

## Limitations

This skill does not prove:

- business semantics beyond the encoded contract/interactions;
- authorization or security correctness;
- production data compatibility unless explicitly represented;
- performance or availability;
- safe deployment/rollback;
- compatibility with unknown consumers.

Tool-specific diff rules may also disagree. Preserve the tool/version and do not elevate a tool heuristic into a universal compatibility law.

## Red flags

Stop and reconsider if:

- "schema valid" is reported as "backward compatible";
- only provider tests exist but consumer compatibility is claimed;
- a generated snapshot is approved without a source-of-truth contract;
- provider verification runs against mutable/shared production state;
- all consumers are assumed to tolerate unknown fields without evidence;
- version/ref information is omitted from a compatibility result;
- a breaking contract change is hidden by regenerating fixtures without review;
- a passing contract test is used to claim production readiness.
