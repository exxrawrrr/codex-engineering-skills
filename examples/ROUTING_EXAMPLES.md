# Routing Examples

## TypeScript backend refactor

Load:
- typescript-node-architecture
- testing-typescript-systems
- verification-loop

Do not load crawler/security/database skills unless the change touches those boundaries.

## SQLite migration

Load:
- sqlite-data-modeling
- testing-typescript-systems
- typescript-node-architecture
- verification-loop

## Crawler retry bug

Load:
- resilient-crawler-engineering
- application-security-local-first
- testing-typescript-systems
- systematic-debugging
- verification-loop

## New project skill suite

Load:
- agent-skill-authoring

Then create:
- one project router;
- only the generic specialist skills actually needed.

## GrowthOps crawler milestone

Load:
- growthops-engineering
- resilient-crawler-engineering
- application-security-local-first
- sqlite-data-modeling
- testing-typescript-systems
- verification-loop

The project router owns scope; specialist skills own technical depth.


## Skill effectiveness / promotion review

Load:
- agent-skill-evaluation

Also load `agent-skill-authoring` only when the task includes editing the skill itself.

Do not use ordinary application testing guidance as a substitute for skill-on/skill-off evidence.

## API backward-compatibility review

Load:
- api-contract-testing

Also load `testing-typescript-systems` only when the task includes broader integration/test-layer design.

Do not treat schema validity as proof that existing consumers remain compatible.

## CI matrix / silent-skip reliability bug

Load:
- ci-pipeline-reliability

Also load `testing-typescript-systems` only when the task includes designing or repairing the tests themselves.

Do not expand this routing into production deployment rollout or rollback design.

## Runtime / host compatibility support review

Load:
- runtime-compatibility-engineering

Also load `ci-pipeline-reliability` only when the task includes whether the compatibility checks actually execute in CI.

Do not load `api-contract-testing` unless the compatibility question is specifically about an HTTP/provider-consumer contract.

Do not infer untested macOS, Linux distribution, architecture, or runtime-loading support from a different environment's successful run.

## Third-party CI/build input integrity review

Load:
- software-supply-chain-integrity

Also load `ci-pipeline-reliability` only when the task includes whether the integrity/provenance gate actually executes and fails visibly.

Use `application-security-local-first` for runtime/application security, not as a substitute for dependency/action/artifact provenance.

Do not treat a version tag, lockfile, checksum, SBOM, or attestation file as sufficient evidence unless the relevant identity/integrity/provenance verification actually occurs.
