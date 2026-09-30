# Skill routing

Always load `growthops-engineering` first.

Then load only skills relevant to the task.

## Architecture proposal / repository skeleton

Use:
- growthops-engineering
- typescript-node-architecture
- monorepo-typescript
- testing-typescript-systems when test/build structure is involved
- verification-loop before completion

Do not load crawler/database/security references unless the architecture decision actually touches them.

## Domain + SQLite

Use:
- growthops-engineering
- typescript-node-architecture
- sqlite-data-modeling
- testing-typescript-systems
- verification-loop

Also load application-security-local-first if storing paths, secrets, untrusted payloads, or security-sensitive configuration.

## Job engine

Use:
- growthops-engineering
- typescript-node-architecture
- sqlite-data-modeling
- testing-typescript-systems
- verification-loop

Focus on persistent state, retries, claims, checkpoints, and restart safety.

## Crawler

Use:
- growthops-engineering
- resilient-crawler-engineering
- application-security-local-first
- sqlite-data-modeling
- testing-typescript-systems
- typescript-node-architecture when package/API boundaries change
- verification-loop

## Parser / deterministic checks

Use:
- growthops-engineering
- typescript-node-architecture
- testing-typescript-systems
- application-security-local-first when parsing hostile HTML/XML
- verification-loop

## Evidence / Finding / Priority

Use:
- growthops-engineering
- typescript-node-architecture
- sqlite-data-modeling
- testing-typescript-systems
- verification-loop

Finding creation must be traceable to persisted evidence.

## Actions / Verification

Use:
- growthops-engineering
- typescript-node-architecture
- sqlite-data-modeling
- testing-typescript-systems
- application-security-local-first if any external/mutating capability is introduced
- verification-loop

## Reporting

Use:
- growthops-engineering
- application-security-local-first
- testing-typescript-systems
- typescript-node-architecture
- verification-loop

HTML report work must load HTML/report XSS safety reference.

## Web UI

Use:
- growthops-engineering
- vercel-react-best-practices when applicable to selected stack
- web-design-guidelines
- a product-UI appropriate design skill
- testing-typescript-systems
- verification-loop

Do not automatically load landing-page-oriented design skills for dense audit/dashboard UI if the skill itself says it is out of scope.

## Browser verifier

Use:
- growthops-engineering
- resilient-crawler-engineering
- application-security-local-first
- playwright-cli or approved browser skill
- testing-typescript-systems
- verification-loop

## Optional AI

Use:
- growthops-engineering
- application-security-local-first
- testing-typescript-systems
- relevant AI/provider skill only when selected

AI must consume bounded structured evidence and remain optional.

## Debugging

When a bug/test failure exists:
- systematic-debugging first;
- then domain-specific skill;
- verification-loop before declaring fixed.

## Code review

Use:
- growthops-engineering
- requesting-code-review
- relevant domain skill(s)
- verification-loop

## Context discipline

Do not load every skill because they exist.

Typical task should use:
- growthops-engineering;
- 1-4 domain skills;
- verification-loop.

Load references within each skill only when the current change needs them.
